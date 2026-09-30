//
//  AIIngredient.swift
//  Tasty
//
//  Created by FR. on 02/08/26.
//

import Foundation
import FoundationModels


@Generable
struct AIIngredient {
    let name: String
}

@Generable
struct AIRecipe {
    let title: String

    let cookingTime: String

    let servings: String

    @Guide(description: "Ingredients needed for the recipe")
    let ingredients: [AIIngredient]

    @Guide(description: "Simple step-by-step cooking instructions")
    let instructions: [String]
}
