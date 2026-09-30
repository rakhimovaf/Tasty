//
//  CategoriesView.swift
//  Tasty
//
//  Created by FR. on 31/07/26.
//
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Premium

    @State private var isPremium: Bool = false
    @State private var showingPaywall = false

    // MARK: - Saved Recipes

    @State private var savedRecipes: [RecipeDetailViewModel.SavedRecipe] = []
    @State private var emptyBounce = false

    var body: some View {
        NavigationStack {
            List {

                // MARK: - Profile / Premium

                Section {
                    HStack(spacing: 14) {

                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 52, height: 52)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.title3)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("User")
                                .font(.headline)

                            Text(isPremium ? "Premium Member" : "Free Plan")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .contentTransition(.opacity)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .staggeredAppear(0)

                    // Premium button
                    if !isPremium {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {

                                Text("Upgrade to Premium")

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }

                // MARK: - Recipes

                Section("Recipes") {
                    NavigationLink {
                        savedRecipesView
                    } label: {
                        Label(
                            "Saved Recipes",
                            systemImage: "bookmark.fill"
                        )
                    }
                    .staggeredAppear(2)
                }

            }
            .animation(Motion.smooth, value: isPremium)
            .scrollContentBackground(.hidden)
            .background { AnimatedBackground() }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                loadSavedRecipes()
            }
        }
    }

    // MARK: - Saved Recipes View

    private var savedRecipesView: some View {
        Group {

            if savedRecipes.isEmpty {

                // Empty state
                VStack(spacing: 14) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 45))
                        .foregroundStyle(.secondary)
                        .symbolEffect(.bounce, value: emptyBounce)

                    Text("No Saved Recipes")
                        .font(.headline)

                    Text("Save your favorite recipes and find them here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .staggeredAppear(0)
                .onAppear { emptyBounce.toggle() }

            } else {

                // Saved recipes list
                List {
                    ForEach(Array(savedRecipes.enumerated()), id: \.element.id) { index, recipe in

                        NavigationLink {
                            RecipeDetailView(
                                mealID: recipe.id,
                                mealName: recipe.name
                            )
                        } label: {
                            HStack(spacing: 12) {

                                AsyncImage(
                                    url: URL(string: recipe.thumbnailURL ?? "")
                                ) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .transition(.opacity)
                                } placeholder: {
                                    Color(.secondarySystemBackground)
                                }
                                .frame(
                                    width: 70,
                                    height: 70
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 12
                                    )
                                )

                                Text(recipe.name)
                                    .font(.headline)
                                    .lineLimit(2)

                                Spacer()
                            }
                        }
                        .staggeredAppear(index)
                    }
                    .onDelete { indexSet in

                        for index in indexSet {
                            let recipe = savedRecipes[index]

                            RecipeDetailViewModel.removeRecipe(
                                id: recipe.id
                            )
                        }

                        withAnimation(Motion.smooth) {
                            loadSavedRecipes()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .animation(Motion.smooth, value: savedRecipes.count)
            }
        }
        .navigationTitle("Saved Recipes")
        .onAppear {
            loadSavedRecipes()
        }
    }

    // MARK: - Load Saved Recipes

    private func loadSavedRecipes() {
        savedRecipes = RecipeDetailViewModel.getSavedRecipes()
    }
}

#Preview {
    SettingsView()
}
