# codeswot's — Engineering Rules**

> These rules apply to every service, every language, every pull request.
> No exceptions. Ask/debate when necessary.in the meantime Just follow them.

- --

## Code Quality

### No comments in code

Code is the documentation. If you feel the need to write a comment, the code
is not clear enough. Rename the variable, extract the function, simplify the
logic — until the comment is unnecessary.

- **Keep methods short.**

A function should do one thing. If you need to scroll to read it, it is too
long. Aim for functions that fit on one screen. If a function is growing,
extract the pieces into well-named helpers.

- **Code should be self-explanatory.**

Variable names, function names, type names — they should tell the reader
exactly what they are and what they do. Abbreviations are banned unless they

are universally understood (`id`, `url`, `ctx`, `err`).

- --

## Principles

### DRY — Don't Repeat Yourself

Every piece of knowledge must have a single, unambiguous representation in
the codebase. If you are writing the same logic in two places, extract it.
If you are copying and pasting, stop.

### YAGNI — You Aren't Gonna Need It

Do not build features or abstractions for requirements that do not exist yet.
Build what is needed now. Extend when the need is real. Speculative
generality is a form of waste.

### SOLID

- **S** — Single Responsibility: one reason to change per class/module
- **O** — Open/Closed: open for extension, closed for modification
- **L** — Liskov Substitution: subtypes must be substitutable for their base types
- **I** — Interface Segregation: many specific interfaces over one general one
- **D** — Dependency Inversion: depend on abstractions, not concretions

- --

## Architecture

- **Clean Architecture where it makes sense.**

Business logic must not depend on frameworks, databases, or transport layers.
The domain is the centre. Infrastructure (HTTP, gRPC, database, cache) adapts
to the domain — not the other way around.

```text

Domain / Business Logic     ← no external dependencies

↑

Use Cases / Application     ← orchestrates domain

↑

Interface Adapters          ← HTTP handlers, gRPC servers, repositories

↑

Infrastructure              ← Postgres, Redis, Ollama, Docker

```

- **Right design patterns.**

Use patterns when they solve a real problem, not to demonstrate knowledge.
Prefer simple and obvious over clever and abstract. If a junior developer
cannot understand it in five minutes, it is too complex.

- **Layered services.**

Each service owns its domain. Services do not reach into each other's
internals. Communication happens through defined interfaces — HTTP, gRPC,
or events via Redis/MQTT. No shared databases between services.

- --

## Dependencies

- **Always use industry-standard packages.**

Before writing something from scratch, check if a well-maintained,
widely-adopted library exists. Use it. Follow its documentation exactly.
Do not invent conventions that the library already defines.

- **Pin dependency versions.**

Never use floating versions (`latest`, `*`, `^` without a lockfile).
Every dependency must be pinned and committed to the lockfile
(`go.sum`, `Cargo.lock`, `package-lock.json`, `pubspec.lock`).

- **Keep dependencies minimal.**

Every dependency is a liability — security surface, upgrade burden,
potential breaking change. Only add a dependency when the alternative
is writing significant, complex code yourself.

- --

## Testing

- **Always write tests. No exception.**

Every function, class, and feature ships with tests. Bug fixes ship with
a regression test that fails before the fix and passes after. Refactors
keep the existing tests green. Untested code is not committed.

- **Test at the right level.**

Unit tests for pure logic. Integration tests for flows that cross
boundaries. Property tests for invariants under random input. Pick the
weakest level that proves the behavior.

- **Tests run in `just precommit`.**

If they don't run there, they don't exist. CI runs the same gate.
No `@Skip`, no `// ignore`, no commented-out tests on main — fix the
test, open a GitHub issue, or delete it.

- **Tests are first-class code.**

Same rules apply: no `dynamic`, no `print`. Test names
describe behavior, not function identifiers (`'returns last 6 chars
of a longer id'`, not `'test_shortDeviceId'`).

- --

## Coverage

- **Floor: 65% overall. `just precommit` enforces it.**

`just coverage` runs `flutter test --coverage`, parses `coverage/lcov.info`,
and fails non-zero if the package falls below 65%. CI runs the same gate.
Coverage below the floor blocks merge.

- **Tier targets — what coverage SHOULD look like.**

Domain logic, services, repositories, parsers, validators — **80–90%**.
Pure Dart, easy to test, highest bug-payoff per test.

State logic (Bloc / Cubit / Riverpod) — **70–80%**. State transitions
are mechanical to test and high-value.

Widget tests — **30–50%**. Smoke + critical paths. Don't chase lines
here; chase confidence in real flows.

Platform glue, generated code, `main()` — exempt from tier targets.

- **Coverage is a floor, not a goal.**

65% overall means low-payoff areas (UI scaffolding, glue) drag the average
down — the high-payoff layers should be at their tier target or higher. A
65% codebase that's 65% in the domain layer is broken even if the number
passes. Read the breakdown, not just the headline.

- **HTML report on demand.**

`just coverage-html` produces a browsable report at `coverage/html/index.html`
when triaging gaps. Requires `lcov` (`brew install lcov`).

- --

## Language-Specific Rules

### TypeScript / NestJS

- `strict` mode enabled in `tsconfig.json` — no exceptions
- No `any` types — ever
- No implicit `any` via missing type annotations
- `class-validator` + `class-transformer` on all DTOs
- Guards on every protected route — no naked endpoints
- Prisma for all database access — no raw SQL unless unavoidable
- Swagger decorators on all endpoints

### Dart / Flutter

- No `dynamic` types — ever
- No `!` null assertions — handle nulls properly
- No `late` variables — initialize everything in the constructor unless you have a very good reason not to
- No `print` statements in production code — use the logger
- **Never use function widgets, always class widgets** — no `Widget _buildX()` helpers or `Widget Function()` typedefs used as components. Every reusable UI fragment must be its own `StatelessWidget` / `StatefulWidget` class (private if used once, public if reused). Class widgets get proper rebuild scoping, const construction, hot-reload state preservation, and inspector identity. Framework builder callbacks (`LayoutBuilder`, `BlocBuilder`, `ListView.builder`'s `itemBuilder`, `showModalBottomSheet`'s `builder`, etc.) are the only legitimate exception.

overall more detailed rules for each language/framework will be added to its respective README/Linter rules.

- --

## What Clean Code Looks Like

```dart

*// ✗ Wrong — comment explains what the code should explain itself*

*// Check if user has admin role before proceeding*
if(user.roles.contains("admin")) {}

*// ✓ Right — self-explanatory*

if(user.roles.contains("admin")) {}

```

```dart

*// ✗ Wrong — method doing too many things*

 Future<Response> processRequest(req Request) {

*// validate*

*// fetch from db*

*// call external service*

*// transform*

*// save*

*// notify*

*// return*

}

*// ✓ Right — each concern extracted*

 Future<Response> processRequest(req Request) {

 validate(req)

 fetch(validated)

transform(data)

save(result)

notify(result)

return result

}

```

```typescript

*// ✗ Wrong — speculative abstraction (YAGNI)*

*class* *UniversalDataProcessorFactoryStrategy* { *...* }

*// ✓ Right — solve the actual problem*

*class* *OrderProcessor* { *...* }

```

- --

## Non-Negotiable

- No secrets in code — ever
- No commented-out code committed
- No `TODO` or `FIXME` committed to main — open a GitHub issue instead
- No `console.log` / `fmt.Println` / `println!` in production code — use the logger
- No direct database access from HTTP handlers — always go through a repository/service layer

- --

> These rules exist to keep the codebase readable, maintainable, and
extensible as it grows. When in doubt, optimise for the next
developer reading this code — which is future you!
