//
//  AIChatMessage.swift
//  Tasty
//
//  Created by FR. on 23/09/26.
//


import SwiftUI
import FoundationModels

@available(iOS 26.0, *)
struct AIAssistantView: View {

    @StateObject private var viewModel = AIAssistantViewModel()
    @State private var float = false

    private var isInputEmpty: Bool {
        viewModel.ingredientsText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Header
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 45))
                                .foregroundStyle(.yellow)
                                .symbolEffect(.pulse, isActive: viewModel.isLoading)
                                .symbolEffect(.bounce, value: viewModel.recipeText)
                                .offset(y: float ? -6 : 6)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                                        float = true
                                    }
                                }

                            Text("AI Recipe Generator")
                                .font(.title2.bold())

                            Text("Tell me what ingredients you have and I'll create a recipe for you.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        .staggeredAppear(0)

                        // MARK: - Ingredients
                        VStack(alignment: .leading, spacing: 10) {

                            Text("🥕 What ingredients do you have?")
                                .font(.headline)

                            TextField(
                                "chicken, potato, tomato...",
                                text: $viewModel.ingredientsText,
                                axis: .vertical
                            )
                            .lineLimit(3...5)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(
                                RoundedRectangle(cornerRadius: 16)
                            )

                            Text("Example: chicken, potato, onion")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .staggeredAppear(1)

                        // MARK: - Generate Button
                        Button {
                            viewModel.generateRecipe()
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Image(systemName: "sparkles")
                                        .transition(.scale.combined(with: .opacity))
                                }

                                Text(viewModel.isLoading ? "Cooking up ideas…" : "Generate Recipe")
                                    .fontWeight(.semibold)
                                    .contentTransition(.opacity)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .animation(Motion.snappy, value: viewModel.isLoading)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                        .buttonShimmer(viewModel.isLoading)
                        .disabled(isInputEmpty)
                        .allowsHitTesting(!viewModel.isLoading)
                        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isLoading)
                        .staggeredAppear(2)

                        // MARK: - Error
                        if let error = viewModel.errorMessage {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")

                                Text(error)
                                    .font(.footnote)
                            }
                            .foregroundStyle(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .clipShape(
                                RoundedRectangle(cornerRadius: 14)
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // MARK: - AI Result
                        if !viewModel.recipeText.isEmpty {
                            recipeView(viewModel.recipeText)
                                .id("result")
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 30)
                    }
                    .padding()
                    .animation(Motion.bouncy, value: viewModel.recipeText.isEmpty)
                    .animation(Motion.smooth, value: viewModel.errorMessage)
                }
                .onChange(of: viewModel.recipeText) { _, newValue in
                    guard !newValue.isEmpty else { return }
                    withAnimation(Motion.smooth.delay(0.3)) {
                        proxy.scrollTo("result", anchor: .top)
                    }
                }
                .sensoryFeedback(.success, trigger: viewModel.recipeText) { old, new in
                    old.isEmpty && !new.isEmpty
                }
                .sensoryFeedback(.error, trigger: viewModel.errorMessage) { _, new in
                    new != nil
                }
            }

            .navigationTitle("AI Chef")
            .navigationBarTitleDisplayMode(.inline)
            .background { AnimatedBackground() }
        }
    }

    // MARK: - Recipe Result 

    private func recipeView(_ recipe: String) -> some View {

        let lines = recipe
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return VStack(alignment: .leading, spacing: 10) {

            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)

                Text("Your AI Recipe")
                    .font(.headline)
            }

            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(index == 0 || line.hasSuffix(":") ? .headline : .body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .staggeredAppear(index, step: 0.07, cap: 14, delay: 0.25)
            }
        }
        .padding(20)
        .background(
            Color(.systemBackground)
                .opacity(0.95)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 24)
        )
        .shadow(
            radius: 10,
            y: 5
        )
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        AIAssistantView()
    }
}
