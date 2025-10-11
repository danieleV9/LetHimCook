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
                                .foregroundStyle(.white, .accentColor)
                                .accessibilityLabel("Add ingredient")
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.ingredients.wrappedValue.count >= 10)
                    }
                } footer: {
                    if viewModel.ingredients.wrappedValue.count >= 10 {
                        Text("Puoi aggiungere al massimo 10 ingredienti")
                            .foregroundStyle(.red)
                    } else {
                        Text("Aggiungi fino a 10 ingredienti per ottenere suggerimenti più precisi.")
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.ingredients.wrappedValue.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "leaf")
                                .font(.title)
                                .foregroundStyle(.tertiary)

                            Text("Nessun ingrediente")
                                .font(.headline)

                            Text("Inizia aggiungendo gli ingredienti che hai a disposizione.")
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
                    Section("I tuoi ingredienti") {
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
                            Label("Svuota lista", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Ingredienti")
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
