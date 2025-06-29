local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("CHAT_MSG_WHISPER")

local ui
local editBox
local enableCheckbox
local checkGuild
local checkFriends
local checkEveryone

InvitePlusDB = InvitePlusDB or {
    enabled = true,
    triggerWord = "+",
    allowGuild = false,
    allowFriends = false,
    allowEveryone = true
}

local function InvitePlus(self, event, msg, author)
    if event ~= "CHAT_MSG_WHISPER" then return end
    msg = msg:lower():gsub("^%s*(.-)%s*$", "%1")

    if InvitePlusDB.enabled and msg == InvitePlusDB.triggerWord then
        local isFriend = false
        local isGuildmate = false

        for i = 1, GetNumFriends() do
            local name = GetFriendInfo(i)
            if name and name:lower() == author:match("^[^%-]+"):lower() then
                isFriend = true
                break
            end
        end

        if IsInGuild() then
            for i = 1, GetNumGuildMembers() do
                local name = GetGuildRosterInfo(i)
                if name and name:lower() == author:match("^[^%-]+"):lower() then
                    isGuildmate = true
                    break
                end
            end
        end

        if InvitePlusDB.allowEveryone or
           (InvitePlusDB.allowFriends and isFriend) or
           (InvitePlusDB.allowGuild and isGuildmate)
        then
            InviteUnit(author)
            print("|cff00ff00[InvitePlus]|r Приглашение отправлено игроку: " .. author)
        end
    end
end

local function CreateUI()
    ui = CreateFrame("Frame", "InvitePlusDBUI", UIParent, "BasicFrameTemplateWithInset")
    ui:SetSize(320, 190)
    ui:SetPoint("CENTER")
    ui:SetMovable(true)
    ui:EnableMouse(true)
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart", ui.StartMoving)
    ui:SetScript("OnDragStop", ui.StopMovingOrSizing)
    ui:Hide()

    ui.title = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.title:SetPoint("TOP", 0, -4)
    ui.title:SetText("InvitePlus")

    enableCheckbox = CreateFrame("CheckButton", nil, ui, "UICheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", 15, -35)
    enableCheckbox.text:SetText("Включить инвайт")
    enableCheckbox:SetChecked(InvitePlusDB.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        InvitePlusDB.enabled = self:GetChecked()
    end)

    local label = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -20)
    label:SetText("Символ для инвайта (например: +, ++, inv):")

    editBox = CreateFrame("EditBox", nil, ui, "InputBoxTemplate")
    editBox:SetSize(120, 25)
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -5)
    editBox:SetAutoFocus(false)
    editBox:SetText(InvitePlusDB.triggerWord)

    local applyButton = CreateFrame("Button", nil, ui, "GameMenuButtonTemplate")
    applyButton:SetSize(80, 25)
    applyButton:SetPoint("LEFT", editBox, "RIGHT", 7, 0)
    applyButton:SetText("Применить")
    applyButton:SetScript("OnClick", function()
        local text = editBox:GetText():lower():gsub("^%s*(.-)%s*$", "%1")
        if text ~= "" then
            InvitePlusDB.triggerWord = text
            print("|cff00ff00[InvitePlus]|r Символ обновлён на: " .. text)
        else
            print("|cffff0000[InvitePlus]|r Символ не может быть пустым!")
        end
    end)

    checkGuild = CreateFrame("CheckButton", nil, ui, "UICheckButtonTemplate")
    checkGuild:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -15)
    checkGuild.text:SetText("Только из гильдии")
    checkGuild:SetChecked(InvitePlusDB.allowGuild)
    checkGuild:SetScript("OnClick", function(self)
        InvitePlusDB.allowGuild = self:GetChecked()
    end)

    checkFriends = CreateFrame("CheckButton", nil, ui, "UICheckButtonTemplate")
    checkFriends:SetPoint("LEFT", checkGuild, "RIGHT", 120, 0)
    checkFriends.text:SetText("Только из друзей")
    checkFriends:SetChecked(InvitePlusDB.allowFriends)
    checkFriends:SetScript("OnClick", function(self)
        InvitePlusDB.allowFriends = self:GetChecked()
    end)

    checkEveryone = CreateFrame("CheckButton", nil, ui, "UICheckButtonTemplate")
    checkEveryone:SetPoint("LEFT", enableCheckbox, "RIGHT", 120, 0)
    checkEveryone.text:SetText("Разрешить всем")
    checkEveryone:SetChecked(InvitePlusDB.allowEveryone)
    checkEveryone:SetScript("OnClick", function(self)
        InvitePlusDB.allowEveryone = self:GetChecked()
    end)

    print("|cff00ff00[InvitePlus]|r UI загружен. Введите /invp для открытия окна.")
	
	local raidButton = CreateFrame("Button", nil, ui, "GameMenuButtonTemplate")
    raidButton:SetSize(80, 25)
    raidButton:SetPoint("LEFT", applyButton, "LEFT", 85, 0)
    raidButton:SetText("Создать рейд")
    raidButton:SetScript("OnClick", function()
        local numGroupMembers = GetNumGroupMembers()
        if numGroupMembers < 2 then
            print("|cffff0000[InvitePlus]|r Для создания рейда нужно минимум 2 игрока в группе!")
            return
        end
        if not IsInRaid() then
            if UnitIsGroupLeader("player") then
                ConvertToRaid()
                print("|cff00ff00[InvitePlus]|r Группа переведена в рейд.")
            else
                print("|cffff0000[InvitePlus]|r Только лидер группы может создать рейд!")
            end
        else
            print("|cffffff00[InvitePlus]|r Уже в рейде.")
        end
    end)
end

SLASH_InvitePlus1 = "/invp"
SlashCmdList["InvitePlus"] = function()
    if not ui then
        CreateUI()
    end

    if ui:IsShown() then
        ui:Hide()
    else
        ui:Show()
    end
end

f:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "InvitePlus" then
        InvitePlusDB = InvitePlusDB or {
            enabled = true,
            triggerWord = "+",
            allowGuild = false,
            allowFriends = false,
            allowEveryone = true
        }
        CreateUI()

    elseif event == "CHAT_MSG_WHISPER" then
        InvitePlus(self, event, arg1, arg2)
    end
end)
