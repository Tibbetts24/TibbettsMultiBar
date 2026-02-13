--=========================================================
-- Borders / Ticks
--=========================================================

--=========================================================
-- Blizzard XP bar hide/show helper (must exist before ApplySettings)
--=========================================================
function HideBlizzardXP(hide)
    if _G.MainMenuExpBar then
        if hide then _G.MainMenuExpBar:Hide() else _G.MainMenuExpBar:Show() end
    end
    if _G.ExhaustionTick then
        if hide then _G.ExhaustionTick:Hide() else _G.ExhaustionTick:Show() end
    end
    if _G.ExhaustionLevelFillBar then
        if hide then _G.ExhaustionLevelFillBar:Hide() else _G.ExhaustionLevelFillBar:Show() end
    end
end

local function CreateBorderTextures(parent)
    local t = {}
    t.top = parent:CreateTexture(nil, "OVERLAY")
    t.bottom = parent:CreateTexture(nil, "OVERLAY")
    t.left = parent:CreateTexture(nil, "OVERLAY")
    t.right = parent:CreateTexture(nil, "OVERLAY")
    for _, tex in pairs(t) do
        tex:SetTexture("Interface\\Buttons\\WHITE8x8")
        tex:SetVertexColor(0,0,0,1)
    end
    return t
end

local function LayoutBorderTextures(border, frame, show)
    if not border then return end
    if not show then
        border.top:Hide(); border.bottom:Hide(); border.left:Hide(); border.right:Hide()
        return
    end
    local px = 1
    border.top:ClearAllPoints()
    border.top:SetPoint("TOPLEFT", frame, "TOPLEFT", -px, px)
    border.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", px, px)
    border.top:SetHeight(px)

    border.bottom:ClearAllPoints()
    border.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -px, -px)
    border.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", px, -px)
    border.bottom:SetHeight(px)

    border.left:ClearAllPoints()
    border.left:SetPoint("TOPLEFT", frame, "TOPLEFT", -px, px)
    border.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -px, -px)
    border.left:SetWidth(px)

    border.right:ClearAllPoints()
    border.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", px, px)
    border.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", px, -px)
    border.right:SetWidth(px)

    border.top:Show(); border.bottom:Show(); border.left:Show(); border.right:Show()
end

local function EnsureTicks(container)
    container = container or {}
    container.ticks = container.ticks or {}
    return container
end

local function ClearTicks(container)
    if not container or not container.ticks then return end
    for i=1, #container.ticks do
        container.ticks[i]:Hide()
    end
end

local function LayoutTicks(container, bar, count, alpha, show)
    container = EnsureTicks(container)
    ClearTicks(container)
    if not show then return end

    count = tonumber(count) or 20
    if count < 2 then return end
    alpha = tonumber(alpha) or 0.25
    if alpha < 0 then alpha = 0 end
    if alpha > 1 then alpha = 1 end

    local width = bar:GetWidth()
    if not width or width <= 0 then return end

    -- Prefer Blizzard's divider texture/coords when available so ticks look identical.
    local proto
    if _G then
        proto = _G.MainMenuXPBarDiv1 or _G.MainMenuExpBarDiv1 or _G.MainMenuXPBarDiv2 or _G.MainMenuExpBarDiv2
    end

    local texPath = "Interface\\MainMenuBar\\UI-XP-Bar"
    local coords
    local tickW, tickH = 9, 9

    if proto and proto.GetTexture then
        texPath = proto:GetTexture() or texPath
        if proto.GetTexCoord then
            coords = { proto:GetTexCoord() }
            if #coords < 4 then coords = nil end
        end
        if proto.GetWidth then tickW = math.floor((proto:GetWidth() or tickW) + 0.5) end
        if proto.GetHeight then tickH = math.floor((proto:GetHeight() or tickH) + 0.5) end
    end

    -- Interior dividers: count segments => (count-1) dividers
    local lines = count - 1

    -- Place each divider centered on its segment boundary, clamped so it never overhangs the bar.
    -- (Older clients can report widths slightly larger than the visible fill; clamping prevents ticks
    -- from extending past the right edge.)
    local step = width / count
    if step <= 0 then return end

    for i=1, lines do
        local tex = container.ticks[i]
        if not tex then
            tex = bar:CreateTexture(nil, "BACKGROUND")
            container.ticks[i] = tex
        end

        tex:SetTexture(texPath)
        if tex.SetDrawLayer then tex:SetDrawLayer("BACKGROUND") end
        if coords then
            tex:SetTexCoord(unpack(coords))
        else
            tex:SetTexCoord(0, 1, 0, 1)
        end

        tex:ClearAllPoints()

        local xCenter = step * i
        local left = math.floor((xCenter - (tickW / 2)) + 0.5)
        if left < 0 then left = 0 end
        local maxLeft = math.floor((width - tickW) + 0.5)
        if left > maxLeft then left = maxLeft end

        tex:SetPoint("TOPLEFT", bar, "TOPLEFT", left, -1)
        tex:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", left, 1)
        tex:SetWidth(tickW)
        tex:SetAlpha(alpha)
        tex:Show()
    end


end



local addonName, addon = ...

-- ------------------------------------------------------------
-- Profiles (lightweight, no AceDB required)
-- ------------------------------------------------------------
local function GetCharKey()
    local name = UnitName("player") or "Player"
    local realm = (GetRealmName and GetRealmName()) or "Realm"
    return name .. "-" .. realm
end

local function EnsureProfileTables()
    _G.TibbettsMultiBarDB = _G.TibbettsMultiBarDB or {}
    local sv = _G.TibbettsMultiBarDB
    sv.profiles = sv.profiles or {}
    sv.profileKeys = sv.profileKeys or {}
    if sv.useGlobalProfile == nil then sv.useGlobalProfile = true end
    if sv.globalProfileName == nil then sv.globalProfileName = "Default" end
    -- Ensure Default profile exists
    sv.profiles["Default"] = sv.profiles["Default"] or {}
    sv.profiles[sv.globalProfileName] = sv.profiles[sv.globalProfileName] or {}
    local ck = GetCharKey()
    if sv.useGlobalProfile then
        sv.profileKeys[ck] = sv.globalProfileName or "Default"
    else
        sv.profileKeys[ck] = sv.profileKeys[ck] or "Default"
        sv.profiles[sv.profileKeys[ck]] = sv.profiles[sv.profileKeys[ck]] or {}
    end
    return sv
end

function addon.GetProfileName()
    local sv = EnsureProfileTables()
    local ck = GetCharKey()
    return sv.profileKeys[ck] or "Default"
end

function addon.GetProfiles()
    local sv = EnsureProfileTables()
    local names = {}
    for name in pairs(sv.profiles) do names[#names+1] = name end
    table.sort(names, function(a,b) return tostring(a):lower() < tostring(b):lower() end)
    return names
end

function addon.SetUseGlobalProfile(enabled)
    local sv = EnsureProfileTables()
    sv.useGlobalProfile = enabled and true or false
    -- Rebind this character to Default when enabled
    if sv.useGlobalProfile then
        sv.profileKeys[GetCharKey()] = sv.globalProfileName or "Default"
    end
end

function addon.GetGlobalProfileName()
    local sv = EnsureProfileTables()
    return sv.globalProfileName or "Default"
end

function addon.SetGlobalProfileName(name)
    if not name or name == "" then return end
    local sv = EnsureProfileTables()
    sv.globalProfileName = name
    sv.profiles[name] = sv.profiles[name] or {}
    if sv.useGlobalProfile then
        sv.profileKeys[GetCharKey()] = name
    end
end


function addon.SetProfile(name)
    if not name or name == "" then return end
    local sv = EnsureProfileTables()
    sv.profiles[name] = sv.profiles[name] or {}
    sv.profileKeys[GetCharKey()] = name
end

function addon.CopyProfile(fromName, toName)
    if not fromName or not toName or fromName == "" or toName == "" then return end
    local sv = EnsureProfileTables()
    if not sv.profiles[fromName] then return end
    sv.profiles[toName] = {}
    for k,v in pairs(sv.profiles[fromName]) do
        if type(v) == "table" then
            local t = {}
            for kk,vv in pairs(v) do t[kk]=vv end
            sv.profiles[toName][k]=t
        else
            sv.profiles[toName][k]=v
        end
    end
end

function addon.DeleteProfile(name)
    if not name or name == "" or name == "Default" then return end
    local sv = EnsureProfileTables()
    sv.profiles[name] = nil
    -- Move any chars using it back to Default
    for ck,pn in pairs(sv.profileKeys) do
        if pn == name then sv.profileKeys[ck] = sv.globalProfileName or "Default" end
    end
end

function addon.GetDB()
    local sv = EnsureProfileTables()
    local pname = addon.GetProfileName()
    sv.profiles[pname] = sv.profiles[pname] or {}
    return sv.profiles[pname]
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

local function Clamp01(v)
    v = tonumber(v) or 0
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end



-- SavedVariables / Profiles (simple, no AceDB)
-- We keep compatibility with older TibbettsMultiBarDB by migrating it into TibbettsMultiBarSV on first run.
local function DeepCopy(src, dst)
    if type(src) ~= "table" then return src end
    dst = dst or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = DeepCopy(v, {})
        else
            dst[k] = v
        end
    end
    return dst
end

function addon.GetDB()
    -- New container SV
    if not _G.TibbettsMultiBarSV or type(_G.TibbettsMultiBarSV) ~= "table" then
        _G.TibbettsMultiBarSV = { current = "Default", profiles = {} }
    end
    local sv = _G.TibbettsMultiBarSV
    if not sv.profiles then sv.profiles = {} end
    if not sv.current or sv.current == "" then sv.current = "Default" end

    -- Migration from legacy flat TibbettsMultiBarDB (older builds)
    if _G.TibbettsMultiBarDB and type(_G.TibbettsMultiBarDB) == "table" and not sv.profiles["Default"] then
        sv.profiles["Default"] = DeepCopy(_G.TibbettsMultiBarDB, {})
    end

    if not sv.profiles["Default"] then
        sv.profiles["Default"] = {}
    end
    if not sv.profiles[sv.current] then
        sv.profiles[sv.current] = DeepCopy(sv.profiles["Default"], {})
    end

    -- Active profile table (global reference used everywhere else)
    _G.TibbettsMultiBarDB = sv.profiles[sv.current]
    _G.TibbettsMultiBarDB.profileName = sv.current
    return _G.TibbettsMultiBarDB, sv
end

local f = CreateFrame("Frame")
addon.frame = f

TibbettsMultiBarDB = TibbettsMultiBarDB or {}

local defaults = {
    hideBlizzard = true,
    width = 1024,
    repWidth = 1024,
    height = 18,
    scale = 1.0,
    repScale = 1,
    locked = false,
    clamp = true,
    point = "CENTER",
    relPoint = "CENTER",
    x = 0,
    y = 0,
    showText = true,
    texture = "Interface\\TARGETINGFRAME\\UI-StatusBar",
    repTexture = "Interface\\TARGETINGFRAME\\UI-StatusBar",
    font = "Fonts\\FRIZQT__.TTF",
    repFont = "Fonts\\FRIZQT__.TTF",
    fontSize = 12,
    repFontSize = 12,
    fontOutline = "OUTLINE",
    repFontOutline = "OUTLINE",
    textColor = { r = 1, g = 1, b = 1, a = 1 },
    textShadow = true,
    showBorder = false,
    showTicks = false,
    tickCount = 20,
    tickAlpha = 0.25,

    textShadowColor = { r = 0, g = 0, b = 0, a = 0.9 },
    textShadowOffset = 1,
    mouseoverFade = false,
    fadeAlpha = 0.25,
    hideInCombat = false,
    pixelSnap = true,
    barColor = { r = 0.0, g = 0.6, b = 1.0, a = 1.0 },
    repBarColor = nil, -- nil = follow XP bar color
    bgAlpha = 0.5,
    repBgAlpha = 0.5,
    bgColor = { r = 0, g = 0, b = 0, a = 0.5 },
    showRested = true,
    showRep = true,
    repSnap = true,
    repLocked = false,
    repAbove = false,
    repGap = 2,
    repX = 0,
    repY = -120,
    repPoint = "CENTER",
    repRelPoint = "CENTER",

    autoRepAtMax = true,
    repHeight = 6,
    repColor = { r = 0, g = 0.8, b = 0.2, a = 1 },
    restedColor = { r = 0.6, g = 0.0, b = 1.0, a = 0.6 },
}

local function ApplyDefaultsTo(db)
    if type(db) ~= "table" then return end

    for k, v in pairs(defaults) do
        local cur = db[k]

        if cur == nil then
            if type(v) == "table" then
                db[k] = DeepCopy(v, {})
            else
                db[k] = v
            end
        elseif type(v) == "table" then
            if type(cur) ~= "table" then
                db[k] = DeepCopy(v, {})
            else
                for kk, vv in pairs(v) do
                    if cur[kk] == nil then
                        cur[kk] = vv
                    end
                end
            end
        end
    end

local function EnsureDB()
    _G.TibbettsMultiBarDB = _G.TibbettsMultiBarDB or {}
    ApplyDefaultsTo(_G.TibbettsMultiBarDB)
end

end




local function EnsureDB()
    _G.TibbettsMultiBarDB = _G.TibbettsMultiBarDB or {}
    -- Ensure root defaults for profile bookkeeping
    if ApplyDefaultsTo then ApplyDefaultsTo(_G.TibbettsMultiBarDB) end

    -- Prefer active profile DB if available
    local db = (_G.addon and _G.addon.GetDB and _G.addon.GetDB()) or (addon and addon.GetDB and addon.GetDB()) or _G.TibbettsMultiBarDB
    ApplyDefaultsTo(db)
    return db
end

function addon:SaveXPPosition()
    local db = EnsureDB()
    if not self.bar or not self.bar.GetPoint then return end
    local point, _, relPoint, x, y = self.bar:GetPoint(1)
    if not point then return end
    db.point = point
    db.relPoint = relPoint or point
    db.x = x or 0
    db.y = y or 0
end

function addon:SaveRepPosition()
    local db = EnsureDB()
    if not self.repFrame or not self.repFrame.GetPoint then return end
    local point, _, relPoint, x, y = self.repFrame:GetPoint(1)
    if not point then return end
    db.repPoint = point
    db.repRelPoint = relPoint or point
    db.repX = x or 0
    db.repY = y or 0
end



--=========================================================
-- XP bar frame
--=========================================================
local bar = CreateFrame("StatusBar", "TibbettsMultiBarFrame", UIParent)
bar:SetFrameStrata("MEDIUM")
bar:SetFrameLevel(10)
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)

bar.bg = bar:CreateTexture(nil, "BACKGROUND")
bar.bg:SetAllPoints(true)

local rested = CreateFrame("StatusBar", nil, bar)
rested:SetAllPoints(true)
rested:SetFrameLevel(bar:GetFrameLevel() + 1)
rested:SetMinMaxValues(0, 1)
rested:SetValue(0)
bar.rested = rested

local txt = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
txt:SetPoint("CENTER", bar, "CENTER", 0, 0)
txt:SetJustifyH("CENTER")
txt:SetJustifyV("MIDDLE")
bar.text = txt

addon.bar = bar

-- Compatibility alias
local xpBar = bar

-- Reputation frame (can be snapped to XP bar or detached)
local repFrame = CreateFrame("Frame", "TibbettsMultiBarRepFrame", UIParent)
repFrame:SetFrameStrata("LOW")
repFrame:SetClampedToScreen(true)
repFrame:EnableMouse(true)
repFrame:RegisterForDrag("LeftButton")
repFrame:SetScript("OnDragStart", function(self)
    local db = EnsureDB()
    if db.repSnap then return end
    if db.locked or db.repLocked then return end
    self:StartMoving()
end)
repFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
        addon:SaveRepPosition()
        addon:SaveXPPosition()
    local db = EnsureDB()
    if db.repSnap then return end
    local p, _, rp, x, y = self:GetPoint(1)
    db.repPoint = p or "CENTER"
    db.repRelPoint = rp or "CENTER"
    db.repX = math.floor((x or 0) + 0.5)
    db.repY = math.floor((y or 0) + 0.5)
end)
repFrame:Hide()

local repBar = CreateFrame("StatusBar", "TibbettsMultiBarRepBar", repFrame)
repBar:SetAllPoints(true)
repBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
repBar:SetMinMaxValues(0, 1)
-- Rep bar size / texture / font (separate from XP, with fallbacks)
local db = EnsureDB()
repBar:SetWidth(db.repWidth or db.width or 1024)
repFrame:SetScale(db.repScale or db.scale or 1)

local repTex = db.repTexture or db.texture or "Interface\\TARGETINGFRAME\\UI-StatusBar"
if repBar.SetStatusBarTexture then
    repBar:SetStatusBarTexture(repTex)
elseif repBar.SetStatusBarTextureFile then
    repBar:SetStatusBarTextureFile(repTex)
end

local repFontPath = db.repFont or db.font or "Fonts\\FRIZQT__.TTF"
local repFontSize = db.repFontSize or db.fontSize or 12
local repOutline = db.repFontOutline or db.fontOutline or "OUTLINE"
if repText and repText.SetFont then
    repText:SetFont(repFontPath, repFontSize, repOutline)
end

if type(db.repTextColor) ~= "table" then db.repTextColor = {} end
if db.repTextColor.r == nil then db.repTextColor.r = (db.textColor and db.textColor.r) or 1 end
if db.repTextColor.g == nil then db.repTextColor.g = (db.textColor and db.textColor.g) or 1 end
if db.repTextColor.b == nil then db.repTextColor.b = (db.textColor and db.textColor.b) or 1 end
if db.repTextColor.a == nil then db.repTextColor.a = (db.textColor and db.textColor.a) or 1 end
if repText and repText.SetTextColor then
    repText:SetTextColor(db.repTextColor.r, db.repTextColor.g, db.repTextColor.b, db.repTextColor.a)
end

if repBar.bg then
    local bgc = db.repBgColor or db.bgColor or {r=0,g=0,b=0,a=1}
    local a = db.repBgAlpha or db.bgAlpha or 0.5
    SetSolidColor(repBar.bg, bgc.r or 0, bgc.g or 0, bgc.b or 0, a)
end

repBar:SetValue(0)

repBar.bg = repBar:CreateTexture(nil, "BACKGROUND")
repBar.bg:SetAllPoints(true)

local repText = repBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
repText:SetPoint("CENTER", repBar, "CENTER", 0, 0)
repText:SetJustifyH("CENTER")
repText:SetJustifyV("MIDDLE")

-- Border + tick containers
bar._border = CreateBorderTextures(bar)
    bar._snapSeparator = bar:CreateTexture(nil, "OVERLAY")
    bar._snapSeparator:SetTexture("Interface\\Buttons\\WHITE8x8")
    bar._snapSeparator:SetVertexColor(0,0,0,1)
    bar._snapSeparator:Hide()
repBar._border = CreateBorderTextures(repBar)
bar._ticks = EnsureTicks(bar._ticks)
repBar._ticks = EnsureTicks(repBar._ticks)

-- Expose for config/debug
addon.repFrame = repFrame
addon.repBar = repBar



local function ShowBlizzardXP()
    if not MainMenuExpBar then return end
    MainMenuExpBar:SetAlpha(1)
    MainMenuExpBar:Show()
end

local function UpdateBar()
    local max = UnitXPMax("player") or 0
    local cur = UnitXP("player") or 0
    if max <= 0 then
        bar:Hide()
        return
    end
    bar:Show()
    bar:SetMinMaxValues(0, max)
    bar:SetValue(cur)
    if TibbettsMultiBarDB.showText then
        local pct = math.floor((cur / max) * 100 + 0.5)
        bar.text:SetText(cur .. " / " .. max .. " (" .. pct .. "%)")
        bar.text:Show()
    else
        bar.text:Hide()
    end
end

local function SavePosition()
    local p, relTo, rp, x, y = bar:GetPoint(1)
    if relTo ~= UIParent then
        -- Normalize relative frame
        p, relTo, rp, x, y = "BOTTOM", UIParent, "BOTTOM", TibbettsMultiBarDB.x or 0, TibbettsMultiBarDB.y or 40
    end
    TibbettsMultiBarDB.point = p or "BOTTOM"
    TibbettsMultiBarDB.relPoint = rp or TibbettsMultiBarDB.point
    TibbettsMultiBarDB.x = x or 0
    TibbettsMultiBarDB.y = y or 0
    addon._lastXPPos = { point = TibbettsMultiBarDB.point, relPoint = TibbettsMultiBarDB.relPoint, x = TibbettsMultiBarDB.x, y = TibbettsMultiBarDB.y }
end

local function ConfigureDragging()
    bar:SetMovable(true)
    bar:SetClampedToScreen(TibbettsMultiBarDB.clamp and true or false)

    if TibbettsMultiBarDB.locked then
        bar:EnableMouse(false)
        bar:RegisterForDrag() -- clears drag registrations
        bar:SetScript("OnDragStart", nil)
        bar:SetScript("OnDragStop", nil)
        return
    end

    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function()
        if TibbettsMultiBarDB.locked then return end
        bar:StartMoving()
    end)
    bar:SetScript("OnDragStop", function()
        bar:StopMovingOrSizing()
        SavePosition()
        if addon.RefreshConfig then addon.RefreshConfig() end
    end)
end


local function ConfigureRepDragging()
    local db = (addon and addon.GetDB and addon.GetDB()) or (TibbettsMultiBarDB or {})
    if not addon.repFrame then return end
    local rf = addon.repFrame

    -- Only draggable when detached
    if db.repSnap ~= false then
        rf:EnableMouse(false)
        rf:RegisterForDrag()
        rf:SetScript("OnDragStart", nil)
        rf:SetScript("OnDragStop", nil)
        return
    end

    rf:SetMovable(true)
    rf:SetClampedToScreen(db.clamp and true or false)

    if db.locked then
        rf:EnableMouse(false)
        rf:RegisterForDrag()
        rf:SetScript("OnDragStart", nil)
        rf:SetScript("OnDragStop", nil)
        return
    end

    rf:EnableMouse(true)
    rf:RegisterForDrag("LeftButton")
    rf:SetScript("OnDragStart", function()
        if TibbettsMultiBarDB.locked then return end
        rf:StartMoving()
    end)
    rf:SetScript("OnDragStop", function()
        rf:StopMovingOrSizing()
        local x, y = rf:GetCenter()
        local ux, uy = UIParent:GetCenter()
        if x and y and ux and uy then
            TibbettsMultiBarDB.repX = math.floor((x-ux) + 0.5)
            TibbettsMultiBarDB.repY = math.floor((y-uy) + 0.5)
        end
    end)
end


function addon.UpdateDragState()
    ConfigureDragging()
end

function addon.ApplyPosition()
    bar:ClearAllPoints()
    bar:SetPoint(TibbettsMultiBarDB.point, UIParent, TibbettsMultiBarDB.relPoint, TibbettsMultiBarDB.x, TibbettsMultiBarDB.y)
end


function addon.ApplyVisibility()
    if not bar then return end
    if TibbettsMultiBarDB.hideInCombat and InCombatLockdown and InCombatLockdown() then
        bar:Hide()
    else
        if TibbettsMultiBarDB.enabled == false then
            bar:Hide()
        else
            bar:Show()
        end
    end
end

local function ApplyFadeState(hovered)
    if not bar then return end
    if TibbettsMultiBarDB.enabled == false then return end
    if TibbettsMultiBarDB.mouseoverFade then
        if hovered then
            bar:SetAlpha(1)
        else
            local a = tonumber(TibbettsMultiBarDB.fadeAlpha) or 0.25
            if a < 0 then a = 0 end
            if a > 1 then a = 1 end
            bar:SetAlpha(a)
        end
    else
        bar:SetAlpha(1)
    end
end

function addon.UpdateFadeHandlers()
    if not bar then return end
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function() ApplyFadeState(true) end)
    bar:SetScript("OnLeave", function() ApplyFadeState(false) end)
    ApplyFadeState(false)
end


local function FormatRepText(name, cur, maxv)
    if not name then return "" end
    if not maxv or maxv == 0 then return name end
    local pct = (cur / maxv) * 100
    return string.format("%s: %d/%d (%.1f%%)", name, cur, maxv, pct)
end

function addon.UpdateReputation()
    if not bar or not repBar then return end
    local db = (addon and addon.GetDB and addon.GetDB()) or (TibbettsMultiBarDB or {})
    local show = db.showRep ~= false

    local atMax = false
    if UnitLevel and GetMaxPlayerLevel then
        atMax = (UnitLevel("player") >= GetMaxPlayerLevel())
    end

    local showOnlyRep = (db.autoRepAtMax ~= false) and atMax

    -- Watched faction API compatibility (Retail/Modern Classic may not have GetWatchedFactionInfo)
local name, barMin, barMax, barValue
do
    local f = _G.GetWatchedFactionInfo
    if type(f) == "function" then
        local ok, n, _, mn, mx, val = pcall(f)
        if ok then
            name = n
            barMin, barMax, barValue = mn, mx, val
        end
    end

    -- Newer API (Retail + some modern Classic branches)
    if not name and _G.C_Reputation then
        local crep = _G.C_Reputation
        if type(crep.GetWatchedFactionData) == "function" then
            local data = crep.GetWatchedFactionData()
            if data then
                name = data.name
                barMin = data.currentReactionThreshold
                barMax = data.nextReactionThreshold
                barValue = data.currentStanding or data.reaction
            end
        elseif type(crep.GetWatchedFactionInfo) == "function" then
            local data = crep.GetWatchedFactionInfo()
            if data then
                name = data.name
                barMin = data.currentReactionThreshold
                barMax = data.nextReactionThreshold
                barValue = data.currentStanding or data.reaction
            end
        end
    end
end

    if not show or not name then
        repBar:Hide()
        if TibbettsMultiBarDB and TibbettsMultiBarDB.repSnap == false then repFrame:Hide() end
        return
    end

    local cur = (barValue or 0) - (barMin or 0)
    local maxv = (barMax or 0) - (barMin or 0)
    if maxv <= 0 then maxv = 1 end

    repBar:SetMinMaxValues(0, maxv)
    repBar:SetValue(cur)
    repBar:Show()

    -- Apply user rep color
    if type(db.repColor) == "table" then
        local c = db.repColor
        repBar:SetStatusBarColor(tonumber(c.r) or 0, tonumber(c.g) or 0.8, tonumber(c.b) or 0.2, tonumber(c.a) or 1)
    end
    if TibbettsMultiBarDB and TibbettsMultiBarDB.repSnap == false then repFrame:Show() end

    if db.showText then
        repText:SetText(FormatRepText(name, cur, maxv))
        repText:Show()
    else
        repText:SetText("")
        repText:Hide()
    end

    -- Optionally hide XP bar when at max level
    if xpBar then
        if showOnlyRep then
            xpBar:Hide()
        else
            xpBar:Show()
        end
    end
end


function addon.LayoutBars()
    local db = EnsureDB()
    local gap = tonumber(db.repGap) or 2
    if gap < 0 then gap = 0 end

    -- If rep not enabled, hide + separator off
    if not db.showRep then
        repFrame:Hide()
        if bar._snapSeparator then bar._snapSeparator:Hide() end
        return
    end

    -- Always keep repBar inside repFrame (simple + stable)
    if repBar:GetParent() ~= repFrame then repBar:SetParent(repFrame) end
    repBar:ClearAllPoints()
    repBar:SetAllPoints(repFrame)

    if db.repSnap then
        -- snapped: repFrame is positioned relative to XP bar (no XP movement)
        repFrame:Show()
        repFrame:EnableMouse(false)

        repFrame:ClearAllPoints()
        if db.repAbove then
            repFrame:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, gap)
            repFrame:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, gap)
        else
            repFrame:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -gap)
            repFrame:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -gap)
        end

        -- keep snapped widths aligned
        repFrame:SetWidth(bar:GetWidth())

        -- 1px separator between bars (optional)
        if bar._snapSeparator and (db.showSnapSeparator ~= false) then
            bar._snapSeparator:Show()
            bar._snapSeparator:ClearAllPoints()
            bar._snapSeparator:SetHeight(1)
            bar._snapSeparator:SetWidth(bar:GetWidth())
            if db.repAbove then
                bar._snapSeparator:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
                bar._snapSeparator:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
            else
                bar._snapSeparator:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
                bar._snapSeparator:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
            end
            local c = db.snapSeparatorColor or {r=0,g=0,b=0,a=1}
            bar._snapSeparator:SetVertexColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
        elseif bar._snapSeparator then
            bar._snapSeparator:Hide()
        end
    else
        -- detached: repFrame is its own draggable bar
        repFrame:Show()
        repFrame:EnableMouse(true)

        repFrame:ClearAllPoints()
        repFrame:SetPoint(db.repPoint or "CENTER", UIParent, db.repRelPoint or "CENTER", db.repX or 0, db.repY or 0)

        if bar._snapSeparator then bar._snapSeparator:Hide() end
    end
end


local function UpdateBorderAndTicks(frame, db)
    if not frame then return end

    -- 1px border (TOP/BOTTOM/LEFT/RIGHT)
    frame._border = frame._border or {}
    local b = frame._border

    local function ensureTex(key)
        if b[key] then return b[key] end
        local t = frame:CreateTexture(nil, "BORDER")
        SetSolidColor(t, 0, 0, 0, 1)
        b[key] = t
        return t
    end

    if db.showBorder then
        local top = ensureTex("top")
        top:ClearAllPoints(); top:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1); top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1); top:SetHeight(1); top:Show()

        local bottom = ensureTex("bottom")
        bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1); bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1); bottom:SetHeight(1); bottom:Show()

        local left = ensureTex("left")
        left:ClearAllPoints(); left:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1); left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1); left:SetWidth(1); left:Show()

        local right = ensureTex("right")
        right:ClearAllPoints(); right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1); right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1); right:SetWidth(1); right:Show()
    else
        for _, t in pairs(b) do if t then t:Hide() end end
    end

    -- Vertical tick marks
    frame._ticks = frame._ticks or {}
    local ticks = frame._ticks

    local count = tonumber(db.tickCount) or 20
    if count < 2 then count = 2 end

    -- Tick hover tooltips (optional)
    frame._tickButtons = frame._tickButtons or {}
    local tickButtons = frame._tickButtons
    local hover = db.tickHoverNumbers and true or false

    if db.showTicks then
        for i = 1, count - 1 do
            local t = ticks[i]
            if not t then
                t = frame:CreateTexture(nil, "OVERLAY")
                SetSolidColor(t, 0, 0, 0, 1)
                ticks[i] = t
            end

            t:ClearAllPoints()
            t:SetWidth(1)
            t:SetPoint("TOP", frame, "TOP", 0, 0)
            t:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)

            local x = (frame:GetWidth() or 0) * (i / count)
            t:SetPoint("LEFT", frame, "LEFT", x, 0)
            t:SetAlpha(tonumber(db.tickAlpha) or 0.25)
            t:Show()

            -- Optional hover tooltip showing the percentage for this divider
            local btn = tickButtons[i]
            if hover then
                if not btn then
                    btn = CreateFrame("Button", nil, frame)
                    tickButtons[i] = btn
                    btn:SetFrameStrata(frame:GetFrameStrata() or "MEDIUM")
                    btn:SetFrameLevel((frame:GetFrameLevel() or 0) + 10)
                    btn:RegisterForClicks("AnyUp")
                    btn:SetScript("OnEnter", function(self)
                        if not self._percent then return end
                        GameTooltip:SetOwner(self, "ANCHOR_TOP")
                        GameTooltip:SetText(string.format("%d%%", self._percent), 1, 1, 1)
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function()
                        if GameTooltip then GameTooltip:Hide() end
                    end)
                end

                btn:ClearAllPoints()
                -- Give a wider hitbox than the 1px line so it's easy to hover/click.
                btn:SetPoint("TOP", frame, "TOP", 0, 0)
                btn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
                btn:SetWidth(12)
                btn:SetPoint("CENTER", frame, "LEFT", x, 0)
                btn:EnableMouse(true)
                btn._percent = math.floor(((i / count) * 100) + 0.5)
                btn:Show()
            elseif btn then
                btn:Hide()
                btn:EnableMouse(false)
            end
        end

        for i = count, #ticks do
            if ticks[i] then ticks[i]:Hide() end
            if tickButtons[i] then tickButtons[i]:Hide() end
        end
    else
        for i = 1, #ticks do
            if ticks[i] then ticks[i]:Hide() end
            if tickButtons[i] then tickButtons[i]:Hide() end
        end
    end
end


function addon.ApplySettings()
    local db = EnsureDB()

    -- Tick preset (cross-client): derive showTicks/tickCount deterministically.
    if db.tickPreset then
        if db.tickPreset == "none" then
            db.showTicks = false
        elseif db.tickPreset == "20" then
            db.showTicks = true
            db.tickCount = 5
        else
            -- default: every 10%
            db.showTicks = true
            db.tickCount = 10
        end
    end
-- When locked, treat the current on-screen position as authoritative.
-- This prevents Options actions (Show Rep / Snap Rep / At Max Level) from snapping XP to stale fallback coords.
if db.locked and addon.bar and addon.bar.GetPoint then
    local p, _, rp, x, y = addon.bar:GetPoint(1)
    if p then
        db.point = p
        db.relPoint = rp or p
        db.x = x or db.x or 0
        db.y = y or db.y or 0
    end
end


-- Link XP and Reputation appearance settings (cross-client safe).
-- TBC/Classic users often want the two bars to match exactly.
if db.linkBars == nil then db.linkBars = true end
if db.linkBars then

-- Keep Reputation position/locking in sync with XP (lockstep).
db.repLocked   = db.locked
db.repPoint    = db.point
db.repRelPoint = db.relPoint
db.repX        = db.x
-- Keep Rep stacked above/below XP using repAbove + repGap (do NOT hard-link repY).
local gap = tonumber(db.repGap) or 2
local sep = ((tonumber(db.height) or 8) + gap) * (tonumber(db.scale) or 1)
if db.repAbove then
    db.repY = db.y + sep
else
    db.repY = db.y - sep
end
db.repClamp    = db.clamp
db.repSnap     = db.pixelSnap
    -- Keep Reputation appearance in sync with XP appearance.
    db.repTexture     = db.texture
    db.repTextureName = db.textureName
    db.repFont        = db.font
    db.repFontName    = db.fontName
    db.repFontSize    = db.fontSize
    db.repFontOutline = db.fontOutline

    db.repColor       = db.barColor
    db.repBgColor     = db.bgColor
    db.repBgAlpha     = db.bgAlpha
    db.repTextColor   = db.textColor

    db.repShowBorder  = db.showBorder

    db.repShowTicks   = db.showTicks
    db.repTickCount   = db.tickCount
    db.repTickAlpha   = db.tickAlpha

    db.repWidth       = db.width
    db.repHeight      = db.height
    db.repScale       = db.scale
end

    if not bar then return end

    -- Hide/show Blizzard XP bar safely
    do
        local hide = db.hideBlizzard and true or false
        if _G.MainMenuExpBar then
            if hide then _G.MainMenuExpBar:Hide() else _G.MainMenuExpBar:Show() end
        end
        if _G.ExhaustionTick then
            if hide then _G.ExhaustionTick:Hide() else _G.ExhaustionTick:Show() end
        end
        if _G.ExhaustionLevelFillBar then
            if hide then _G.ExhaustionLevelFillBar:Hide() else _G.ExhaustionLevelFillBar:Show() end
        end
    end

    -- XP frame position/size
    -- If SavedVariables contain a stale fallback position (commonly BOTTOM/BOTTOM 0,0),
    -- but the bar is currently placed somewhere else (e.g. centered), adopt the current
    -- anchor so opening Options / toggling rep settings doesn't snap the XP bar.
    local curP, curRelTo, curRP, curX, curY = bar:GetPoint(1)
    if curRelTo == UIParent and curP then
        local dx = tonumber(db.x) or 0
        local dy = tonumber(db.y) or 0
        if (db.point == nil) or (db.relPoint == nil) or (db.point == 'BOTTOM' and (db.relPoint == 'BOTTOM' or db.relPoint == nil) and dx == 0 and dy == 0) then
            db.point = curP
            db.relPoint = curRP or curP
            db.x = math.floor((curX or 0) + 0.5)
            db.y = math.floor((curY or 0) + 0.5)
            addon._lastXPPos = { point = db.point, relPoint = db.relPoint, x = db.x, y = db.y }
        end
    end
    bar:ClearAllPoints()
    local p = db.point or "CENTER"
    local rp = db.relPoint or p
    local x = tonumber(db.x) or 0
    local y = tonumber(db.y) or 0
    if addon._lastXPPos and p == "BOTTOM" and rp == "BOTTOM" and x == 0 and y == 0 then
        p = addon._lastXPPos.point or p
        rp = addon._lastXPPos.relPoint or rp
        x = tonumber(addon._lastXPPos.x) or x
        y = tonumber(addon._lastXPPos.y) or y
    end
    bar:SetPoint(p, UIParent, rp, x, y)
    bar:SetScale(tonumber(db.scale) or 1)
    bar:SetWidth(tonumber(db.width) or 1024)
    bar:SetHeight(tonumber(db.height) or 18)

    -- Texture
    local tex = db.texture or "Interface\\TARGETINGFRAME\\UI-StatusBar"
    bar:SetStatusBarTexture(tex)
    if bar.bg then
        local bgc = db.bgColor
        local a = tonumber(db.bgAlpha)
        if a == nil then a = (type(bgc)=="table" and tonumber(bgc.a)) or 0.5 end
        if type(bgc) == "table" then
            SetSolidColor(bar.bg, tonumber(bgc.r) or 0, tonumber(bgc.g) or 0, tonumber(bgc.b) or 0, a)
        else
            SetSolidColor(bar.bg, 0,0,0,a)
        end
    end

    -- Colors
    if type(db.barColor) == "table" then
        bar:SetStatusBarColor(tonumber(db.barColor.r) or 0.58, tonumber(db.barColor.g) or 0.0, tonumber(db.barColor.b) or 0.55, tonumber(db.barColor.a) or 1)
    end
    if bar.rested then
        bar.rested:SetStatusBarTexture(tex)
        if type(db.restedColor) == "table" then
            bar.rested:SetStatusBarColor(tonumber(db.restedColor.r) or 0.0, tonumber(db.restedColor.g) or 0.39, tonumber(db.restedColor.b) or 0.88, tonumber(db.restedColor.a) or 0.6)
        end
        bar.rested:SetShown(db.showRested and true or false)
    end

    -- Text
    if bar.text then
        local showText = db.showText and true or false
        bar.text:SetShown(showText)
        local fontPath = db.font or "Fonts\\FRIZQT__.TTF"
        local fontSize = tonumber(db.fontSize) or 12
        local outline = db.fontOutline or "OUTLINE"
        bar.text:SetFont(fontPath, fontSize, outline)

        if type(db.textColor) == "table" then
            bar.text:SetTextColor(tonumber(db.textColor.r) or 1, tonumber(db.textColor.g) or 1, tonumber(db.textColor.b) or 1, tonumber(db.textColor.a) or 1)
        else
            bar.text:SetTextColor(1,1,1,1)
        end

        if db.textShadow then
            local sc = db.textShadowColor or {r=0,g=0,b=0,a=1}
            local off = tonumber(db.textShadowOffset) or 1
            bar.text:SetShadowColor(tonumber(sc.r) or 0, tonumber(sc.g) or 0, tonumber(sc.b) or 0, tonumber(sc.a) or 1)
            bar.text:SetShadowOffset(off, -off)
        else
            bar.text:SetShadowColor(0,0,0,0)
            bar.text:SetShadowOffset(0,0)
        end
    end

    -- Borders / ticks
    UpdateBorderAndTicks(bar, db, false)
    -- Rep bar
    local wantRep = db.showRep and true or false
    if wantRep then
        -- Ensure rep frame/bar
        if not addon.repFrame then
            addon.repFrame = CreateFrame("Frame", "TibbettsMultiBarRepFrame", UIParent)
        end
        if not addon.repBar then
            addon.repBar = CreateFrame("StatusBar", "TibbettsMultiBarRepBar", addon.repFrame)
            addon.repBar:SetAllPoints(true)
            addon.repBar.bg = addon.repBar:CreateTexture(nil, "BACKGROUND")
            addon.repBar.bg:SetAllPoints(true)
            addon.repBar.text = addon.repBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            addon.repBar.text:SetPoint("CENTER", addon.repBar, "CENTER", 0, 0)
        end

        local rf = addon.repFrame
        local rb = addon.repBar

        -- Size/scale (separate from XP if desired)
        local repScale = tonumber(db.repScale) or tonumber(db.scale) or 1
        local repWidth = tonumber(db.repWidth) or tonumber(db.width) or 1024
        local repHeight = tonumber(db.repHeight) or math.max(6, math.floor((tonumber(db.height) or 18) * 0.35))

        rf:SetScale(repScale)
        rf:SetWidth(repWidth)
        rf:SetHeight(repHeight)

        rb:SetStatusBarTexture(db.repTexture or db.texture or "Interface\TARGETINGFRAME\UI-StatusBar")
        rb:SetWidth(repWidth)
        rb:SetHeight(repHeight)

        -- Rep colors
        local rc = (type(db.repColor)=="table") and db.repColor or {r=0,g=0.7,b=0.1,a=1}
        rb:SetStatusBarColor(tonumber(rc.r) or 0, tonumber(rc.g) or 0.7, tonumber(rc.b) or 0.1, tonumber(rc.a) or 1)

        -- Rep background
        if rb.bg then
            local bgc = (type(db.repBgColor)=="table") and db.repBgColor or (type(db.bgColor)=="table" and db.bgColor) or {r=0,g=0,b=0,a=1}
            local a = tonumber(db.repBgAlpha)
            if a == nil then a = tonumber(db.bgAlpha) end
            if a == nil then a = tonumber(bgc.a) end
            if a == nil then a = 0.5 end
            a = Clamp01(a)
            SetSolidColor(rb.bg, tonumber(bgc.r) or 0, tonumber(bgc.g) or 0, tonumber(bgc.b) or 0, a)
        end

        -- Rep text styling
        if rb.text then
            local fontPath = db.repFont or db.font or "Fonts\FRIZQT__.TTF"
            local fontSize = tonumber(db.repFontSize) or tonumber(db.fontSize) or 12
            local outline = db.repFontOutline or db.fontOutline or "OUTLINE"
            rb.text:SetFont(fontPath, fontSize, outline)

            local tc = (type(db.repTextColor)=="table") and db.repTextColor or (type(db.textColor)=="table" and db.textColor) or {r=1,g=1,b=1,a=1}
            rb.text:SetTextColor(tonumber(tc.r) or 1, tonumber(tc.g) or 1, tonumber(tc.b) or 1, tonumber(tc.a) or 1)

            if db.repTextShadow == nil then db.repTextShadow = db.textShadow end
            if db.repTextShadow then
                local sc = (type(db.repTextShadowColor)=="table") and db.repTextShadowColor or db.textShadowColor or {r=0,g=0,b=0,a=1}
                local off = tonumber(db.repTextShadowOffset) or tonumber(db.textShadowOffset) or 1
                rb.text:SetShadowColor(tonumber(sc.r) or 0, tonumber(sc.g) or 0, tonumber(sc.b) or 0, tonumber(sc.a) or 1)
                rb.text:SetShadowOffset(off, -off)
            else
                rb.text:SetShadowColor(0,0,0,0)
                rb.text:SetShadowOffset(0,0)
            end
        end

        -- Positioning
        addon.LayoutBars()

        -- Rep border / ticks (separate toggles)
        if db.repShowBorder == nil then db.repShowBorder = db.showBorder end

        -- Keep Reputation ticks identical to XP ticks so the bars match visually.
        -- (Older profiles may have separate repTickCount/repShowTicks values; we intentionally mirror XP here.)
        db.repShowTicks = db.showTicks and true or false
        db.repTickCount = tonumber(db.tickCount) or 10
        db.repTickAlpha = tonumber(db.tickAlpha) or 0.25

        UpdateBorderAndTicks(rb, {showBorder=db.repShowBorder, showTicks=db.repShowTicks, tickCount=db.repTickCount, tickAlpha=db.repTickAlpha, pixelSnap=db.pixelSnap})

        -- Update rep value (API varies by client)
        if addon.UpdateReputation then
            addon.UpdateReputation()
        end
    else
        if addon.repFrame then addon.repFrame:Hide() end
        if bar and bar._snapSeparator then bar._snapSeparator:Hide() end
    end

    ConfigureRepDragging()

    ConfigureDragging()
    UpdateBar()

    -- Ensure border/ticks refresh immediately (not only on resize).
    LayoutBorderTextures(bar._border, bar, db.showBorder and true or false)
    LayoutTicks(bar._ticks, bar, db.tickCount, db.tickAlpha or 0.25, db.showTicks and true or false)
    if addon.repBar then
        -- Rep can have its own toggles/values; fall back to XP settings if unset
        local repShow = db.showTicks and true or false
        local repCount = tonumber(db.tickCount) or 10
        local repAlpha = tonumber(db.tickAlpha) or 0.25
        LayoutBorderTextures(addon.repBar._border, addon.repBar, (db.repShowBorder ~= nil) and (db.repShowBorder and true or false) or (db.showBorder and true or false))
        LayoutTicks(addon.repBar._ticks, addon.repBar, repCount, repAlpha, repShow)
    end
end


f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("UPDATE_EXHAUSTION")
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        EnsureDB()
        addon.ApplySettings()
    else
        UpdateBar()
    end
end)

-------------------------------------------------
-- Profile safety
-------------------------------------------------
local function EnsureProfileExists(store, name)
    if store and store.profiles then
        if store.profiles[name] then return name end
        if store.profiles["Default"] then return "Default" end
        for k in pairs(store.profiles) do return k end
    end
    return nil
end

--=========================================================
-- Setup Export / Import (profile + bindings)
--=========================================================
function addon:ExportSetupString()
    local store, mode = GetActiveStore()
    store = EnsureStore(store)
    local cur = store.current or "Default"
    local payload = {
        v = 1,
        mode = mode,
        current = cur,
        profile = store.profiles[cur] or {},
        bindings = store.bindings or { char = {}, spec = {} },
        autoProfileChar = store.autoProfileChar and true or false,
        autoProfileSpec = store.autoProfileSpec and true or false,
    }
    return "XPMBS1:" .. SerializeValue(payload)
end

function addon:ImportSetupString(str, applyBindings, overwriteProfile)
    if type(str) ~= "string" then return false, "No import string." end
    if not str:match("^XPMBS1:") then return false, "Invalid setup string." end
    if IsDangerousImportString(str) then return false, "Import rejected (unsafe content)." end

    local payload = str:gsub("^XPMBS1:", "")
    local fn = loadstring and loadstring("return " .. payload) or load("return " .. payload)
    if type(fn) ~= "function" then return false, "Import failed (parse error)." end

    local ok, tbl = pcall(fn)
    if not ok or type(tbl) ~= "table" then return false, "Import failed (bad data)." end
    if type(tbl.profile) ~= "table" then return false, "Import failed (missing profile)." end
    local name = tostring(tbl.current or "Imported")

    local store = GetActiveStore()
    store = EnsureStore(store)

    if store.profiles[name] and not overwriteProfile then
        -- make a unique name
        local base = name
        local i = 2
        while store.profiles[name] do
            name = base .. " " .. i
            i = i + 1
        end
    end

    store.profiles[name] = DeepCopy(tbl.profile, {})
    store.current = name

    if applyBindings then
        if type(tbl.bindings) == "table" then
            store.bindings = store.bindings or { char = {}, spec = {} }
            store.bindings.char = tbl.bindings.char or store.bindings.char or {}
            store.bindings.spec = tbl.bindings.spec or store.bindings.spec or {}
        end
        store.autoProfileChar = tbl.autoProfileChar and true or false
        store.autoProfileSpec = tbl.autoProfileSpec and true or false
    end

    ActivateProfile(name)
    addon:CleanBindings()
    return true
end

function addon:CopyStringToChat(s, prefix)
    if type(s) ~= "string" or s == "" then return end
    local chat = DEFAULT_CHAT_FRAME
    if not chat or type(chat.AddMessage) ~= "function" then return end

    local maxLen = 240
    local total = math.ceil(#s / maxLen)
    if total > 1 then
        chat:AddMessage((prefix or "TibbettsMultiBar") .. ": message will be split into " .. total .. " parts.")
    end
    local i = 1
    local part = 1
    while i <= #s do
        local chunk = s:sub(i, i + maxLen - 1)
        local tag = (total > 1) and ("["..part.."/"..total.."] ") or ""
        chat:AddMessage(tag .. chunk)
        i = i + maxLen
        part = part + 1
    end
end



-- Relayout tick dividers when bars resize
bar:SetScript("OnSizeChanged", function()
    local db = (addon and addon.GetDB and addon.GetDB()) or (TibbettsMultiBarDB or {})
    LayoutTicks(bar._ticks, bar, db.tickCount, db.tickAlpha or 0.25, db.showTicks and true or false)
    LayoutBorderTextures(bar._border, bar, db.showBorder and true or false)
    if addon.repBar then
        LayoutTicks(addon.repBar._ticks, addon.repBar, db.tickCount, db.tickAlpha or 0.25, db.showTicks and true or false)
        LayoutBorderTextures(addon.repBar._border, addon.repBar, db.showBorder and true or false)
    end
end)