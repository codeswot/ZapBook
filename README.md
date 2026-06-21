# ZapBook

A Nostr-native social reading app for Flutter (iOS + Android). Read books together in circles of 1–100 people, hit milestones share your progress with your circle and zap each other sats as encouragement.

This repository is open source under the [MIT License](LICENSE).

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

State management is [flutter_bloc](https://pub.dev/packages/flutter_bloc).
Dependency injection is [get_it](https://pub.dev/packages/get_it) +
[injectable](https://pub.dev/packages/injectable) — the graph is generated into
`lib/core/di/injection.config.dart` and resolved in `bootstrap()`.

Immutable value types are hand-written with const constructors and
[equatable](https://pub.dev/packages/equatable) value equality, matching the ZBF
JSON shape exactly.

## ZapBook Format (ZBF)

A `.zbf` package (directory or archive) structure:

```text
book.zbf/
├── manifest.json     metadata (title, author, counts, cover ref, flags)
├── cover.png         extracted or generated
├── pages.db          SQLite database of pages (JSON rows) for fast on-demand rendering
└── assets/           img_001.png … (extracted images)
```

`manifest.needsAiProcessing` is `true` only when PDF pages carry complex
layouts that need Gemma 4 (Part 1B). DOCX, EPUB, and TXT are always `false`.

`ZbfReader` returns the manifest immediately and loads chapters lazily — the
seam the reader feature consumes later.

### Cover per format

| Format | Cover source                                               |
| ------ |----------------------------------------------------------- |
| PDF    | page 1 rendered to 600×900                                 |
| EPUB   | cover image declared in `content.opf`                      |

## Circle Sharing

ZapBook securely shares books within Nostr circles using **Blossom** for decentralized storage and **Marmot** for NIP-104 group encryption.

### How the Data Flows

To keep sharing fast and reliable, ZapBook doesn't upload the entire book at once. Instead, it breaks it down into pieces:

1. **Local Database (`pages.db`):** When you read a book locally, the app uses a highly efficient SQLite database (`pages.db`) to render pages on demand without bloating memory.
2. **Chunking into Segments (`.zbfseg`):** During upload, the app reads from `pages.db` and chunks the book into 20-page zip archives called segments. Each segment contains the JSON data for those 20 pages and any image assets they reference.
3. **The Manifest (`manifest.json`):** The book's metadata (title, author, total pages) is bundled into *every* segment. This guarantees the app knows what it's downloading even if segments arrive out of order.
4. **Encryption & Upload:** Each `.zbfseg` segment is encrypted individually via Marmot using the circle's shared key and uploaded to a Blossom server. The metadata for these segments is securely published to the Nostr circle.
5. **Download & Reassembly:** When a user opens a shared book, the app downloads the encrypted segments, decrypts them, and reassembles them locally. Finally, it unpacks them back into a fast, local `pages.db` so the new user gets the same smooth reading experience.

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
