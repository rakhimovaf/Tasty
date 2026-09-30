//
//  RecipeDetailViewModel.swift
//  Tasty
//
//  Created by FR. on 16/09/26.
//


import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class RecipeDetailViewModel: ObservableObject {
    
    // MARK: - Saved Recipe
    
    struct SavedRecipe: Codable, Identifiable, Equatable {
        let id: String
        let name: String
        let thumbnailURL: String?
    }
    
    private static let savedRecipesKey = "savedRecipes"
    
    static func getSavedRecipes() -> [SavedRecipe] {
        guard let data = UserDefaults.standard.data(forKey: savedRecipesKey) else {
            return []
        }
        
        return (try? JSONDecoder().decode([SavedRecipe].self, from: data)) ?? []
    }
    
    static func saveRecipe(_ recipe: SavedRecipe) {
        var recipes = getSavedRecipes()
        
        // Agar oldin saqlangan bo'lsa, yana qo'shmaymiz
        guard !recipes.contains(where: { $0.id == recipe.id }) else {
            return
        }
        
        recipes.append(recipe)
        saveRecipes(recipes)
    }
    
    static func removeRecipe(id: String) {
        var recipes = getSavedRecipes()
        recipes.removeAll { $0.id == id }
        saveRecipes(recipes)
    }
    
    static func isRecipeSaved(id: String) -> Bool {
        getSavedRecipes().contains { $0.id == id }
    }
    
    private static func saveRecipes(_ recipes: [SavedRecipe]) {
        if let data = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(data, forKey: savedRecipesKey)
        }
    }
    
    // MARK: - Recipe
    
    @Published var meal: Meal?
    @Published var isLoading = true
    @Published var errorMessage: String?

    func load(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            meal = try await MealDBService.shared.lookup(id: id)
        } catch {
            errorMessage = "Recipe not found. Try again"
        }
        
        isLoading = false
    }
}

// MARK: - Detail View

struct RecipeDetailView: View {
    let mealID: String
    let mealName: String

    @StateObject private var viewModel = RecipeDetailViewModel()
    @StateObject private var savedStore = SavedRecipesStore.shared

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 80)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text(error)
                        .foregroundStyle(.secondary)
                    Button("Try again") {
                        Task { await viewModel.load(id: mealID) }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 80)
            } else if let meal = viewModel.meal {
                content(for: meal)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(mealName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if savedStore.isSaved(id: mealID) {
                        savedStore.remove(id: mealID)
                    } else {
                        savedStore.save(
                            recipe: SavedRecipe(
                                id: mealID,
                                name: mealName,
                                thumbnailURL: viewModel.meal?.thumbnailURL?.absoluteString
                            )
                        )
                    }
                } label: {
                    Image(
                        systemName: savedStore.isSaved(id: mealID)
                        ? "bookmark.fill"
                        : "bookmark"
                    )
                }
            }
        }
        .task {
            await viewModel.load(id: mealID)
        }
    }

    // MARK: - Content

    private func content(for meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            heroImage(meal)

            VStack(alignment: .leading, spacing: 20) {
                titleSection(meal)
                Divider()
                ingredientsSection(meal)
                Divider()
                instructionsSection(meal)

                if let youtube = meal.youtubeURL,
                   !youtube.isEmpty,
                   let url = URL(string: youtube) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                            Text("Watch full recipe")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    private func heroImage(_ meal: Meal) -> some View {
        AsyncImage(url: meal.thumbnailURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Color(.tertiarySystemFill)
            default:
                Color(.tertiarySystemFill)
                    .overlay(ProgressView())
            }
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func titleSection(_ meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(meal.name)
                .font(.title2.bold())

            HStack(spacing: 8) {
                if let category = meal.category {
                    tagChip(category, icon: "tag")
                }
                if let area = meal.area {
                    tagChip(area, icon: "globe")
                }
            }
        }
    }

    private func tagChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }

    private func ingredientsSection(_ meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Igredients")
                    .font(.headline)
                Spacer()
                Text("\(meal.ingredients.count) cup ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(meal.ingredients) { ingredient in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.4))
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)

                        Text(ingredient.name)
                            .font(.subheadline)

                        Spacer()

                        Text(ingredient.measure)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func instructionsSection(_ meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)

            let steps = (meal.instructions ?? "")
                .components(separatedBy: CharacterSet(charactersIn: ".\n"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 12 }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.accentColor)
                            .clipShape(Circle())

                        Text(step)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(mealID: "52772", mealName: "Teriyaki Chicken Casserole")
    }
}

