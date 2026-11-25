--[[
    OneMail - OptionsUI.lua
    Graphical Configuration Panel for OneMail.
    Supports standalone draggable window and Blizzard Settings registration.
--]]

local addonName, ns = ...

ns.OptionsUI = {}
local OptionsUI = ns.OptionsUI

local standaloneWindow = nil

local function CreateCheckbox(parent, label, getVal, setVal)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    if not cb.text then
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    end
    cb.text:SetText(label)

    cb:SetScript("OnShow", function(self)
        self:SetChecked(getVal() and true or false)
    end)
    cb:SetScript("OnClick", function(self)
        setVal(self:GetChecked() and true or false)
    end)
    return cb
end

local function CreateButton(parent, label, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width or 140, height or 24)
    btn:SetText(label)
    if onClick then
        btn:SetScript("OnClick", onClick)
    end
    return btn
end

function OptionsUI:CreateStandaloneWindow()
    if standaloneWindow then return standaloneWindow end

    local frame = CreateFrame("Frame", "OneMailOptionsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(360, 260)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    table.insert(UISpecialFrames, "OneMailOptionsFrame")

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, xOfs, yOfs = self:GetPoint()
        OneMailDB = OneMailDB or {}
        OneMailDB.optionsPosition = {
            point = point,
            relPoint = relPoint,
            x = xOfs,
            y = yOfs,
        }
    end)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.10, 0.96)

    if OneMailDB and OneMailDB.optionsPosition then
        local p = OneMailDB.optionsPosition
        frame:SetPoint(p.point or "CENTER", UIParent, p.relPoint or "CENTER", p.x or 0, p.y or 0)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -16)
    title:SetText("OneMail Options")
    title:SetTextColor(1.0, 0.82, 0.0)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

    local y = -50

    local enabledCB = CreateCheckbox(frame, "Enable Auto-Subject",
        function() return OneMailDB and OneMailDB.enabled end,
        function(val)
            OneMailDB.enabled = val
            ns:Print("Auto-subject " .. (val and "|cff00ff00enabled|r" or "|cffff4444disabled|r") .. ".")
            if val then
                ns:UpdateSendMailSubject()
            end
        end)
    enabledCB:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, y)
    y = y - 30

    local chatTabCB = CreateCheckbox(frame, "Route Messages to 'OneAddon' Chat Tab",
        function() return OneMailDB and (OneMailDB.routeToOneAddonTab ~= false) end,
        function(val)
            OneMailDB.routeToOneAddonTab = val
            local dest = val and "'OneAddon' chat tab" or "General chat"
            ns:Print("Message routing set to " .. dest .. ".")
        end)
    chatTabCB:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, y)
    y = y - 38

    local moneyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, y)
    moneyLabel:SetText("Money Subject (when no items attached):")
    y = y - 24

    local moneyBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    moneyBox:SetSize(200, 24)
    moneyBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 32, y)
    moneyBox:SetAutoFocus(false)
    moneyBox:SetMaxLetters(64)

    local function SaveMoneySubject()
        local text = (moneyBox:GetText() or ""):match("^%s*(.-)%s*$")
        if text == "" then
            text = "Money"
            moneyBox:SetText(text)
        end
        if OneMailDB.moneySubject ~= text then
            OneMailDB.moneySubject = text
            ns:Print("Money subject set to: " .. text)
            ns:UpdateSendMailSubject()
        end
    end

    moneyBox:SetScript("OnShow", function(self)
        self:SetText((OneMailDB and OneMailDB.moneySubject) or "Money")
    end)
    moneyBox:SetScript("OnEnterPressed", function(self)
        SaveMoneySubject()
        self:ClearFocus()
    end)
    moneyBox:SetScript("OnEscapePressed", function(self)
        self:SetText((OneMailDB and OneMailDB.moneySubject) or "Money")
        self:ClearFocus()
    end)

    local saveBtn = CreateButton(frame, "Save", 80, 24, function()
        SaveMoneySubject()
        moneyBox:ClearFocus()
    end)
    saveBtn:SetPoint("LEFT", moneyBox, "RIGHT", 10, 0)
    y = y - 46

    local resetBtn = CreateButton(frame, "Reset Defaults", 130, 24, function()
        ns:ResetDefaults()
        enabledCB:SetChecked(OneMailDB.enabled and true or false)
        chatTabCB:SetChecked(OneMailDB.routeToOneAddonTab ~= false)
        moneyBox:SetText(OneMailDB.moneySubject or "Money")
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        ns:Print("Settings reset to defaults.")
        ns:UpdateSendMailSubject()
    end)
    resetBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, y)

    frame:Hide()
    standaloneWindow = frame
    return frame
end

function OptionsUI:Toggle()
    local win = self:CreateStandaloneWindow()
    if win:IsShown() then
        win:Hide()
    else
        win:Show()
    end
end

function OptionsUI:Init()
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local panel = CreateFrame("Frame", "OneMailSettingsPanel", UIParent)
        panel.name = "OneMail"

        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("OneMail")

        local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        desc:SetText("Automatically populates Send Mail subjects with the first attached item or Money.")

        local openBtn = CreateButton(panel, "Open OneMail Options", 200, 28, function()
            OptionsUI:Toggle()
        end)
        openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)

        local category = Settings.RegisterCanvasLayoutCategory(panel, "OneMail")
        Settings.RegisterAddOnCategory(category)
    end
end
