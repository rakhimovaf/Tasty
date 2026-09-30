//
//  MotionKit.swift
//  Tasty
//
//  Created by FR. on 07/09/26.
//


import SwiftUI

// MARK: - Motion tokens

enum Motion {
    static let snappy = Animation.snappy(duration: 0.35) 
    static let smooth = Animation.smooth(duration: 0.45)
    static let bouncy = Animation.bouncy(duration: 0.5)
    static let press  = Animation.spring(response: 0.25, dampingFraction: 0.7)

    static func stagger(_ index: Int, step: Double = 0.05, cap: Int = 8) -> Double {
        Double(min(index, cap)) * step
    }
}

// MARK: - Staggered entrance

struct StaggeredAppear: ViewModifier {
    let index: Int
    let step: Double
    let cap: Int
    let baseDelay: Double

    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 24)
            .scaleEffect(shown || reduceMotion ? 1 : 0.96)
            .onAppear {
                guard !shown else { return }
                withAnimation(Motion.smooth.delay(baseDelay + Motion.stagger(index, step: step, cap: cap))) {
                    shown = true
                }
            }
    }
}

extension View {
    func staggeredAppear(_ index: Int, step: Double = 0.05, cap: Int = 8, delay: Double = 0) -> some View {
        modifier(StaggeredAppear(index: index, step: step, cap: cap, baseDelay: delay))
    }
}

// MARK: - Press feedback

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Shimmer

struct ShimmerBand: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: [.clear, .white.opacity(0.35), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: geo.size.width * 0.5)
                .offset(x: phase * geo.size.width)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = 1.5 }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func buttonShimmer(_ active: Bool) -> some View {
        overlay { if active { ShimmerBand().clipShape(Capsule()) } }
    }

    func skeletonShimmer(cornerRadius: CGFloat) -> some View {
        overlay { ShimmerBand() }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Background

struct AnimatedBackground: View {
    @State private var drift = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image("image")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .scaleEffect(1.08)
            .offset(x: drift ? 10 : -10, y: drift ? -8 : 8)
            .ignoresSafeArea()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { drift = true }
            }
    }
}
