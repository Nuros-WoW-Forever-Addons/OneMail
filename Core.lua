local addonName, ns = ...

local DEFAULTS = {
    enabled = true,
    moneySubject = "Money",
    routeToOneAddonTab = true,
    optionsPosition = nil,
}

local db
local lastAutoSubject = nil
local isUpdatingSubject = false
local hooksInstalled = false
local chatTabInitialized = false

-------------------------------------------------------------------------------
-- Database Initialization
-------------------------------------------------------------------------------
local function InitDB()
    if type(OneMailDB) ~= "table" then
        OneMailDB = {}
    end
    for k, v in pairs(DEFAULTS) do
        if OneMailDB[k] == nil then
            OneMailDB[k] = v
        end
    end
    db = OneMailDB
end

function ns:ResetDefaults()
    if type(OneMailDB) ~= "table" then
        OneMailDB = {}
    end
    for k, v in pairs(DEFAULTS) do
        OneMailDB[k] = v
    end
    db = OneMailDB
end

-------------------------------------------------------------------------------
-- Message Routing & Dedicated Chat Tab ("OneAddon")
-------------------------------------------------------------------------------
function ns:EnsureChatTab()
    if not db or db.routeToOneAddonTab == false then
        return DEFAULT_CHAT_FRAME
    end

    local targetName = "OneAddon"

    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local name = GetChatWindowInfo(i)
        if name == targetName then
            local cf = _G["ChatFrame" .. i]
            if cf then
                local tab = _G["ChatFrame" .. i .. "Tab"]
                if tab then
                    tab:Show()
                    if PanelTemplates_TabResize then
                        pcall(PanelTemplates_TabResize, tab, 0)
                    end
                end
                return cf
            end
        end
    end

    if FCF_OpenNewWindow then
        local frame = FCF_OpenNewWindow(targetName)
        if frame then
            if FCF_DockFrame and GENERAL_CHAT_DOCK then
                local docked = (FCFDock_GetChatFrames and FCFDock_GetChatFrames(GENERAL_CHAT_DOCK))
                    or (GENERAL_CHAT_DOCK and GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES)
                    or {}
                local nextIdx = #docked + 1
                pcall(FCF_DockFrame, frame, nextIdx, false)
            end
            if ChatFrame_RemoveAllMessageGroups then
                pcall(ChatFrame_RemoveAllMessageGroups, frame)
            end
            if ChatFrame_RemoveAllChannels then
                pcall(ChatFrame_RemoveAllChannels, frame)
            end
            if FCF_DockUpdate then
                pcall(FCF_DockUpdate)
            end
            local id = frame.GetID and frame:GetID()
            if id then
                local tab = _G["ChatFrame" .. id .. "Tab"]
                if tab then
                    tab:Show()
                    if PanelTemplates_TabResize then
                        pcall(PanelTemplates_TabResize, tab, 0)
                    end
                end
            end
            if FCF_SelectDockFrame and DEFAULT_CHAT_FRAME then
                pcall(FCF_SelectDockFrame, DEFAULT_CHAT_FRAME)
            end
            return frame
        end
    end

    return DEFAULT_CHAT_FRAME
end

function ns:Print(msg)
    local out = self:EnsureChatTab() or DEFAULT_CHAT_FRAME
    if out and out.AddMessage then
        out:AddMessage("|cff00ccff[OneMail]|r " .. tostring(msg))
    end
end

-------------------------------------------------------------------------------
-- Send Mail Subject Logic
-------------------------------------------------------------------------------
local function GetFirstAttachedItemName()
    local maxSlots = ATTACHMENTS_MAX_SEND or 12
    for i = 1, maxSlots do
        local itemName, itemID = GetSendMailItem(i)
        if itemName and itemName ~= "" then
            return itemName
        elseif itemID then
            local name = C_Item.GetItemNameByID(itemID)
            if name and name ~= "" then
                return name
            end
        end
    end
    return nil
end

local function GetPendingSendMoney()
    if SendMailMoney and MoneyInputFrame_GetCopper then
        return MoneyInputFrame_GetCopper(SendMailMoney) or 0
    end
    if GetSendMailMoney then
        return GetSendMailMoney() or 0
    end
    return 0
end

local function ComputeDesiredSubject()
    local itemName = GetFirstAttachedItemName()
    if itemName then
        return itemName
    end

    local copper = GetPendingSendMoney()
    if copper > 0 then
        local moneyText = db and db.moneySubject
        if type(moneyText) == "string" and moneyText ~= "" then
            return moneyText
        end
        return "Money"
    end

    return nil
end

function ns:UpdateSendMailSubject()
    if not db or not db.enabled then
        return
    end
    if not SendMailSubjectEditBox or not SendMailFrame or not SendMailFrame:IsShown() then
        return
    end
    if isUpdatingSubject then
        return
    end

    local currentText = SendMailSubjectEditBox:GetText() or ""
    -- Respect custom subjects typed by the user.
    if currentText ~= "" and currentText ~= lastAutoSubject then
        return
    end

    local desired = ComputeDesiredSubject()
    isUpdatingSubject = true
    if desired then
        if currentText ~= desired then
            SendMailSubjectEditBox:SetText(desired)
        end
        lastAutoSubject = desired
    elseif lastAutoSubject and currentText == lastAutoSubject then
        SendMailSubjectEditBox:SetText("")
        lastAutoSubject = nil
    end
    isUpdatingSubject = false
end

local function InstallMailHooks()
    if hooksInstalled then
        return
    end

    if SendMailSubjectEditBox then
        SendMailSubjectEditBox:HookScript("OnTextChanged", function(self, isUserInput)
            if isUpdatingSubject then
                return
            end
            if isUserInput then
                local text = self:GetText() or ""
                if text ~= lastAutoSubject then
                    lastAutoSubject = nil
                end
            end
        end)
    end

    local moneyBoxes = {
        SendMailMoneyGold,
        SendMailMoneySilver,
        SendMailMoneyCopper,
    }
    for _, box in ipairs(moneyBoxes) do
        if box then
            box:HookScript("OnTextChanged", function()
                ns:UpdateSendMailSubject()
            end)
        end
    end

    hooksInstalled = true
end

-------------------------------------------------------------------------------
-- Event Dispatch
-------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

function eventHandlers.ADDON_LOADED(loadedName)
    if loadedName ~= addonName then
        return
    end
    InitDB()
    if ns.OptionsUI and ns.OptionsUI.Init then
        ns.OptionsUI:Init()
    end
    eventFrame:UnregisterEvent("ADDON_LOADED")
end

function eventHandlers.PLAYER_ENTERING_WORLD()
    if not chatTabInitialized then
        chatTabInitialized = true
        if C_Timer and C_Timer.After then
            C_Timer.After(0.3, function()
                if db and db.routeToOneAddonTab ~= false then
                    ns:EnsureChatTab()
                end
            end)
        elseif db and db.routeToOneAddonTab ~= false then
            ns:EnsureChatTab()
        end
    end
end

function eventHandlers.MAIL_SHOW()
    lastAutoSubject = nil
    InstallMailHooks()
    ns:UpdateSendMailSubject()
end

function eventHandlers.MAIL_CLOSED()
    lastAutoSubject = nil
end

function eventHandlers.MAIL_SEND_INFO_UPDATE()
    ns:UpdateSendMailSubject()
end

function eventHandlers.MAIL_SEND_SUCCESS()
    lastAutoSubject = nil
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local handler = eventHandlers[event]
    if handler then
        handler(...)
    end
end)

for eventName in pairs(eventHandlers) do
    eventFrame:RegisterEvent(eventName)
end

-------------------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------------------
SLASH_ONEMAIL1 = "/om"
SLASH_ONEMAIL2 = "/onemail"
SlashCmdList["ONEMAIL"] = function(msg)
    if not db then
        InitDB()
    end

    local cmd, arg = msg:match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "options" or cmd == "config" then
        if ns.OptionsUI and ns.OptionsUI.Toggle then
            ns.OptionsUI:Toggle()
        end
    elseif cmd == "toggle" then
        db.enabled = not db.enabled
        ns:Print("Auto-subject " .. (db.enabled and "|cff00ff00enabled|r" or "|cffff4444disabled|r") .. ".")
        if db.enabled then
            ns:UpdateSendMailSubject()
        end
    elseif cmd == "money" then
        if arg and arg ~= "" then
            db.moneySubject = arg
            ns:Print("Money subject set to: " .. arg)
            ns:UpdateSendMailSubject()
        else
            ns:Print("Current money subject: \"" .. tostring(db.moneySubject) .. "\"")
        end
    elseif cmd == "chat" then
        db.routeToOneAddonTab = not (db.routeToOneAddonTab ~= false)
        local dest = db.routeToOneAddonTab and "'OneAddon' chat tab" or "General chat"
        ns:Print("Message routing set to " .. dest .. ".")
    else
        ns:Print("Commands:")
        ns:Print("  |cffffd200/om|r - Open OneMail Options")
        ns:Print("  |cffffd200/om toggle|r - Enable/disable auto-subject")
        ns:Print("  |cffffd200/om money <subject>|r - Set money subject (default: Money)")
        ns:Print("  |cffffd200/om chat|r - Toggle 'OneAddon' chat tab routing")
    end
end
