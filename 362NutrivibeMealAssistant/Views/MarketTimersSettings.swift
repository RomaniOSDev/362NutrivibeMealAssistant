import SwiftUI

struct MarketView: View {
    @EnvironmentObject private var store: DataStore
    @State private var name = ""
    @State private var quantity = "1 jar"
    @State private var category = "Herbs"
    @State private var error = ""
    private let categories = ["Herbs", "Seeds", "Powders", "Heat", "Bark", "Pods"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Market list")
                    .font(.system(size: 32, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                if store.market.isEmpty {
                    RecipeCard(title: "Your spice list is empty", detail: "Start by adding essential ingredients, or save a blend to auto-fill the jars you need.")
                } else {
                    ForEach(store.market) { item in
                        HStack(alignment: .top) {
                            Button {
                                var next = item
                                next.purchased.toggle()
                                store.upsertMarket(next)
                                if next.purchased { Haptics.success() }
                            } label: {
                                Image(systemName: item.purchased ? "checkmark.square.fill" : "square")
                                    .foregroundColor(Color("AppPrimary"))
                                    .font(.title3)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(.headline, design: .serif))
                                    .strikethrough(item.purchased)
                                    .foregroundColor(Color("AppPrimary"))
                                Text("\(item.quantity) · \(item.category)")
                                    .font(.system(.caption, design: .serif))
                                    .foregroundColor(Color("AppPrimary").opacity(0.6))
                                if !item.note.isEmpty {
                                    Text(item.note)
                                        .font(.system(.caption2, design: .serif))
                                        .foregroundColor(Color("AppPrimary"))
                                }
                                if let swap = marketSwap(for: item.name) {
                                    Text("Swap: \(swap.toName). \(swap.note)")
                                        .font(.system(.caption2, design: .serif))
                                        .foregroundColor(Color("AppPrimary").opacity(0.65))
                                }
                            }
                            Spacer()
                            Button { store.deleteMarket(item) } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(Color("AppPrimary").opacity(0.35))
                            }
                        }
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Color("AppPrimary").opacity(0.12)).frame(height: 1)
                        }
                    }
                }
                TextField("Spice name", text: $name)
                    .padding(10)
                    .background(Color.white)
                    .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.2), lineWidth: 1))
                TextField("Quantity", text: $quantity)
                    .padding(10)
                    .background(Color.white)
                    .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.2), lineWidth: 1))
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Color("AppPrimary"))
                if !error.isEmpty { Text(error).foregroundColor(.red).font(.caption) }
                StampButton(title: "Add spice", action: add)
            }
            .padding(20)
        }
        .kitchenScreen()
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { error = "Name the spice."; return }
        let duplicate = store.market.contains { $0.name.compare(trimmed, options: .caseInsensitive) == .orderedSame && $0.category == category }
        if duplicate {
            error = "That spice is already in this category."
            return
        }
        error = ""
        store.upsertMarket(MarketItem(name: trimmed, quantity: quantity.trimmingCharacters(in: .whitespacesAndNewlines), category: category, note: "", purchased: false))
        name = ""
        Haptics.success()
    }

    private func marketSwap(for name: String) -> SpiceSwap? {
        guard let spice = SpiceCatalog.all.first(where: { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }) else { return nil }
        return SpiceCatalog.swaps(for: [spice.id]).first
    }
}

struct TimerBoardView: View {
    @EnvironmentObject private var store: DataStore
    @State private var dish = ""
    @State private var minutes = 10
    @State private var blendId: UUID?
    @State private var error = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Kitchen timers")
                    .font(.system(size: 32, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                if store.timers.isEmpty {
                    RecipeCard(title: "Create your first timer", detail: "Name it after a dish or a saved blend so the kitchen stays in sync.")
                } else {
                    ForEach(store.timers) { timer in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(timer.dishName)
                                    .font(.system(.headline, design: .serif))
                                    .foregroundColor(Color("AppPrimary"))
                                Text(format(timer.remaining))
                                    .font(.system(size: 28, design: .serif).weight(.bold))
                                    .foregroundColor(Color("AppPrimary"))
                            }
                            Spacer()
                            Button {
                                var next = timer
                                next.isRunning.toggle()
                                store.upsertTimer(next)
                            } label: {
                                Text(timer.isRunning ? "Pause" : "Start")
                                    .font(.system(.caption, design: .serif).weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color("AppPrimary"))
                                    .foregroundColor(.white)
                            }
                            Button { store.deleteTimer(timer) } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(Color("AppPrimary").opacity(0.35))
                            }
                        }
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Color("AppPrimary").opacity(0.12)).frame(height: 1)
                        }
                    }
                }
                TextField("Dish name", text: $dish)
                    .padding(10)
                    .background(Color.white)
                    .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.2), lineWidth: 1))
                Stepper("Duration \(minutes) min", value: $minutes, in: 1...180)
                    .foregroundColor(Color("AppPrimary"))
                if !store.blends.isEmpty {
                    Picker("Linked blend", selection: $blendId) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(store.blends) { Text($0.name).tag(Optional($0.id)) }
                    }
                    .tint(Color("AppPrimary"))
                }
                if !error.isEmpty { Text(error).foregroundColor(.red).font(.caption) }
                StampButton(title: "Start timer", action: add)
            }
            .padding(20)
        }
        .kitchenScreen()
        .onAppear {
            if blendId == nil { blendId = store.blends.first?.id }
        }
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func add() {
        var title = dish.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty, let blend = store.blends.first(where: { $0.id == blendId }) {
            title = blend.name
        }
        if title.isEmpty { error = "Name the dish or pick a blend."; return }
        if minutes < 1 { error = "Duration must be at least one minute."; return }
        error = ""
        let total = minutes * 60
        store.upsertTimer(CookTimer(dishName: title, blendId: blendId, duration: total, remaining: total, isRunning: true))
        dish = ""
        Haptics.success()
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Kitchen desk")
                    .font(.system(size: 32, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                StampButton(title: "Rate Us") { viewModel.rateApp() }
                StampButton(title: "Privacy") { viewModel.openPrivacy() }
                StampButton(title: "Terms") { viewModel.openTerms() }
                Button {
                    viewModel.confirmReset = true
                } label: {
                    Text("Reset All Data")
                        .font(.system(.body, design: .serif).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundColor(Color("AppPrimary"))
                        .overlay(Rectangle().stroke(Color("AppPrimary"), lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .kitchenScreen()
        .confirmationDialog("Clear blends, market list, favorites, and timers?", isPresented: $viewModel.confirmReset, titleVisibility: .visible) {
            Button("Reset All Data", role: .destructive) { store.resetAllData() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
