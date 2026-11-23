# Foundations

The shared contracts of the modular Flutter app. Micro apps depend on this package only, so everything exported from `lib/foundations.dart` is public API that micro app developers read.

## Public API documentation (required)

Every exported declaration has a proper dartdoc comment, updated in the same change as the code. Follow the shape in the container repository's `CLAUDE.md` ("Public API documentation"), which mirrors the user's reference classes:

- **Types**: a role-noun summary ("Contract that…", "Value that…", "Exception returned when…"), then "Use this when…", "This is **not**…", "Built-in: …", any rules, and a "Usage from a micro app:" label directly above a ` ```dart ` block.
- **Constructors**: "Creates a/an <thing>.", then `Parameters:` with `* [name] - Description` lines.
- **Methods**: a third-person verb summary, `Parameters:`, then what they return and how they fail.
- **Fields**: a noun phrase. Nullable fields start with "Optional…", booleans with "Whether…".
- Use `[links]`, with `/// @docImport` where needed. No `@param` tags and no spec IDs. `public_member_api_docs`, `comment_references`, and `dart doc --dry-run` must stay at 0 issues.

## Other conventions

- Error types are named `…Exception` and live in `lib/src/exceptions/`. Use "type", not "kind". Scope names to their feature. Group helpers as static methods, and prefer SDK helpers.
- No global state: no `static` mutable fields and no top-level variables (`test/architecture/no_global_state_test.dart`).
- Runtime dependencies are only `flutter`, `design_system`, and `switchable_state` (`test/architecture/dependency_rules_test.dart`).
- Tests are written in Gherkin notation (`group('Given …')`, `test('When …, Then …')`).

The container repository's `CLAUDE.md` and `specs/001-foundations-package/` hold the full conventions and the spec.
