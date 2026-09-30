//
//  OnboardingView.swift
//  Tasty
//
//  Created by FR. on 29/07/26.
//
//

import SwiftUI

// MARK: - Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let accentColor: Color
    let title: String
    let subtitle: String
}

// MARK: - Data

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        symbol: "fork.knife.circle.fill",
        accentColor: Color(hex: "E8A98A"),
        title: "Discover Delicious Recipes",
        subtitle: "Explore delicious recipes by category or search for meals using the ingredients you have."
    ),
    
    OnboardingPage(
        symbol: "sparkles",
        accentColor: Color(hex: "F4C77A"),
        title: "Meet Your AI Chef",
        subtitle: "Tell Tasty what ingredients you have and let AI create a simple recipe just for you."
    ),
    
    OnboardingPage(
        symbol: "bookmark.circle.fill",
        accentColor: Color(hex: "F2A8B8"),
        title: "Save Your Favorites",
        subtitle: "Found a recipe you love? Save it and easily find it again whenever you want to cook."
    ),
    
    OnboardingPage(
        symbol: "cart.fill",
        accentColor: Color(hex: "B3A6E0"),
        title: "Shop Smarter",
        subtitle: "Add ingredients to your shopping list and check them off as you shop."
    )
]

// MARK: - Root View

struct OnboardingView: View {
    @State private var currentPage = 0
    var onFinish: () -> Void = {}

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                pageIndicator
                    .padding(.bottom, 24)

                actionButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                onboardingPages[currentPage].accentColor.opacity(0.25),
                Color(hex: "FDF6EF")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: currentPage)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(onboardingPages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage
                          ? onboardingPages[currentPage].accentColor
                          : Color.gray.opacity(0.25))
                    .frame(width: index == currentPage ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    private var actionButton: some View {
        Button {
            if currentPage < onboardingPages.count - 1 {
                withAnimation(.easeInOut) { currentPage += 1 }
            } else {
                onFinish()
            }
        } label: {
            Text(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(onboardingPages[currentPage].accentColor)
                )
        }
        .animation(.easeInOut, value: currentPage)
    }
}

// MARK: - Single Page

private struct OnboardingPageView: View {
    let page: OnboardingPage

    // Continuous floating animation state
    @State private var floatUp = false
    @State private var appear = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.18))
                    .frame(width: 220, height: 220)
                    .scaleEffect(appear ? 1 : 0.6)

                Circle()
                    .fill(page.accentColor.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .scaleEffect(appear ? 1 : 0.6)

                Image(systemName: page.symbol)
                    .font(.system(size: 96, weight: .medium))
                    .foregroundStyle(page.accentColor)
                    .offset(y: floatUp ? -12 : 12)
                    .scaleEffect(appear ? 1 : 0.4)
                    .opacity(appear ? 1 : 0)
            }
            .onAppear {
                appear = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                    appear = true
                }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    floatUp = true
                }
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 16)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Hex Color Helper

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}



#Preview {
    OnboardingView()
}
