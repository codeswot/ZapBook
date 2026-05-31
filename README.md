# ZapBook

A Nostr-native social reading app for Flutter (iOS + Android). Read books
together in circles of 1–100 people, hit AI-verified milestones, and zap each
other sats as encouragement.

This repository is open source under the [MIT License](LICENSE).

---

## Status

ZapBook ships in parts. This repository currently implements:

| Part   | Scope                                              | State    |
| ------ | -------------------------------------------------- | ---------| -------------------------------------------------- |
| **1A** | Book ingestion pipeline (local, offline)           | ✅ Done     |
| 1B     | Gemma 4 AI processing of complex PDF layouts       | ⏳ Planned  |
| 2+     | Nostr events, circles, zaps, reader feature        | ⏳ Planned    |

Part 1A is **pure local extraction and format conversion**. No networking, no
Nostr, no AI. A user picks a file (PDF, DOCX, EPUB, TXT), the pipeline extracts
its content into a structured representation, and writes a `.zbf` archive to
device storage while streaming progress to the UI.

---

## Architecture

Clean Architecture, feature-first. Business logic depends on nothing; the
infrastructure adapts to the domain.

```text
lib/
├── zbf/                     ← shared format kernel: entities, enums, reader, writer
├── core/di/                 ← get_it + injectable composition root
├── app/                     ← MaterialApp shell
├── bootstrap.dart           ← binding init + DI + runApp
└── features/book_ingestion/
    ├── domain/              ← ingestion entities, repository interface, use cases
    ├── data/                ← extractors, repository impl, cover, DI module
    └── presentation/        ← BLoC, progress widget, ingestion page
```

ZBF is a **format kernel**, not a feature — ingestion *produces* it, the future
reader/library features *consume* it, so it lives in `lib/zbf/` and is shared.

State management is [flutter_bloc](https://pub.dev/packages/flutter_bloc).
Dependency injection is [get_it](https://pub.dev/packages/get_it) +
[injectable](https://pub.dev/packages/injectable) — the graph is generated into
`lib/core/di/injection.config.dart` and resolved in `bootstrap()`.

Immutable value types are hand-written with const constructors and
[equatable](https://pub.dev/packages/equatable) value equality, matching the ZBF
JSON shape exactly.

### Ingestion flow

```text
File ─▶ BookExtractor ─▶ ZbfBook ─▶ ZbfWriter ─▶ book.zbf
         (per format)    (in-memory)  (ZIP)        (documents dir)
   └──────────────── Stream<IngestionProgress> ──────────────┘
                              │
                         IngestionBloc ─▶ IngestionProgressWidget
```

Each extractor emits an `IngestionProgress` stream (stage, 0→1 progress,
current item, terminal result/error). The BLoC maps that stream to states and
cancels cleanly on request.

---

## ZapBook Format (ZBF)

A `.zbf` file is a ZIP archive:

```text
book.zbf
├── manifest.json     metadata (title, author, counts, cover ref, flags)
├── cover.png         extracted or generated
├── chapters/         ch_001.json … (ordered BookPage arrays)
└── assets/           img_001.png … (extracted images)
```

`manifest.needsAiProcessing` is `true` only when PDF pages carry complex
layouts that need Gemma 4 (Part 1B). DOCX, EPUB, and TXT are always `false`.

`ZbfReader` returns the manifest immediately and loads chapters lazily — the
seam the reader feature consumes later.

### Cover per format

| Format | Cover source                                                      |
| ------ | ---------------------------------------------------------------- |
| PDF    | page 1 rendered to 600×900                                        |
| EPUB   | cover image declared in `content.opf`                            |
| DOCX   | first embedded image                                             |
| TXT    | generated amber (`#F5A623`) canvas with white title text         |

---

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) and
[`just`](https://github.com/casey/just).

```sh
just setup        # flutter pub get + code generation (DI)
just gen          # re-run build_runner after changing @injectable annotations
just test         # run the test suite
just coverage     # test with coverage, enforce the 65% floor
just precommit    # format + analyze + test + coverage gate
```

Run `just` with no arguments to list every recipe.

---

## Engineering rules

This codebase follows [`rules.md`](rules.md): zero comments, no `dynamic`, no
`!` null assertions, no `late`, no `print`, class widgets only, tests for all
logic, and a 65% coverage floor enforced in `just precommit`.

---

## License

[MIT](LICENSE) — open source.
