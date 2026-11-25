# OneMail

Lightweight helper addon for **WoW Forever (v1.60.1 / Interface 16001)** that automatically populates the Send Mail subject line when sending items or currency.

## Features
- **Item Subject**: Sets the Send Mail subject to the name of the first item attached to the mail. If multiple items are attached, it uses the first item's name. If the first item is removed, it updates to the next remaining item.
- **Money Subject**: Sets the Send Mail subject to `Money` (configurable) when entering Gold, Silver, or Copper with no items attached.
- **Respects Custom Subjects**: If you manually type a subject, OneMail will not overwrite it.
- **Graphical Options Panel**: Configure everything via the standalone movable Options window (`/om` or `Game Menu -> Options -> AddOns -> OneMail`).
- **OneSuite Chat Tab**: Routes addon messages to the shared `"OneAddon"` chat tab.
- **Taint-Safe**: Uses non-intrusive `HookScript` and standard mail events.

## Slash Commands
- `/om` or `/onemail` — Open/toggle the OneMail Options window
- `/om toggle` — Enable or disable auto-subject population
- `/om money <subject>` — Set the subject used when sending money (default: `Money`)
- `/om chat` — Toggle routing messages to the `'OneAddon'` chat tab
- `/om help` — List available commands

## Installation
Sync to `/Applications/World of Warcraft/_forever_/Interface/AddOns/OneMail/` via `./sync-live.sh OneMail` and `/reload` in game.
