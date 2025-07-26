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
        VStack(spacing: 0) {
            Text("Your Ingredients")
                .font(.title2)
                .padding(.top)

            if viewModel.ingredients.wrappedValue.count >= 10 {
                Text("Puoi aggiungere al massimo 10 ingredienti")
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            List {
                ForEach(viewModel.ingredients.wrappedValue, id: \.self) { ingredient in
                    Text("\u{2022}  " + ingredient)
                        .font(.system(size: 18))
                }
                .onDelete { offsets in
                    viewModel.removeIngredient(at: offsets)
                }
            }
            .listStyle(.plain)

            if !viewModel.ingredients.wrappedValue.isEmpty {
                Button(action: {
                    viewModel.reset()
                }) {
                    Label("Clean", systemImage: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Spacer()
            Divider()
            HStack(spacing: 12) {
                TextField("Add an ingredient", text: $viewModel.currentInput)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 10)
                    .focused($isTextFieldFocused)

                Button {
                    viewModel.addIngredient()
                    isTextFieldFocused = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.ingredients.wrappedValue.count >= 10)
                .foregroundColor(.accentColor)
                .labelStyle(.titleAndIcon)

                Button {
                    dismiss()
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .foregroundColor(.teal)
                .labelStyle(.titleAndIcon)
            }
            .padding([.horizontal, .bottom])
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    IngredientInputView(viewModel: IngredientInputViewModel(ingredients: .constant(["Eggs", "Milk", "Flour"])))
}
