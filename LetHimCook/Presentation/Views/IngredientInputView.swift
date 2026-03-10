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
            ZStack {
                AppBackground()

                List {
                    Section {
                        AppCard {
                            HStack(spacing: 12) {
                                TextField("ingredient_input_placeholder", text: $viewModel.currentInput)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.words)
                                    .focused($isTextFieldFocused)

                                Button {
                                    viewModel.addIngredient()
                                    isTextFieldFocused = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            AppTheme.accent,
                                            in: Circle()
                                        )
                                        .accessibilityLabel("ingredient_input_accessibility_add")
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.ingredients.wrappedValue.count >= 10)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
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
                            AppCard {
                                VStack(spacing: 10) {
                                    Image(systemName: "leaf")
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.accent)

                                    Text("ingredient_input_empty_title")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))

                                    Text("ingredient_input_empty_description")
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 12)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        }
                    } else {
                        Section(header: AppSectionHeader(titleKey: "ingredient_input_section_title")) {
                            ForEach(viewModel.ingredients.wrappedValue, id: \.self) { ingredient in
                                HStack(spacing: 12) {
                                    Image(systemName: "leaf.fill")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.accent)

                                    Text(ingredient)
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.ink)
                                }
                                .padding(12)
                                .background(
                                    .thinMaterial,
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            }
                            .onDelete { offsets in
                                viewModel.removeIngredient(at: offsets)
                            }

                            Button(role: .destructive) {
                                viewModel.reset()
                            } label: {
                                Label("ingredient_input_clear_list", systemImage: "trash")
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.horizontal)
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
