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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var entitlements: EntitlementManager
    @StateObject private var vm = PaywallViewModel()
    
    // Optional: Pass user's current streak to personalize the paywall
    var currentStreak: Int = 0
    var tasksCompleted: Int = 0
    
    @State private var animationPhase: CGFloat = 0
    @State private var showContent = false
    
    // MARK: - Theme-aware Colors
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }
    
    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4)
    }
    
    private var buttonBackgroundColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var buttonTextColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }
    
    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
    
    private var accentColor: Color {
        .red
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Full-screen background
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(secondaryTextColor)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(cardBackgroundColor))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Hero Section with personalized messaging
                        heroSection
                        
                        // Identity messaging - builds belonging
                        identitySection
                        
                        // Loss Aversion - what you're missing
                        lossAversionSection
                        
                        // Value Proposition - clear benefits
                        valuePropositionSection
                        
                        // Streak Protection - if user has streak
                        if currentStreak > 0 {
                            streakProtectionSection
                        }
                        
                        // Package Selection
                        packageSelectionSection
                        
                        // CTA Button
                        ctaSection
                        
                        // Trust & Links
                        trustSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
        }
        .onAppear {
            vm.loadOfferings()
            startAnimation()
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(primaryTextColor.opacity(0.05))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.0 + animationPhase * 0.1)
                
                // Glow effect
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(primaryTextColor.opacity(0.2))
                    .blur(radius: 15)
                    .scaleEffect(1.0 + animationPhase * 0.1)
                
                // Main icon
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(primaryTextColor)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5), isActive: !reduceMotion)
            }
            .frame(height: 100)
            
            VStack(spacing: 12) {
                // Personalized headline based on user's progress
                if tasksCompleted > 10 {
                    Text("You've completed \(tasksCompleted) tasks.")
                        .font(.subheadline)
                        .foregroundStyle(secondaryTextColor)
                    
                    Text("Imagine what's next.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(primaryTextColor)
                } else {
                    Text("Unlock Your")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(primaryTextColor)
                    
                    Text("Full Potential")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(primaryTextColor.opacity(0.6))
                }
                
                Text("Stop losing focus. Start finishing\nwhat matters most.")
                    .font(.body)
                    .foregroundStyle(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Identity Section (Apple-safe alternative to social proof)
    
    private var identitySection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 32))
                .foregroundStyle(primaryTextColor)
                .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.3), isActive: !reduceMotion)
            
            Text("Built for people who finish\nwhat they start.")
                .font(.headline)
                .foregroundStyle(primaryTextColor)
                .multilineTextAlignment(.center)
            
            Text("Join the focused few. No distractions.\nJust results.")
                .font(.subheadline)
                .foregroundStyle(secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackgroundColor)
        )
    }
    
    // MARK: - Loss Aversion Section (What You're Missing)
    
    private var lossAversionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                
                Text("Without Pro, you're missing:")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                LossItem(text: "Unlimited focus sessions", colorScheme: colorScheme)
                LossItem(text: "Streak protection when life happens", colorScheme: colorScheme)
                LossItem(text: "Insights that reveal your peak hours", colorScheme: colorScheme)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(colorScheme == .dark ? 0.15 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Value Proposition Section
    
    private var valuePropositionSection: some View {
        VStack(spacing: 12) {
            ValueCard(
                icon: "infinity",
                title: "Unlimited Focus",
                subtitle: "No artificial limits on your productivity",
                colorScheme: colorScheme
            )
            
            ValueCard(
                icon: "shield.fill",
                title: "Streak Freeze",
                subtitle: "Protect your streak when life gets busy",
                colorScheme: colorScheme
            )
            
            ValueCard(
                icon: "icloud.fill",
                title: "iCloud Sync",
                subtitle: "Access your progress on all devices",
                colorScheme: colorScheme
            )
            
            ValueCard(
                icon: "chart.bar.fill",
                title: "Deep Insights",
                subtitle: "Discover when you focus best",
                colorScheme: colorScheme
            )
        }
    }
    
    // MARK: - Streak Protection Section (Loss Aversion for Existing Users)
    
    private var streakProtectionSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(primaryTextColor.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(primaryTextColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Your \(currentStreak)-day streak is valuable")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
                
                Text("Pro gives you 1 freeze per month. Don't lose what you've built.")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(primaryTextColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Package Selection Section
    
    private var packageSelectionSection: some View {
        VStack(spacing: 16) {
            // Section header
            Text("Choose your plan")
                .font(.headline)
                .foregroundStyle(primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Group {
                if vm.isLoading && vm.packages.isEmpty {
                    ProgressView()
                        .padding(.vertical, 24)
                } else if vm.packages.isEmpty {
                    Text("No plans available right now.")
                        .font(.subheadline)
                        .foregroundStyle(secondaryTextColor)
                        .padding(.vertical, 24)
                } else {
                    VStack(spacing: 12) {
                        ForEach(vm.packages, id: \.identifier) { pkg in
                            ProPackageRow(
                                package: pkg,
                                isSelected: vm.selected?.identifier == pkg.identifier,
                                colorScheme: colorScheme
                            )
                            .onTapGesture { vm.selected = pkg }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 12) {
            // Error message
            if let msg = vm.errorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Main CTA button
            Button {
                vm.purchaseSelected(entitlements: entitlements) {
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(ctaTitle(for: vm.selected))
                        .font(.headline.weight(.semibold))
                    
                    if vm.isLoading {
                        ProgressView()
                            .tint(buttonTextColor)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                }
                .foregroundColor(buttonTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(buttonBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(vm.selected == nil || vm.isLoading)
            .opacity(vm.selected == nil ? 0.5 : 1.0)
            
            // Urgency text (subtle, not pushy)
            Text("Start focusing today. Cancel anytime.")
                .font(.caption)
                .foregroundStyle(tertiaryTextColor)
        }
    }
    
    // MARK: - Trust Section
    
    private var trustSection: some View {
        VStack(spacing: 16) {
            // Trust badges
            HStack(spacing: 16) {
                TrustBadge(icon: "lock.fill", text: "Secure", colorScheme: colorScheme)
                TrustBadge(icon: "arrow.counterclockwise", text: "Cancel anytime", colorScheme: colorScheme)
                TrustBadge(icon: "apple.logo", text: "Apple Pay", colorScheme: colorScheme)
            }
            
            HStack(spacing: 24) {
                Button("Restore Purchases") {
                    vm.restore(entitlements: entitlements)
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(primaryTextColor.opacity(0.8))
                
                Button("Not Now") {
                    dismiss()
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(secondaryTextColor)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func ctaTitle(for pkg: Package?) -> String {
        guard let pkg else { return "Continue" }
        let price = pkg.storeProduct.localizedPriceString
        let period = pkg.packageType == .annual ? "/year" :
                     pkg.packageType == .monthly ? "/month" : ""
        return "Unlock Pro — \(price)\(period)"
    }
    
    private func startAnimation() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Loss Item Component

private struct LossItem: View {
    let text: String
    let colorScheme: ColorScheme
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.8)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.red.opacity(0.8))
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(textColor)
        }
    }
}

// MARK: - Trust Badge Component

private struct TrustBadge: View {
    let icon: String
    let text: String
    let colorScheme: ColorScheme
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(textColor)
            
            Text(text)
                .font(.caption2)
                .foregroundStyle(textColor)
        }
    }
}

// MARK: - Value Card Component

private struct ValueCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let colorScheme: ColorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03)
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var titleColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var subtitleColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(cardBackground)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(titleColor)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(subtitleColor)
            }
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconColor.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
    }
}

// MARK: - Pro Package Row Component

private struct ProPackageRow: View {
    let package: Package
    let isSelected: Bool
    let colorScheme: ColorScheme
    
    private var backgroundColor: Color {
        if isSelected {
            return colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
        }
        return colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02)
    }
    
    private var borderColor: Color {
        if isSelected {
            return colorScheme == .dark ? Color.white : Color.black
        }
        return colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }
    
    private var isAnnual: Bool {
        package.packageType == .annual
    }
    
    var body: some View {
        let product = package.storeProduct
        let title = prettyTitle(for: package.packageType)
        let price = product.localizedPriceString
        
        HStack(spacing: 14) {
            // Selection indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? primaryColor : secondaryColor.opacity(0.5), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Circle()
                        .fill(primaryColor)
                        .frame(width: 14, height: 14)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(primaryColor)
                    
                    if isAnnual {
                        Text("Best Value")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(primaryColor))
                    }
                }
                
                Text(subtitle(for: product))
                    .font(.subheadline)
                    .foregroundStyle(secondaryColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(price)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryColor)
                
                if isAnnual {
                    Text("Save 50%")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func prettyTitle(for type: PackageType) -> String {
        switch type {
        case .annual: return "Yearly"
        case .monthly: return "Monthly"
        case .weekly: return "Weekly"
        case .lifetime: return "Lifetime"
        default: return "Pro"
        }
    }
    
    private func subtitle(for product: StoreProduct) -> String {
        if let _ = product.introductoryDiscount {
            return "Includes free trial"
        }
        return "Full access"
    }
}

#Preview("Light") {
    PaywallView(entitlements: EntitlementManager(), currentStreak: 12, tasksCompleted: 45)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PaywallView(entitlements: EntitlementManager(), currentStreak: 12, tasksCompleted: 45)
        .preferredColorScheme(.dark)
}

#Preview("New User - Light") {
    PaywallView(entitlements: EntitlementManager())
        .preferredColorScheme(.light)
}
