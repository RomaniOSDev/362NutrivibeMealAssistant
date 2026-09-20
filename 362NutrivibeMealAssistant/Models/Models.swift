import Foundation

struct Spice: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var category: String
    var note: String
}

struct SpiceBlend: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var spiceIds: [String]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, spiceIds: [String], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.spiceIds = spiceIds
        self.createdAt = createdAt
    }
}

struct RecipeIngredient: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var grams: Double

    init(id: UUID = UUID(), name: String, grams: Double) {
        self.id = id
        self.name = name
        self.grams = grams
    }
}

struct Recipe: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var title: String
    var summary: String
    var minutes: Int
    var spiceIds: [String]
    var steps: [String]
    var ingredients: [RecipeIngredient]
    var isCustom: Bool
    var blendId: UUID?

    init(id: String, title: String, summary: String, minutes: Int, spiceIds: [String], steps: [String], ingredients: [RecipeIngredient] = [], isCustom: Bool = false, blendId: UUID? = nil) {
        self.id = id
        self.title = title
        self.summary = summary
        self.minutes = minutes
        self.spiceIds = spiceIds
        self.steps = steps
        self.ingredients = ingredients
        self.isCustom = isCustom
        self.blendId = blendId
    }

    var heatLevel: String {
        if spiceIds.contains("chili") { return "Hot" }
        if spiceIds.contains("paprika") || spiceIds.contains("cinnamon") { return "Medium" }
        return "Mild"
    }

    var timeBand: String {
        if minutes <= 20 { return "Quick" }
        if minutes <= 35 { return "Standard" }
        return "Slow"
    }
}

struct MarketItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var quantity: String
    var category: String
    var note: String
    var purchased: Bool

    init(id: UUID = UUID(), name: String, quantity: String, category: String, note: String, purchased: Bool) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.category = category
        self.note = note
        self.purchased = purchased
    }
}

struct CookTimer: Identifiable, Codable, Equatable {
    var id: UUID
    var dishName: String
    var blendId: UUID?
    var recipeId: String?
    var duration: Int
    var remaining: Int
    var isRunning: Bool
    var endsAt: Date?

    init(id: UUID = UUID(), dishName: String, blendId: UUID?, recipeId: String? = nil, duration: Int, remaining: Int, isRunning: Bool, endsAt: Date? = nil) {
        self.id = id
        self.dishName = dishName
        self.blendId = blendId
        self.recipeId = recipeId
        self.duration = duration
        self.remaining = remaining
        self.isRunning = isRunning
        if isRunning, remaining > 0 {
            self.endsAt = endsAt ?? Date().addingTimeInterval(TimeInterval(remaining))
        } else {
            self.endsAt = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, dishName, blendId, recipeId, duration, remaining, isRunning, endsAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        dishName = try c.decode(String.self, forKey: .dishName)
        blendId = try c.decodeIfPresent(UUID.self, forKey: .blendId)
        recipeId = try c.decodeIfPresent(String.self, forKey: .recipeId)
        duration = try c.decode(Int.self, forKey: .duration)
        remaining = try c.decode(Int.self, forKey: .remaining)
        isRunning = try c.decode(Bool.self, forKey: .isRunning)
        endsAt = try c.decodeIfPresent(Date.self, forKey: .endsAt)
    }
}

struct TastingNote: Identifiable, Codable, Equatable {
    var id: UUID
    var recipeId: String
    var dishName: String
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), recipeId: String, dishName: String, text: String, createdAt: Date = Date()) {
        self.id = id
        self.recipeId = recipeId
        self.dishName = dishName
        self.text = text
        self.createdAt = createdAt
    }
}

struct PendingTasting: Identifiable, Codable, Equatable {
    var id: UUID
    var dishName: String
    var recipeId: String?

    init(id: UUID = UUID(), dishName: String, recipeId: String?) {
        self.id = id
        self.dishName = dishName
        self.recipeId = recipeId
    }
}

struct PlannedMeal: Identifiable, Codable, Equatable {
    var id: UUID
    var weekday: Int
    var recipeId: String

    init(id: UUID = UUID(), weekday: Int, recipeId: String) {
        self.id = id
        self.weekday = weekday
        self.recipeId = recipeId
    }
}

struct SpiceSwap: Identifiable, Equatable {
    var id: String { fromId + "-" + toId }
    var fromId: String
    var toId: String
    var fromName: String
    var toName: String
    var note: String
}

enum KitchenWeek {
    static let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
}

enum KitchenScale {
    static func grams(_ value: Double, factor: Double) -> String {
        let scaled = value * factor
        if abs(scaled - scaled.rounded()) < 0.05 {
            return "\(Int(scaled.rounded()))g"
        }
        return String(format: "%.1fg", scaled)
    }

    static func text(_ text: String, factor: Double) -> String {
        guard factor != 1 else { return text }
        guard let regex = try? NSRegularExpression(pattern: #"\d+(?:\.\d+)?"#) else { return text }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        var result = text
        for match in matches.reversed() {
            guard let range = Range(match.range, in: text), let value = Double(text[range]) else { continue }
            let scaled = value * factor
            let token = abs(scaled - scaled.rounded()) < 0.05 ? "\(Int(scaled.rounded()))" : String(format: "%.1f", scaled)
            result.replaceSubrange(range, with: token)
        }
        return result
    }

    static func minutes(_ minutes: Int, factor: Double) -> Int {
        max(1, Int((Double(minutes) * factor).rounded()))
    }
}

enum SpiceCatalog {
    static let all: [Spice] = [
        Spice(id: "cumin", name: "Cumin", category: "Seeds", note: "Warm earth, good with beans."),
        Spice(id: "paprika", name: "Paprika", category: "Powders", note: "Sweet smoke for stews."),
        Spice(id: "coriander", name: "Coriander", category: "Seeds", note: "Citrus lift for fish."),
        Spice(id: "turmeric", name: "Turmeric", category: "Powders", note: "Golden color, mild bitterness."),
        Spice(id: "chili", name: "Chili flakes", category: "Heat", note: "Finish oils and eggs."),
        Spice(id: "cinnamon", name: "Cinnamon", category: "Bark", note: "Sweet warmth for braises."),
        Spice(id: "cardamom", name: "Cardamom", category: "Pods", note: "Floral, pairs with coffee."),
        Spice(id: "fennel", name: "Fennel seed", category: "Seeds", note: "Anise note for sausage."),
        Spice(id: "oregano", name: "Oregano", category: "Herbs", note: "Tomato sauces and bread."),
        Spice(id: "thyme", name: "Thyme", category: "Herbs", note: "Roasts and mushrooms.")
    ]

    static let recipes: [Recipe] = [
        Recipe(
            id: "lentil",
            title: "Charred lentil stew",
            summary: "Cumin and paprika over tomatoes.",
            minutes: 35,
            spiceIds: ["cumin", "paprika", "chili"],
            steps: ["Bloom 8g cumin, 10g paprika, and 3g chili in 20g oil.", "Add 250g lentils and 400g tomatoes.", "Simmer 20 minutes until thick."],
            ingredients: [
                RecipeIngredient(name: "Cumin", grams: 8),
                RecipeIngredient(name: "Paprika", grams: 10),
                RecipeIngredient(name: "Chili flakes", grams: 3),
                RecipeIngredient(name: "Oil", grams: 20),
                RecipeIngredient(name: "Lentils", grams: 250),
                RecipeIngredient(name: "Tomatoes", grams: 400)
            ]
        ),
        Recipe(
            id: "fish",
            title: "Citrus roast fish",
            summary: "Coriander crust with lemon.",
            minutes: 22,
            spiceIds: ["coriander", "thyme"],
            steps: ["Crush 6g coriander with 3g thyme.", "Rub over 400g fish with 60g lemon.", "Roast 12 minutes until just opaque."],
            ingredients: [
                RecipeIngredient(name: "Coriander", grams: 6),
                RecipeIngredient(name: "Thyme", grams: 3),
                RecipeIngredient(name: "Fish", grams: 400),
                RecipeIngredient(name: "Lemon", grams: 60)
            ]
        ),
        Recipe(
            id: "rice",
            title: "Golden pilaf",
            summary: "Turmeric rice with cinnamon bark.",
            minutes: 28,
            spiceIds: ["turmeric", "cinnamon", "cardamom"],
            steps: ["Toast 200g rice in 25g ghee.", "Add 4g turmeric, 3g cinnamon, 2g cardamom, and 400g stock.", "Steam covered 18 minutes."],
            ingredients: [
                RecipeIngredient(name: "Rice", grams: 200),
                RecipeIngredient(name: "Ghee", grams: 25),
                RecipeIngredient(name: "Turmeric", grams: 4),
                RecipeIngredient(name: "Cinnamon", grams: 3),
                RecipeIngredient(name: "Cardamom", grams: 2),
                RecipeIngredient(name: "Stock", grams: 400)
            ]
        ),
        Recipe(
            id: "sausage",
            title: "Fennel skillet",
            summary: "Fennel sausage with oregano.",
            minutes: 18,
            spiceIds: ["fennel", "oregano", "chili"],
            steps: ["Brown 350g sausage in the pan.", "Add 5g fennel seed and 2g chili.", "Finish with 3g oregano."],
            ingredients: [
                RecipeIngredient(name: "Sausage", grams: 350),
                RecipeIngredient(name: "Fennel seed", grams: 5),
                RecipeIngredient(name: "Chili flakes", grams: 2),
                RecipeIngredient(name: "Oregano", grams: 3)
            ]
        ),
        Recipe(
            id: "beans",
            title: "Herb white beans",
            summary: "Thyme pot beans, olive oil.",
            minutes: 40,
            spiceIds: ["thyme", "oregano", "cumin"],
            steps: ["Sweat 80g onion in 20g olive oil.", "Add 300g beans, 4g thyme, 3g oregano, and 3g cumin.", "Stew 25 minutes until creamy."],
            ingredients: [
                RecipeIngredient(name: "Onion", grams: 80),
                RecipeIngredient(name: "Olive oil", grams: 20),
                RecipeIngredient(name: "White beans", grams: 300),
                RecipeIngredient(name: "Thyme", grams: 4),
                RecipeIngredient(name: "Oregano", grams: 3),
                RecipeIngredient(name: "Cumin", grams: 3)
            ]
        )
    ]

    static let flavorScores: [String: (heat: Double, smoke: Double, citrus: Double, floral: Double)] = [
        "cumin": (0.25, 0.35, 0.15, 0.05),
        "paprika": (0.35, 0.95, 0.05, 0.1),
        "coriander": (0.1, 0.05, 0.95, 0.25),
        "turmeric": (0.2, 0.15, 0.25, 0.1),
        "chili": (1.0, 0.35, 0.05, 0.0),
        "cinnamon": (0.15, 0.25, 0.1, 0.45),
        "cardamom": (0.1, 0.05, 0.35, 1.0),
        "fennel": (0.1, 0.05, 0.25, 0.7),
        "oregano": (0.2, 0.15, 0.15, 0.35),
        "thyme": (0.1, 0.2, 0.2, 0.3)
    ]

    static let substitutes: [String: [(id: String, note: String)]] = [
        "coriander": [("cumin", "Warm earth instead of citrus lift."), ("fennel", "Sweeter, with a light anise edge.")],
        "cumin": [("coriander", "Brighter and less earthy."), ("paprika", "Color and smoke, softer bite.")],
        "paprika": [("chili", "More heat, less sweet smoke."), ("cumin", "Earth instead of smoke.")],
        "chili": [("paprika", "Gentler warmth and color."), ("cumin", "Earth without the burn.")],
        "turmeric": [("paprika", "Color with smoke instead of gold."), ("cinnamon", "Warm sweetness, no bitterness.")],
        "cinnamon": [("cardamom", "Floral instead of bark-sweet."), ("cumin", "Savory warmth for braises.")],
        "cardamom": [("cinnamon", "Sweet bark in place of floral pods."), ("fennel", "Anise perfume, less citrus.")],
        "fennel": [("coriander", "Citrus instead of anise."), ("cardamom", "More floral, still sweet.")],
        "oregano": [("thyme", "Woodier herb for the same pot."), ("cumin", "Earth if the jar is empty.")],
        "thyme": [("oregano", "Bolder herb, same savory path."), ("coriander", "Citrus lift on roasts.")]
    ]

    static func spice(id: String) -> Spice? {
        all.first { $0.id == id }
    }

    static func names(for ids: [String]) -> [String] {
        ids.compactMap { spice(id: $0)?.name }
    }

    static func profile(for spiceIds: [String]) -> (heat: Double, smoke: Double, citrus: Double, floral: Double) {
        let scores = spiceIds.compactMap { flavorScores[$0] }
        guard !scores.isEmpty else { return (0, 0, 0, 0) }
        let n = Double(scores.count)
        return (
            scores.reduce(0) { $0 + $1.heat } / n,
            scores.reduce(0) { $0 + $1.smoke } / n,
            scores.reduce(0) { $0 + $1.citrus } / n,
            scores.reduce(0) { $0 + $1.floral } / n
        )
    }

    static func flavorCaption(for spiceIds: [String]) -> String {
        let p = profile(for: spiceIds)
        return [("Heat", p.heat), ("Smoke", p.smoke), ("Citrus", p.citrus), ("Floral", p.floral)]
            .sorted { $0.1 > $1.1 }
            .prefix(2)
            .filter { $0.1 >= 0.2 }
            .map(\.0)
            .joined(separator: " · ")
    }

    static func swaps(for spiceIds: [String]) -> [SpiceSwap] {
        spiceIds.flatMap { id -> [SpiceSwap] in
            guard let from = spice(id: id) else { return [] }
            return (substitutes[id] ?? []).compactMap { pair in
                guard let to = spice(id: pair.id) else { return nil }
                return SpiceSwap(fromId: id, toId: pair.id, fromName: from.name, toName: to.name, note: pair.note)
            }
        }
    }

    static func blendOfTheDay(on date: Date = Date()) -> (name: String, spiceIds: [String]) {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 1
        var ids = all.map(\.id)
        var seed = UInt64(bitPattern: Int64(day)) &* 1_103_515_245 &+ 12_345
        for i in stride(from: ids.count - 1, through: 1, by: -1) {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            let j = Int(seed % UInt64(i + 1))
            ids.swapAt(i, j)
        }
        let count = 2 + (day % 3)
        let titles = ["Dawn jar", "Market dust", "Sunday heat", "Citrus shelf", "Smoke tin", "Herb wrap", "Night braise"]
        return (titles[day % titles.count], Array(ids.prefix(count)))
    }
}
