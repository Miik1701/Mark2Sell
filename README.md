# Mark2Sell

**Mark2Sell** is a World of Warcraft **Retail** addon for tagging specific bag items you plan to sell. Marks are stored **per item instance** (item GUID), so you can mark one stack without marking every copy of that item. Only slots with a **vendor sell price** can be marked.

## Features

- **Toggle mark** - With the mouse over a bag slot, press your keybind to mark or unmark that stack instance.
- **Clear all marks** - Keybind to wipe every mark at once.
- **Bag overlay** - Marked slots get a clear visual indicator.
- **BagBrother** - Optional compatibility with **BagBrother** (and **Bagnon** / **Bagnonium**): marks, overlays, and the clear-marks button work in those bag windows when the addon is loaded.
- **Merchant helper** - While a vendor window is open, use the addon control to **sell all marked items** (respects normal sell delays and locked slots).
- **Clear-marks button** - Optional button near the bags UI; position is adjustable in settings or the setup wizard.
- **Setup wizard** - First-run (and repeatable) flow for language, keybinds, and clear-button placement. Open anytime with **`/m2s`**.
- **Localization** - **English** ships with the addon. Additional languages come as **optional language-pack addons** (e.g. **`Mark2Sell_deDE`** for German). Automatic mode picks the client language if a matching pack is installed and otherwise falls back to English.

## Installation

1. Copy the **`Mark2Sell`** folder into:
   - `_retail_/Interface/AddOns/Mark2Sell/`
2. The folder must contain **`Mark2Sell.toc`** at the top level (same level as this `README.md` if you ship it in the package).
3. Restart the game or use `/reload` after installing or updating.

## Usage

| Action | How |
|--------|-----|
| Mark / unmark | Keybind: *Toggle mark on bag item under cursor* - hover the bag slot first. |
| Clear all marks | Keybind: *Clear all marks*. |
| Setup wizard | Chat: **`/m2s`**, or the button in **Options → AddOns → Mark2Sell**. |
| Sell marked items | Open a vendor, then use the **Mark2Sell** sell control on the merchant frame. |

Bindings are under **Esc → Options → Keybindings**, category **Mark2Sell**.

### Debug mode

With **debug mode** enabled in addon settings, an extra binding (*List marked items in chat*) appears. It is hidden in the setup wizard and intended for troubleshooting.

## Saved data

Settings and marks use **`ItemMarkerDB`** (**per character**). They are not synced across characters.

## Releasing a new version (maintainers)

Releases are driven by **GitHub Actions** (`.github/workflows/release-version.yml`) so **`## Version`** in `Mark2Sell.toc` stays in sync with a **git tag** for hosts such as **CurseForge** (packager on new tags).

### How to bump the version

1. Push to **`main`** or **`master`**.
2. Include **`[release] X.Y.Z`** anywhere in the **commit message** (subject or body), with **`X.Y.Z`** = semantic version digits only, for example:
   - `[release] 1.0.2`
   - `[release] v1.0.2` (the leading `v` is ignored; the tag will still be `v1.0.2`)
3. If that pattern is **missing**, the workflow does **nothing** (no `.toc` edit, no tag).
4. If it **matches**, the workflow will:
   - set `## Version: X.Y.Z` in `Mark2Sell.toc`;
   - commit **`chore(release): Mark2Sell X.Y.Z`** (without `[release]`, so it does not run again);
   - push the commit and create an annotated tag **`vX.Y.Z`**.

**Example commit message:**

```text
Fix merchant button tooltip

[release] 1.0.2
```

### Monorepo layout

If the git repository root is **above** this addon folder, set `TOC_FILE` in the workflow to the path of `Mark2Sell.toc` (e.g. `src/Mark2Sell/Mark2Sell.toc`) and keep `.github/workflows` at the **repository** root.

## Author


**Mik1701** - see `Mark2Sell.toc` for the current `## Version` line.

## Language packs

Mark2Sell ships with **English only**. Any other language is a separate addon that registers itself with Mark2Sell at load time. The German pack **`Mark2Sell_deDE`** in this repository is the reference example - copy it, rename the folder, and swap the locale code / strings to publish a new language.

### Installing a pack (as a user)

1. Copy the pack folder into `_retail_/Interface/AddOns/` (next to `Mark2Sell`).
2. Enable both addons in the AddOns list. `/reload` or restart.
3. Automatic mode now picks the pack when the WoW client language matches; a specific language can also be chosen in **Options - AddOns - Mark2Sell** or via `/m2s`.

### Writing a pack (as an author)

A pack is a normal WoW addon with a single Lua file. Requirements:

- Its `.toc` must declare **`## Dependencies: Mark2Sell`** so Mark2Sell loads first.
- Its Lua calls exactly one function against the shared `ItemMarker` API:

```lua
ItemMarker:RegisterLocale("frFR", "Français", { --[[ same keys as English ]] })
```

- The `locale` argument must equal `GetLocale()` for the target client (`deDE`, `frFR`, `esES`, `ruRU`, `koKR`, `zhCN`, `zhTW`, `itIT`, `ptBR`, ...).
- Missing keys automatically fall back to English, so partial translations are fine.

Full walkthrough and copy-paste template: [`Mark2Sell_deDE/README.md`](../Mark2Sell_deDE/README.md).

## Roadmap

- **Mark2Disenchant** - planned companion addon later, in the same spirit as Mark2Sell but for disenchanting workflows.