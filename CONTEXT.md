# AI Context & Living Specification — OneMail

> **Living Document**: This file serves as the primary context, architectural specification, and state-handoff document for AI-assisted development across sessions. Update this file on every development cycle ("spin").

---

## 🎯 Overview & Scope

- **Addon Name**: OneMail
- **Current Version**: 0.2.0
- **Suite**: Part of the **OneSuite** family
- **GitHub Repository**:
  - Exists: TRUE
  - URL: https://github.com/Nuros-WoW-Forever-Addons/OneMail
- **Branching Policy**: All new features must be developed on a branch != `main` (active branch: `dev`)
- **Live Sync Path**: `/Applications/World of Warcraft/_forever_/Interface/AddOns/OneMail/`
- **Rollback Target**: Last working `main` branch commit
- **Release Package**: `.github/workflows/package.yml` generates `OneMail-latest.zip` on push to `main`
- **Target WoW Runtime**: WoW Forever (v1.60.1 / Interface 16001)
- **Primary Goal**: Automatically populate the Send Mail subject line with the first attached item's name (if any items are attached) or `"Money"` (configurable) when sending currency, without overwriting custom subjects typed by the user.

---

## 🏗️ Architecture & Component Map

### File Structure
- `OneMail.toc`: Addon manifest (`## Interface: 16001`), `OneMailDB` SavedVariables declaration, and load order (`Core.lua`, `OptionsUI.lua`).
- `Core.lua`: SavedVariables initialization (`ADDON_LOADED`), `"OneAddon"` chat tab creation and routing (`EnsureChatTab`, `Print`), event dispatch table (`PLAYER_ENTERING_WORLD`, `MAIL_SHOW`, `MAIL_CLOSED`, `MAIL_SEND_INFO_UPDATE`, `MAIL_SEND_SUCCESS`), `HookScript("OnTextChanged", ...)` hooks on `SendMailSubjectEditBox` and `SendMailMoney{Gold,Silver,Copper}`, subject computation, and `/om` / `/onemail` slash commands.
- `OptionsUI.lua`: Standalone draggable, ESC-closable `OneMailOptionsFrame` and Blizzard Settings category registration (`Game Menu -> Options -> AddOns -> OneMail`).

### Global State & Database Schema (`OneMailDB`)
```lua
OneMailDB = {
    enabled = true,
    moneySubject = "Money",
    routeToOneAddonTab = true,
    optionsPosition = nil,
}
```

---

## ✅ Recent Completed Work (Latest Spins)

### Spin 0.2.0
- **Dedicated `"OneAddon"` Chat Tab Routing**: Added `ns:EnsureChatTab()` and `ns:Print()` in `Core.lua` with deferred `PLAYER_ENTERING_WORLD` initialization (`0.3s`), routing all addon feedback to the `"OneAddon"` tab when `OneMailDB.routeToOneAddonTab` is enabled.
- **Graphical Options Panel (`OptionsUI.lua`)**: Added standalone movable/ESC-closable `OneMailOptionsFrame` (toggled via `/om` or `/onemail`) and registered `OneMail` in Blizzard's AddOns Settings panel (`Game Menu -> Options -> AddOns -> OneMail`) with toggles for Auto-Subject, `"OneAddon"` chat tab routing, custom Money subject input, and Reset Defaults.
- **Slash Command Conflict Resolution**: Removed `/om` from `OneWorldMap/Core.lua` (retaining `/owm`, `/oneworldmap`, `/onemap`; `OneMiniMap` uses `/omm`) so `/om` belongs exclusively to `OneMail`.

### Spin 0.1.0
- **Initial OneMail Addon**:
  - Created `OneMail.toc` (`## Interface: 16001`) and `Core.lua`.
  - Added automatic Send Mail subject population using the first non-empty attachment slot (`GetSendMailItem`, with `C_Item.GetItemNameByID` fallback).
  - Added automatic `"Money"` subject population when copper > 0 (`MoneyInputFrame_GetCopper(SendMailMoney)`) and no items are attached.
  - Preserves user-typed custom subjects by tracking `lastAutoSubject` and hooking `SendMailSubjectEditBox` `OnTextChanged` (`isUserInput`).

---

## 📋 Living Roadmap & Upcoming Backlog

### High Priority
- Verify in-game on WoW Forever (v1.60.1 / Interface 16001) with single items, multiple items, item removal, Gold/Silver/Copper entry, `/om` Options window, and `"OneAddon"` chat tab output.

### Nice-to-Have / Future Enhancements
- Optional item count suffix (e.g., `"Linen Cloth (x20)"`).
