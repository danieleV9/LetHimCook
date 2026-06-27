# 🍳 LetHimCook

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2026+-black.svg?logo=apple" alt="iOS 26+" />
  <img src="https://img.shields.io/badge/Swift-5-orange.svg?logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/UI-SwiftUI-blue.svg" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/AI-Apple%20Foundation%20Models-purple.svg" alt="Foundation Models" />
  <img src="https://img.shields.io/badge/Architecture-Clean%20%2B%20MVVM-green.svg" alt="Architecture" />
</p>

**LetHimCook** is an iOS app that turns the ingredients you have at home into a complete recipe — generated **entirely on-device** using Apple's [Foundation Models](https://developer.apple.com/documentation/foundationmodels) framework (Apple Intelligence). No servers, no API keys, no internet required for the AI: type what's in your fridge, and let the model cook.

## ✨ Features

- 🧑‍🍳 **AI recipe generation** — enter up to 10 ingredients and get a full recipe (title, ingredients, step-by-step method) written by an on-device language model prompted to act as a professional chef.
- 🔒 **100% on-device & private** — recipes are generated locally via Apple's `SystemLanguageModel`. Your ingredients never leave the device.
- 📖 **Save your favorites** — persist generated recipes with **Core Data** and browse them in the *My Recipes* tab.
- 🗑️ **Manage your collection** — delete a single recipe or clear them all.
- 🎬 **Polished UI** — SwiftUI with a custom design system and a **Lottie** animation on the home screen.
- 🌍 **Localized** — available in **English** and **Italian**.
- ♿️ **Accessible** — accessibility labels on interactive controls.

## 📱 How it works

1. Open the app and tap **Find the recipe**.
2. Add the ingredients you have available (up to 10).
3. The on-device model generates a recipe formatted in Markdown.
4. Save the ones you love and find them later under **My Recipes**.

## 🧱 Architecture

LetHimCook follows **Clean Architecture** with an **MVVM** presentation layer, keeping business logic independent from UI and frameworks.

```
LetHimCook/
├── App/                     # App entry point & composition
├── Core/
│   ├── DI/                  # AppContainer — dependency registration (ActorDI)
│   ├── Logging/             # Logger abstraction + ConsoleLogger
│   └── Utils/               # FoundationModelManager (Apple Intelligence wrapper)
├── Domain/                  # Pure business layer (no framework dependencies)
│   ├── Entities/            # Recipe
│   ├── Repositories/        # Repository protocols
│   └── UseCases/            # GetRecipe, SaveRecipe, GetSavedRecipes, DeleteSavedRecipes
├── Data/
│   ├── CoreData/            # PersistenceController
│   └── Repositories/        # Foundation & Core Data repository implementations
├── Presentation/
│   ├── ViewModels/          # @Observable view models
│   └── Views/               # SwiftUI views + reusable Components / DesignSystem
└── Resources/               # Assets, Lottie animation, localizations (en/it)
```

**Layered flow:**

```
View → ViewModel → UseCase → Repository → (Foundation Models | Core Data)
```

- **Domain** defines `RecipeRepository` / `SavedRecipeRepository` protocols and the use cases that orchestrate them — with no knowledge of SwiftUI, Core Data, or Apple Intelligence.
- **Data** provides concrete implementations: `FoundationRecipeRepository` (AI generation) and `CoreDataSavedRecipesRepository` (persistence).
- **Presentation** binds everything to SwiftUI through lightweight `@Observable` view models.

### Dependency Injection

Dependencies are wired together at launch in [`AppContainer`](LetHimCook/Core/DI/AppContainer.swift) using [**ActorDI**](https://github.com/danieleV9/ActorDI) — an actor-based, concurrency-safe DI container. Repositories and use cases are registered as singletons and resolved on demand:

```swift
await container.register(GetRecipeUseCase.self, scope: .singleton) {
    GetRecipeUseCaseImpl(repository: repository)
}
```

## 🤖 On-device AI

The [`FoundationModelManager`](LetHimCook/Core/Utils/FoundationModelManager.swift) wraps Apple's Foundation Models framework. It checks model availability (eligible device, Apple Intelligence enabled, model downloaded) and runs a `LanguageModelSession` with a chef-style system prompt, returning Markdown output. Availability errors are surfaced to the user with clear, localized messages.

## 🛠️ Tech Stack

| Area              | Technology                                   |
|-------------------|----------------------------------------------|
| Language          | Swift                                        |
| UI                | SwiftUI                                       |
| On-device AI      | Apple Foundation Models (Apple Intelligence) |
| Persistence       | Core Data                                     |
| Dependency Injection | [ActorDI](https://github.com/danieleV9/ActorDI) |
| Animations        | [Lottie](https://github.com/airbnb/lottie-spm) |
| Architecture      | Clean Architecture + MVVM                     |

## 📋 Requirements

- **iOS 26.0+**
- **Xcode 26+**
- A device that supports **Apple Intelligence** with the feature enabled (required for recipe generation)

> [!NOTE]
> Foundation Models run only on Apple Intelligence–capable devices. On unsupported devices or when Apple Intelligence is disabled, the app explains why generation is unavailable instead of crashing.

## 🚀 Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/danieleV9/LetHimCook.git
   cd LetHimCook
   ```
2. Open the project in Xcode:
   ```bash
   open LetHimCook.xcodeproj
   ```
3. Swift Package Manager will resolve the dependencies (**ActorDI**, **Lottie**) automatically.
4. Select an Apple Intelligence–capable device (or a compatible simulator) and run with `⌘R`.

## 🧪 Testing

The project includes unit (`LetHimCookTests`) and UI (`LetHimCookUITests`) test targets. Run them from Xcode with `⌘U`, or from the command line:

```bash
xcodebuild test \
  -project LetHimCook.xcodeproj \
  -scheme LetHimCook \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## 👤 Author

Created and maintained by [Daniele Valentino](https://github.com/danieleV9).

Contributions, issues, and feature requests are welcome!
