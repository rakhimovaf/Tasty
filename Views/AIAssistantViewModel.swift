import SwiftUI
import FoundationModels
import Combine

@available(iOS 26.0, *)
@MainActor
final class AIAssistantViewModel: ObservableObject {

    @Published var ingredientsText = ""
    @Published var recipeText = ""

    @Published var isLoading = false
    @Published var errorMessage: String?

    func generateRecipe() {

        let ingredients = ingredientsText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !ingredients.isEmpty else {
            return
        }

        recipeText = ""
        errorMessage = nil
        isLoading = true

        Task {

            defer {
                isLoading = false
            }

            do {

                let model = SystemLanguageModel(
                    useCase: .general,
                    guardrails: .permissiveContentTransformations
                )

                guard model.availability == .available else {
                    throw AIRecipeError.unavailable
                }

                let session = LanguageModelSession(
                    model: model,
                    instructions: """
                    You are Tasty, a helpful cooking assistant.

                    The user will give you food ingredients.

                    Create ONE simple recipe using those ingredients.

                    Answer in this exact structure:

                    🍳 Recipe Name

                    ⏱ Cooking time:
                    👥 Servings:

                    🥕 Ingredients:
                    - ingredient
                    - ingredient
                    - ingredient

                    👨‍🍳 Instructions:
                    1. Step one
                    2. Step two
                    3. Step three

                    Keep the recipe short, practical and easy to cook.
                    Do not talk about anything unrelated to cooking.
                    """
                )

                let prompt = """
                Create a recipe using these ingredients:

                \(ingredients)
                """

                let response = try await session.respond(
                    to: prompt
                )

                recipeText = response.content

            } catch {

                print("AI ERROR:", error)

                errorMessage = """
                AI could not create the recipe.
                Please try again.
                """
            }
        }
    }
}

enum AIRecipeError: LocalizedError {

    case unavailable

   var errorDescription: String? {
    switch self {
    case .unavailable:
        return "Apple Intelligence is currently unavailable."
    }
   }
}
