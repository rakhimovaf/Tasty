//
//  HomeViewModel.swift
//  Tasty
//
//  Created by FR. on 16/09/26.
//


import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var selectedCategory: MealCategory = .breakfast
    @Published var meals: [MealSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""


    @Published var isSearching = false

    enum MealCategory: String, CaseIterable, Identifiable {
        case breakfast = "Breakfast"
        case beef = "Beef"
        case chicken = "Chicken"
        case pasta = "Pasta"
        case seafood = "Seafood"
        case dessert = "Dessert"
        case vegetarian = "Vegetarian"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .breakfast: return "Breakfast"
            case .beef: return "Beef"
            case .chicken: return "Chicken"
            case .pasta: return "Pasta"
            case .seafood: return "Seafood"
            case .dessert: return "Dessert"
            case .vegetarian: return "Vegetarian"
            }
        }

        var icon: String {
            switch self {
            case .breakfast: return "sunrise"
            case .beef: return "flame"
            case .chicken: return "bird"
            case .pasta: return "fork.knife"
            case .seafood: return "fish"
            case .dessert: return "birthday.cake"
            case .vegetarian: return "leaf"
            }
        }
    }


    var filteredMeals: [MealSummary] {
        meals
    }

    func loadMeals() async {
        isLoading = true
        errorMessage = nil

        do {
            meals = try await MealDBService.shared.filter(
                byCategory: selectedCategory.rawValue
            )
        } catch {
            errorMessage = "No internet connection."
            meals = []
        }

        isLoading = false
    }


    func searchByIngredient() async {
        let ingredient = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !ingredient.isEmpty else {
            await loadMeals()
            return
        }

        isSearching = true
        isLoading = true
        errorMessage = nil

        do {
            meals = try await MealDBService.shared.filter(
                byIngredient: ingredient
            )

            if meals.isEmpty {
                errorMessage = "No recipes found for \(ingredient)."
            }

        } catch {
            errorMessage = "Could not search recipes."
            meals = []
        }

        isLoading = false
        isSearching = false
    }

    func selectCategory(_ category: MealCategory) async {
        guard category != selectedCategory else { return }

        selectedCategory = category
        searchText = ""
        await loadMeals()
    }
}
