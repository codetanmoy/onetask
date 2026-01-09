//
//  PackageRow.swift
//  onething
//
//  Created by Tanmoy Khanra on 10/01/26.
//

import SwiftUI
import RevenueCat

struct PackageRow: View {
    let package: Package
    let isSelected: Bool

    var body: some View {
        let product = package.storeProduct
        let title = prettyTitle(for: package.packageType)
        let price = product.localizedPriceString

        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle(for: product))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(price)
                .font(.headline)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isSelected ? Color.primary : Color.secondary.opacity(0.25),
                    lineWidth: 1.5
                )
        )
    }
func prettyTitle(for type: PackageType) -> String {
        switch type {
        case .annual: return "Yearly"
        case .monthly: return "Monthly"
        case .weekly: return "Weekly"
        case .lifetime: return "Lifetime"
        default: return "Pro"
        }
    }

    private func subtitle(for product: StoreProduct) -> String {
        // If you want: show trial/intro offer hints when available.
        // Keep it simple (brand: clarity, not fine print overload).
        if product.introductoryDiscount != nil {
            return "Includes intro offer"
        }
        return "Full access"
    }
}

struct Bullet: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.footnote.bold())
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
        }
    }
}


