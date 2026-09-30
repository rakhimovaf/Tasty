//
//  SavedRecipe.swift
//  Tasty
//
//  Created by FR. on 26/09/26.
//


import Foundation
import Combine

struct SavedRecipe: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let thumbnailURL: String?
}

@MainActor
final class SavedRecipesStore: ObservableObject {

    static let shared = SavedRecipesStore()

    @Published private(set) var recipes: [SavedRecipe] = []

    private let key = "savedRecipes"

    private init() {
        load()
    }

    // MARK: - Save

    func save(recipe: SavedRecipe) {
        // Agar oldin saqlangan bo'lsa, qayta qo'shmaymiz
        guard !recipes.contains(where: { $0.id == recipe.id }) else {
            return
        }

        recipes.append(recipe)
        persist()
    }

    // MARK: - Remove

    func remove(id: String) {
        recipes.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Check

    func isSaved(id: String) -> Bool {
        recipes.contains { $0.id == id }
    }

    // MARK: - Save to UserDefaults

    private func persist() {
        do {
            let data = try JSONEncoder().encode(recipes)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Could not save recipes:", error)
        }
    }

    // MARK: - Load

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return
        }

        do {
            recipes = try JSONDecoder().decode(
                [SavedRecipe].self,
                from: data
            )
        } catch {
            print("Could not load saved recipes:", error)
        }
    }
}

