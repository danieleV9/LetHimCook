// IngredientInputView.swift
// LetHimCook
//
// Created by Daniele Valentino on 13/07/25.

import SwiftUI

struct IngredientInputView: View {
    @Bindable var viewModel: IngredientInputViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    private let chipColumns = [GridItem(.adaptive(minimum: 110), spacing: 8, alignment: .leading)]

    private var isAtLimit: Bool { viewModel.ingredients.count >= 10 }
    private var canAdd: Bool {
        !viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isAtLimit
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        inputField
                        hint
                        ingredientsSection
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
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

    // MARK: - Input

    private var inputField: some View {
        HStack(spacing: 10) {
            TextField("ingredient_input_placeholder", text: $viewModel.currentInput)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .rounded))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit(addIngredient)

            Button(action: addIngredient) {
                Image(systemName: "plus")
                    .font(.headline)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.accent)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .disabled(!canAdd)
            .accessibilityLabel("ingredient_input_accessibility_add")
        }
        .padding(.vertical, 8)
        .padding(.leading, 18)
        .padding(.trailing, 8)
        .background(.regularMaterial, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var hint: some View {
        HStack {
            Text(isAtLimit ? "ingredient_input_footer_limit" : "ingredient_input_footer_hint")
                .foregroundStyle(isAtLimit ? Color.red : Color.secondary)
            Spacer()
            Text("\(viewModel.ingredients.count)/10")
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(isAtLimit ? Color.red : Color.secondary)
        }
        .font(.footnote)
        .padding(.horizontal, 4)
    }

    // MARK: - Ingredients

    @ViewBuilder
    private var ingredientsSection: some View {
        if viewModel.ingredients.isEmpty {
            ContentUnavailableView {
                Label("ingredient_input_empty_title", systemImage: "leaf")
            } description: {
                Text("ingredient_input_empty_description")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ingredient_input_section_title")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button(role: .destructive) {
                        withAnimation { viewModel.reset() }
                        isTextFieldFocused = true
                    } label: {
                        Text("ingredient_input_clear_list")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }

                LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                    ForEach(Array(viewModel.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        ingredientChip(ingredient, at: index)
                    }
                }
            }
        }
    }

    private func ingredientChip(_ ingredient: String, at index: Int) -> some View {
        Button {
            withAnimation {
                viewModel.removeIngredient(at: IndexSet(integer: index))
            }
        } label: {
            HStack(spacing: 6) {
                Text(ingredient)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppTheme.accentSoft.opacity(0.30), in: Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(format: String(localized: "ingredient_input_remove"), ingredient)))
    }

    private func addIngredient() {
        viewModel.addIngredient()
        isTextFieldFocused = true
    }
}

#Preview {
    IngredientInputView(viewModel: IngredientInputViewModel(ingredients: ["Eggs", "Milk", "Flour"]))
}
