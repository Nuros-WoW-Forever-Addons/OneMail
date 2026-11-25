# Changelog

## [0.2.0] - 2026-11-23
### Added
- Graphical `OptionsUI.lua` standalone window (`/om` / `/onemail`) and Blizzard AddOns Settings category (`OneMail`).
- Automatic `"OneAddon"` chat tab creation and message routing (`OneMailDB.routeToOneAddonTab`).
- `/om chat` and `/om help` slash subcommands.

### Changed
- `/om` and `/onemail` without arguments now toggle the Options window directly.
- Removed the conflicting `/om` alias from `OneWorldMap` (retaining `/owm`, `/oneworldmap`, `/onemap`).

## [0.1.0] - 2026-11-23
### Added
- Initial release of `OneMail` for WoW Forever (Interface 16001).
- Automatic Send Mail subject population using the first attached item name.
- Automatic `"Money"` subject population when sending Gold, Silver, or Copper without items.
- Preserves manually typed subjects.
