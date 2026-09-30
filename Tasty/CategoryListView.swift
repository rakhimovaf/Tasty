//
//  CategoryListView.swift
//  Tasty
//
//  Created by FR. on 07/09/26.
//

//
//import SwiftUI
//
//struct CategoryListView: View {
//    let category: MealCategory
//    @EnvironmentObject var recipeStore: RecipeStore
//
//    var recipes: [Recipe] {
//        recipeStore.recipes(for: category)
//    }
//
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
//                ForEach(recipes) { recipe in
//                    NavigationLink {
//                        RecipeDetailView(recipe: recipe)
//                    } label: {
//                        RecipeCard(recipe: recipe, compact: false)
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//            .padding()
//        }
//        .background(Color(.systemGroupedBackground))
//        .navigationTitle(category.rawValue)
//        .navigationBarTitleDisplayMode(.large)
//    }
//}
//
//#Preview {
//    NavigationStack {
//        CategoryListView(category: .breakfast)
//            .environmentObject(RecipeStore())
//    }
//}
