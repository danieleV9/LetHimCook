# Raccolta di ricette locale

L'app include una raccolta di ricette in `LetHimCook/Resources/RecipeLibrary/recipes.json`.
Quando l'utente cerca una ricetta, gli ingredienti vengono confrontati con la raccolta:

| Corrispondenza | Cosa succede |
| --- | --- |
| L'utente ha tutti gli ingredienti principali della ricetta e la ricetta usa almeno il 60% dei suoi ingredienti | La ricetta viene mostrata così com'è, con il badge "Dalla raccolta" |
| L'utente ha almeno metà degli ingredienti principali | La ricetta viene usata come base e adattata agli ingredienti disponibili ("Ispirata a …") |
| Altrimenti | La ricetta viene scritta da zero |

Le soglie sono in `LetHimCook/Domain/Services/RecipeMatcher.swift`.

La raccolta contiene 30 piatti (classici italiani e ricette svuotafrigo), ognuno in italiano e in inglese, con dosi per 4 persone. Gli `id` hanno il suffisso della lingua, ad esempio `pasta-zucchine-it` e `pasta-zucchine-en`.

## Formato

```json
{
  "recipes": [
    {
      "id": "spaghetti-carbonara",
      "language": "it",
      "title": "Spaghetti alla carbonara",
      "tags": ["primo", "pasta"],
      "ingredients": [
        { "quantity": "320", "unit": "g", "name": "spaghetti" },
        { "quantity": "4", "name": "tuorli d'uovo" },
        { "quantity": "q.b.", "name": "sale grosso", "pantry": true }
      ],
      "steps": [
        {
          "title": "Cuoci la pasta",
          "instruction": "Butta gli spaghetti in acqua bollente salata e cuocili al dente.",
          "durationMinutes": 9
        }
      ]
    }
  ]
}
```

| Campo | Obbligatorio | Note |
| --- | --- | --- |
| `id` | sì | Identificativo univoco, ad esempio `spaghetti-carbonara` |
| `language` | sì | Codice lingua (`it`, `en`): l'app mostra solo le ricette nella sua lingua |
| `title` | sì | |
| `tags` | no | Categorie libere, per ora non usate nel confronto |
| `ingredients[].name` | sì | Solo il nome, senza quantità |
| `ingredients[].quantity` | no | Testo libero: `200`, `1/2`, `q.b.` |
| `ingredients[].unit` | no | `g`, `ml`, `cucchiai`… |
| `ingredients[].pantry` | no | `true` per gli ingredienti di base (sale, olio, pepe, acqua…), che non contano nel confronto |
| `steps[].instruction` | sì | Il testo completo del passaggio |
| `steps[].title` | no | Titolo breve del passaggio |
| `steps[].durationMinutes` | no | Durata in minuti |

## Consigli per un buon confronto

- Scrivi i nomi degli ingredienti come li scriverebbe l'utente: "pomodori pelati" viene trovato cercando "pomodoro", ma "pelati" da solo no.
- Plurali, maiuscole e accenti vengono ignorati; parole come "di", "del", "fresco" anche.
- Segna con `pantry` tutto ciò che si dà per scontato in cucina, altrimenti la ricetta richiederà all'utente di inserirlo.
