import SwiftUI

struct SwapList: View {
    let spiceIds: [String]

    var body: some View {
        let swaps = SpiceCatalog.swaps(for: spiceIds)
        if !swaps.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("If a jar is empty")
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                ForEach(swaps) { swap in
                    Text("\(swap.fromName) → \(swap.toName). \(swap.note)")
                        .font(.system(.footnote, design: .serif))
                        .foregroundColor(Color("AppPrimary").opacity(0.75))
                }
            }
        }
    }
}

struct ServingPicker: View {
    @Binding var factor: Double
    private let options: [(Double, String)] = [(0.5, "½×"), (1, "1×"), (2, "2×"), (4, "4×")]

    var body: some View {
        HStack(spacing: 8) {
            Text("Scale")
                .font(.system(.subheadline, design: .serif))
                .foregroundColor(Color("AppPrimary"))
            Spacer()
            ForEach(options, id: \.0) { option in
                FilterChip(title: option.1, selected: factor == option.0) {
                    factor = option.0
                }
            }
        }
    }
}

struct WeekPlanSection: View {
    @EnvironmentObject private var store: DataStore
    @State private var pickingDay: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Week of plates")
                .font(.system(.headline, design: .serif))
                .foregroundColor(Color("AppPrimary"))
            HStack(alignment: .top, spacing: 5) {
                ForEach(0..<7, id: \.self) { day in
                    Button {
                        pickingDay = day
                    } label: {
                        VStack(spacing: 4) {
                            Text(KitchenWeek.dayNames[day])
                                .font(.system(.caption2, design: .serif).weight(.bold))
                            Text(slotTitle(for: day))
                                .font(.system(size: 9, design: .serif))
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(Color("AppPrimary"))
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .top)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                        .background(Color.white.opacity(0.9))
                        .overlay(Rectangle().stroke(Color("AppPrimary").opacity(planned(day) == nil ? 0.15 : 0.45), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            StampButton(title: "Add week's spices to the list") {
                store.fillMarketFromWeekPlan()
                Haptics.success()
            }
        }
        .sheet(isPresented: Binding(get: { pickingDay != nil }, set: { if !$0 { pickingDay = nil } })) {
            if let day = pickingDay {
                PlanRecipePicker(day: day) { recipeId in
                    store.setPlan(weekday: day, recipeId: recipeId)
                    pickingDay = nil
                }
                .environmentObject(store)
            }
        }
    }

    private func planned(_ day: Int) -> PlannedMeal? {
        store.weekPlan.first { $0.weekday == day }
    }

    private func slotTitle(for day: Int) -> String {
        guard let meal = planned(day), let recipe = store.recipe(id: meal.recipeId) else { return "—" }
        return recipe.title
    }
}

private struct PlanRecipePicker: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let day: Int
    let onPick: (String?) -> Void

    var body: some View {
        NavigationStack {
            List {
                Button("Clear this day") { onPick(nil) }
                    .foregroundColor(Color("AppPrimary"))
                ForEach(choices) { recipe in
                    Button {
                        onPick(recipe.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.title).foregroundColor(.primary)
                            Text("\(recipe.minutes) min · \(recipe.heatLevel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(KitchenWeek.dayNames[day])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    private var choices: [Recipe] {
        let all = store.allRecipes()
        let favs = store.favorites.compactMap { id in all.first { $0.id == id } }
        let rest = all.filter { !store.favorites.contains($0.id) }
        return favs + rest
    }
}

struct TastingNoteSheet: View {
    @EnvironmentObject private var store: DataStore
    let pending: PendingTasting
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("How was \(pending.dishName)?")
                    .font(.system(size: 26, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Text("Two or three lines. Too sharp, more salt, cook it again.")
                    .font(.system(.footnote, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.7))
                TextField("Write the tasting note", text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(10)
                    .background(Color.white)
                    .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.2), lineWidth: 1))
                StampButton(title: "Save note", action: save)
                Button("Skip") { store.dismissPendingTasting() }
                    .font(.system(.body, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { Keyboard.dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            store.addTastingNote(TastingNote(recipeId: pending.recipeId ?? "", dishName: pending.dishName, text: trimmed))
            Haptics.success()
        }
        store.dismissPendingTasting()
    }
}

struct CustomPlateEditor: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    var existing: Recipe?
    var blend: SpiceBlend?
    @State private var title = ""
    @State private var summary = ""
    @State private var minutes = 25
    @State private var selected: Set<String> = []
    @State private var steps: [String] = [""]
    @State private var ingredients: [RecipeIngredient] = [RecipeIngredient(name: "", grams: 0)]
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Plate name", text: $title)
                TextField("Short note", text: $summary)
                Stepper("Duration \(minutes) min", value: $minutes, in: 5...180)
                Section("Spices") {
                    ForEach(SpiceCatalog.all) { spice in
                        Button {
                            if selected.contains(spice.id) { selected.remove(spice.id) } else { selected.insert(spice.id) }
                        } label: {
                            HStack {
                                Text(spice.name).foregroundColor(.primary)
                                Spacer()
                                if selected.contains(spice.id) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color("AppPrimary"))
                                }
                            }
                        }
                    }
                }
                Section("Steps") {
                    ForEach(steps.indices, id: \.self) { index in
                        TextField("Step \(index + 1)", text: $steps[index])
                    }
                    Button("Add step") { steps.append("") }
                }
                Section("Grams") {
                    ForEach(ingredients.indices, id: \.self) { index in
                        HStack {
                            TextField("Ingredient", text: bindingName(index))
                            TextField("g", text: bindingGrams(index))
                                .keyboardType(.decimalPad)
                                .frame(width: 72)
                        }
                    }
                    Button("Add ingredient") { ingredients.append(RecipeIngredient(name: "", grams: 0)) }
                }
                if !error.isEmpty { Text(error).foregroundColor(.red) }
            }
            .navigationTitle(existing == nil ? "Write a plate" : "Edit plate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { Keyboard.dismiss() }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onAppear { load() }
        }
    }

    private func load() {
        if let existing {
            title = existing.title
            summary = existing.summary
            minutes = existing.minutes
            selected = Set(existing.spiceIds)
            steps = existing.steps.isEmpty ? [""] : existing.steps
            ingredients = existing.ingredients.isEmpty ? [RecipeIngredient(name: "", grams: 0)] : existing.ingredients
        } else if let blend {
            title = blend.name
            selected = Set(blend.spiceIds)
            summary = SpiceCatalog.names(for: blend.spiceIds).joined(separator: " · ")
        }
    }

    private func bindingName(_ index: Int) -> Binding<String> {
        Binding(
            get: { ingredients.indices.contains(index) ? ingredients[index].name : "" },
            set: { if ingredients.indices.contains(index) { ingredients[index].name = $0 } }
        )
    }

    private func bindingGrams(_ index: Int) -> Binding<String> {
        Binding(
            get: {
                guard ingredients.indices.contains(index) else { return "" }
                let value = ingredients[index].grams
                return value == 0 ? "" : String(format: value == floor(value) ? "%.0f" : "%.1f", value)
            },
            set: { ingredients[index].grams = Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
        )
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSteps = steps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let cleanIngredients = ingredients.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if trimmed.isEmpty { error = "Name the plate."; return }
        if selected.isEmpty { error = "Pick at least one spice."; return }
        if cleanSteps.isEmpty { error = "Add at least one step."; return }
        error = ""
        store.upsertCustomRecipe(
            Recipe(
                id: existing?.id ?? UUID().uuidString,
                title: trimmed,
                summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
                minutes: minutes,
                spiceIds: Array(selected),
                steps: cleanSteps,
                ingredients: cleanIngredients.map { RecipeIngredient(id: $0.id, name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines), grams: $0.grams) },
                isCustom: true,
                blendId: blend?.id ?? existing?.blendId
            )
        )
        Haptics.success()
        dismiss()
    }
}
