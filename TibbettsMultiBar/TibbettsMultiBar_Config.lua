local addonName, addon = ...

-- Thin DB/Refresh wrappers (profile-aware DB comes from main file)
local function DB()
    if addon and addon.GetDB then
        return addon.GetDB()
    end
    _G.TibbettsMultiBarDB = _G.TibbettsMultiBarDB or {}
    return _G.TibbettsMultiBarDB
end

local function Refresh()
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon and addon.UpdateReputation then addon.UpdateReputation() end
    if addon and addon.UpdateXP then addon.UpdateXP() end
end

local function EnsureDefaults()
    local db = DB()

    if db.enabled == nil then db.enabled = true end
    if db.hideBlizzard == nil then db.hideBlizzard = false end

    if db.locked == nil then db.locked = false end
    if db.clamp == nil then db.clamp = true end
    if db.pixelSnap == nil then db.pixelSnap = true end

    if db.showText == nil then db.showText = true end
    if db.showRested == nil then db.showRested = true end

    if db.width == nil then db.width = 1024 end
    if db.height == nil then db.height = 14 end
    if db.scale == nil then db.scale = 1 end

    if db.texture == nil then db.texture = "Interface\\TargetingFrame\\UI-StatusBar" end
    if db.textureName == nil then db.textureName = "UI-StatusBar" end

    if db.font == nil then db.font = "Fonts\\FRIZQT__.TTF" end
    if db.fontName == nil then db.fontName = "Friz Quadrata" end
    if db.fontSize == nil then db.fontSize = 12 end
    if db.fontOutline == nil then db.fontOutline = "" end

    if db.barColor == nil then db.barColor = { r=0.0, g=0.6, b=1.0, a=1.0 } end
    if db.repColor == nil then db.repColor = { r=0.0, g=0.8, b=0.2, a=1.0 } end
    if db.bgColor == nil then db.bgColor = { r=0.0, g=0.0, b=0.0, a=1.0 } end
    if db.bgAlpha == nil then db.bgAlpha = 0.50 end
    if db.textColor == nil then db.textColor = { r=1, g=1, b=1, a=1 } end

    if db.showBorder == nil then db.showBorder = true end

    if db.tickPreset == nil then db.tickPreset = "10" end
    if db.tickAlpha == nil then db.tickAlpha = 0.25 end
    if db.tickHover == nil then db.tickHover = false end

    if db.showRep == nil then db.showRep = true end
    if db.repAbove == nil then db.repAbove = false end
    if db.repGap == nil then db.repGap = 2 end
    if db.autoRepAtMax == nil then db.autoRepAtMax = true end

    if db.linkBars == nil then db.linkBars = true end

    if db.hideInCombat == nil then db.hideInCombat = false end
    if db.fadeAlpha == nil then db.fadeAlpha = 1.0 end
    if db.mouseoverFade == nil then db.mouseoverFade = false end
end

-- ---------------------------------------
-- UI helpers
-- ---------------------------------------
local updating = false
local UI = {}

local function MakeHeader(parent, text, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", 16, y)
    fs:SetText(text)
    return fs
end

local function MakeSubHeader(parent, text, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 16, y)
    fs:SetText(text)
    return fs
end

local function MakeCheckbox(parent, label, tooltip, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x or 16, y)
    cb.text = cb.Text or _G[cb:GetName() .. "Text"]
    if cb.text then cb.text:SetText(label) end
    if tooltip then cb.tooltipText = tooltip end
    return cb
end

local function MakeSlider(parent, label, minV, maxV, step, x, y, width)
    local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x or 16, y)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step or 1)
    s:SetObeyStepOnDrag(true)
    s:SetWidth(width or 260)
    if s.Text then s.Text:SetText(label) end
    if s.Low then s.Low:SetText(tostring(minV)) end
    if s.High then s.High:SetText(tostring(maxV)) end
    return s
end

local function MakeValueBox(parent, anchor, width)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetAutoFocus(false)
    eb:SetSize(width or 54, 20)
    eb:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
    eb:SetJustifyH("CENTER")
    eb:SetText("")
    eb:SetCursorPosition(0)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return eb
end

local function MakeButton(parent, label, w, h, x, y)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or 120, h or 22)
    b:SetPoint("TOPLEFT", x or 16, y)
    b:SetText(label)
    return b
end

local function ColorToRGBA(c)
    if type(c) ~= "table" then return 1,1,1,1 end
    return c.r or 1, c.g or 1, c.b or 1, c.a or 1
end

local function SetSwatch(tex, c)
    if not tex then return end
    local r,g,b,a = ColorToRGBA(c)
    tex:SetColorTexture(r,g,b,a or 1)
end

local function ShowColorPicker(initial, hasAlpha, changed)
    local r,g,b,a = ColorToRGBA(initial)
    ColorPickerFrame.hasOpacity = hasAlpha and true or false
    ColorPickerFrame.opacity = hasAlpha and (1 - (a or 1)) or 0
    ColorPickerFrame.previousValues = { r=r, g=g, b=b, a=a or 1 }

    ColorPickerFrame.func = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        local na = (hasAlpha and (1 - (ColorPickerFrame.opacity or 0))) or 1
        changed(nr, ng, nb, na)
    end
    ColorPickerFrame.swatchFunc = ColorPickerFrame.func
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func

    ColorPickerFrame.cancelFunc = function(prev)
        changed(prev.r, prev.g, prev.b, prev.a)
    end

    ColorPickerFrame:SetColorRGB(r,g,b)
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

local function GetTextures()
    local list = {
        ["Blizzard"] = "Interface\\TARGETINGFRAME\\UI-StatusBar",
        ["Flat"] = "Interface\\BUTTONS\\WHITE8X8",
    }
    if LibStub then
        local ok, lsm = pcall(LibStub, "LibSharedMedia-3.0", true)
        if ok and lsm and lsm.List and lsm.Fetch then
            for _, name in ipairs(lsm:List("statusbar")) do
                list[name] = lsm:Fetch("statusbar", name)
            end
        end
    end
    return list
end

local function GetFonts()
    local list = {
        ["Friz"] = "Fonts\\FRIZQT__.TTF",
        ["ArialN"] = "Fonts\\ARIALN.TTF",
        ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
        ["Skurri"] = "Fonts\\SKURRI.TTF",
    }
    if LibStub then
        local ok, lsm = pcall(LibStub, "LibSharedMedia-3.0", true)
        if ok and lsm and lsm.List and lsm.Fetch then
            for _, name in ipairs(lsm:List("font")) do
                list[name] = lsm:Fetch("font", name)
            end
        end
    end
    return list
end

local function MapToSortedItems(map)
    local names = {}
    for name in pairs(map or {}) do names[#names+1] = name end
    table.sort(names, function(a,b) return tostring(a):lower() < tostring(b):lower() end)
    local out = {}
    for i=1, #names do
        local n = names[i]
        out[i] = { name = n, path = map[n] }
    end
    return out
end

local function OpenTexturePicker(anchor, onPick)
    local up = addon and addon.UniversalPicker
    if not (up and up.Show) then return end
    up.Show(anchor, "Select Texture", "texture", MapToSortedItems(GetTextures()), function(it)
        if it and onPick then onPick(it.path, it.name) end
    end)
end

local function OpenFontPicker(anchor, onPick)
    local up = addon and addon.UniversalPicker
    if not (up and up.Show) then return end
    up.Show(anchor, "Select Font", "font", MapToSortedItems(GetFonts()), function(it)
        if it and onPick then onPick(it.path, it.name) end
    end)
end

local function OpenProfilePicker(anchor, onPick)
    if not (addon and addon.UniversalPicker and addon.UniversalPicker.Show) then return end
    if not (addon and addon.GetProfiles) then return end
    local names = addon.GetProfiles()
    local items = {}
    for i=1, #names do
        items[i] = { name = names[i], path = names[i] }
    end
    addon.UniversalPicker.Show(anchor, "Select Default Profile", "text", items, function(it)
        if it and onPick then onPick(it.name) end
    end)
end


-- ---------------------------------------
-- Panel + Tabs
-- ---------------------------------------
local panel = CreateFrame("Frame", "TibbettsMultiBarOptionsPanel", InterfaceOptionsFramePanelContainer)
panel.name = "TibbettsMultiBar"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -12)
title:SetText("TibbettsMultiBar")

local tabGeneral = MakeButton(panel, "General", 90, 22, 16, -40)
local tabProfiles = MakeButton(panel, "Profiles", 90, 22, 110, -40)

local function MakeScroll(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -70)
    scroll:SetPoint("BOTTOMRIGHT", -28, 4)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    return scroll, content
end

local scrollG, contentG = MakeScroll(panel)
local scrollP, contentP = MakeScroll(panel)
scrollP:Hide()

local function SelectTab(which)
    if which == "profiles" then
        scrollG:Hide()
        scrollP:Show()
        tabGeneral:Enable()
        tabProfiles:Disable()
    else
        scrollP:Hide()
        scrollG:Show()
        tabProfiles:Enable()
        tabGeneral:Disable()
    end
end

tabGeneral:SetScript("OnClick", function() SelectTab("general") end)
tabProfiles:SetScript("OnClick", function() SelectTab("profiles") end)

-- ---------------------------------------
-- GENERAL TAB CONTENT
-- ---------------------------------------
local y = -12
local desc = contentG:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
desc:SetPoint("TOPLEFT", 16, y)
desc:SetWidth(560)
desc:SetJustifyH("LEFT")
desc:SetText("Custom XP & Reputation bars with texture/font pickers, tick presets, and cross-client support.")
y = y - 34

MakeHeader(contentG, "General", y); y = y - 28
UI.enabled = MakeCheckbox(contentG, "Enable TibbettsMultiBar", nil, 16, y); y = y - 28
UI.hideBlizz = MakeCheckbox(contentG, "Hide Blizzard XP bar", nil, 16, y); y = y - 28
UI.locked = MakeCheckbox(contentG, "Lock bars (disable dragging)", nil, 16, y); y = y - 28
UI.showText = MakeCheckbox(contentG, "Show text (level/rep)", nil, 16, y); y = y - 28
UI.showRested = MakeCheckbox(contentG, "Show rested XP overlay", nil, 16, y); y = y - 34

MakeSubHeader(contentG, "Size", y); y = y - 22
UI.width = MakeSlider(contentG, "Width", 200, 2000, 1, 16, y, 300)
UI.widthEB = MakeValueBox(contentG, UI.width, 60)
y = y - 48

UI.height = MakeSlider(contentG, "Height", 4, 40, 1, 16, y, 300)
UI.heightEB = MakeValueBox(contentG, UI.height, 60)
y = y - 48

UI.scale = MakeSlider(contentG, "Scale", 50, 200, 1, 16, y, 300)
y = y - 54

MakeHeader(contentG, "Appearance", y); y = y - 28
UI.linkBars = MakeCheckbox(contentG, "Link XP & Rep appearance (one set of controls)", "When enabled, Reputation appearance mirrors XP settings.", 16, y); y = y - 30

UI.textureBtn = MakeButton(contentG, "Choose Texture…", 160, 22, 16, y)
UI.textureLabel = contentG:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
UI.textureLabel:SetPoint("LEFT", UI.textureBtn, "RIGHT", 10, 0)
UI.textureLabel:SetText("")
y = y - 30

UI.fontBtn = MakeButton(contentG, "Choose Font…", 160, 22, 16, y)
UI.fontLabel = contentG:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
UI.fontLabel:SetPoint("LEFT", UI.fontBtn, "RIGHT", 10, 0)
UI.fontLabel:SetText("")
y = y - 34

UI.barColorBtn = MakeButton(contentG, "Bar Color…", 120, 22, 16, y)
UI.barSwatch = contentG:CreateTexture(nil, "ARTWORK")
UI.barSwatch:SetSize(18, 18)
UI.barSwatch:SetPoint("LEFT", UI.barColorBtn, "RIGHT", 8, 0)

UI.textColorBtn = MakeButton(contentG, "Text Color…", 120, 22, 170, y)
UI.textSwatch = contentG:CreateTexture(nil, "ARTWORK")
UI.textSwatch:SetSize(18, 18)
UI.textSwatch:SetPoint("LEFT", UI.textColorBtn, "RIGHT", 8, 0)

UI.bgColorBtn = MakeButton(contentG, "Background Color…", 140, 22, 320, y)
UI.bgSwatch = contentG:CreateTexture(nil, "ARTWORK")
UI.bgSwatch:SetSize(18, 18)
UI.bgSwatch:SetPoint("LEFT", UI.bgColorBtn, "RIGHT", 8, 0)
y = y - 34

UI.bgAlpha = MakeSlider(contentG, "Background Opacity (%)", 0, 100, 1, 16, y, 300); y = y - 50
UI.showBorder = MakeCheckbox(contentG, "Show border", nil, 16, y); y = y - 34

MakeSubHeader(contentG, "Ticks", y); y = y - 22
UI.tickNone = MakeCheckbox(contentG, "No ticks", nil, 16, y)
UI.tick10 = MakeCheckbox(contentG, "Every 10%", nil, 140, y)
UI.tick20 = MakeCheckbox(contentG, "Every 20%", nil, 260, y)
y = y - 28
UI.tickHover = MakeCheckbox(contentG, "Show % on hover", nil, 16, y); y = y - 34
UI.tickAlpha = MakeSlider(contentG, "Tick Opacity (%)", 0, 100, 1, 16, y, 300); y = y - 54

MakeHeader(contentG, "Reputation", y); y = y - 28
UI.showRep = MakeCheckbox(contentG, "Show reputation bar", nil, 16, y); y = y - 28
UI.autoRepAtMax = MakeCheckbox(contentG, "Auto-hide rep at max level", nil, 16, y); y = y - 28
UI.repColorBtn = MakeButton(contentG, "Reputation Color…", 150, 22, 16, y)
UI.repSwatch = contentG:CreateTexture(nil, "ARTWORK")
UI.repSwatch:SetSize(18, 18)
UI.repSwatch:SetPoint("LEFT", UI.repColorBtn, "RIGHT", 8, 0)
y = y - 34

UI.repAbove = MakeCheckbox(contentG, "Place rep above XP bar", nil, 16, y); y = y - 44
UI.repGap = MakeSlider(contentG, "Gap (pixels)", 0, 40, 1, 16, y, 300); y = y - 58

MakeHeader(contentG, "Advanced", y); y = y - 28
UI.advToggle = MakeButton(contentG, "Show Advanced ▼", 160, 22, 16, y); y = y - 30

UI.adv = CreateFrame("Frame", nil, contentG)
UI.adv:SetPoint("TOPLEFT", 0, y)
UI.adv:SetSize(1,1)
UI.adv:Hide()

local ay = -6
UI.clamp = MakeCheckbox(UI.adv, "Clamp to screen", nil, 16, ay); ay = ay - 28
UI.pixelSnap = MakeCheckbox(UI.adv, "Pixel snap (crisp edges)", nil, 16, ay); ay = ay - 28
UI.hideInCombat = MakeCheckbox(UI.adv, "Hide bars in combat", nil, 16, ay); ay = ay - 28
UI.mouseoverFade = MakeCheckbox(UI.adv, "Fade in/out on mouseover", nil, 16, ay); ay = ay - 44
UI.fadeAlpha = MakeSlider(UI.adv, "Inactive opacity (%)", 0, 100, 1, 16, ay, 300); ay = ay - 50

contentG:SetHeight(-y + 340)

-- ---------------------------------------
-- PROFILES TAB CONTENT
-- ---------------------------------------
local py = -12
local pdesc = contentP:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
pdesc:SetPoint("TOPLEFT", 16, py)
pdesc:SetWidth(560)
pdesc:SetJustifyH("LEFT")
pdesc:SetText("Profiles let you share one setup across all characters, or use separate setups per character.")
py = py - 34

MakeHeader(contentP, "Profiles", py); py = py - 28

UI.useGlobalProfile = MakeCheckbox(contentP, "Use one profile for all characters (Default)", "When enabled, every character uses the Default profile.", 16, py); py = py - 34

UI.profileCurrent = contentP:CreateFontString(nil, "ARTWORK", "GameFontNormal")
UI.profileCurrent:SetPoint("TOPLEFT", 16, py)
UI.profileCurrent:SetText("Current profile: Default")
py = py - 26
-- Choose which profile is used when "Use one profile for all characters" is enabled
UI.globalProfileBtn = MakeButton(contentP, "Default profile…", 140, 22, 16, py)
UI.globalProfileLabel = contentP:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
UI.globalProfileLabel:SetPoint("LEFT", UI.globalProfileBtn, "RIGHT", 10, 0)
UI.globalProfileLabel:SetText("")
py = py - 30


UI.profileNameLabel = contentP:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
UI.profileNameLabel:SetPoint("TOPLEFT", 16, py)
UI.profileNameLabel:SetText("Profile name:")

UI.profileNameEB = CreateFrame("EditBox", nil, contentP, "InputBoxTemplate")
UI.profileNameEB:SetAutoFocus(false)
UI.profileNameEB:SetSize(180, 20)
UI.profileNameEB:SetPoint("LEFT", UI.profileNameLabel, "RIGHT", 8, 0)
UI.profileNameEB:SetJustifyH("LEFT")
UI.profileNameEB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
py = py - 30

UI.profileSwitch = MakeButton(contentP, "Switch", 90, 22, 16, py)
UI.profileCopy = MakeButton(contentP, "Copy to New", 110, 22, 112, py)
UI.profileDelete = MakeButton(contentP, "Delete", 90, 22, 234, py)
py = py - 40

local pnote = contentP:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
pnote:SetPoint("TOPLEFT", 16, py)
pnote:SetWidth(560)
pnote:SetJustifyH("LEFT")
pnote:SetText("Tip: Keep 'Use one profile for all characters' enabled to share settings account-wide. Disable it if you want per-character profiles.")
py = py - 40

contentP:SetHeight(-py + 200)

-- ---------------------------------------
-- Logic
-- ---------------------------------------
local function SetTickPreset(preset)
    local db = DB()
    db.tickPreset = preset
    UI.tickNone:SetChecked(preset == "none")
    UI.tick10:SetChecked(preset == "10")
    UI.tick20:SetChecked(preset == "20")
end

local function GetTypedProfile()
    if not UI.profileNameEB then return "Default" end
    local n = tostring(UI.profileNameEB:GetText() or ""):gsub("^%s+",""):gsub("%s+$","")
    if n == "" then n = "Default" end
    return n
end

local function RefreshUI()
    EnsureDefaults()
    updating = true

    local db = DB()

    -- Profiles
    if UI.useGlobalProfile then
        local sv = _G.TibbettsMultiBarDB
        local useGlobal = (sv and sv.useGlobalProfile ~= false) or false
        UI.useGlobalProfile:SetChecked(useGlobal)

        local pname = (addon and addon.GetProfileName and addon.GetProfileName()) or "Default"
        if UI.profileCurrent then UI.profileCurrent:SetText("Current profile: " .. pname) end
        if UI.globalProfileLabel and addon and addon.GetGlobalProfileName then
            UI.globalProfileLabel:SetText(addon.GetGlobalProfileName())
        elseif UI.globalProfileLabel then
            UI.globalProfileLabel:SetText("Default")
        end
        if UI.profileNameEB then UI.profileNameEB:SetText(pname) end

        if useGlobal then
            if UI.globalProfileBtn then UI.globalProfileBtn:Enable() end
            UI.profileNameEB:Disable()
            UI.profileSwitch:Disable()
            UI.profileCopy:Disable()
            UI.profileDelete:Disable()
        else
            if UI.globalProfileBtn then UI.globalProfileBtn:Disable() end
            UI.profileNameEB:Enable()
            UI.profileSwitch:Enable()
            UI.profileCopy:Enable()
            UI.profileDelete:Enable()
        end
    end

    -- General
    UI.enabled:SetChecked(db.enabled ~= false)
    UI.hideBlizz:SetChecked(db.hideBlizzard and true or false)
    UI.locked:SetChecked(db.locked and true or false)
    UI.showText:SetChecked(db.showText and true or false)
    UI.showRested:SetChecked(db.showRested and true or false)

    UI.width:SetValue(tonumber(db.width) or 1024)
    if UI.widthEB then UI.widthEB:SetText(tostring(tonumber(db.width) or 1024)) end

    UI.height:SetValue(tonumber(db.height) or 14)
    if UI.heightEB then UI.heightEB:SetText(tostring(tonumber(db.height) or 14)) end

    UI.scale:SetValue((tonumber(db.scale) or 1) * 100)

    UI.linkBars:SetChecked(db.linkBars ~= false)

    UI.textureLabel:SetText(db.textureName or "")
    UI.fontLabel:SetText(db.fontName or "")

    SetSwatch(UI.barSwatch, db.barColor)
    SetSwatch(UI.textSwatch, db.textColor)
    SetSwatch(UI.bgSwatch, db.bgColor)
    if UI.repSwatch then SetSwatch(UI.repSwatch, db.repColor) end

    UI.bgAlpha:SetValue((tonumber(db.bgAlpha) or 0.5) * 100)
    UI.showBorder:SetChecked(db.showBorder and true or false)

    SetTickPreset(db.tickPreset or "10")
    UI.tickHover:SetChecked(db.tickHover and true or false)
    UI.tickAlpha:SetValue((tonumber(db.tickAlpha) or 0.25) * 100)

    UI.showRep:SetChecked(db.showRep ~= false)
    UI.autoRepAtMax:SetChecked(db.autoRepAtMax ~= false)
    UI.repAbove:SetChecked(db.repAbove and true or false)
    if UI.repColorBtn then
        local linked = (db.linkBars ~= false)
        UI.repColorBtn:SetShown(not linked)
        if UI.repSwatch then UI.repSwatch:SetShown(not linked) end
    end
    UI.repGap:SetValue(tonumber(db.repGap) or 2)

    UI.clamp:SetChecked(db.clamp ~= false)
    UI.pixelSnap:SetChecked(db.pixelSnap ~= false)
    UI.hideInCombat:SetChecked(db.hideInCombat and true or false)
    UI.mouseoverFade:SetChecked(db.mouseoverFade and true or false)
    UI.fadeAlpha:SetValue((tonumber(db.fadeAlpha) or 1) * 100)

    updating = false
end

-- ---------------------------------------
-- Wiring (General tab)
-- ---------------------------------------
UI.enabled:SetScript("OnClick", function(self)
    if updating then return end
    DB().enabled = self:GetChecked() and true or false
    Refresh()
end)

UI.hideBlizz:SetScript("OnClick", function(self)
    if updating then return end
    DB().hideBlizzard = self:GetChecked() and true or false
    Refresh()
end)

UI.locked:SetScript("OnClick", function(self)
    if updating then return end
    DB().locked = self:GetChecked() and true or false
    Refresh()
end)

UI.showText:SetScript("OnClick", function(self)
    if updating then return end
    DB().showText = self:GetChecked() and true or false
    Refresh()
end)

UI.showRested:SetScript("OnClick", function(self)
    if updating then return end
    DB().showRested = self:GetChecked() and true or false
    Refresh()
end)

UI.width:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    v = math.floor(v + 0.5)
    if UI.widthEB then UI.widthEB:SetText(tostring(v)) end
    DB().width = v
    Refresh()
end)

UI.height:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    v = math.floor(v + 0.5)
    if UI.heightEB then UI.heightEB:SetText(tostring(v)) end
    DB().height = v
    Refresh()
end)

if UI.widthEB then
    UI.widthEB:SetScript("OnEnterPressed", function(self)
        local v = tonumber(self:GetText() or "")
        if not v then self:ClearFocus() return end
        if v < 200 then v = 200 elseif v > 2000 then v = 2000 end
        updating = true
        UI.width:SetValue(v)
        updating = false
        DB().width = math.floor(v + 0.5)
        self:ClearFocus()
        Refresh()
    end)
end

if UI.heightEB then
    UI.heightEB:SetScript("OnEnterPressed", function(self)
        local v = tonumber(self:GetText() or "")
        if not v then self:ClearFocus() return end
        if v < 4 then v = 4 elseif v > 40 then v = 40 end
        updating = true
        UI.height:SetValue(v)
        updating = false
        DB().height = math.floor(v + 0.5)
        self:ClearFocus()
        Refresh()
    end)
end

UI.scale:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().scale = (tonumber(v) or 100) / 100
    Refresh()
end)

UI.linkBars:SetScript("OnClick", function(self)
    if updating then return end
    DB().linkBars = self:GetChecked() and true or false
    if DB().linkBars then DB().repColor = nil end
    RefreshUI()
    Refresh()
end)

UI.textureBtn:SetScript("OnClick", function()
    OpenTexturePicker(UI.textureBtn, function(texPath, texName)
        local db = DB()
        db.texture = texPath
        db.textureName = texName or texPath
        RefreshUI()
        Refresh()
    end)
end)

UI.fontBtn:SetScript("OnClick", function()
    OpenFontPicker(UI.fontBtn, function(fontPath, fontName)
        local db = DB()
        db.font = fontPath
        db.fontName = fontName or fontPath
        RefreshUI()
        Refresh()
    end)
end)

UI.barColorBtn:SetScript("OnClick", function()
    local db = DB()
    ShowColorPicker(db.barColor, true, function(r,g,b,a)
        db.barColor = { r=r,g=g,b=b,a=a }
        SetSwatch(UI.barSwatch, db.barColor)
        Refresh()
    end)
end)

UI.textColorBtn:SetScript("OnClick", function()
    local db = DB()
    ShowColorPicker(db.textColor, true, function(r,g,b,a)
        db.textColor = { r=r,g=g,b=b,a=a }
        SetSwatch(UI.textSwatch, db.textColor)
        Refresh()
    end)
end)

UI.bgColorBtn:SetScript("OnClick", function()
    local db = DB()
    ShowColorPicker(db.bgColor, true, function(r,g,b,a)
        db.bgColor = { r=r,g=g,b=b,a=a }
        SetSwatch(UI.bgSwatch, db.bgColor)
        Refresh()
    end)
end)

UI.repColorBtn:SetScript("OnClick", function()
    local db = DB()
    ShowColorPicker(db.repColor, true, function(r,g,b,a)
        db.repColor = { r=r,g=g,b=b,a=a }
        SetSwatch(UI.repSwatch, db.repColor)
        Refresh()
    end)
end)

UI.bgAlpha:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().bgAlpha = (tonumber(v) or 50) / 100
    Refresh()
end)

UI.showBorder:SetScript("OnClick", function(self)
    if updating then return end
    DB().showBorder = self:GetChecked() and true or false
    Refresh()
end)

UI.tickNone:SetScript("OnClick", function(self)
    if updating then return end
    SetTickPreset("none")
    Refresh()
end)
UI.tick10:SetScript("OnClick", function(self)
    if updating then return end
    SetTickPreset("10")
    Refresh()
end)
UI.tick20:SetScript("OnClick", function(self)
    if updating then return end
    SetTickPreset("20")
    Refresh()
end)

UI.tickHover:SetScript("OnClick", function(self)
    if updating then return end
    DB().tickHover = self:GetChecked() and true or false
    Refresh()
end)

UI.tickAlpha:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().tickAlpha = (tonumber(v) or 25) / 100
    Refresh()
end)

UI.showRep:SetScript("OnClick", function(self)
    if updating then return end
    DB().showRep = self:GetChecked() and true or false
    Refresh()
end)

UI.autoRepAtMax:SetScript("OnClick", function(self)
    if updating then return end
    DB().autoRepAtMax = self:GetChecked() and true or false
    Refresh()
end)

UI.repAbove:SetScript("OnClick", function(self)
    if updating then return end
    DB().repAbove = self:GetChecked() and true or false
    Refresh()
end)

UI.repGap:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().repGap = math.floor(v + 0.5)
    Refresh()
end)

UI.clamp:SetScript("OnClick", function(self)
    if updating then return end
    DB().clamp = self:GetChecked() and true or false
    Refresh()
end)

UI.pixelSnap:SetScript("OnClick", function(self)
    if updating then return end
    DB().pixelSnap = self:GetChecked() and true or false
    Refresh()
end)

UI.hideInCombat:SetScript("OnClick", function(self)
    if updating then return end
    DB().hideInCombat = self:GetChecked() and true or false
    Refresh()
end)

UI.mouseoverFade:SetScript("OnClick", function(self)
    if updating then return end
    DB().mouseoverFade = self:GetChecked() and true or false
    Refresh()
end)

UI.fadeAlpha:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().fadeAlpha = (tonumber(v) or 100) / 100
    Refresh()
end)

UI.advToggle:SetScript("OnClick", function()
    if UI.adv:IsShown() then
        UI.adv:Hide()
        UI.advToggle:SetText("Show Advanced ▼")
    else
        UI.adv:Show()
        UI.advToggle:SetText("Hide Advanced ▲")
    end
end)

-- ---------------------------------------
-- Wiring (Profiles tab)
-- ---------------------------------------
UI.useGlobalProfile:SetScript("OnClick", function(self)
    if updating then return end
    if addon and addon.SetUseGlobalProfile then
        addon.SetUseGlobalProfile(self:GetChecked() and true or false)
    else
        _G.TibbettsMultiBarDB = _G.TibbettsMultiBarDB or {}
        _G.TibbettsMultiBarDB.useGlobalProfile = self:GetChecked() and true or false
    end
    RefreshUI()
    Refresh()
end)


UI.globalProfileBtn:SetScript("OnClick", function()
    if updating then return end
    if not (addon and addon.SetGlobalProfileName) then return end
    OpenProfilePicker(UI.globalProfileBtn, function(name)
        addon.SetGlobalProfileName(name)
        RefreshUI()
        Refresh()
    end)
end)

UI.profileSwitch:SetScript("OnClick", function()
    if updating then return end
    if addon and addon.SetProfile then
        addon.SetProfile(GetTypedProfile())
    end
    RefreshUI()
    Refresh()
end)

UI.profileCopy:SetScript("OnClick", function()
    if updating then return end
    if addon and addon.CopyProfile and addon.GetProfileName then
        local from = addon.GetProfileName()
        local to = GetTypedProfile()
        if to and to ~= "" then
            addon.CopyProfile(from, to)
            addon.SetProfile(to)
        end
    end
    RefreshUI()
    Refresh()
end)

UI.profileDelete:SetScript("OnClick", function()
    if updating then return end
    if addon and addon.DeleteProfile then
        addon.DeleteProfile(GetTypedProfile())
        if addon.SetProfile then addon.SetProfile("Default") end
    end
    RefreshUI()
    Refresh()
end)

-- ---------------------------------------
-- Register panel + slash
-- ---------------------------------------
panel.refresh = RefreshUI

if _G.Settings and _G.Settings.RegisterCanvasLayoutCategory then
    local cat = _G.Settings.RegisterCanvasLayoutCategory(panel, panel.name or "TibbettsMultiBar")
    if cat and _G.Settings.RegisterAddOnCategory then
        _G.Settings.RegisterAddOnCategory(cat)
    end
elseif _G.InterfaceOptions_AddCategory then
    _G.InterfaceOptions_AddCategory(panel)
end

SLASH_TIBBETTSMULTIBAR1 = "/tmb"
SlashCmdList.TIBBETTSMULTIBAR = function()
    SelectTab("general")
    RefreshUI()
    if _G.Settings and _G.Settings.OpenToCategory then
        _G.Settings.OpenToCategory(panel.name or "TibbettsMultiBar")
    elseif _G.InterfaceOptionsFrame_OpenToCategory then
        _G.InterfaceOptionsFrame_OpenToCategory(panel)
        _G.InterfaceOptionsFrame_OpenToCategory(panel)
    end
end

-- default tab
SelectTab("general")
