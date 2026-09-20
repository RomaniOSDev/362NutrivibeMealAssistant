import SwiftUI

struct BlendLibraryView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showEditor = false
    @State private var editing: SpiceBlend?
    @State private var plateFromBlend: SpiceBlend?
    @State private var query = ""
    @State private var category = "All"
    private let daily = SpiceCatalog.blendOfTheDay()
    private let categories = ["All"] + Array(Set(SpiceCatalog.all.map(\.category))).sorted()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Polaroid(image: "banner_herbs", tilt: -2)
                        .padding(.horizontal, 28)
                    Text("Spice shelf")
                        .font(.system(size: 34, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                    dailyCard
                    KitchenField(placeholder: "Search jars or spices", text: $query)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { item in
                                FilterChip(title: item, selected: category == item) { category = item }
                            }
                        }
                    }
                    if visibleBlends.isEmpty {
                        RecipeCard(title: store.blends.isEmpty ? "No blends yet" : "No jars match", detail: store.blends.isEmpty ? "Mix two or more spices. The market list fills itself from the jar." : "Try another word or category.")
                    } else {
                        ForEach(visibleBlends) { blend in
                            Button {
                                editing = blend
                                showEditor = true
                            } label: {
                                let caption = SpiceCatalog.flavorCaption(for: blend.spiceIds)
                                RecipeCard(
                                    title: blend.name,
                                    detail: [SpiceCatalog.names(for: blend.spiceIds).joined(separator: " · "), caption].filter { !$0.isEmpty }.joined(separator: " · ")
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Turn into a plate") { plateFromBlend = blend }
                                Button("Delete", role: .destructive) { store.deleteBlend(blend) }
                            }
                        }
                    }
                    StampButton(title: "New blend") {
                        editing = nil
                        showEditor = true
                    }
                }
                .padding(20)
            }
            .navigationBarHidden(true)
            .kitchenScreen()
            .sheet(isPresented: $showEditor, onDismiss: { editing = nil }) {
                BlendEditorView(existing: editing)
                    .environmentObject(store)
            }
            .sheet(item: $plateFromBlend) { blend in
                CustomPlateEditor(blend: blend)
                    .environmentObject(store)
            }
        }
        .kitchenScreen()
    }

    private var dailyCard: some View {
        let exists = store.blends.contains { Set($0.spiceIds) == Set(daily.spiceIds) }
        return VStack(alignment: .leading, spacing: 10) {
            RecipeCard(title: "Jar of the day · \(daily.name)", detail: SpiceCatalog.names(for: daily.spiceIds).joined(separator: " · "))
            FlavorRadar(spiceIds: daily.spiceIds)
            if exists {
                Text("Already on the shelf.")
                    .font(.system(.footnote, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.65))
            } else {
                StampButton(title: "Save this jar") {
                    store.upsertBlend(SpiceBlend(name: daily.name, spiceIds: daily.spiceIds))
                    Haptics.success()
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.72))
        .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.12), lineWidth: 1))
    }

    private var visibleBlends: [SpiceBlend] {
        store.blends.filter { blend in
            let haystack = (blend.name + " " + SpiceCatalog.names(for: blend.spiceIds).joined(separator: " ")).lowercased()
            let matchesQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || haystack.contains(query.lowercased())
            let matchesCategory = category == "All" || blend.spiceIds.contains { SpiceCatalog.spice(id: $0)?.category == category }
            return matchesQuery && matchesCategory
        }
    }
}

struct BlendEditorView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    var existing: SpiceBlend?
    @State private var name = ""
    @State private var selected: Set<String> = []
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Blend name", text: $name)
                if !selected.isEmpty {
                    Section("Flavor") {
                        FlavorRadar(spiceIds: Array(selected))
                        if !SpiceCatalog.flavorCaption(for: Array(selected)).isEmpty {
                            Text(SpiceCatalog.flavorCaption(for: Array(selected)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Section("If a jar is empty") {
                        ForEach(SpiceCatalog.swaps(for: Array(selected))) { swap in
                            Text("\(swap.fromName) → \(swap.toName). \(swap.note)")
                                .font(.caption)
                        }
                    }
                }
                Section("Spices") {
                    ForEach(SpiceCatalog.all) { spice in
                        Button {
                            if selected.contains(spice.id) { selected.remove(spice.id) } else { selected.insert(spice.id) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(spice.name).foregroundColor(.primary)
                                    Text(spice.note).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if selected.contains(spice.id) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color("AppPrimary"))
                                }
                            }
                        }
                    }
                }
                if !error.isEmpty { Text(error).foregroundColor(.red) }
            }
            .navigationTitle(existing == nil ? "Craft blend" : "Edit blend")
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
            .onAppear {
                if let existing {
                    name = existing.name
                    selected = Set(existing.spiceIds)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { error = "Name the blend."; return }
        if selected.count < 2 { error = "Pick at least two spices."; return }
        store.upsertBlend(SpiceBlend(id: existing?.id ?? UUID(), name: trimmed, spiceIds: Array(selected)))
        Haptics.success()
        dismiss()
    }
}

struct RecipeListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var query = ""
    @State private var timeBand = "All"
    @State private var heat = "All"
    @State private var writingPlate = false
    @State private var editingPlate: Recipe?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Polaroid(image: "tile_pan", tilt: 3)
                        .padding(.horizontal, 28)
                    Text("Plates from your jars")
                        .font(.system(size: 30, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                    KitchenField(placeholder: "Search plates", text: $query)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["All", "Quick", "Standard", "Slow"], id: \.self) { item in
                                FilterChip(title: item, selected: timeBand == item) { timeBand = item }
                            }
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["All", "Mild", "Medium", "Hot"], id: \.self) { item in
                                FilterChip(title: item, selected: heat == item) { heat = item }
                            }
                        }
                    }
                    WeekPlanSection()
                    StampButton(title: "Write a plate") { writingPlate = true }
                    let custom = filtered(store.customRecipes)
                    if !custom.isEmpty {
                        Text("Your plates")
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(Color("AppPrimary"))
                        ForEach(custom) { recipe in
                            NavigationLink {
                                RecipeDetailView(recipe: recipe)
                            } label: {
                                RecipeCard(title: recipe.title, detail: "\(recipe.minutes) min · \(recipe.heatLevel) · \(recipe.summary)")
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Edit") { editingPlate = recipe }
                                Button("Delete", role: .destructive) { store.deleteCustomRecipe(recipe) }
                            }
                        }
                    }
                    if store.blends.isEmpty {
                        let catalog = filtered(SpiceCatalog.recipes)
                        if catalog.isEmpty {
                            RecipeCard(title: "No recipes found", detail: "Create a blend or write a plate, then search again.")
                        } else {
                            Text("Catalog plates")
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Color("AppPrimary"))
                            ForEach(catalog) { recipe in
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                } label: {
                                    RecipeCard(title: recipe.title, detail: "\(recipe.minutes) min · \(recipe.heatLevel) · \(recipe.summary)")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        ForEach(store.blends) { blend in
                            let recipes = filtered(store.matchingRecipes(for: blend)).filter { !$0.isCustom }
                            Text(blend.name)
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(Color("AppPrimary"))
                            if recipes.isEmpty {
                                Text("No plate uses these spices yet.")
                                    .font(.system(.footnote, design: .serif))
                                    .foregroundColor(Color("AppPrimary").opacity(0.6))
                            }
                            ForEach(recipes) { recipe in
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                } label: {
                                    RecipeCard(title: recipe.title, detail: "\(recipe.minutes) min · \(recipe.heatLevel) · \(recipe.summary)")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarHidden(true)
            .kitchenScreen()
            .sheet(isPresented: $writingPlate) {
                CustomPlateEditor()
                    .environmentObject(store)
            }
            .sheet(item: $editingPlate) { recipe in
                CustomPlateEditor(existing: recipe)
                    .environmentObject(store)
            }
        }
        .kitchenScreen()
    }

    private func filtered(_ recipes: [Recipe]) -> [Recipe] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return recipes.filter { recipe in
            let haystack = (recipe.title + " " + recipe.summary + " " + SpiceCatalog.names(for: recipe.spiceIds).joined(separator: " ")).lowercased()
            let matchesQuery = needle.isEmpty || haystack.contains(needle)
            let matchesTime = timeBand == "All" || recipe.timeBand == timeBand
            let matchesHeat = heat == "All" || recipe.heatLevel == heat
            return matchesQuery && matchesTime && matchesHeat
        }
    }
}

struct RecipeDetailView: View {
    @EnvironmentObject private var store: DataStore
    let recipe: Recipe
    @State private var factor = 1.0
    @State private var editing = false
    @State private var draftNote = ""
    @Environment(\.dismiss) private var dismiss

    private var current: Recipe {
        store.recipe(id: recipe.id) ?? recipe
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Polaroid(image: "tile_mortar", tilt: -1)
                    .padding(.horizontal, 24)
                Text(current.title)
                    .font(.system(size: 32, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                Text(current.summary)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.7))
                Text("\(KitchenScale.minutes(current.minutes, factor: factor)) min · \(current.heatLevel)")
                    .font(.system(.footnote, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.7))
                ServingPicker(factor: $factor)
                if !current.spiceIds.isEmpty {
                    FlavorRadar(spiceIds: current.spiceIds)
                }
                if !current.ingredients.isEmpty {
                    Text("Grams")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                    ForEach(current.ingredients) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(KitchenScale.grams(item.grams, factor: factor))
                        }
                        .font(.system(.body, design: .serif))
                        .foregroundColor(Color("AppPrimary"))
                    }
                }
                ForEach(Array(current.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(.headline, design: .serif))
                            .foregroundColor(Color("AppPrimary"))
                            .frame(width: 22)
                        Text(KitchenScale.text(step, factor: factor))
                            .font(.system(.body, design: .serif))
                            .foregroundColor(Color("AppPrimary"))
                    }
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color("AppPrimary").opacity(0.15)).frame(height: 1)
                    }
                }
                SwapList(spiceIds: current.spiceIds)
                Text("Tasting notes")
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                TextField("Too sharp, more salt, cook again.", text: $draftNote, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(10)
                    .background(Color.white)
                    .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.2), lineWidth: 1))
                StampButton(title: "Save tasting note") {
                    let trimmed = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.addTastingNote(TastingNote(recipeId: current.id, dishName: current.title, text: trimmed))
                    draftNote = ""
                    Haptics.success()
                }
                let notes = store.tastingNotes.filter { $0.recipeId == current.id || ($0.recipeId.isEmpty && $0.dishName == current.title) }
                if !notes.isEmpty {
                    ForEach(notes) { note in
                        RecipeCard(title: note.dishName, detail: note.text)
                    }
                }
                StampButton(title: "Start \(KitchenScale.minutes(current.minutes, factor: factor)) min timer") {
                    let seconds = KitchenScale.minutes(current.minutes, factor: factor) * 60
                    store.upsertTimer(CookTimer(dishName: current.title, blendId: current.blendId, recipeId: current.id, duration: seconds, remaining: seconds, isRunning: true))
                    Haptics.success()
                }
                StampButton(title: store.favorites.contains(current.id) ? "Saved to favorites" : "Save plate") {
                    store.toggleFavorite(current.id)
                    Haptics.success()
                }
                if current.isCustom {
                    StampButton(title: "Edit plate") { editing = true }
                    Button("Delete plate", role: .destructive) {
                        store.deleteCustomRecipe(current)
                        dismiss()
                    }
                    .font(.system(.body, design: .serif).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(20)
        }
        .canvasBackground()
        .kitchenScreen()
        .onAppear { store.markRecipeViewed(current.id) }
        .sheet(isPresented: $editing) {
            CustomPlateEditor(existing: current)
                .environmentObject(store)
        }
    }
}
