import Combine
import Foundation

@MainActor
final class DataStore: ObservableObject {
    @Published var hasSeenOnboarding: Bool
    @Published var blends: [SpiceBlend]
    @Published var favorites: [String]
    @Published var market: [MarketItem]
    @Published var timers: [CookTimer]
    @Published var lastViewedRecipeID: String?
    @Published var cookDates: [Date]
    @Published var recipeViewDates: [Date]
    @Published var customRecipes: [Recipe]
    @Published var tastingNotes: [TastingNote]
    @Published var pendingTastings: [PendingTasting]
    @Published var weekPlan: [PlannedMeal]

    private let defaults = UserDefaults.standard
    private enum Key {
        static let onboarding = "hasSeenOnboarding"
        static let blends = "savedSpiceBlends"
        static let favorites = "favoriteRecipes"
        static let market = "spiceShoppingList"
        static let timers = "timerDetails"
        static let lastRecipe = "lastViewedRecipeID"
        static let cookDates = "completedCookDates"
        static let recipeViews = "recipeViewDates"
        static let customRecipes = "customKitchenPlates"
        static let tastingNotes = "plateTastingNotes"
        static let pendingTastings = "pendingTastingPrompts"
        static let weekPlan = "weeklyPlatePlan"
    }

    init() {
        hasSeenOnboarding = defaults.bool(forKey: Key.onboarding)
        blends = Self.decode(key: Key.blends)
        favorites = Self.decode(key: Key.favorites)
        market = Self.decode(key: Key.market)
        timers = Self.decode(key: Key.timers)
        lastViewedRecipeID = defaults.string(forKey: Key.lastRecipe)
        cookDates = Self.decode(key: Key.cookDates)
        recipeViewDates = Self.decode(key: Key.recipeViews)
        customRecipes = Self.decode(key: Key.customRecipes)
        tastingNotes = Self.decode(key: Key.tastingNotes)
        pendingTastings = Self.decode(key: Key.pendingTastings)
        weekPlan = Self.decode(key: Key.weekPlan)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Key.onboarding)
    }

    func allRecipes() -> [Recipe] {
        customRecipes + SpiceCatalog.recipes
    }

    func recipe(id: String) -> Recipe? {
        allRecipes().first { $0.id == id }
    }

    func upsertBlend(_ item: SpiceBlend) {
        if let index = blends.firstIndex(where: { $0.id == item.id }) {
            blends[index] = item
        } else {
            blends.append(item)
        }
        persist(blends, key: Key.blends)
        syncMarket(fromSpiceIds: item.spiceIds, note: "For \(item.name)")
    }

    func deleteBlend(_ item: SpiceBlend) {
        blends.removeAll { $0.id == item.id }
        persist(blends, key: Key.blends)
    }

    func toggleFavorite(_ recipeId: String) {
        if let index = favorites.firstIndex(of: recipeId) {
            favorites.remove(at: index)
        } else {
            favorites.append(recipeId)
        }
        persist(favorites, key: Key.favorites)
    }

    func markRecipeViewed(_ id: String) {
        lastViewedRecipeID = id
        defaults.set(id, forKey: Key.lastRecipe)
        recipeViewDates.append(Date())
        persist(recipeViewDates, key: Key.recipeViews)
    }

    func upsertCustomRecipe(_ item: Recipe) {
        var next = item
        next.isCustom = true
        if let index = customRecipes.firstIndex(where: { $0.id == next.id }) {
            customRecipes[index] = next
        } else {
            customRecipes.append(next)
        }
        persist(customRecipes, key: Key.customRecipes)
        syncMarket(fromSpiceIds: next.spiceIds, note: "For \(next.title)")
    }

    func deleteCustomRecipe(_ item: Recipe) {
        customRecipes.removeAll { $0.id == item.id }
        persist(customRecipes, key: Key.customRecipes)
        favorites.removeAll { $0 == item.id }
        persist(favorites, key: Key.favorites)
        weekPlan.removeAll { $0.recipeId == item.id }
        persist(weekPlan, key: Key.weekPlan)
        tastingNotes.removeAll { $0.recipeId == item.id }
        persist(tastingNotes, key: Key.tastingNotes)
    }

    func addTastingNote(_ note: TastingNote) {
        tastingNotes.insert(note, at: 0)
        persist(tastingNotes, key: Key.tastingNotes)
    }

    func dismissPendingTasting() {
        if !pendingTastings.isEmpty {
            pendingTastings.removeFirst()
            persist(pendingTastings, key: Key.pendingTastings)
        }
    }

    func setPlan(weekday: Int, recipeId: String?) {
        weekPlan.removeAll { $0.weekday == weekday }
        if let recipeId {
            weekPlan.append(PlannedMeal(weekday: weekday, recipeId: recipeId))
        }
        persist(weekPlan, key: Key.weekPlan)
    }

    func fillMarketFromWeekPlan() {
        for meal in weekPlan {
            guard let recipe = recipe(id: meal.recipeId) else { continue }
            let day = KitchenWeek.dayNames[meal.weekday]
            syncMarket(fromSpiceIds: recipe.spiceIds, note: "\(day) · \(recipe.title)")
        }
    }

    func upsertMarket(_ item: MarketItem) {
        if let index = market.firstIndex(where: { $0.id == item.id }) {
            market[index] = item
        } else {
            market.append(item)
        }
        persist(market, key: Key.market)
    }

    func deleteMarket(_ item: MarketItem) {
        market.removeAll { $0.id == item.id }
        persist(market, key: Key.market)
    }

    func upsertTimer(_ item: CookTimer, syncAlert: Bool = true) {
        var next = item
        if next.isRunning, next.remaining > 0 {
            next.endsAt = Date().addingTimeInterval(TimeInterval(next.remaining))
        } else {
            next.endsAt = nil
        }
        if let index = timers.firstIndex(where: { $0.id == next.id }) {
            timers[index] = next
        } else {
            timers.append(next)
        }
        persist(timers, key: Key.timers)
        if syncAlert {
            if next.isRunning, next.remaining > 0 {
                KitchenAlerts.shared.prepare()
                KitchenAlerts.shared.schedule(next)
            } else {
                KitchenAlerts.shared.cancel(next.id)
            }
        }
    }

    func deleteTimer(_ item: CookTimer) {
        timers.removeAll { $0.id == item.id }
        persist(timers, key: Key.timers)
        KitchenAlerts.shared.cancel(item.id)
    }

    func tickTimers() {
        var changed = false
        for index in timers.indices where timers[index].isRunning {
            let end = timers[index].endsAt ?? Date().addingTimeInterval(TimeInterval(timers[index].remaining))
            timers[index].endsAt = end
            let left = max(0, Int(ceil(end.timeIntervalSinceNow)))
            if left != timers[index].remaining {
                timers[index].remaining = left
                changed = true
            }
            if left == 0 {
                let finished = timers[index]
                timers[index].isRunning = false
                timers[index].endsAt = nil
                cookDates.append(Date())
                pendingTastings.append(PendingTasting(dishName: finished.dishName, recipeId: finished.recipeId))
                persist(pendingTastings, key: Key.pendingTastings)
                KitchenAlerts.shared.cancel(finished.id)
                Haptics.success()
                changed = true
            }
        }
        if changed {
            persist(timers, key: Key.timers)
            persist(cookDates, key: Key.cookDates)
        }
    }

    func matchingRecipes(for blend: SpiceBlend) -> [Recipe] {
        allRecipes().filter { recipe in
            !Set(recipe.spiceIds).isDisjoint(with: Set(blend.spiceIds))
        }
    }

    private func syncMarket(fromSpiceIds spiceIds: [String], note: String) {
        for spiceId in spiceIds {
            guard let spice = SpiceCatalog.spice(id: spiceId) else { continue }
            let exists = market.contains { $0.name.compare(spice.name, options: .caseInsensitive) == .orderedSame }
            if !exists {
                market.append(MarketItem(name: spice.name, quantity: "1 jar", category: spice.category, note: note, purchased: false))
            }
        }
        persist(market, key: Key.market)
    }

    func resetAllData() {
        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
        hasSeenOnboarding = false
        blends = []
        favorites = []
        market = []
        timers = []
        lastViewedRecipeID = nil
        cookDates = []
        recipeViewDates = []
        customRecipes = []
        tastingNotes = []
        pendingTastings = []
        weekPlan = []
        KitchenAlerts.shared.cancelAll()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func decode<T: Decodable>(key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key), let value = try? JSONDecoder().decode([T].self, from: data) else {
            return []
        }
        return value
    }
}
