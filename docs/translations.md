# Contributing translations

Translations are currently maintained directly in this repository. There is no Weblate or Crowdin project in use at this time.

## Existing languages

1. Edit the appropriate ARB file under `lib/ui/core/l10n/`.
2. Keep message keys and placeholders aligned with the source locale; change translated values and translation metadata only as needed.
3. Run the available localization, formatting, and test checks for the repository.
4. Submit the change as a pull request.

The VS Code extension `innwin.i18n-arb-editor` can be used to edit ARB files, but it is optional.

## Adding a new language

Open an issue first so the locale identifier, file setup, and integration can be coordinated before adding a new ARB file.

## Translation platforms

A dedicated translation platform such as Weblate or Crowdin may be considered in the future. Until then, the ARB files in this repository and pull requests are the source of truth for translation contributions.

This workflow reflects the maintainer guidance recorded in upstream issue `tsutsu3/pi-hole-client#404`.
