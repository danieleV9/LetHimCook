// IngredientInputView.swift
// LetHimCook
//
// Created by Daniele Valentino on 13/07/25.

import SwiftUI

struct IngredientInputView: View {
    @Bindable var viewModel: IngredientInputViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        TextField("Add an ingredient", text: $viewModel.currentInput)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .focused($isTextFieldFocused)

                        Button {
                            viewModel.addIngredient()
                            isTextFieldFocused = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .tint)
                                .accessibilityLabel("Add ingredient")
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.ingredients.wrappedValue.count >= 10)
                    }
                } footer: {
                    if viewModel.ingredients.wrappedValue.count >= 10 {
                        Text("You can add up to 10 ingredients")
                            .foregroundStyle(.red)
                    } else {
                        Text("Add up to 10 ingredients for more precise suggestions.")
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.ingredients.wrappedValue.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "leaf")
                                .font(.title)
                                .foregroundStyle(.tertiary)

                            Text("No ingredients")
                                .font(.headline)

                            Text("Start by adding the ingredients you have available.")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section("Your ingredients") {
                        ForEach(viewModel.ingredients.wrappedValue, id: \.self) { ingredient in
                            Text(ingredient)
                                .font(.body)
                        }
                        .onDelete { offsets in
                            viewModel.removeIngredient(at: offsets)
                        }

                        Button(role: .destructive) {
                            viewModel.reset()
                        } label: {
                            Label("Clear list", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Ingredients")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    IngredientInputView(viewModel: IngredientInputViewModel(ingredients: .constant(["Eggs", "Milk", "Flour"])))
}
