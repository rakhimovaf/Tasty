//
//  PaywallView.swift
//  Tasty
//
//  Created by FR. on 15/09/26.
//

import SwiftUI
import RevenueCat

// MARK: - Subscription Plan Model

struct SubscriptionPlan: Identifiable {
    let id: String
    let title: String
    let price: String
    let period: String
    let badge: String?
    let savingsNote: String?
    let package: Package
}

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var plans: [SubscriptionPlan] = []
    @State private var selectedPlanID: String?
    @State private var isLoadingPlans = true

    // MARK: - Features Data

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("sparkles", "AI Assistant", "Ask unlimited questions about recipes"),
        ("fork.knife", "All Recipes", "Unlock every premium recipe"),
        ("heart.text.square", "Personalized Picks", "Meals tailored to your taste")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    featureList

                    if isLoadingPlans {
                        ProgressView()
                            .padding(.vertical, 20)
                    } else if !plans.isEmpty {
                        planPicker
                        purchaseButton
                    } else {
                        Text("No subscription plans available.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 20)
                    }

                    if let errorMessage = subscriptionManager.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restore") {
                        Task {
                            let success = await subscriptionManager.restorePurchases()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .font(.body.weight(.medium))
                    .disabled(subscriptionManager.isLoading)
                }
            }
        }
        .task {
            await loadPlans()
        }
        .onChange(of: subscriptionManager.isPremium) { _, isPremium in
            if isPremium {
                dismiss()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gray, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 10)

            Text("Tasty Pro")
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)

            Text("Unlock all recipes, the AI assistant")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(features, id: \.title) { feature in
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(.blue)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.system(size: 17, weight: .semibold))

                        Text(feature.subtitle)
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Plan Picker

    private var planPicker: some View {
        VStack(spacing: 12) {
            ForEach(plans) { plan in
                PlanRow(plan: plan, isSelected: selectedPlanID == plan.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedPlanID = plan.id
                        }
                    }
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                guard let selectedPlanID,
                      let selectedPlan = plans.first(where: { $0.id == selectedPlanID }) else {
                    return
                }

                Task {
                    let success = await subscriptionManager.purchase(package: selectedPlan.package)
                    if success {
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(subscriptionManager.isLoading || selectedPlanID == nil)

            Button {
                dismiss()
            } label: {
                Text("Cancel anytime")
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
            }
        }
    }

    // MARK: - Load RevenueCat Plans

    private func loadPlans() async {
        isLoadingPlans = true

        do {
            let offerings = try await Purchases.shared.offerings()

            guard let current = offerings.current else {
                plans = []
                isLoadingPlans = false
                return
            }

            var loadedPlans: [SubscriptionPlan] = []

            for package in current.availablePackages {
                let product = package.storeProduct

                switch package.packageType {
                case .monthly:
                    loadedPlans.append(
                        SubscriptionPlan(
                            id: package.identifier,
                            title: "Monthly",
                            price: product.localizedPriceString,
                            period: "per month",
                            badge: nil,
                            savingsNote: nil,
                            package: package
                        )
                    )

                case .annual:
                    loadedPlans.append(
                        SubscriptionPlan(
                            id: package.identifier,
                            title: "Yearly",
                            price: product.localizedPriceString,
                            period: "per year",
                            badge: "Best Value",
                            savingsNote: nil,
                            package: package
                        )
                    )

                default:
                    loadedPlans.append(
                        SubscriptionPlan(
                            id: package.identifier,
                            title: product.localizedTitle,
                            price: product.localizedPriceString,
                            period: product.localizedDescription,
                            badge: nil,
                            savingsNote: nil,
                            package: package
                        )
                    )
                }
            }

            loadedPlans.sort {
                if $0.package.packageType == .monthly { return true }
                if $1.package.packageType == .monthly { return false }
                return false
            }

            plans = loadedPlans

            if let yearly = loadedPlans.first(where: { $0.package.packageType == .annual }) {
                selectedPlanID = yearly.id
            } else {
                selectedPlanID = loadedPlans.first?.id
            }

        } catch {
            plans = []
        }

        isLoadingPlans = false
    }
}

// MARK: - Plan Row Component

private struct PlanRow: View {
    let plan: SubscriptionPlan
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 27))
                .foregroundStyle(isSelected ? Color.blue : Color.gray.opacity(0.45))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(plan.title)
                        .font(.system(size: 17, weight: .semibold))

                    if let badge = plan.badge {
                        Text(badge)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }

                if let savingsNote = plan.savingsNote {
                    Text(savingsNote)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(plan.price)
                    .font(.system(size: 17, weight: .semibold))

                Text(plan.period)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(isSelected ? Color(.systemBackground) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        }
    }
}



#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
