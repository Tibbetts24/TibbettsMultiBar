
local addonName, addon = ...


local function DB()
    if addon and addon.GetDB then
        return addon.GetDB()
    end
    _G.TibbettsMultiBarDB = _G.TibbettsMultiBarDB or {}
    return _G.TibbettsMultiBarDB
end

local function Refresh()
    if addon and addon.ApplySettings then if addon and addon.ApplySettings then addon.ApplySettings() end end
    if addon and addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
end

-- Cross-client safe color setter (writes into current profile DB())
local function SetColorTable(key, r, g, b, keepAlpha)
    local db = DB()
    db[key] = db[key] or {}
    local t = db[key]
    t.r = tonumber(r) or 0
    t.g = tonumber(g) or 0
    t.b = tonumber(b) or 0
    if keepAlpha then
        t.a = tonumber(t.a) or 1
    else
        if t.a == nil then t.a = 1 end
    end
    Refresh()
end

-- Solid color helper (cross-client safe: avoids Texture:SetColorTexture signature differences)
local function SetSolidColor(tex, r, g, b, a)
    if not tex then return end
    tex:SetTexture('Interface\\Buttons\\WHITE8X8')
    if tex.SetVertexColor then
        a = tonumber(a) or 1
        if a < 0 then a = 0 elseif a > 1 then a = 1 end
        tex:SetVertexColor(tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0, a)
    end
end

local panel = CreateFrame("Frame", "TibbettsMultiBarOptionsPanel", UIParent)
panel.name = "Tibbetts' MultiBar"
-------------------------------------------------
-- Tabs
-------------------------------------------------
local tabs = {}
local frames = {}

local function CreateTab(id, text)
    local tab = CreateFrame("Button", "TibbettsMultiBarTab"..id, panel, "OptionsFrameTabButtonTemplate")
    tab:SetID(id)
    tab:SetText(text)
    PanelTemplates_TabResize(tab, 0)
    return tab
end

local function ShowTab(id)
    for i = 1, #frames do
        frames[i]:Hide()
        PanelTemplates_DeselectTab(tabs[i])
    end
    frames[id]:Show()
    PanelTemplates_SelectTab(tabs[id])
    local db = DB(); db.lastTab = id
    if RefreshUI then RefreshUI() end
end

tabs[1] = CreateTab(1, "General")
tabs[2] = CreateTab(2, "Appearance")
tabs[3] = CreateTab(3, "Size & Position")
tabs[4] = CreateTab(4, "Reputation")
tabs[5] = CreateTab(5, "Advanced")
tabs[6] = CreateTab(6, "Profiles")

tabs[1]:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -12)
for i = 2, 6 do
    tabs[i]:SetPoint("LEFT", tabs[i-1], "RIGHT", -10, 0)
end

for i = 1, 6 do
    local f = CreateFrame("Frame", nil, panel)
    f:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -48)
    f:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    f:Hide()
    frames[i] = f
end

frames[1]:Show()
PanelTemplates_SelectTab(tabs[1])

for i = 1, 6 do
    tabs[i]:SetScript("OnClick", function(self) ShowTab(self:GetID()) end)
end

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function MakeCheckbox(parent, label, tooltip, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.Text:SetText(label)
    cb.tooltipText = tooltip
    return cb
end

local function MakeSlider(parent, label, minv, maxv, step, x, y)
    local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y)
    s:SetMinMaxValues(minv, maxv)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s.Text:SetText(label)
    s.Low:SetText(tostring(minv))
    s.High:SetText(tostring(maxv))
    return s
end

local function MakeEditBox(parent, w, h)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetAutoFocus(false)
    h = h or 20
    eb:SetSize(w, h)
    eb:SetJustifyH("CENTER")
    return eb
end

local function MakeButton(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetText(text)
    return b
end

local function MakeSwatch(parent, anchor)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetSize(18, 18)
    t:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
    return t
end

local function Clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

-------------------------------------------------
-- Color picker helper
-------------------------------------------------
-- Show the Blizzard color picker.
-- getRGB() -> r,g,b; setRGB(r,g,b) writes RGB
-- Optional alpha support: getA() -> a (0..1); setA(a)
-- Note: Blizzard's picker historically uses "opacity" meaning transparency, so we map:
--   opacity = 1 - alpha
local function ShowColorPicker(getRGB, setRGB, getA, setA)
    local r, g, b = getRGB()
    local a = getA and Clamp01(tonumber(getA()) or 1) or 1
    local prev = { r = r, g = g, b = b, a = a }

    local function applyRGB()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        setRGB(nr, ng, nb)
    end

    local function applyA(opacity)
        if not setA then return end
        -- opacity is transparency in many clients
        local oa = opacity
        if oa == nil and _G.OpacitySliderFrame and _G.OpacitySliderFrame.GetValue then
            oa = _G.OpacitySliderFrame:GetValue()
        end
        setA(Clamp01(1 - (tonumber(oa) or 0)))
    end

    if ColorPickerFrame and type(ColorPickerFrame.SetupColorPickerAndShow) == "function" then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            hasOpacity = (setA ~= nil),
            opacity = (setA ~= nil) and (1 - a) or nil,
            swatchFunc = function() applyRGB() end,
            opacityFunc = function(opacity) applyA(opacity) end,
            cancelFunc = function()
                setRGB(prev.r, prev.g, prev.b)
                if setA then setA(prev.a) end
            end,
        })
        return
    end

    -- Legacy picker API
    ColorPickerFrame.func = function() applyRGB() end
    ColorPickerFrame.cancelFunc = function()
        setRGB(prev.r, prev.g, prev.b)
        if setA then setA(prev.a) end
    end

    if setA then
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacityFunc = function() applyA(nil) end
        if _G.OpacitySliderFrame and _G.OpacitySliderFrame.SetValue then
            _G.OpacitySliderFrame:SetValue(1 - a)
        end
    else
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.opacityFunc = nil
    end

    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Show()
end

-------------------------------------------------
-- TAB 1: GENERAL
-------------------------------------------------
local g = frames[1]
local title1 = g:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title1:SetPoint("TOPLEFT", 16, -16)
title1:SetText("General")

local enable = MakeCheckbox(g, "Enable XP Bar", nil, 16, -46)
local hideBlizz = MakeCheckbox(g, "Hide Blizzard XP Bar", nil, 16, -76)
local lock = MakeCheckbox(g, "Lock Bar", "Prevents dragging the bar.", 16, -106)
local clamp = MakeCheckbox(g, "Clamp to Screen", "Stops the bar from being dragged off-screen.", 16, -136)

local showText = MakeCheckbox(g, "Show Text", nil, 16, -176)
local showRested = MakeCheckbox(g, "Show Rested Overlay", nil, 16, -206)

-------------------------------------------------
-- TAB 2: APPEARANCE
-------------------------------------------------
local a = frames[2]
-- ScrollFrame for Appearance (restores scrolling on all clients)
local aScroll = CreateFrame("ScrollFrame", "TibbettsMultiBarAppearanceScroll", a, "UIPanelScrollFrameTemplate")
aScroll:SetPoint("TOPLEFT", a, "TOPLEFT", 0, -8)
aScroll:SetPoint("BOTTOMRIGHT", a, "BOTTOMRIGHT", -30, 8)
local aChild = CreateFrame("Frame", nil, aScroll)
aChild:SetPoint("TOPLEFT", 0, 0)
aChild:SetSize(1, 900) -- allow scrolling; height is adjusted by layout
aScroll:SetScrollChild(aChild)
-- From here down, build Appearance UI on the scroll child
a = aChild

local title2 = a:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title2:SetPoint("TOPLEFT", 16, -16)
title2:SetText("Appearance")

-- Dropdowns
local XPMB_DD_COUNTER = 0
local function MakeDropdown(parent, width, x, y)
    XPMB_DD_COUNTER = XPMB_DD_COUNTER + 1
    local dd = CreateFrame("Frame", "TibbettsMultiBarDropDown"..XPMB_DD_COUNTER, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dd, width)
    return dd
end

local texLabel = a:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
texLabel:SetPoint("TOPLEFT", 16, -46)
texLabel:SetText("Texture")
local texDD = MakeDropdown(a, 180, 80, -58)

-- Texture filter (outside picker)
local texFilterLabel = a:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
texFilterLabel:SetPoint("TOPLEFT", 16, -36)
texFilterLabel:SetText("Filter")
local texFilterEB = MakeEditBox(a, 160, 20)
texFilterEB:ClearAllPoints()
texFilterEB:SetPoint("TOPLEFT", a, "TOPLEFT", 80, -34)
texFilterEB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
if texFilterEB.HookScript then
    texFilterEB:HookScript("OnTextChanged", function(self)
        local f = (UniversalPicker and UniversalPicker.GetFrame and UniversalPicker.GetFrame())
        if f and f:IsShown() and f.externalEdit == self then
            f:RebuildFilter()
        end
    end)
end


local fontLabel = a:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
fontLabel:SetPoint("TOPLEFT", 320, -46)
fontLabel:SetText("Font")
local fontDD = MakeDropdown(a, 180, 370, -58)

-- Font filter (outside picker)
local fontFilterLabel = a:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
fontFilterLabel:SetPoint("TOPLEFT", 320, -36)
fontFilterLabel:SetText("Filter")
local fontFilterEB = MakeEditBox(a, 160, 20)
fontFilterEB:ClearAllPoints()
fontFilterEB:SetPoint("TOPLEFT", a, "TOPLEFT", 370, -34)
fontFilterEB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
if fontFilterEB.HookScript then
    fontFilterEB:HookScript("OnTextChanged", function(self)
        local f = (UniversalPicker and UniversalPicker.GetFrame and UniversalPicker.GetFrame())
        if f and f:IsShown() and f.externalEdit == self then
            f:RebuildFilter()
        end
    end)
end


-- Font size
local fontSize = MakeSlider(a, "Font Size", 8, 24, 1, 320, -110)
local fontSizeEB = MakeEditBox(a, 60, 20)
fontSizeEB:SetPoint("LEFT", fontSize, "RIGHT", 12, 0)

-- Preview sample
local previewLabel = a:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
previewLabel:SetPoint("TOPLEFT", 320, -150)
previewLabel:SetText("Preview")
local previewSample = a:CreateFontString(nil, "ARTWORK", "GameFontNormal")
previewSample:SetPoint("TOPLEFT", 320, -164)
previewSample:SetText("12345 XP  (45%)")

-- Text
local textShadow = MakeCheckbox(a, "Text Shadow", nil, 16, -114)
local textColorBtn = MakeButton(a, "Text Color...", 160, 22)
textColorBtn:SetPoint("TOPLEFT", 16, -144)
local textColorSwatch = MakeSwatch(a, textColorBtn)

-- Bar / Background / Rested
local barColorBtn = MakeButton(a, "Bar Color...", 160, 22)
barColorBtn:SetPoint("TOPLEFT", 16, -184)
local barColorSwatch = MakeSwatch(a, barColorBtn)

local bgColorBtn = MakeButton(a, "Background Color...", 160, 22)
bgColorBtn:SetPoint("TOPLEFT", barColorBtn, "BOTTOMLEFT", 0, -8)
local bgColorSwatch = MakeSwatch(a, bgColorBtn)

local restedColorBtn = MakeButton(a, "Rested Color...", 160, 22)
restedColorBtn:SetPoint("TOPLEFT", bgColorBtn, "BOTTOMLEFT", 0, -8)
local restedColorSwatch = MakeSwatch(a, restedColorBtn)

local bgAlpha = MakeSlider(a, "Background Alpha (x100)", 0, 100, 5, 320, -214)
-- Alpha is handled in the Background Color picker (like Blizzard). Hide this legacy slider.
bgAlpha:Hide()
local resetColors = MakeButton(a, "Reset Colors", 160, 22)
resetColors:SetPoint("TOPLEFT", 320, -234)

-- -------------------------------------------------
-- Reputation appearance (separate from XP)
-- -------------------------------------------------
local repAppHeader = a:CreateFontString(nil, "ARTWORK", "GameFontNormal")
repAppHeader:SetPoint("TOPLEFT", 16, -274)
repAppHeader:SetText("Reputation Appearance")

local repColorBtn = MakeButton(a, "Reputation Bar Color...", 180, 22)
repColorBtn:SetPoint("TOPLEFT", 16, -304)
local repColorSwatch = MakeSwatch(a, repColorBtn)

local repTextColorBtn = MakeButton(a, "Reputation Text Color...", 180, 22)
repTextColorBtn:SetPoint("TOPLEFT", 16, -342)
local repTextColorSwatch = MakeSwatch(a, repTextColorBtn)

local repBgColorBtn = MakeButton(a, "Reputation Background Color...", 200, 22)
repBgColorBtn:SetPoint("TOPLEFT", 320, -304)
local repBgColorSwatch = MakeSwatch(a, repBgColorBtn)

local repBgAlpha = MakeSlider(a, "Rep Background Alpha (x100)", 0, 100, 5, 320, -342)
local repBgAlphaEB = MakeEditBox(a, 60, 20)
repBgAlphaEB:SetPoint("LEFT", repBgAlpha, "RIGHT", 12, 0)

-- Alpha is handled in the Reputation Background Color picker (like Blizzard). Hide legacy controls.
repBgAlpha:Hide()
repBgAlphaEB:Hide()

local repTexLabel = a:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
repTexLabel:SetPoint("TOPLEFT", 16, -392)
repTexLabel:SetText("Rep Texture")
local repTexDD = MakeDropdown(a, 180, 120, -404)

local repFontLabel = a:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
repFontLabel:SetPoint("TOPLEFT", 320, -392)
repFontLabel:SetText("Rep Font")
local repFontDD = MakeDropdown(a, 180, 390, -404)

local repFontSize = MakeSlider(a, "Rep Font Size", 8, 24, 1, 16, -450)
local repFontSizeEB = MakeEditBox(a, 60, 20)
repFontSizeEB:SetPoint("LEFT", repFontSize, "RIGHT", 12, 0)

local repBorder = MakeCheckbox(a, "Rep: Show border (1px)", nil, 320, -450)
local repTicks = MakeCheckbox(a, "Rep: Show tick marks", nil, 320, -480)
local repTickCount = MakeSlider(a, "Rep tick count", 1, 40, 1, 16, -510)
local repTickAlpha = MakeSlider(a, "Rep tick alpha (x100)", 0, 100, 5, 320, -510)

local repCopyFromXP = MakeButton(a, "Copy XP appearance → Rep", 200, 22)
repCopyFromXP:SetPoint("TOPLEFT", 16, -560)


-------------------------------------------------
-- TAB 3: SIZE & POSITION
-------------------------------------------------
local sp = frames[3]
local title3 = sp:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title3:SetPoint("TOPLEFT", 16, -16)
title3:SetText("Size & Position")

local width = MakeSlider(sp, "Width", 200, 2000, 10, 16, -46)
local widthEB = MakeEditBox(sp, 60, 20)
widthEB:SetPoint("LEFT", width, "RIGHT", 12, 0)

local height = MakeSlider(sp, "Height", 4, 64, 1, 16, -96)
local heightEB = MakeEditBox(sp, 60, 20)
heightEB:SetPoint("LEFT", height, "RIGHT", 12, 0)

local scale = MakeSlider(sp, "Scale (x100)", 50, 200, 5, 16, -146)

local posHint = sp:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
posHint:SetPoint("TOPLEFT", 16, -200)
posHint:SetText("Drag the bar to position it (unlock first).")

local posText = sp:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
posText:SetPoint("TOPLEFT", 16, -225)
posText:SetText("X: 0   Y: 0")

local resetPos = MakeButton(sp, "Reset Position (Center)", 200, 22)
resetPos:SetPoint("TOPLEFT", 16, -260)

-------------------------------------------------
-------------------------------------------------
-- TAB 4: REPUTATION
-------------------------------------------------
local r = frames[4]
local titleR = r:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
titleR:SetPoint("TOPLEFT", 16, -16)
titleR:SetText("Reputation")

local repEnable = MakeCheckbox(r, "Show Reputation Bar", "Shows a second bar using your watched faction.", 16, -46)
local repAuto = MakeCheckbox(r, "At max level, show rep bar only", "Hides the XP bar when you are at max level.", 16, -76)
local repSnap = MakeCheckbox(r, "Snap rep bar to XP bar", "If disabled, the rep bar becomes its own draggable bar.", 16, -106)
local repAbove = MakeCheckbox(r, "Place rep bar above XP bar", "Stacks rep above XP when snapped.", 36, -136)
local repGap = MakeSlider(r, "Gap", 0, 20, 1, 320, -106)

local repInfo = r:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
repInfo:SetPoint("TOPLEFT", 16, -168)
repInfo:SetJustifyH("LEFT")
repInfo:SetWidth(560)
repInfo:SetText("Tip: Set a faction as Watched in the Reputation pane to populate the bar. If snapping is disabled, drag the rep bar with Left Mouse when unlocked.")


-- (Rep appearance controls moved to Appearance tab to avoid crowding)

local repSizeHeader = r:CreateFontString(nil, "ARTWORK", "GameFontNormal")
repSizeHeader:SetPoint("TOPLEFT", 16, -212)
repSizeHeader:SetText("Reputation Size & Position")

local repWidth = MakeSlider(r, "Width", 200, 2000, 10, 16, -236)
local repWidthEB = MakeEditBox(r, 60, 20)
repWidthEB:SetPoint("LEFT", repWidth, "RIGHT", 12, 0)

local repHeight = MakeSlider(r, "Height", 4, 64, 1, 16, -286)
local repHeightEB = MakeEditBox(r, 60, 20)
repHeightEB:SetPoint("LEFT", repHeight, "RIGHT", 12, 0)

local repScale = MakeSlider(r, "Scale (x100)", 50, 200, 5, 16, -336)
local repScaleEB = MakeEditBox(r, 60, 20)
repScaleEB:SetPoint("LEFT", repScale, "RIGHT", 12, 0)

local repLock = MakeCheckbox(r, "Lock Reputation Bar", "Prevents dragging the reputation bar.", 16, -386)

local repResetPos = MakeButton(r, "Reset Rep Position (Center)", 200, 22)
repResetPos:SetPoint("TOPLEFT", 16, -420)


-- TAB 5: ADVANCED
-------------------------------------------------
local adv = frames[5]
local title4 = adv:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title4:SetPoint("TOPLEFT", 16, -16)
title4:SetText("Advanced")

local mouseFade = MakeCheckbox(adv, "Mouseover Fade", "Fades the bar until you mouse over it.", 16, -46)
local fadeAlpha = MakeSlider(adv, "Fade Alpha (x100)", 0, 100, 5, 16, -96)

local hideCombat = MakeCheckbox(adv, "Hide in Combat", "Hides the bar while in combat.", 16, -156)
local pixelSnap = MakeCheckbox(adv, "Pixel Snap", "Rounds saved position to whole pixels for stability.", 16, -186)

local resetAll = MakeButton(adv, "Reset All Settings", 200, 22)
resetAll:SetPoint("TOPLEFT", 16, -226)

-------------------------------------------------
-- Dropdown contents (basic + LSM if present)
-------------------------------------------------
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

-- Border / Tick dividers
local border = CreateFrame("CheckButton", nil, adv, "InterfaceOptionsCheckButtonTemplate")
border.Text:SetText("Show 1px Border")
border:SetPoint("TOPLEFT", 16, -256)
border:SetChecked(DB().showBorder and true or false)
border:SetScript("OnClick", function(self)
    DB().showBorder = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

-- Tick dividers (preset options)
local tickNone = CreateFrame("CheckButton", nil, adv, "InterfaceOptionsCheckButtonTemplate")
tickNone.Text:SetText("Ticks: None")
tickNone:SetPoint("TOPLEFT", 16, -288)

local tick10 = CreateFrame("CheckButton", nil, adv, "InterfaceOptionsCheckButtonTemplate")
tick10.Text:SetText("Ticks: Every 10%")
tick10:SetPoint("TOPLEFT", 16, -312)

local tick20 = CreateFrame("CheckButton", nil, adv, "InterfaceOptionsCheckButtonTemplate")
tick20.Text:SetText("Ticks: Every 20%")
tick20:SetPoint("TOPLEFT", 16, -336)

-- Optional: show percentage on hover over tick dividers
local tickHover = CreateFrame("CheckButton", nil, adv, "InterfaceOptionsCheckButtonTemplate")
tickHover.Text:SetText("Show tick % on hover")
tickHover:SetPoint("TOPLEFT", 16, -360)
tickHover:SetChecked(DB().tickHoverNumbers and true or false)
tickHover:SetScript("OnClick", function(self)
    DB().tickHoverNumbers = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon and addon.UpdateReputation then addon.UpdateReputation() end
    Refresh()
end)


local function SetTickPreset(preset)
    -- preset: "none" | "10" | "20"
    local db = DB()

    -- Store for cross-client consistency (ApplySettings can derive showTicks/tickCount from this)
    db.tickPreset = preset

    if preset == "none" then
        db.showTicks = false
    else
        db.showTicks = true
        if preset == "10" then
            db.tickCount = 10
        else
            db.tickCount = 5
        end
        -- Keep a sane default if slider UI removed
        if db.tickAlpha == nil then db.tickAlpha = 0.25 end
    end

    -- Keep reputation ticks in sync by default (rep UI can still override via Copy button/controls)
    db.repShowTicks = db.showTicks
    db.repTickCount = db.tickCount
    if db.repTickAlpha == nil then db.repTickAlpha = db.tickAlpha end

    tickNone:SetChecked(preset == "none")
    tick10:SetChecked(preset == "10")
    tick20:SetChecked(preset == "20")

    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon and addon.UpdateReputation then addon.UpdateReputation() end
    Refresh()
end

-- Initialize preset from DB
do
    local db = DB()
    local preset = "none"
    if db.showTicks then
        local tc = tonumber(db.tickCount) or 10
        if tc <= 6 then
            preset = "20"
            db.tickCount = 5
        else
            preset = "10"
            db.tickCount = 10
        end
    end
    SetTickPreset(preset)
end

tickNone:SetScript("OnClick", function() SetTickPreset("none") end)
tick10:SetScript("OnClick", function() SetTickPreset("10") end)
tick20:SetScript("OnClick", function() SetTickPreset("20") end)



local texMap, fontMap

-------------------------------------------------
-- Universal searchable picker moved to TibbettsMultiBar_Picker.lua
-------------------------------------------------
local UniversalPicker = addon and addon.UniversalPicker
local function AttachPickerToDropDown(...)
    if UniversalPicker and UniversalPicker.AttachToDropDown then
        return UniversalPicker.AttachToDropDown(...)
    end
end

local function SetDropdownValue(dd, displayName)
    if UIDropDownMenu_SetSelectedName then UIDropDownMenu_SetSelectedName(dd, displayName) end
    if UIDropDownMenu_SetSelectedValue then UIDropDownMenu_SetSelectedValue(dd, displayName) end
    UIDropDownMenu_SetText(dd, displayName)
end

local function InitTextureDD()
    texMap = GetTextures()
    UIDropDownMenu_Initialize(texDD, function(self, level)
        local names = {}
        for n in pairs(texMap) do
            names[#names+1] = n
        end
        table.sort(names, function(a,b) return a:lower() < b:lower() end)

        for _, n in ipairs(names) do
            local p = texMap[n]
            local info = UIDropDownMenu_CreateInfo()
            info.text = n
            info.value = n
            info.notCheckable = true
            info.func = function()
                local db = DB()
                db.texture = p
                db.textureName = n
                SetDropdownValue(texDD, n)
                Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

local function InitFontDD()
    fontMap = GetFonts()
    UIDropDownMenu_Initialize(fontDD, function(self, level)
        local names = {}
        for n in pairs(fontMap) do
            names[#names+1] = n
        end
        table.sort(names, function(a,b) return a:lower() < b:lower() end)

        for _, n in ipairs(names) do
            local p = fontMap[n]
            local info = UIDropDownMenu_CreateInfo()
            info.text = n
            info.value = n
            info.notCheckable = true
            info.func = function()
                local db = DB()
                db.font = p
                db.fontName = n
                SetDropdownValue(fontDD, n)
                Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

local function InitRepTextureDD()
    repTexMap = GetTextures()
    UIDropDownMenu_Initialize(repTexDD, function(self, level)
        local names = {}
        for n in pairs(repTexMap) do
            names[#names+1] = n
        end
        table.sort(names, function(a,b) return a:lower() < b:lower() end)

        for _, n in ipairs(names) do
            local p = repTexMap[n]
            local info = UIDropDownMenu_CreateInfo()
            info.text = n
            info.value = n
            info.notCheckable = true
            info.func = function()
                local db = DB()
                db.repTexture = p
                db.repTextureName = n
                SetDropdownValue(repTexDD, n)
                Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

local function InitRepFontDD()
    repFontMap = GetFonts()
    UIDropDownMenu_Initialize(repFontDD, function(self, level)
        local names = {}
        for n in pairs(repFontMap) do
            names[#names+1] = n
        end
        table.sort(names, function(a,b) return a:lower() < b:lower() end)

        for _, n in ipairs(names) do
            local p = repFontMap[n]
            local info = UIDropDownMenu_CreateInfo()
            info.text = n
            info.value = n
            info.notCheckable = true
            info.func = function()
                local db = DB()
                db.repFont = p
                db.repFontName = n
                SetDropdownValue(repFontDD, n)
                Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end


-- Initialize dropdown display text and attach universal pickers
do
    -- Ensure maps exist for tooltips
    texMap = GetTextures()
    fontMap = GetFonts()

    -- Set initial display text
    SetDropdownValue(texDD, (DB().textureName or "Select..."))
    SetDropdownValue(fontDD, (DB().fontName or "Select..."))
    SetDropdownValue(repTexDD, (DB().repTextureName or "Select..."))
    SetDropdownValue(repFontDD, (DB().repFontName or "Select..."))

    -- Attach pickers (searchable, preview + overlay text)
    AttachPickerToDropDown(texDD, "Texture", "texture", GetTextures, function(name, path)
        local db = DB()
        db.texture = path; db.textureName = name
        SetDropdownValue(texDD, name)
        Refresh()
    end, function() return { externalEdit = texFilterEB } end)

    AttachPickerToDropDown(fontDD, "Font", "font", GetFonts, function(name, path)
        local db = DB()
        db.font = path; db.fontName = name
        SetDropdownValue(fontDD, name)
        Refresh()
    end, function() return { externalEdit = fontFilterEB } end)

    AttachPickerToDropDown(repTexDD, "Reputation Texture", "texture", GetTextures, function(name, path)
        local db = DB()
        db.repTexture = path; db.repTextureName = name
        SetDropdownValue(repTexDD, name)
        Refresh()
    end)

    AttachPickerToDropDown(repFontDD, "Reputation Font", "font", GetFonts, function(name, path)
        local db = DB()
        db.repFont = path; db.repFontName = name
        SetDropdownValue(repFontDD, name)
        Refresh()
    end)
end
-------------------------------------------------
-- Dropdown tooltips
-------------------------------------------------
local function AttachDropdownTooltip(dd, labelText, getCurrentName, getCurrentPath)
    dd:EnableMouse(true)
    dd:SetScript("OnEnter", function()
        GameTooltip:SetOwner(dd, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(labelText, 1, 1, 1)
        local n = getCurrentName()
        local p = getCurrentPath()
        if n then
            GameTooltip:AddLine("Selected: "..tostring(n), 0.9, 0.9, 0.9)
        end
        if p then
            GameTooltip:AddLine(tostring(p), 0.6, 0.8, 1.0, true)
        end
        GameTooltip:Show()
    end)
    dd:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end



AttachDropdownTooltip(texDD, "Texture", function() return TibbettsMultiBarDB and DB().textureName end, function() return TibbettsMultiBarDB and DB().texture end)
AttachDropdownTooltip(fontDD, "Font", function() return TibbettsMultiBarDB and DB().fontName end, function() return TibbettsMultiBarDB and DB().font end)

-------------------------------------------------
-- Defaults + refresh
-------------------------------------------------
local updating = false

local function EnsureDefaults()
    if DB().enabled == nil then DB().enabled = true end
    if DB().hideBlizzard == nil then DB().hideBlizzard = true end
    if DB().showText == nil then DB().showText = true end
    if DB().showRested == nil then DB().showRested = true end

    if DB().textShadow == nil then DB().textShadow = true end
if DB().showBorder == nil then DB().showBorder = false end
if DB().showTicks == nil then DB().showTicks = false end
if DB().tickCount == nil then DB().tickCount = 10 end
if DB().tickAlpha == nil then DB().tickAlpha = 0.25 end
    if DB().textColor == nil then DB().textColor = { r=1,g=1,b=1,a=1 } end
    if DB().barColor == nil then DB().barColor = { r=0,g=0.6,b=1,a=1 } end
    if DB().bgAlpha == nil then DB().bgAlpha = 0.5 end
    -- Migrate old "x100"-style saved values (e.g. 50 -> 0.5)
    if type(DB().bgAlpha) == "number" and DB().bgAlpha > 1 then
        DB().bgAlpha = DB().bgAlpha / 100
    end
    DB().bgAlpha = Clamp01(tonumber(DB().bgAlpha) or 0.5)
    if DB().bgColor == nil then DB().bgColor = { r=0,g=0,b=0,a=DB().bgAlpha } end
    if DB().restedColor == nil then DB().restedColor = { r=0.6,g=0,b=1,a=0.6 }
                    DB().repColor = { r=0, g=0.8, b=0.2, a=1 } end

    if DB().mouseoverFade == nil then DB().mouseoverFade = false end
    if DB().fadeAlpha == nil then DB().fadeAlpha = 0.25 end
    if DB().hideInCombat == nil then DB().hideInCombat = false end
    if DB().pixelSnap == nil then DB().pixelSnap = true end

    if DB().fontSize == nil then DB().fontSize = 12 end
    if DB().width == nil then DB().width = 1024 end
    if DB().height == nil then DB().height = 14 end
    if DB().scale == nil then DB().scale = 1.0 end
    if DB().point == nil then DB().point = "CENTER" end
    if DB().relPoint == nil then DB().relPoint = "CENTER" end
    if DB().x == nil then DB().x = 0 end
    if DB().y == nil then DB().y = 0 end
end


local function UpdateEnabledStates()
    -- Reputation controls depend on enable
    local repOn = DB().showRep ~= false
    local snapped = (DB().repSnap ~= false)
    repAuto:SetEnabled(repOn)
    if repOn then repAuto.Text:SetTextColor(1,1,1) else repAuto.Text:SetTextColor(0.5,0.5,0.5) end
    repSnap:SetEnabled(repOn)
    if repOn then repSnap.Text:SetTextColor(1,1,1) else repSnap.Text:SetTextColor(0.5,0.5,0.5) end
    repAbove:SetEnabled(repOn and snapped)
    if (repOn and snapped) then repAbove.Text:SetTextColor(1,1,1) else repAbove.Text:SetTextColor(0.5,0.5,0.5) end
    repGap:SetEnabled(repOn and snapped)
    if (repOn and snapped) then repGap.Text:SetTextColor(1,1,1) else repGap.Text:SetTextColor(0.5,0.5,0.5) end
    repColorBtn:SetEnabled(repOn)
    if repOn then repColorBtn:GetFontString():SetTextColor(1,1,1); repColorSwatch:SetAlpha(1) else repColorBtn:GetFontString():SetTextColor(0.5,0.5,0.5); repColorSwatch:SetAlpha(0.35) end
    repHeight:SetEnabled(repOn)
    if repOn then
        repHeight.Text:SetTextColor(1,1,1)
        repHeightEB:Enable()
        repHeightEB:SetTextColor(1,1,1)
    else
        repHeight.Text:SetTextColor(0.5,0.5,0.5)
        repHeightEB:Disable()
        repHeightEB:SetTextColor(0.5,0.5,0.5)
    end
    if ticks and tickCount then
        ticks:SetEnabled(true)
        tickCount:SetEnabled(DB().showTicks and true or false)
        if DB().showTicks then tickCount.Text:SetTextColor(1,1,1) else tickCount.Text:SetTextColor(0.5,0.5,0.5) end
    end

-- Text-related controls depend on Show Text
    local textOn = DB().showText and true or false

    textShadow:SetEnabled(textOn)
    if textOn then
        textShadow.Text:SetTextColor(1,1,1)
    else
        textShadow.Text:SetTextColor(0.5,0.5,0.5)
    end

    textColorBtn:SetEnabled(textOn)
    if textOn then
        textColorBtn:GetFontString():SetTextColor(1,1,1)
        textColorSwatch:SetAlpha(1)
    else
        textColorBtn:GetFontString():SetTextColor(0.5,0.5,0.5)
        textColorSwatch:SetAlpha(0.35)
    end

    fontSize:SetEnabled(textOn)
    if textOn then
        fontSize.Text:SetTextColor(1,1,1)
        fontSizeEB:Enable()
        fontSizeEB:SetTextColor(1,1,1)
    else
        fontSize.Text:SetTextColor(0.5,0.5,0.5)
        fontSizeEB:Disable()
        fontSizeEB:SetTextColor(0.5,0.5,0.5)
    end

    -- Dropdowns + preview also depend on Show Text
    if textOn then
        UIDropDownMenu_EnableDropDown(fontDD)
        fontLabel:SetTextColor(1,1,1)
        previewLabel:SetTextColor(1,1,1)
        previewSample:SetTextColor(1,1,1)
        previewSample:SetAlpha(1)
    else
        UIDropDownMenu_DisableDropDown(fontDD)
        fontLabel:SetTextColor(0.5,0.5,0.5)
        previewLabel:SetTextColor(0.5,0.5,0.5)
        previewSample:SetTextColor(0.5,0.5,0.5)
        previewSample:SetAlpha(0.6)
    end

    -- Fade alpha depends on Mouseover Fade
    local fadeOn = DB().mouseoverFade and true or false
    fadeAlpha:SetEnabled(fadeOn)
    if fadeOn then
        fadeAlpha.Text:SetTextColor(1,1,1)
    else
        fadeAlpha.Text:SetTextColor(0.5,0.5,0.5)
    end
end


local function RefreshUI()
    EnsureDefaults()
    updating = true
    
    enable:SetChecked(DB().enabled ~= false)
    hideBlizz:SetChecked(DB().hideBlizzard and true or false)
    lock:SetChecked(DB().locked and true or false)
    clamp:SetChecked(DB().clamp and true or false)
    showText:SetChecked(DB().showText and true or false)
    showRested:SetChecked(DB().showRested and true or false)
    repEnable:SetChecked(DB().showRep ~= false)
    repAuto:SetChecked(DB().autoRepAtMax ~= false)
    repSnap:SetChecked(DB().repSnap ~= false)
    repAbove:SetChecked(DB().repAbove and true or false)
    repGap:SetValue(tonumber(DB().repGap) or 2)
    if repLock then repLock:SetChecked(DB().repLocked and true or false) end

    textShadow:SetChecked(DB().textShadow and true or false)
    
    fontSize:SetValue(tonumber(DB().fontSize) or 12)
    fontSizeEB:SetText(tostring(tonumber(DB().fontSize) or 12))
    
    width:SetValue(tonumber(DB().width) or 1024)
    widthEB:SetText(tostring(tonumber(DB().width) or 1024))
    height:SetValue(tonumber(DB().height) or 14)
    heightEB:SetText(tostring(tonumber(DB().height) or 14))
    scale:SetValue(math.floor((tonumber(DB().scale) or 1.0) * 100 + 0.5))
    repHeight:SetValue(tonumber(DB().repHeight) or 6)
    repHeightEB:SetText(tostring(tonumber(DB().repHeight) or 6))
    
    
    -- Rep-specific UI values
    if DB().repWidth == nil then DB().repWidth = DB().width end
    if DB().repScale == nil then DB().repScale = DB().scale end
    if DB().repFontSize == nil then DB().repFontSize = DB().fontSize end
    if DB().repTextureName == nil then DB().repTextureName = DB().textureName end
    if DB().repFontName == nil then DB().repFontName = DB().fontName end
    if DB().repTextColor == nil then DB().repTextColor = { r=1,g=1,b=1,a=1 } end
    if DB().repBgColor == nil then DB().repBgColor = { r=0,g=0,b=0,a=0.5 } end
    if DB().repBgAlpha == nil then DB().repBgAlpha = DB().bgAlpha or 0.5 end
    if type(DB().repBgAlpha) == "number" and DB().repBgAlpha > 1 then
        DB().repBgAlpha = DB().repBgAlpha / 100
    end
    DB().repBgAlpha = Clamp01(tonumber(DB().repBgAlpha) or 0.5)
    if DB().repShowBorder == nil then DB().repShowBorder = DB().showBorder end
    if DB().repShowTicks == nil then DB().repShowTicks = DB().showTicks end
    if DB().repTickCount == nil then DB().repTickCount = DB().tickCount end
    if DB().repTickAlpha == nil then DB().repTickAlpha = DB().tickAlpha end

    repWidth:SetValue(tonumber(DB().repWidth) or tonumber(DB().width) or 1024)
    repWidthEB:SetText(tostring(tonumber(DB().repWidth) or tonumber(DB().width) or 1024))
    repScale:SetValue(tonumber(DB().repScale) or tonumber(DB().scale) or 1)
    repScaleEB:SetText(tostring(tonumber(DB().repScale) or tonumber(DB().scale) or 1))

    repFontSize:SetValue(tonumber(DB().repFontSize) or tonumber(DB().fontSize) or 12)
    repFontSizeEB:SetText(tostring(tonumber(DB().repFontSize) or tonumber(DB().fontSize) or 12))

    local rtc = DB().repTextColor or {}
    SetSolidColor(repTextColorSwatch, rtc.r or 1, rtc.g or 1, rtc.b or 1, 1)

    local rbgc = DB().repBgColor or {}
    SetSolidColor(repBgColorSwatch, rbgc.r or 0, rbgc.g or 0, rbgc.b or 0, DB().repBgAlpha or 0.5)
    repBgAlpha:SetValue(tonumber(DB().repBgAlpha) or 0.5)
    repBgAlphaEB:SetText(tostring(tonumber(DB().repBgAlpha) or 0.5))

    repBorder:SetChecked(DB().repShowBorder and true or false)
    repTicks:SetChecked(DB().repShowTicks and true or false)
    repTickCount:SetValue(tonumber(DB().repTickCount) or 20)
    repTickAlpha:SetValue(tonumber(DB().repTickAlpha) or 0.25)

    if DB().repTextureName then SetDropdownValue(repTexDD, DB().repTextureName) end
    if DB().repFontName then SetDropdownValue(repFontDD, DB().repFontName) end
posText:SetText(string.format("X: %d   Y: %d", tonumber(DB().x) or 0, tonumber(DB().y) or 0))
    
    local tc = DB().textColor or {}
    SetSolidColor(textColorSwatch, tc.r or 1, tc.g or 1, tc.b or 1, 1)
    
    local bc = DB().barColor or {}
    SetSolidColor(barColorSwatch, bc.r or 0, bc.g or 0.6, bc.b or 1, 1)
    
    local bgc = DB().bgColor or {}
    SetSolidColor(bgColorSwatch, bgc.r or 0, bgc.g or 0, bgc.b or 0, DB().bgAlpha or 0.5)
    
    local rc = DB().restedColor or {}
    SetSolidColor(restedColorSwatch, rc.r or 0.6, rc.g or 0, rc.b or 1, 1)
    local rpc = DB().repColor or {}
    SetSolidColor(repColorSwatch, rpc.r or 0, rpc.g or 0.8, rpc.b or 0.2, 1)
    
    local aVal = bgc.a
    if aVal == nil then aVal = DB().bgAlpha or 0.5 end
    bgAlpha:SetValue(math.floor(Clamp01(tonumber(aVal) or 0.5) * 100 + 0.5))
    
    mouseFade:SetChecked(DB().mouseoverFade and true or false)
    fadeAlpha:SetValue(math.floor(Clamp01(tonumber(DB().fadeAlpha) or 0.25) * 100 + 0.5))
    hideCombat:SetChecked(DB().hideInCombat and true or false)
    pixelSnap:SetChecked(DB().pixelSnap ~= false)
    
    if DB().textureName then SetDropdownValue(texDD, DB().textureName) end
    if DB().fontName then SetDropdownValue(fontDD, DB().fontName) end
    
    
    
    
    -- Preview sample
    do
    local fontPath = DB().font or "Fonts\\FRIZQT__.TTF"
    local fs = tonumber(DB().fontSize) or 12
    previewSample:SetFont(fontPath, fs, DB().fontOutline or "")
    local tc = DB().textColor or {}
    previewSample:SetTextColor(tc.r or 1, tc.g or 1, tc.b or 1, 1)
    if DB().textShadow then
    local off = tonumber(DB().textShadowOffset) or 1
    previewSample:SetShadowOffset(off, -off)
    local sc = DB().textShadowColor or { r=0,g=0,b=0,a=0.9 }
    previewSample:SetShadowColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 0.9)
    else
    previewSample:SetShadowOffset(0, 0)
    end
    end
    
    UpdateEnabledStates()
    updating = false
    end

panel.refresh = RefreshUI

-------------------------------------------------
-- Handlers
-------------------------------------------------
enable:SetScript("OnClick", function(self)
    if updating then return end
    DB().enabled = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

hideBlizz:SetScript("OnClick", function(self)
    if updating then return end
    DB().hideBlizzard = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

lock:SetScript("OnClick", function(self)
    if updating then return end
    DB().locked = self:GetChecked() and true or false
    if addon.UpdateDragState then addon.UpdateDragState() else if addon and addon.ApplySettings then addon.ApplySettings() end end
end)

clamp:SetScript("OnClick", function(self)
    if updating then return end
    DB().clamp = self:GetChecked() and true or false
    if addon.UpdateDragState then addon.UpdateDragState() else if addon and addon.ApplySettings then addon.ApplySettings() end end
end)

showText:SetScript("OnClick", function(self)
    if updating then return end
    DB().showText = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

showRested:SetScript("OnClick", function(self)
    if updating then return end
    DB().showRested = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

repEnable:SetScript("OnClick", function(self)
    if updating then return end
    DB().showRep = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

repAuto:SetScript("OnClick", function(self)
    if updating then return end
    DB().autoRepAtMax = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

repSnap:SetScript("OnClick", function(self)
    if updating then return end
    DB().repSnap = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

repAbove:SetScript("OnClick", function(self)
    if updating then return end
    DB().repAbove = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

repGap:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().repGap = math.floor(v + 0.5)
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

repLock:SetScript("OnClick", function(self)
    if updating then return end
    DB().repLocked = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
    Refresh()
end)

repResetPos:SetScript("OnClick", function()
    DB().repPoint = "CENTER"
    DB().repRelPoint = "CENTER"
    DB().repX = 0
    DB().repY = 0
    if addon and addon.ApplySettings then addon.ApplySettings() end
    Refresh()
end)


textShadow:SetScript("OnClick", function(self)
    if updating then return end
    DB().textShadow = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

fontSize:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    local nv = math.floor(v + 0.5)
    DB().fontSize = nv
    if not fontSizeEB:HasFocus() then fontSizeEB:SetText(tostring(nv)) end
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

fontSizeEB:SetScript("OnEnterPressed", function(self)
    if updating then self:ClearFocus(); return end
    local v = tonumber(self:GetText())
    if not v then self:SetText(tostring(DB().fontSize or 12)); self:ClearFocus(); return end
    v = math.max(8, math.min(24, math.floor(v + 0.5)))
    DB().fontSize = v
    updating = true
    fontSize:SetValue(v)
    updating = false
    self:SetText(tostring(v))
    self:ClearFocus()
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)
fontSizeEB:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(DB().fontSize or 12))
    self:ClearFocus()
end)

width:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    v = math.floor(v + 0.5)
    DB().width = v
    if not widthEB:HasFocus() then widthEB:SetText(tostring(v)) end
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)
widthEB:SetScript("OnEnterPressed", function(self)
    if updating then self:ClearFocus(); return end
    local v = tonumber(self:GetText())
    if not v then self:SetText(tostring(DB().width or 1024)); self:ClearFocus(); return end
    v = math.max(200, math.min(2000, math.floor(v + 0.5)))
    DB().width = v
    updating = true
    width:SetValue(v)
    updating = false
    self:SetText(tostring(v))
    self:ClearFocus()
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)
widthEB:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(DB().width or 1024))
    self:ClearFocus()
end)

height:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    v = math.floor(v + 0.5)
    DB().height = v
    if not heightEB:HasFocus() then heightEB:SetText(tostring(v)) end
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)
heightEB:SetScript("OnEnterPressed", function(self)
    if updating then self:ClearFocus(); return end
    local v = tonumber(self:GetText())
    if not v then self:SetText(tostring(DB().height or 14)); self:ClearFocus(); return end
    v = math.max(4, math.min(64, math.floor(v + 0.5)))
    DB().height = v
    updating = true
    height:SetValue(v)
    updating = false
    self:SetText(tostring(v))
    self:ClearFocus()
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)
heightEB:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(DB().height or 14))
    self:ClearFocus()
end)

scale:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().scale = (math.floor(v + 0.5)) / 100
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

repHeight:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    local nv = math.floor(v + 0.5)
    DB().repHeight = nv
    if not repHeightEB:HasFocus() then repHeightEB:SetText(tostring(nv)) end
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

repHeightEB:SetScript("OnEnterPressed", function(self)
    if updating then self:ClearFocus(); return end
    local v = tonumber(self:GetText())
    if not v then self:SetText(tostring(DB().repHeight or 6)); self:ClearFocus(); return end
    v = math.max(4, math.min(20, math.floor(v + 0.5)))
    DB().repHeight = v
    updating = true
    repHeight:SetValue(v)
    updating = false
    self:SetText(tostring(v))
    self:ClearFocus()
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)


-- Rep Width / Scale
repWidth:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    local nv = math.floor(v + 0.5)
    DB().repWidth = nv
    if not repWidthEB:HasFocus() then repWidthEB:SetText(tostring(nv)) end
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then addon.UpdateReputation() end
end)

repWidthEB:SetScript("OnEnterPressed", function(self)
    if updating then self:ClearFocus(); return end
    local v = tonumber(self:GetText())
    if not v then self:SetText(tostring(DB().repWidth or DB().width or 1024)); self:ClearFocus(); return end
    v = math.max(100, math.min(3000, math.floor(v + 0.5)))
    DB().repWidth = v
    updating = true
    repWidth:SetValue(v)
    updating = false
    self:SetText(tostring(v))
    self:ClearFocus()
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then addon.UpdateReputation() end
end)

repScale:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    local nv = (math.floor((v * 100) + 0.5)) / 100
    DB().repScale = nv
    if not repScaleEB:HasFocus() then repScaleEB:SetText(tostring(nv)) end
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then addon.UpdateReputation() end
end)

repScaleEB:SetScript("OnEnterPressed", function(self)
    if updating then self:ClearFocus(); return end
    local v = tonumber(self:GetText())
    if not v then self:SetText(tostring(DB().repScale or DB().scale or 1)); self:ClearFocus(); return end
    v = math.max(0.1, math.min(3.0, v))
    v = (math.floor((v * 100) + 0.5)) / 100
    DB().repScale = v
    updating = true
    repScale:SetValue(v)
    updating = false
    self:SetText(tostring(v))
    self:ClearFocus()
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then addon.UpdateReputation() end
end)

-- Rep Font size
repFontSize:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    local nv = math.floor(v + 0.5)
    DB().repFontSize = nv
    if not repFontSizeEB:HasFocus() then repFontSizeEB:SetText(tostring(nv)) end
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

repFontSizeEB:SetScript("OnEnterPressed", function(self)
    if updating then self:ClearFocus(); return end
    local v = tonumber(self:GetText())
    if not v then self:SetText(tostring(DB().repFontSize or DB().fontSize or 12)); self:ClearFocus(); return end
    v = math.max(6, math.min(64, math.floor(v + 0.5)))
    DB().repFontSize = v
    updating = true
    repFontSize:SetValue(v)
    updating = false
    self:SetText(tostring(v))
    self:ClearFocus()
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

-- Rep background alpha
repBgAlpha:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    local nv = (math.floor((v * 100) + 0.5)) / 100
    DB().repBgAlpha = nv
    if not repBgAlphaEB:HasFocus() then repBgAlphaEB:SetText(tostring(nv)) end
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

repBgAlphaEB:SetScript("OnEnterPressed", function(self)
    if updating then self:ClearFocus(); return end
    local v = tonumber(self:GetText())
    if not v then self:SetText(tostring(DB().repBgAlpha or DB().bgAlpha or 0.5)); self:ClearFocus(); return end
    v = math.max(0, math.min(1, v))
    v = (math.floor((v * 100) + 0.5)) / 100
    DB().repBgAlpha = v
    updating = true
    repBgAlpha:SetValue(v)
    updating = false
    self:SetText(tostring(v))
    self:ClearFocus()
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

-- Rep border / ticks
repBorder:SetScript("OnClick", function(self)
    if updating then return end
    DB().repShowBorder = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

repTicks:SetScript("OnClick", function(self)
    if updating then return end
    DB().repShowTicks = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

repTickCount:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().repTickCount = math.floor(v + 0.5)
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

repTickAlpha:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().repTickAlpha = (math.floor((v * 100) + 0.5)) / 100
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

-- Copy XP appearance -> Rep
repCopyFromXP:SetScript("OnClick", function()
    local d = DB()
    d.repTexture = d.texture
    d.repTextureName = d.textureName
    d.repFont = d.font
    d.repFontName = d.fontName
    d.repFontSize = d.fontSize
    d.repTextColor = { r = d.textColor.r, g = d.textColor.g, b = d.textColor.b, a = d.textColor.a }
    d.repBgColor = { r = d.bgColor.r, g = d.bgColor.g, b = d.bgColor.b, a = d.bgColor.a }
    d.repBgAlpha = d.bgAlpha
    d.repShowBorder = d.showBorder
    d.repShowTicks = d.showTicks
    d.repTickCount = d.tickCount
    d.repTickAlpha = d.tickAlpha
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

-- Color pickers
repTextColorBtn:SetScript("OnClick", function()
    ShowColorPicker(
        function()
            local c = DB().repTextColor or {}
            return c.r or 1, c.g or 1, c.b or 1
        end,
        function(r,g,b) SetColorTable("repTextColor", r,g,b) end
    )
end)

repBgColorBtn:SetScript("OnClick", function()
    ShowColorPicker(
        function()
            local c = DB().repBgColor or {}
            return c.r or 0, c.g or 0, c.b or 0
        end,
        function(r,g,b) SetColorTable("repBgColor", r,g,b, true) end,
        function()
            local db = DB()
            return db.repBgAlpha or (db.repBgColor and db.repBgColor.a) or 0.5
        end,
        function(a)
            local db = DB()
            a = Clamp01(tonumber(a) or 0.5)
            db.repBgAlpha = a
            db.repBgColor = db.repBgColor or { r=0,g=0,b=0,a=a }
            db.repBgColor.a = a
            Refresh()
        end
    )
end)

repHeightEB:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(DB().repHeight or 6))
    self:ClearFocus()
end)


bgAlpha:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    local aVal = Clamp01((math.floor(v + 0.5)) / 100)
    DB().bgAlpha = aVal
    DB().bgColor = DB().bgColor or { r = 0, g = 0, b = 0, a = aVal }
    DB().bgColor.a = aVal
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)


textColorBtn:SetScript("OnClick", function()
    ShowColorPicker(
        function()
            local c = DB().textColor or {}
            return c.r or 1, c.g or 1, c.b or 1
        end,
        function(r,g,b) SetColorTable("textColor", r,g,b) end
    )
end)

barColorBtn:SetScript("OnClick", function()
    ShowColorPicker(
        function()
            local c = DB().barColor or {}
            return c.r or 0, c.g or 0.6, c.b or 1
        end,
        function(r,g,b) SetColorTable("barColor", r,g,b) end
    )
end)

bgColorBtn:SetScript("OnClick", function()
    ShowColorPicker(
        function()
            local c = DB().bgColor or {}
            return c.r or 0, c.g or 0, c.b or 0
        end,
        function(r,g,b) SetColorTable("bgColor", r,g,b, true) end,
        function()
            local db = DB()
            return db.bgAlpha or (db.bgColor and db.bgColor.a) or 0.5
        end,
        function(a)
            local db = DB()
            a = Clamp01(tonumber(a) or 0.5)
            db.bgAlpha = a
            db.bgColor = db.bgColor or { r=0,g=0,b=0,a=a }
            db.bgColor.a = a
            Refresh()
        end
    )
end)

repColorBtn:SetScript("OnClick", function()
    ShowColorPicker(
        function()
            local c = DB().repColor or {}
            return c.r or 0, c.g or 0.8, c.b or 0.2
        end,
        function(r,g,b) SetColorTable("repColor", r,g,b) end
    )
end)

restedColorBtn:SetScript("OnClick", function()
    ShowColorPicker(
        function()
            local c = DB().restedColor or {}
            return c.r or 0.6, c.g or 0, c.b or 1
        end,
        function(r,g,b) SetColorTable("restedColor", r,g,b) end
    )
end)

resetPos:SetScript("OnClick", function()
    if updating then return end
    DB().point = "CENTER"
    DB().relPoint = "CENTER"
    DB().x = 0
    DB().y = 0
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

mouseFade:SetScript("OnClick", function(self)
    if updating then return end
    DB().mouseoverFade = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if addon.UpdateReputation then if addon and addon.UpdateReputation then addon.UpdateReputation() end end
    Refresh()
end)

fadeAlpha:SetScript("OnValueChanged", function(self, v)
    if updating then return end
    DB().fadeAlpha = Clamp01((math.floor(v + 0.5)) / 100)
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

hideCombat:SetScript("OnClick", function(self)
    if updating then return end
    DB().hideInCombat = self:GetChecked() and true or false
    if addon and addon.ApplySettings then addon.ApplySettings() end
end)

pixelSnap:SetScript("OnClick", function(self)
    if updating then return end
    DB().pixelSnap = self:GetChecked() and true or false
end)


resetColors:SetScript("OnClick", function()
    StaticPopupDialogs["XPMB_RESET_COLORS"] = {
        text = "Reset Tibbetts' MultiBar colors to defaults?",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            DB().textColor = { r=1,g=1,b=1,a=1 }
            DB().textShadowColor = { r=0,g=0,b=0,a=0.9 }
            DB().barColor = { r=0,g=0.6,b=1,a=1 }
            DB().bgAlpha = 0.5
            DB().bgColor = { r=0,g=0,b=0,a=0.5 }
            DB().restedColor = { r=0.6,g=0,b=1,a=0.6 }
                    DB().repColor = { r=0, g=0.8, b=0.2, a=1 }
            if addon and addon.ApplySettings then addon.ApplySettings() end
            Refresh()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("XPMB_RESET_COLORS")
end)

resetAll:SetScript("OnClick", function()
    StaticPopupDialogs["XPMB_RESET_ALL"] = {
        text = "Reset all Tibbetts' MultiBar settings?",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            TibbettsMultiBarDB = nil
            if addon and addon.ApplySettings then addon.ApplySettings() end
            Refresh()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("XPMB_RESET_ALL")
end)

-------------------------------------------------
-- TAB 6: PROFILES
-------------------------------------------------
local p = frames[6]
local titleP = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
titleP:SetPoint("TOPLEFT", 16, -16)
titleP:SetText("Profiles")

local profLabel = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
profLabel:SetPoint("TOPLEFT", 16, -46)
profLabel:SetText("Active Profile")

local profileDD = CreateFrame("Frame", nil, p, "UIDropDownMenuTemplate")
profileDD:SetPoint("TOPLEFT", 120, -58)
UIDropDownMenu_SetWidth(profileDD, 220)

local profNew = MakeButton(p, "New", 80, 22)
profNew:SetPoint("LEFT", profileDD, "RIGHT", -10, 2)
local profCopy = MakeButton(p, "Copy", 80, 22)
profCopy:SetPoint("LEFT", profNew, "RIGHT", 6, 0)
local profDelete = MakeButton(p, "Delete", 80, 22)
profDelete:SetPoint("LEFT", profCopy, "RIGHT", 6, 0)

local profHelp = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
profHelp:SetPoint("TOPLEFT", 16, -100)
profHelp:SetJustifyH("LEFT")
profHelp:SetWidth(560)
profHelp:SetText("Profiles let you save multiple layouts (size, colors, position, etc.). Switching profiles applies instantly.")

local function DeepCopy(src, dst)
    if type(src) ~= "table" then return src end
    dst = dst or {}
    for k,v in pairs(src) do
        if type(v) == "table" then dst[k] = DeepCopy(v, {}) else dst[k] = v end
    end
    return dst
end

local function EnsureSV()
    if not TibbettsMultiBarSV or type(TibbettsMultiBarSV) ~= "table" then
        TibbettsMultiBarSV = { current = "Default", profiles = {} }
    end
    TibbettsMultiBarSV.profiles = TibbettsMultiBarSV.profiles or {}
    if not TibbettsMultiBarSV.profiles["Default"] then
        TibbettsMultiBarSV.profiles["Default"] = DeepCopy(TibbettsMultiBarDB or {}, {})
    end
    if not TibbettsMultiBarSV.current or TibbettsMultiBarSV.current == "" then
        TibbettsMultiBarSV.current = "Default"
    end
    if not TibbettsMultiBarSV.profiles[TibbettsMultiBarSV.current] then
        TibbettsMultiBarSV.profiles[TibbettsMultiBarSV.current] = DeepCopy(TibbettsMultiBarSV.profiles["Default"], {})
    end
end

local function SwitchProfile(name)
    EnsureSV()
    if not TibbettsMultiBarSV.profiles[name] then return end
    TibbettsMultiBarSV.current = name
    TibbettsMultiBarDB = TibbettsMultiBarSV.profiles[name]
    DB().profileName = name
    if addon and addon.ApplySettings then addon.ApplySettings() end
    if RefreshProfileDD then RefreshProfileDD() end
    if RefreshUI then RefreshUI() end
    Refresh()
end

local function RefreshProfileDD()
    EnsureSV()
    UIDropDownMenu_Initialize(profileDD, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local names = {}
        for n in pairs(TibbettsMultiBarSV.profiles) do names[#names+1] = n end
        table.sort(names, function(a,b) return a:lower() < b:lower() end)
        for _, n in ipairs(names) do
            info.text = n
            info.func = function()
                UIDropDownMenu_SetText(profileDD, n)
                SwitchProfile(n)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(profileDD, TibbettsMultiBarSV.current or "Default")
end

RefreshProfileDD()

StaticPopupDialogs["XPMB_NEW_PROFILE"] = {
    text = "New profile name:",
    button1 = "Create",
    button2 = CANCEL,
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function(self)
    local eb = self.editBox or self.EditBox
    local name = eb and eb:GetText() or ""
        if not name or name == "" then return end
        EnsureSV()
        if TibbettsMultiBarSV.profiles[name] then return end
        TibbettsMultiBarSV.profiles[name] = DeepCopy(TibbettsMultiBarDB or {}, {})
        SwitchProfile(name)
        RefreshProfileDD()
        if RefreshUI then RefreshUI() end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        parent.button1:Click()
    end,
}

StaticPopupDialogs["XPMB_CONFIRM_DELETE_PROFILE"] = {
    text = "Delete this profile? (cannot be undone)",
    button1 = YES,
    button2 = NO,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function()
        EnsureSV()
        local cur = TibbettsMultiBarSV.current or "Default"
        if cur == "Default" then return end
        TibbettsMultiBarSV.profiles[cur] = nil
        SwitchProfile("Default")
        RefreshProfileDD()
    end,
}

profNew:SetScript("OnClick", function() StaticPopup_Show("XPMB_NEW_PROFILE") end)
profCopy:SetScript("OnClick", function()
    EnsureSV()
    local cur = TibbettsMultiBarSV.current or "Default"
    local name = cur .. " Copy"
    local i = 2
    while TibbettsMultiBarSV.profiles[name] do
        name = cur .. " Copy " .. i
        i = i + 1
    end
    TibbettsMultiBarSV.profiles[name] = DeepCopy(TibbettsMultiBarDB or {}, {})
    SwitchProfile(name)
    RefreshProfileDD()
end)
profDelete:SetScript("OnClick", function() StaticPopup_Show("XPMB_CONFIRM_DELETE_PROFILE") end)

-- Show last tab on open
panel:SetScript("OnShow", function()
    EnsureDefaults()
    if RefreshProfileDD then RefreshProfileDD() end
    local id = tonumber(DB().lastTab) or 1
    if id < 1 or id > 6 then id = 1 end
    ShowTab(id)
    if RefreshUI then RefreshUI() end
    Refresh()
end)


-------------------------------------------------
-- About / Export
-------------------------------------------------
local function EncodeProfile(tbl)
    local ok, s = pcall(function() return LibStub("AceSerializer-3.0"):Serialize(tbl) end)
    if ok then return s end
    return nil
end

local function DecodeProfile(s)
    local ok, data = pcall(function() return LibStub("AceSerializer-3.0"):Deserialize(s) end)
    if ok and data then return data end
    return nil
end

-------------------------------------------------
-- Registration (Retail + Classic)
-------------------------------------------------
local function RegisterPanel()
    -- Retail (Dragonflight+): Settings API
    if type(Settings) == "table" and type(Settings.RegisterCanvasLayoutCategory) == "function" and type(Settings.RegisterAddOnCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        return
    end

    -- Classic: InterfaceOptions
    if type(InterfaceOptions_AddCategory) == "function" then

        return
    end
end

RegisterPanel()