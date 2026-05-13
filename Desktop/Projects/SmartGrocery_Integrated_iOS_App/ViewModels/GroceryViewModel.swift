import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import Vision
import UIKit

final class GroceryViewModel: ObservableObject {
    @Published var lists: [GroceryList] = []
    @Published var shoppingSessions: [ShoppingSession] = []
    
    let db = Firestore.firestore()
    
    var generatedItems: [GeneratedEntry] {
        lists.flatMap { list in
            list.items
                .filter { !$0.bought }
                .map { GeneratedEntry(list: list, item: $0) }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    func createAccount(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    func fetchLists() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("lists")
            .getDocuments { snapshot, _ in
                self.lists = snapshot?.documents.map { doc in
                    GroceryList(
                        id: doc.documentID,
                        name: doc["name"] as? String ?? "",
                        icon: doc["icon"] as? String ?? "🛒",
                        items: []
                    )
                } ?? []
                
                for list in self.lists {
                    self.fetchItems(for: list.id)
                }
            }
    }
    
    func addList(name: String, icon: String) {
        let newList = GroceryList(name: name, icon: icon)
        lists.append(newList)
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .setData(["created": true], merge: true)
        
        db.collection("users")
            .document(userId)
            .collection("lists")
            .document(newList.id)
            .setData([
                "name": newList.name,
                "icon": newList.icon
            ])
    }
    
    func deleteList(listId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let listRef = db.collection("users")
            .document(userId)
            .collection("lists")
            .document(listId)
        
        listRef.collection("items").getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
            listRef.delete()
        }
        
        lists.removeAll { $0.id == listId }
    }
    
    func addItem(to listId: String, name: String, quantity: String, price: Double) {
        guard let index = lists.firstIndex(where: { $0.id == listId }) else { return }
        
        let newItem = GroceryItem(name: name, quantity: quantity, price: price)
        lists[index].items.append(newItem)
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("lists")
            .document(listId)
            .collection("items")
            .document(newItem.id)
            .setData([
                "name": newItem.name,
                "quantity": newItem.quantity,
                "price": newItem.price,
                "bought": newItem.bought
            ])
    }
    
    func fetchItems(for listId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("lists")
            .document(listId)
            .collection("items")
            .getDocuments { snapshot, _ in
                let items = snapshot?.documents.map { doc in
                    GroceryItem(
                        id: doc.documentID,
                        name: doc["name"] as? String ?? "",
                        quantity: doc["quantity"] as? String ?? "",
                        price: doc["price"] as? Double ?? 0.0,
                        bought: doc["bought"] as? Bool ?? false
                    )
                } ?? []
                
                if let index = self.lists.firstIndex(where: { $0.id == listId }) {
                    self.lists[index].items = items
                }
            }
    }
    
    func deleteItem(listId: String, itemId: String) {
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }) else { return }
        lists[listIndex].items.removeAll { $0.id == itemId }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("lists")
            .document(listId)
            .collection("items")
            .document(itemId)
            .delete()
    }
    
    func toggleBought(listId: String, itemId: String) {
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }) else { return }
        guard let itemIndex = lists[listIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        
        lists[listIndex].items[itemIndex].bought.toggle()
        let newStatus = lists[listIndex].items[itemIndex].bought
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("lists")
            .document(listId)
            .collection("items")
            .document(itemId)
            .updateData(["bought": newStatus])
    }
    
    func fetchAllItemsForGeneratedList() {
        for list in lists {
            fetchItems(for: list.id)
        }
    }
    
    func markAllGeneratedItemsAsBought() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let shoppingTotal = generatedItems.reduce(0) { $0 + $1.item.price }
        saveShoppingSession(total: shoppingTotal)
        
        for listIndex in lists.indices {
            for itemIndex in lists[listIndex].items.indices {
                if !lists[listIndex].items[itemIndex].bought {
                    let listId = lists[listIndex].id
                    let itemId = lists[listIndex].items[itemIndex].id
                    
                    lists[listIndex].items[itemIndex].bought = true
                    
                    db.collection("users")
                        .document(userId)
                        .collection("lists")
                        .document(listId)
                        .collection("items")
                        .document(itemId)
                        .updateData(["bought": true])
                }
            }
        }
    }
    
    func generateAIList() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let allItems = lists.flatMap { $0.items }

        let openItemNames = Set(
            allItems
                .filter { !$0.bought }
                .map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        )

        let boughtItems = allItems
            .filter { $0.bought }
            .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let grouped = Dictionary(grouping: boughtItems) { item in
            item.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let suggestions = grouped
            .filter { key, items in
                items.count >= 2 && !openItemNames.contains(key)
            }
            .sorted { first, second in
                first.value.count > second.value.count
            }
            .prefix(5)
            .compactMap { _, items in
                items.last
            }

        guard !suggestions.isEmpty else {
            print("No strong AI suggestions yet.")
            return
        }

        let aiList = GroceryList(name: "AI Weekly List", icon: "✨")
        lists.append(aiList)

        let listRef = db.collection("users")
            .document(userId)
            .collection("lists")
            .document(aiList.id)

        listRef.setData([
            "name": aiList.name,
            "icon": aiList.icon
        ])

        for item in suggestions {
            let newItem = GroceryItem(
                name: item.name,
                quantity: item.quantity,
                price: item.price,
                bought: false
            )

            listRef.collection("items")
                .document(newItem.id)
                .setData([
                    "name": newItem.name,
                    "quantity": newItem.quantity,
                    "price": newItem.price,
                    "bought": false
                ])
        }

        fetchLists()
    }
    
    func addRecipeIngredients(_ ingredients: [GroceryItem]) {
        let targetListName = "Recipe Ingredients"
        let targetListId: String

        if let existing = lists.first(where: { $0.name == targetListName }) {
            targetListId = existing.id
        } else {
            let recipeList = GroceryList(name: targetListName, icon: "🍳")
            lists.append(recipeList)
            targetListId = recipeList.id

            if let userId = Auth.auth().currentUser?.uid {
                db.collection("users")
                    .document(userId)
                    .collection("lists")
                    .document(recipeList.id)
                    .setData([
                        "name": recipeList.name,
                        "icon": recipeList.icon
                    ])
            }
        }

        for ingredient in ingredients {
            addItem(to: targetListId, name: ingredient.name, quantity: ingredient.quantity, price: ingredient.price)
        }
    }

    func saveShoppingSession(total: Double) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard total > 0 else { return }

        let session = ShoppingSession(total: total, date: Date())
        shoppingSessions.append(session)

        db.collection("users")
            .document(userId)
            .collection("shoppingSessions")
            .document(session.id)
            .setData([
                "total": session.total,
                "date": Timestamp(date: session.date)
            ])
    }
    
    func fetchShoppingSessions() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(userId)
            .collection("shoppingSessions")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, _ in
                self.shoppingSessions = snapshot?.documents.map { doc in
                    ShoppingSession(
                        id: doc.documentID,
                        total: doc["total"] as? Double ?? 0.0,
                        date: (doc["date"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
            }
    }
    
    func extractText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }

            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            DispatchQueue.main.async {
                completion(text)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
    
    func extractTotalAmount(from text: String) -> Double? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        func extractAmount(from line: String) -> Double? {
            let pattern = #"(\d+[,.]\d{2})"#

            guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            let range = NSRange(line.startIndex..., in: line)

            guard let match = regex.firstMatch(in: line, range: range),
                  let r = Range(match.range(at: 1), in: line) else { return nil }

            let value = String(line[r]).replacingOccurrences(of: ",", with: ".")
            return Double(value)
        }

        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()

            if lower.contains("total") && !lower.contains("subtotal") {
                if let amount = extractAmount(from: line) {
                    return amount
                }

                if index + 1 < lines.count {
                    if let amount = extractAmount(from: lines[index + 1]) {
                        return amount
                    }
                }
            }
        }

        let allAmounts = lines.compactMap { extractAmount(from: $0) }
        return allAmounts.max()
    }
}
