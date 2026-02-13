# Tibbetts MultiBar – Changelog

## 1.1.3
- Fix: removed remaining ApplyDefaults() call in PLAYER_LOGIN; initialization now uses EnsureDB()


## 1.1.2
- Fix: EnsureDB no longer calls missing ApplyDefaults() on TBC/Classic; defaults applied via ApplyDefaultsTo


## 1.1.1
- Fix: Reputation color now applies correctly with Profiles (ApplySettings now uses active profile DB)


## 1.1.0
- Profiles: choose which profile is used as the global "default" when using one profile for all characters


## 1.0.9
- Options: added Reputation color picker (hidden when XP/Rep are linked)


## 1.0.8
- Fix: Reputation progress now reads correct values on Classic/TBC (GetWatchedFactionInfo unpack)
- Fix: Reputation/XP updates now use the active profile DB


## 1.0.7
- Options: moved Profiles into its own tab; main settings tab renamed to General
- Options: fixed Profiles layout (no overlap)


## 1.0.6
- Bars: tick dividers inset 1px to eliminate top-edge "indent" on Rep bar
- Added lightweight Profiles (Default + per-character) with "Use one profile for all characters" toggle


## 1.0.5
- Options: added manual numeric entry boxes for Width/Height
- Options: fixed Texture/Font picker buttons using UniversalPicker (LSM-aware)
- Bars: tick dividers now render behind bar/border to match XP/Rep look
- Options: spacing tweaks in Reputation and Advanced sections
- Fix: ColorPicker OK button compatibility on Classic/TBC


## 1.0.4
- Rebuilt Options UI cleanly for Classic/TBC: unified single-page layout + collapsible Advanced
- Eliminated upvalue-limit and syntax issues from prior unified-options iterations


## 1.0.3
- Unified options: merged General + Appearance into a single streamlined page
- Added collapsible Advanced section for rarely-used settings


## 1.0.1
- Rep bar ticks now render under the border (removes top-edge notches)
- Streamlined Appearance tab with optional Link XP & Rep appearance (hides duplicate Rep controls)


## 1.0.0
- Universal texture & font picker with previews + search
- Tick presets (None / 10% / 20%)
- Optional tick percentage tooltips on hover
- Blizzard-style color pickers with opacity sliders (XP/Rep)
- XP/Rep tick rendering unified and clamped
- Optional linking of XP & Reputation appearance settings
- Compatible with Retail, Classic Era, TBC Anniversary, and Wrath