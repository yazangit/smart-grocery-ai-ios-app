import SwiftUI
import MapKit
import FirebaseAuth

struct SmartRecipe: Identifiable, Codable {
    var id = UUID().uuidString
    var title: String
    var description: String
    var ingredients: [GroceryItem]
    var steps: [String]
    var cookingTime: String
    var difficulty: String
    var servings: Int
    var estimatedCost: Double
    var icon: String
}

struct ManualSpending: Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var price: Double
    var category: String
    var date: Date
}

struct NearbyShop: Identifiable {
    var id = UUID().uuidString
    var name: String
    var address: String
    var distance: String
    var mapsQuery: String
}

private let demoRecipes: [SmartRecipe] = [
    SmartRecipe(
        title: "Budget Lentil Soup",
        description: "Cheap, warm, and realistic for a student grocery budget.",
        ingredients: [
            GroceryItem(name: "Red lentils", quantity: "300g", price: 1.49),
            GroceryItem(name: "Carrots", quantity: "2", price: 0.50),
            GroceryItem(name: "Onion", quantity: "1", price: 0.30),
            GroceryItem(name: "Vegetable broth", quantity: "1L", price: 0.99),
            GroceryItem(name: "Bread", quantity: "1 loaf", price: 1.29)
        ],
        steps: ["Dice onion and carrots.", "Sauté vegetables.", "Add lentils and broth.", "Simmer for 25 minutes.", "Serve with bread."],
        cookingTime: "40 min",
        difficulty: "Easy",
        servings: 4,
        estimatedCost: 4.57,
        icon: "🥣"
    ),
    SmartRecipe(
        title: "Chicken Rice Bowl",
        description: "Fast weekly meal using common grocery ingredients.",
        ingredients: [
            GroceryItem(name: "Rice", quantity: "300g", price: 1.49),
            GroceryItem(name: "Chicken breast", quantity: "400g", price: 5.99),
            GroceryItem(name: "Mixed vegetables", quantity: "300g", price: 2.99),
            GroceryItem(name: "Soy sauce", quantity: "1 bottle", price: 1.99)
        ],
        steps: ["Cook rice.", "Slice and cook chicken.", "Stir-fry vegetables.", "Combine with sauce.", "Serve warm."],
        cookingTime: "30 min",
        difficulty: "Easy",
        servings: 3,
        estimatedCost: 12.46,
        icon: "🍚"
    ),
    SmartRecipe(
        title: "Pasta with Vegetables",
        description: "Simple dinner with a low estimated basket cost.",
        ingredients: [
            GroceryItem(name: "Pasta", quantity: "400g", price: 1.29),
            GroceryItem(name: "Zucchini", quantity: "2", price: 1.49),
            GroceryItem(name: "Cherry tomatoes", quantity: "250g", price: 1.99),
            GroceryItem(name: "Parmesan", quantity: "50g", price: 1.99)
        ],
        steps: ["Cook pasta.", "Sauté vegetables.", "Mix pasta with vegetables.", "Top with parmesan."],
        cookingTime: "25 min",
        difficulty: "Easy",
        servings: 3,
        estimatedCost: 6.76,
        icon: "🍝"
    )
]

private let cityShops: [String: [NearbyShop]] = [
    "augsburg": [
        NearbyShop(name: "REWE", address: "Augsburg Zentrum", distance: "nearby", mapsQuery: "REWE Augsburg"),
        NearbyShop(name: "Lidl", address: "Augsburg", distance: "nearby", mapsQuery: "Lidl Augsburg"),
        NearbyShop(name: "Aldi Süd", address: "Augsburg", distance: "nearby", mapsQuery: "Aldi Süd Augsburg"),
        NearbyShop(name: "Edeka", address: "Augsburg", distance: "nearby", mapsQuery: "Edeka Augsburg")
    ],
    "munich": [
        NearbyShop(name: "REWE", address: "Munich", distance: "nearby", mapsQuery: "REWE Munich"),
        NearbyShop(name: "Lidl", address: "Munich", distance: "nearby", mapsQuery: "Lidl Munich"),
        NearbyShop(name: "Aldi Süd", address: "Munich", distance: "nearby", mapsQuery: "Aldi Süd Munich"),
        NearbyShop(name: "Edeka", address: "Munich", distance: "nearby", mapsQuery: "Edeka Munich")
    ]
]

struct AIAssistantView: View {
    @ObservedObject var vm: GroceryViewModel
    @AppStorage("smartGroceryCity") private var city = "Augsburg"
    @AppStorage("smartGroceryCountry") private var country = "Germany"
    @AppStorage("smartGroceryPreferredShops") private var preferredShopsData = "REWE,Lidl,Aldi Süd"
    @State private var newShop = ""
    @State private var selectedRecipe: SmartRecipe?
    @State private var successMessage = ""

    private var preferredShops: [String] {
        preferredShopsData.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private var openItemNames: [String] {
        vm.generatedItems.map { $0.item.name }
    }

    private var weeklyRecommendation: SmartRecipe {
        let names = Set(openItemNames.map { $0.lowercased() })
        if names.contains("rice") || names.contains("chicken") { return demoRecipes[1] }
        if names.contains("pasta") { return demoRecipes[2] }
        return demoRecipes[0]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        locationCard
                        shopsCard
                        recipeCard(weeklyRecommendation, title: "AI Weekly Recommendation")
                        ForEach(demoRecipes) { recipe in
                            recipeCard(recipe, title: recipe.title)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Assistant")
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe) {
                    addIngredients(recipe)
                }
            }
            .overlay(alignment: .bottom) {
                if !successMessage.isEmpty {
                    Text(successMessage)
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Smart Grocery AI")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Text("Recipe ideas, preferred shops, and fast grocery planning in one native iOS app.")
                .foregroundStyle(.secondary)
        }
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "location.fill")
                .font(.headline)
            HStack {
                TextField("City", text: $city)
                    .textFieldStyle(.roundedBorder)
                TextField("Country", text: $country)
                    .textFieldStyle(.roundedBorder)
            }
            Text("Used for local shop suggestions. Google Maps opens externally from the Shops tab.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(.systemGray6).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var shopsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Preferred Shops", systemImage: "storefront.fill")
                .font(.headline)
            FlowLayout(items: preferredShops) { shop in
                HStack(spacing: 6) {
                    Text(shop)
                    Button {
                        removeShop(shop)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.blue.opacity(0.18))
                .clipShape(Capsule())
            }
            HStack {
                TextField("Add shop", text: $newShop)
                    .textFieldStyle(.roundedBorder)
                Button("Add") { addShop() }
                    .buttonStyle(.borderedProminent)
                    .disabled(newShop.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(18)
        .background(Color(.systemGray6).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func recipeCard(_ recipe: SmartRecipe, title: String) -> some View {
        Button {
            selectedRecipe = recipe
        } label: {
            HStack(spacing: 16) {
                Text(recipe.icon)
                    .font(.system(size: 38))
                    .frame(width: 64, height: 64)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(recipe.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack {
                        Label(recipe.cookingTime, systemImage: "clock")
                        Label(recipe.estimatedCost.formatted(.currency(code: "EUR")), systemImage: "eurosign.circle")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(Color(.systemGray6).opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func addShop() {
        let value = newShop.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        var shops = preferredShops
        if !shops.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
            shops.append(value)
        }
        preferredShopsData = shops.joined(separator: ",")
        newShop = ""
    }

    private func removeShop(_ shop: String) {
        preferredShopsData = preferredShops.filter { $0 != shop }.joined(separator: ",")
    }

    private func addIngredients(_ recipe: SmartRecipe) {
        vm.addRecipeIngredients(recipe.ingredients)
        selectedRecipe = nil
        successMessage = "Ingredients added to your grocery list"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { successMessage = "" }
    }
}

struct RecipeDetailView: View {
    let recipe: SmartRecipe
    let addIngredients: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(recipe.icon).font(.system(size: 54))
                        Text(recipe.description).foregroundStyle(.secondary)
                        HStack {
                            Label(recipe.cookingTime, systemImage: "clock")
                            Label("\(recipe.servings) servings", systemImage: "person.2")
                            Label(recipe.estimatedCost.formatted(.currency(code: "EUR")), systemImage: "eurosign.circle")
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
                Section("Ingredients") {
                    ForEach(recipe.ingredients) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.quantity)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Steps") {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                    }
                }
                Button("Add ingredients to list", action: addIngredients)
                    .font(.headline)
            }
            .navigationTitle(recipe.title)
        }
    }
}

struct BudgetView: View {
    @ObservedObject var vm: GroceryViewModel
    @AppStorage("smartGroceryMonthlyBudget") private var monthlyBudget = 300.0
    @AppStorage("smartGroceryManualSpending") private var manualSpendingData = "[]"
    @State private var budgetInput = "300"
    @State private var showAddSpending = false

    private var manualSpendings: [ManualSpending] {
        (try? JSONDecoder().decode([ManualSpending].self, from: Data(manualSpendingData.utf8))) ?? []
    }

    private var boughtItemsTotal: Double {
        vm.lists.flatMap { $0.items }.filter { $0.bought }.reduce(0) { $0 + $1.price }
    }

    private var openItemsEstimated: Double {
        vm.generatedItems.reduce(0) { $0 + $1.item.price }
    }

    private var manualTotal: Double {
        manualSpendings.reduce(0) { $0 + $1.price }
    }

    private var total: Double { boughtItemsTotal + manualTotal }
    private var remaining: Double { monthlyBudget - total }
    private var progress: Double { monthlyBudget > 0 ? min(total / monthlyBudget, 1) : 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Monthly Budget", systemImage: "wallet.pass.fill")
                                .font(.headline)
                            HStack {
                                TextField("Budget", text: $budgetInput)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                Button("Save") {
                                    if let value = Double(budgetInput), value > 0 { monthlyBudget = value }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            ProgressView(value: progress)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Spent")
                                        .foregroundStyle(.secondary)
                                    Text(total.formatted(.currency(code: "EUR")))
                                        .font(.title2.bold())
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Remaining")
                                        .foregroundStyle(.secondary)
                                    Text(remaining.formatted(.currency(code: "EUR")))
                                        .font(.title2.bold())
                                        .foregroundStyle(remaining < 0 ? .red : .primary)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(.systemGray6).opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            StatCard(title: "Bought Items", value: boughtItemsTotal.formatted(.currency(code: "EUR")), icon: "checkmark.circle.fill")
                            StatCard(title: "Manual", value: manualTotal.formatted(.currency(code: "EUR")), icon: "plus.circle.fill")
                            StatCard(title: "Open Basket", value: openItemsEstimated.formatted(.currency(code: "EUR")), icon: "cart.fill")
                            StatCard(title: "Weekly Target", value: (monthlyBudget / 4).formatted(.currency(code: "EUR")), icon: "calendar")
                        }

                        Button {
                            showAddSpending = true
                        } label: {
                            Label("Add Manual Spending", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                        }
                        .buttonStyle(.borderedProminent)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Manual Spending")
                                .font(.headline)
                            if manualSpendings.isEmpty {
                                Text("No manual spending yet.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(manualSpendings) { item in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.name).font(.headline)
                                            Text(item.category).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(item.price.formatted(.currency(code: "EUR")))
                                    }
                                    Divider()
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(.systemGray6).opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Budget")
            .onAppear { budgetInput = String(format: "%.0f", monthlyBudget) }
            .sheet(isPresented: $showAddSpending) {
                AddSpendingView { spending in
                    var items = manualSpendings
                    items.insert(spending, at: 0)
                    if let data = try? JSONEncoder().encode(items), let json = String(data: data, encoding: .utf8) {
                        manualSpendingData = json
                    }
                    showAddSpending = false
                }
            }
        }
    }
}

struct AddSpendingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var price = ""
    @State private var category = "Food"
    let onSave: (ManualSpending) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Price", text: $price).keyboardType(.decimalPad)
                TextField("Category", text: $category)
            }
            .navigationTitle("New Spending")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(ManualSpending(name: name, price: Double(price) ?? 0, category: category, date: Date()))
                    }
                    .disabled(name.isEmpty || Double(price) == nil)
                }
            }
        }
    }
}

struct ShopsView: View {
    @AppStorage("smartGroceryCity") private var city = "Augsburg"
    @AppStorage("smartGroceryCountry") private var country = "Germany"

    private var shops: [NearbyShop] {
        cityShops[city.lowercased()] ?? cityShops["augsburg"] ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                List {
                    Section("Search Area") {
                        TextField("City", text: $city)
                        TextField("Country", text: $country)
                    }
                    Section("Nearby Supermarkets") {
                        ForEach(shops) { shop in
                            Button {
                                openMaps(shop)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "storefront.fill")
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading) {
                                        Text(shop.name).font(.headline)
                                        Text(shop.address).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "map.fill")
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Shops")
        }
    }

    private func openMaps(_ shop: NearbyShop) {
        let query = shop.mapsQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shop.name
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
}

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @AppStorage("smartGroceryLanguage") private var language = "English"
    @AppStorage("smartGroceryCurrency") private var currency = "EUR"
    @AppStorage("smartGroceryMonthlyBudget") private var monthlyBudget = 300.0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                Form {
                    Section("Preferences") {
                        Picker("Language", selection: $language) {
                            Text("English").tag("English")
                            Text("Deutsch").tag("Deutsch")
                            Text("Arabic").tag("Arabic")
                        }
                        TextField("Currency", text: $currency)
                        Stepper("Budget: \(monthlyBudget.formatted(.currency(code: currency)))", value: $monthlyBudget, in: 50...2000, step: 25)
                    }
                    Section("Account") {
                        Button(role: .destructive) {
                            try? Auth.auth().signOut()
                            isLoggedIn = false
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                    Section("Prototype") {
                        Text("Integrated native iOS version: Firebase Auth, Firestore grocery lists, generated weekly list, receipt OCR, budget tracking, recipes, preferred shops, and maps handoff.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
            }
        }
    }
}
