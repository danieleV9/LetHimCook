import SwiftUI

/// Renders a structured recipe: title, key facts, ingredients and ordered steps.
struct RecipeBody: View {
    let recipe: Recipe
    var isSaved = false

    /// Ingredients the user has ticked off while cooking. View-only state.
    @State private var checkedIngredients: Set<Int> = []
    /// Steps the user has marked as done while cooking. View-only state.
    @State private var completedSteps: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            titleBlock

            if !recipe.ingredients.isEmpty || !recipe.steps.isEmpty {
                factsRow
            }

            if !recipe.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    AppSectionHeader(titleKey: "recipe_ingredients_header")
                        .padding(.bottom, 8)

                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        ingredientRow(ingredient, at: index)

                        if index < recipe.ingredients.count - 1 {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
            }

            if !recipe.steps.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    AppSectionHeader(titleKey: "recipe_steps_header")

                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        stepRow(step, at: index)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Pieces

    @ViewBuilder
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                originBadge
                if isSaved {
                    AppBadge(titleKey: "recipe_saved_badge", systemImage: "bookmark.fill")
                }
            }

            if !recipe.title.isEmpty {
                Text(recipe.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var originBadge: some View {
        switch recipe.origin {
        case .generated:
            AppBadge(titleKey: "badge_on_device_ai", systemImage: "sparkles")
        case .library:
            AppBadge(titleKey: "recipe_library_badge", systemImage: "book.closed")
        case .adapted(let sourceTitle):
            AppBadge(titleKey: "recipe_adapted_badge \(sourceTitle)", systemImage: "book.closed")
        }
    }

    private var factsRow: some View {
        HStack(spacing: 12) {
            factTile(value: recipe.ingredients.count, titleKey: "recipe_ingredients_header", systemImage: "basket")
            factTile(value: recipe.steps.count, titleKey: "recipe_steps_header", systemImage: "list.number")
        }
    }

    private func factTile(value: Int, titleKey: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 0) {
                Text(value, format: .number)
                    .font(.headline)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(titleKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func ingredientRow(_ ingredient: RecipeIngredient, at index: Int) -> some View {
        let isChecked = checkedIngredients.contains(index)

        return Button {
            withAnimation(.snappy) {
                if isChecked {
                    checkedIngredients.remove(index)
                } else {
                    checkedIngredients.insert(index)
                }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? AppTheme.accent : .secondary)
                ingredientText(ingredient)
                    .font(.body)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }

    /// "200 g spaghetti" with the amount in bold, or just the name.
    private func ingredientText(_ ingredient: RecipeIngredient) -> Text {
        guard let amount = ingredient.amount else { return Text(ingredient.name) }
        return Text("\(Text(amount).bold()) \(ingredient.name)")
    }

    private func stepRow(_ step: RecipeStep, at index: Int) -> some View {
        let number = index + 1
        let isCompleted = completedSteps.contains(index)

        return Button {
            withAnimation(.snappy) {
                if isCompleted {
                    completedSteps.remove(index)
                } else {
                    completedSteps.insert(index)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                    } else {
                        Text(number, format: .number)
                            .font(.subheadline.weight(.bold))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(isCompleted ? AppTheme.accent : .white)
                .frame(width: 30, height: 30)
                .background(isCompleted ? AppTheme.accentSoft : AppTheme.accent, in: Circle())
                .accessibilityHidden(true)

                stepContent(step, isCompleted: isCompleted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(number). \(step.title) \(step.instruction)"))
        .accessibilityAddTraits(isCompleted ? .isSelected : [])
    }

    private func stepContent(_ step: RecipeStep, isCompleted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !step.title.isEmpty {
                Text(step.title)
                    .font(.headline)
                    .strikethrough(isCompleted)
            }

            Text(step.instruction)
                .font(.body)
                .strikethrough(isCompleted && step.title.isEmpty)

            if let minutes = step.durationMinutes, minutes > 0 {
                Label {
                    Text("recipe_step_duration \(minutes)")
                } icon: {
                    Image(systemName: "timer")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(isCompleted ? AnyShapeStyle(.secondary) : AnyShapeStyle(AppTheme.accent))
            }
        }
        .foregroundStyle(isCompleted ? .secondary : .primary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Recipe detail") {
    RecipeDetailLayout(artworkSeed: "Carbonara", title: "Creamy Egg & Parmigiano Pasta") {
        RecipeBody(
            recipe: Recipe(
                title: "Creamy Egg & Parmigiano Pasta",
                ingredients: [
                    RecipeIngredient(quantity: "200", unit: "g", name: "spaghetti"),
                    RecipeIngredient(quantity: "2", name: "eggs"),
                    RecipeIngredient(quantity: "50", unit: "g", name: "Parmigiano"),
                    RecipeIngredient(name: "Black pepper"),
                    RecipeIngredient(name: "Salt")
                ],
                steps: [
                    RecipeStep(
                        title: "Cook the pasta",
                        instruction: "Boil the spaghetti in salted water until al dente.",
                        durationMinutes: 9
                    ),
                    RecipeStep(
                        title: "Make the cream",
                        instruction: "Whisk the eggs with the grated Parmigiano and plenty of pepper."
                    ),
                    RecipeStep(
                        title: "Toss off the heat",
                        instruction: "Toss the drained pasta off the heat with the egg mixture, adding pasta water until creamy.",
                        durationMinutes: 2
                    )
                ],
                origin: .adapted(fromTitle: "Spaghetti alla carbonara")
            ),
            isSaved: true
        )
    }
}
