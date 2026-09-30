//
//  SubscriptionManager.swift
//  Tasty
//
//  Created by FR. on 23/09/26.
//


import Foundation
import RevenueCat
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {

    static let entitlementID = "Premium"

    @Published var isPremium = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        Task {
            await refreshCustomerInfo()
        }
    }

    // MARK: - Check Premium

    func refreshCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()

            isPremium =
                customerInfo.entitlements
                    .all[Self.entitlementID]?
                    .isActive == true

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async -> Bool {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let result =
                try await Purchases.shared.purchase(
                    package: package
                )

            isPremium =
                result.customerInfo.entitlements
                    .all[Self.entitlementID]?
                    .isActive == true

            return isPremium

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let customerInfo =
                try await Purchases.shared.restorePurchases()

            isPremium =
                customerInfo.entitlements
                    .all[Self.entitlementID]?
                    .isActive == true

            if !isPremium {
                errorMessage = "No active subscription found."
            }

            return isPremium

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
