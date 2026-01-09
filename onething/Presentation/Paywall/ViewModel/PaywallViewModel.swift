//
//  PaywallViewModel.swift
//  onething
//
//  Created by Tanmoy Khanra on 10/01/26.
//
import Foundation
import RevenueCat
import Combine

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var packages: [Package] = []
    @Published var selected: Package? = nil

    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func loadOfferings() {
        isLoading = true
        errorMessage = nil

        Purchases.shared.getOfferings { [weak self] offerings, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                let pkgs = offerings?.current?.availablePackages ?? []  // Displaying Products doc
                self.packages = pkgs
                self.selected = pkgs.first
            }
        }
    }

    func purchaseSelected(entitlements: EntitlementManager, onSuccess: @escaping () -> Void) {
        guard let pkg = selected else { return }

        isLoading = true
        errorMessage = nil

        Purchases.shared.purchase(package: pkg) { _, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                self.isLoading = false

                if userCancelled {
                    return
                }

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                if let customerInfo {
                    entitlements.update(with: customerInfo)
                    if entitlements.isPro { onSuccess() }
                }
            }
        }
    }

    func restore(entitlements: EntitlementManager) {
        isLoading = true
        errorMessage = nil

        Purchases.shared.restorePurchases { customerInfo, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                if let customerInfo {
                    entitlements.update(with: customerInfo)
                }
            }
        }
    }
}
