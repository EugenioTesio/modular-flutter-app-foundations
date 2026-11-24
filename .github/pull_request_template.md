## What changes

<!-- One or two sentences on what this pull request changes and why. -->

## Version impact

Pick one. Below 1.0.0, a breaking change bumps the minor version; from 1.0.0
on, it bumps the major version.

- [ ] **Compatible**: no public element was removed, renamed, or changed in a
  way that breaks existing callers or implementers.
- [ ] **Breaking**: a public element was removed, renamed, or changed in a way
  that needs consumer changes. This includes adopting a breaking
  `design_system` or `switchable_state` release.

## Migration notes

<!-- Required for a breaking change: what each consumer (micro apps, Core,
hosts) must change, with before and after code. Write "None" otherwise. -->

## Checklist

**Documentation**

- [ ] Every new or changed public element has a dartdoc comment in the house
  style: role summary, "Use this…", "This is **not**…", "Built-in:…",
  parameters, outcomes and failures, and a usage example.
- [ ] Privacy rules are stated where they apply: no credentials or personal
  data in logs, analytics, crash reports, or `toString`.
- [ ] `flutter analyze` and `dart doc --dry-run` report 0 issues.

**Inclusion rules**

- [ ] No feature-specific models, such as an account or card response. They
  stay in the micro app that owns them.
- [ ] No business entitlements: access rules belong to the micro app that
  owns the data.
- [ ] No wrappers, renames, or `show`/`hide` lists around `design_system` or
  `switchable_state`: both are re-exported unchanged.
- [ ] No new capability: the capability set is fixed. A new one needs a
  specification change first.
- [ ] No concrete implementations, vendor types, global state, or new runtime
  dependencies.

**Deprecation**

- [ ] A public element that will be removed is marked `@Deprecated` for at
  least one minor release first, with the replacement named in the message.

**Changelog**

- [ ] `CHANGELOG.md` has an entry under the next version, with the Added,
  Changed, Deprecated, Removed, and Breaking sections.
- [ ] The entry states the delivered `design_system` and `switchable_state`
  versions.

**Tests**

- [ ] New behavior has tests in Gherkin notation, and line coverage of `lib/`
  stays at 90% or more.
