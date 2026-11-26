# Changelog

All notable changes to the `design_system` package. The package follows
semantic versioning; Foundations' changelog states which version it delivers.

## 0.1.0

First interim release, delivered through Foundations.

- Primitive tokens: `DsPalette` (neutral, success, warning, and error
  scales), `DsSpacing` (4 · 8 · 12 · 16 · 24 · 32 · 48), and `DsRadius`
  (4 · 8 · 16 · pill).
- Semantic tokens as `ThemeExtension`s: `DsColors` and `DsTypography`, read
  with `context.dsColors` and `context.dsTypography`.
- One brand configuration, `DsBrand(primary, fontFamily)`, and the themes
  `DsTheme.light` and `DsTheme.dark` derived from it. Text roles reach at
  least 4.5:1 contrast, and the action color reaches at least 4.5:1 against
  the page, for any brand color.
- Atoms: `DsButton` (primary, secondary, and tertiary; loading; disabled),
  `DsTextField` (label, hint, helper, error, disabled), and
  `DsLoadingIndicator`.
- Molecules: `DsCard`, `DsListTile`, `DsInlineMessage` with `DsMessageTone`,
  and `DsEmptyState`.
- Template: `DsPageScaffold`.
- Every component is tested for tap targets, labels, and text contrast in
  both themes, and for layout at 200% text size on a 320-wide screen.
