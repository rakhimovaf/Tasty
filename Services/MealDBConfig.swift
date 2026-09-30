//
//  SwiftUIView.swift
//  Tasty
//
//  Created by FR. on 09/09/26.
//

import Foundation

// MARK: - Config

enum MealDBConfig {
    static let apiKey = "1"
    static let baseURLV1 = "https://www.themealdb.com/api/json/v1/\(apiKey)/"
}

// MARK: - Models

struct Meal: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let category: String?
    let area: String?
    let instructions: String?
    let thumbnailURL: URL?
    let tags: String?
    let youtubeURL: String?
    let ingredients: [MealIngredient]

    enum CodingKeys: String, CodingKey {
        case id = "idMeal"
        case name = "strMeal"
        case category = "strCategory"
        case area = "strArea"
        case instructions = "strInstructions"
        case thumbnailURL = "strMealThumb"
        case tags = "strTags"
        case youtubeURL = "strYoutube"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        area = try? container.decodeIfPresent(String.self, forKey: .area)
        instructions = try? container.decodeIfPresent(String.self, forKey: .instructions)
        thumbnailURL = try? container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
        tags = try? container.decodeIfPresent(String.self, forKey: .tags)
        youtubeURL = try? container.decodeIfPresent(String.self, forKey: .youtubeURL)

        
        let dynamic = try decoder.container(keyedBy: DynamicKey.self)
        var collected: [MealIngredient] = []
        for i in 1...20 {
            guard let ingredientKey = DynamicKey(stringValue: "strIngredient\(i)"),
                  let measureKey = DynamicKey(stringValue: "strMeasure\(i)") else { continue }

            let ingredientName = try? dynamic.decodeIfPresent(String.self, forKey: ingredientKey)
            let measure = try? dynamic.decodeIfPresent(String.self, forKey: measureKey)

            guard let name = ingredientName, !name.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            collected.append(MealIngredient(name: name, measure: measure ?? ""))
        }
        ingredients = collected
    }


    init(id: String, name: String, category: String?, area: String?, instructions: String?,
         thumbnailURL: URL?, tags: String?, youtubeURL: String?, ingredients: [MealIngredient]) {
        self.id = id
        self.name = name
        self.category = category
        self.area = area
        self.instructions = instructions
        self.thumbnailURL = thumbnailURL
        self.tags = tags
        self.youtubeURL = youtubeURL
        self.ingredients = ingredients
    }
}

struct MealIngredient: Identifiable, Codable, Equatable {
    var id: String { name }
    let name: String
    let measure: String
}

private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
}

private struct MealsResponse: Codable {
    let meals: [Meal]?
}

private struct MealListItem: Codable {
    let id: String
    let name: String
    let thumbnailURL: URL?

    enum CodingKeys: String, CodingKey {
        case id = "idMeal"
        case name = "strMeal"
        case thumbnailURL = "strMealThumb"
    }
}

private struct MealListResponse: Codable {
    let meals: [MealListItem]?
}

// MARK: - Errors

enum MealDBError: LocalizedError {
    case invalidURL
    case notFound
    case decoding
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request URL."
        case .notFound: return "Nothing found."
        case .decoding: return "Failed to decode data."
        case .network(let error): return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Service

final class MealDBService {
    static let shared = MealDBService()
    private init() {}

    private let session = URLSession.shared
    private let decoder = JSONDecoder()


    func search(byName name: String) async throws -> [Meal] {
        try await fetchMeals(endpoint: "search.php", query: [URLQueryItem(name: "s", value: name)])
    }


    func lookup(id: String) async throws -> Meal {
        let meals = try await fetchMeals(endpoint: "lookup.php", query: [URLQueryItem(name: "i", value: id)])
        guard let meal = meals.first else { throw MealDBError.notFound }
        return meal
    }


    func randomMeal() async throws -> Meal {
        let meals = try await fetchMeals(endpoint: "random.php", query: [])
        guard let meal = meals.first else { throw MealDBError.notFound }
        return meal
    }


    func filter(byCategory category: String) async throws -> [MealSummary] {
        try await fetchMealList(endpoint: "filter.php", query: [URLQueryItem(name: "c", value: category)])
    }


    func filter(byIngredient ingredient: String) async throws -> [MealSummary] {
        try await fetchMealList(endpoint: "filter.php", query: [URLQueryItem(name: "i", value: ingredient)])
    }

    // Barcha kategoriyalar ro'yxati (masalan Breakfast/Lunch/Dinner bo'limlari uchun)
    func categories() async throws -> [String] {
        guard var components = URLComponents(string: MealDBConfig.baseURLV1 + "list.php") else {
            throw MealDBError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "c", value: "list")]
        guard let url = components.url else { throw MealDBError.invalidURL }

        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try decoder.decode(CategoryListResponse.self, from: data)
            return decoded.meals?.compactMap { $0.name } ?? []
        } catch let error as DecodingError {
            _ = error
            throw MealDBError.decoding
        } catch {
            throw MealDBError.network(error)
        }
    }



    private func fetchMeals(endpoint: String, query: [URLQueryItem]) async throws -> [Meal] {
        guard var components = URLComponents(string: MealDBConfig.baseURLV1 + endpoint) else {
            throw MealDBError.invalidURL
        }
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { throw MealDBError.invalidURL }

        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try decoder.decode(MealsResponse.self, from: data)
            return decoded.meals ?? []
        } catch let error as DecodingError {
            _ = error
            throw MealDBError.decoding
        } catch {
            throw MealDBError.network(error)
        }
    }

    private func fetchMealList(endpoint: String, query: [URLQueryItem]) async throws -> [MealSummary] {
        guard var components = URLComponents(string: MealDBConfig.baseURLV1 + endpoint) else {
            throw MealDBError.invalidURL
        }
        components.queryItems = query
        guard let url = components.url else { throw MealDBError.invalidURL }

        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try decoder.decode(MealListResponse.self, from: data)
            return (decoded.meals ?? []).map {
                MealSummary(id: $0.id, name: $0.name, thumbnailURL: $0.thumbnailURL)
            }
        } catch let error as DecodingError {
            _ = error
            throw MealDBError.decoding
        } catch {
            throw MealDBError.network(error)
        }
    }
}


struct MealSummary: Identifiable, Equatable {
    let id: String
    let name: String
    let thumbnailURL: URL?
}

private struct CategoryListResponse: Codable {
    let meals: [CategoryName]?
}

private struct CategoryName: Codable {
    let name: String
    enum CodingKeys: String, CodingKey {
        case name = "strCategory"
    }
}

