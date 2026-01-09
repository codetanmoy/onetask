//
//  PaywallView.swift
//  onething
//
//  Created by Tanmoy Khanra on 10/01/26.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entitlements: EntitlementManager
    @StateObject private var vm = PaywallViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Brand header
                VStack(spacing: 8) {
                    Text("Focus isn’t motivation.")
                        .font(.title.bold())

                    Text("It’s fewer choices.\nUpgrade to remove limits and keep one task visible, always.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // Packages
                Group {
                    if vm.isLoading && vm.packages.isEmpty {
                        ProgressView().padding(.vertical, 24)
                    } else if vm.packages.isEmpty {
                        Text("No plans available right now.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(vm.packages, id: \.identifier) { pkg in
                                PackageRow(
                                    package: pkg,
                                    isSelected: vm.selected?.identifier == pkg.identifier
                                )
                                .onTapGesture { vm.selected = pkg }
                            }
                        }
                    }
                }

                // Value bullets (tight, no fluff)
                VStack(alignment: .leading, spacing: 8) {
                    Bullet("Unlimited usage (no artificial stops).")
                    Bullet("iCloud sync across devices.")
                    Bullet("Widgets / Live Activity support stays unlocked.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

                // Error
                if let msg = vm.errorMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // CTA
                Button {
                    vm.purchaseSelected(entitlements: entitlements) {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Text(ctaTitle(for: vm.selected))
                            .font(.headline)
                        Spacer()
                        if vm.isLoading { ProgressView() }
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.selected == nil || vm.isLoading)

                // Trust + Restore
                VStack(spacing: 8) {
                    Text("Cancel anytime • Secure Apple billing")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Button("Restore") { vm.restore(entitlements: entitlements) }
                        Button("Not now") { dismiss() }
                    }
                    .font(.footnote)
                }
                .padding(.bottom, 6)
            }
            .padding()
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { vm.loadOfferings() }
        }
    }

    private func ctaTitle(for pkg: Package?) -> String {
        guard let pkg else { return "Continue" }
        // Show dynamic price from the StoreProduct
        let price = pkg.storeProduct.localizedPriceString
        let period = pkg.packageType == .annual ? "/year" :
                     pkg.packageType == .monthly ? "/month" : ""
        return "Unlock Pro — \(price)\(period)"
    }
}

#Preview {
    PaywallView()
}
