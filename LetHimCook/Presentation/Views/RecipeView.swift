import SwiftUI

struct RecipeView: View {
    @Bindable var viewModel: RecipeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppSectionHeader(titleKey: "recipe_title")

                    content
                }
                .padding(.horizontal)
                .padding(.top, 70)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .top) {
            topBar
        }
        .task {
            await viewModel.loadRecipe()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(
                        .ultraThinMaterial,
                        in: Circle()
                    )
                    .accessibilityLabel("recipe_back_button")
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            .ultraThinMaterial
                .opacity(0.9)
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            AppCard {
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)

                    Text("recipe_title")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .success(let recipe):
            AppCard {
                Text(.init(recipe))
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(AppTheme.ink)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .failure(let message):
            AppCard {
                ContentUnavailableView {
                    Label(message, systemImage: "sparkles.slash")
                }
            }
        case .idle:
            AppCard {
                Text("recipe_placeholder")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    RecipeView(viewModel: RecipeViewModel(ingredients: ["Eggs", "Milk", "Flour"]))
}
