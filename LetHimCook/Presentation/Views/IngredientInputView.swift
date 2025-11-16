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
                        TextField("ingredient_input_placeholder", text: $viewModel.currentInput)
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
                                .accessibilityLabel("ingredient_input_accessibility_add")
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.ingredients.wrappedValue.count >= 10)
                    }
                } footer: {
                    if viewModel.ingredients.wrappedValue.count >= 10 {
                        Text("ingredient_input_footer_limit")
                            .foregroundStyle(.red)
                    } else {
                        Text("ingredient_input_footer_hint")
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.ingredients.wrappedValue.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "leaf")
                                .font(.title)
                                .foregroundStyle(.tertiary)

                            Text("ingredient_input_empty_title")
                                .font(.headline)

                            Text("ingredient_input_empty_description")
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
                    Section {
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
                            Label("ingredient_input_clear_list", systemImage: "trash")
                        }
                    } header: {
                        Text("ingredient_input_section_title")
                    }
                }
            }
            .navigationTitle("ingredient_input_nav_title")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("ingredient_input_done_button") {
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
