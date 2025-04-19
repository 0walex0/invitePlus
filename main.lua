local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("CHAT_MSG_WHISPER")

local ui
local editBox
local enableCheckbox

InvitePlusDB = InvitePlusDB or {
    enabled = true,
    triggerWord = "+",
    allowGuild = false,
    allowFriends = false,
    allowEveryone = true
}

local function InviteHelper(self, event, msg, author)
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
        end
    end
end


local function CreateUI()
    ui = CreateFrame("Frame", "InvitePlusUI", UIParent, "BasicFrameTemplate")
    ui:SetSize(300, 160)
    ui:SetPoint("CENTER")
    ui:SetMovable(true)
    ui:EnableMouse(true)
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart", ui.StartMoving)
    ui:SetScript("OnDragStop", ui.StopMovingOrSizing)
    ui:Hide()

    ui.title = ui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.title:SetPoint("TOP", 0, 0)
    ui.title:SetText("InvitePlus")
    
    enableCheckbox = CreateFrame("CheckButton", nil, ui, "UICheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", 15, -35)
    enableCheckbox.text:SetText("Включить инвайт")

    local label = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -10)
    label:SetText("Символ для инвайта (например: +, ++, inv):")

    editBox = CreateFrame("EditBox", nil, ui, "InputBoxTemplate")
    editBox:SetSize(100, 20)
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -5)
    editBox:SetAutoFocus(false)

    local raidButton = CreateFrame("Button", nil, ui, "GameMenuButtonTemplate")
    raidButton:SetSize(80, 20)
    raidButton:SetPoint("LEFT", enableCheckbox, "BOTTOMLEFT", 195, -37)
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

    local applyButton = CreateFrame("Button", nil, ui, "GameMenuButtonTemplate")
    applyButton:SetSize(80, 20)
    applyButton:SetPoint("LEFT", editBox, "BOTTOMRIGHT", 10, 10)
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

    local checkGuild = CreateFrame("CheckButton", nil, ui, "UICheckButtonTemplate")
    checkGuild:SetPoint("LEFT", enableCheckbox, "LEFT", 0, -90)
    checkGuild.text:SetText("Только из гильдии")
    checkGuild:SetChecked(InvitePlusDB.allowGuild)
    checkGuild:SetScript("OnClick", function(self)
        InvitePlusDB.allowGuild = self:GetChecked()
    end)

    local checkFriends = CreateFrame("CheckButton", nil, ui, "UICheckButtonTemplate")
    checkFriends:SetPoint("LEFT", checkGuild, "RIGHT", 120, 0)
    checkFriends.text:SetText("Только из друзей")
    checkFriends:SetChecked(InvitePlusDB.allowFriends)
    checkFriends:SetScript("OnClick", function(self)
        InvitePlusDB.allowFriends = self:GetChecked()
    end)

    local checkEveryone = CreateFrame("CheckButton", nil, ui, "UICheckButtonTemplate")
    checkEveryone:SetPoint("LEFT", enableCheckbox, "RIGHT", 120, 0)
    checkEveryone.text:SetText("Разрешить всем")
    checkEveryone:SetChecked(InvitePlusDB.allowEveryone)
    checkEveryone:SetScript("OnClick", function(self)
        InvitePlusDB.allowEveryone = self:GetChecked()
    end)
end


f:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1:lower() == "inviteplus" then
        InvitePlusDB = InvitePlusDB or {
            enabled = true,
            triggerWord = "+"
        }

        CreateUI()

        editBox:SetText(InvitePlusDB.triggerWord)
        enableCheckbox:SetChecked(InvitePlusDB.enabled)
        enableCheckbox:SetScript("OnClick", function(self)
            InvitePlusDB.enabled = self:GetChecked()
        end)

    elseif event == "CHAT_MSG_WHISPER" then
        local msg = arg1
        local author = arg2
        InviteHelper(self, event, msg, author)
    end
end)


-- ✅ Регистрация команды /invp — отдельно и безопасно
SLASH_INVITEPLUS1 = "/invp"
SlashCmdList["INVITEPLUS"] = function()
    if not ui then
        print("InvitePlus: UI ещё не загружено.")
        return
    end

    if ui:IsShown() then
        ui:Hide()
    else
        ui:Show()
    end
end
