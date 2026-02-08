# Tibbetts MultiBar – Changelog

## 1.0.1
### Added
- Universal texture & font picker with live preview
- Search filtering for textures and fonts
- Optional tick presets:
  - No ticks
  - Every 10%
  - Every 20%
- Optional percentage tooltip when hovering ticks
- Blizzard-style color picker with opacity slider for:
  - XP background
  - Reputation background

### Changed
- Replaced fragile sliders with preset options for better cross-version support
- Moved picker logic into a standalone module to avoid Classic/TBC Lua limits
- Unified XP and Reputation tick rendering for consistency

### Fixed
- Tick dividers extending past bar edges
- Dropdowns not saving or applying selected textures
- Transparent gaps between picker entries
- Color picker crashes on TBC / Classic
- Alpha values behaving incorrectly (0 or max only)
- Multiple Classic/TBC-only Lua errors (upvalue limit, missing APIs)

### Compatibility
- Fully compatible with:
  - Retail
  - Classic Era
  - TBC Anniversary
  - Wrath (including Ascension-style clients)
