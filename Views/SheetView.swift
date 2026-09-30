//
//  Untitled.swift
//  Tasty
//
//  Created by FR. on 12/09/26.
//

import SwiftUI

struct SheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var itemText = ""
    @State private var shoppingItems: [ShoppingItem] = []

    @FocusState private var fieldIsFocused: Bool

    struct ShoppingItem: Codable, Identifiable, Equatable {
        let id: UUID
        var name: String
        var isCompleted: Bool
    }

    private let storageKey = "shoppingList"

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // MARK: - Add Item

                HStack(spacing: 10) {
                    TextField(
                        "Add product...",
                        text: $itemText
                    )
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldIsFocused)
                    .onSubmit {
                        addItem()
                    }

                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 42, height: 42)
                            .symbolEffect(.bounce, value: shoppingItems.count)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        itemText
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }

                // MARK: - Shopping List

                if shoppingItems.isEmpty {

                    VStack(spacing: 12) {
                        Image(systemName: "cart")
                            .font(.system(size: 45))
                            .foregroundStyle(.secondary)
                            .symbolEffect(.bounce, options: .nonRepeating)

                        Text("Your shopping list is empty")
                            .font(.headline)

                        Text("Add products you need to buy.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))

                } else {

                    List {
                        ForEach($shoppingItems) { $item in

                            HStack(spacing: 12) {

                                Button {
                                    withAnimation(Motion.snappy) {
                                        item.isCompleted.toggle()
                                    }
                                    saveItems()
                                } label: {
                                    Image(
                                        systemName: item.isCompleted
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                    )
                                    .font(.title3)
                                    .foregroundStyle(
                                        item.isCompleted
                                        ? .green
                                        : .secondary
                                    )
                                    .contentTransition(.symbolEffect(.replace))
                                    .symbolEffect(.bounce, value: item.isCompleted)
                                    .scaleEffect(item.isCompleted ? 1.1 : 1)
                                }
                                .buttonStyle(.plain)

    
                                Text(item.name)
                                    .foregroundStyle(
                                        item.isCompleted
                                        ? .secondary
                                        : .primary
                                    )
                                    .overlay(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.secondary)
                                            .frame(height: 1.5)
                                            .scaleEffect(x: item.isCompleted ? 1 : 0, anchor: .leading)
                                    }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .sensoryFeedback(.selection, trigger: item.isCompleted)
                        }
                        .onDelete { indexSet in
                            withAnimation(Motion.smooth) {
                                shoppingItems.remove(atOffsets: indexSet)
                            }
                            saveItems()
                        }
                    }
                    .listStyle(.plain)
                    .animation(Motion.smooth, value: shoppingItems)
                    .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .animation(Motion.smooth, value: shoppingItems.isEmpty)
            .sensoryFeedback(.impact(weight: .light), trigger: shoppingItems.count)
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !shoppingItems.isEmpty {
                        Button("Clear") {
                            withAnimation(Motion.smooth) {
                                shoppingItems.removeAll()
                            }
                            saveItems()
                        }
                    }
                }
            }
            .onAppear {
                loadItems()
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Add

    private func addItem() {
        let name = itemText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            return
        }

        guard !shoppingItems.contains(where: {
            $0.name.lowercased() == name.lowercased()
        }) else {
            itemText = ""
            return
        }

        let newItem = ShoppingItem(
            id: UUID(),
            name: name,
            isCompleted: false
        )

        withAnimation(Motion.bouncy) {
            shoppingItems.insert(newItem, at: 0)
        }
        itemText = ""

        saveItems()
        fieldIsFocused = true
    }

    // MARK: - Save

    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(shoppingItems)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save shopping list:", error)
        }
    }

    // MARK: - Load

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            shoppingItems = try JSONDecoder()
                .decode([ShoppingItem].self, from: data)
        } catch {
            print("Failed to load shopping list:", error)
        }
    }
}

#Preview {
    SheetView()
}
