//
//  HomeView.swift
//  Tasty
//
//  Created by FR. on 31/07/26.
//

import SwiftUI
import Combine

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    @State private var showingPaywall = false
    @Namespace private var chipNS
    @Namespace private var heroNS

    private let freeRecipeLimit = 6
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categoryScroller

                    if viewModel.isLoading {
                        skeletonGrid
                            .transition(.opacity)
                    } else if let error = viewModel.errorMessage {
                        errorState(error)
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.95))
                            )
                    } else if viewModel.filteredMeals.isEmpty {
                        emptyState
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.95))
                            )
                    } else {
                        mealGrid
                            .transition(.opacity)
                    }
                }
                .padding(.vertical, 8)
                .animation(Motion.smooth, value: viewModel.isLoading)
            }
            .navigationTitle("Recipes 🥘")
            .searchable(
                text: $viewModel.searchText,
                prompt: "What ingredients do you have?"
            )
            .onSubmit(of: .search) {
                Task {
                    await viewModel.searchByIngredient()
                }
            }
            .task {
                if viewModel.meals.isEmpty {
                    await viewModel.loadMeals()
                }
                await subscriptionManager.refreshCustomerInfo()
            }
            .refreshable {
                await viewModel.loadMeals()
                await subscriptionManager.refreshCustomerInfo()
            }
            .background {
                AnimatedBackground()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environmentObject(subscriptionManager)
            }
        }
    }

    // MARK: - Category Scroller

    private var categoryScroller: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HomeViewModel.MealCategory.allCases) { category in
                        let isSelected = viewModel.selectedCategory == category

                        Button {
                            Task {
                                await viewModel.selectCategory(category)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.caption)

                                Text(category.displayName)
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(Color.accentColor)
                                        .matchedGeometryEffect(id: "pill", in: chipNS)
                                } else {
                                    Capsule()
                                        .fill(Color(.secondarySystemBackground))
                                }
                            }
                            .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .buttonStyle(PressableStyle())
                        .id(category)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: viewModel.selectedCategory) { _, newValue in
                withAnimation(Motion.snappy) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .animation(Motion.snappy, value: viewModel.selectedCategory)
        .sensoryFeedback(.selection, trigger: viewModel.selectedCategory)
    }

    // MARK: - Meal Grid

    private var mealGrid: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(Array(viewModel.filteredMeals.enumerated()), id: \.element.id) { index, meal in
                cell(for: meal, at: index)
                    .staggeredAppear(index)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Recipe Cell

    @ViewBuilder
    private func cell(for meal: MealSummary, at index: Int) -> some View {
        let isUnlocked = subscriptionManager.isPremium || index < freeRecipeLimit

        if isUnlocked {
            NavigationLink {
                RecipeDetailView(mealID: meal.id, mealName: meal.name)
                    .navigationTransition(.zoom(sourceID: meal.id, in: heroNS))
            } label: {
                MealCard(meal: meal)
                    .matchedTransitionSource(id: meal.id, in: heroNS)
            }
            .buttonStyle(PressableStyle())
        } else {
            Button {
                showingPaywall = true
            } label: {
                LockedMealCard(meal: meal)
            }
            .buttonStyle(PressableStyle())
        }
    }

    // MARK: - Loading Skeleton

    private var skeletonGrid: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(0..<6, id: \.self) { i in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 130)
                        .skeletonShimmer(cornerRadius: 14)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 90, height: 12)
                        .skeletonShimmer(cornerRadius: 6)
                }
                .staggeredAppear(i, step: 0.04)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Restart") {
                Task {
                    await viewModel.loadMeals()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
        .padding(.horizontal, 40)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
                .symbolEffect(.bounce)

            Text("No recipes found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Normal Meal Card

private struct MealCard: View {
    let meal: MealSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(
                url: meal.thumbnailURL,
                transaction: Transaction(animation: .easeOut(duration: 0.35))
            ) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity)

                case .failure:
                    Color(.tertiarySystemFill)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )

                default:
                    Color(.tertiarySystemFill)
                        .overlay(ProgressView())
                }
            }
            .frame(height: 130)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(meal.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Locked Meal Card

private struct LockedMealCard: View {
    let meal: MealSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                AsyncImage(url: meal.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)

                    case .failure, .empty:
                        Color(.tertiarySystemFill)
                    @unknown default:
                        Color(.tertiarySystemFill)
                    }
                }
                .frame(height: 130)
                .blur(radius: 8)
                .clipped()

                RoundedRectangle(cornerRadius: 14)
                    .fill(.black.opacity(0.35))

                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse)

                    Text("Premium")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Premium Recipe")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SubscriptionManager())
}
