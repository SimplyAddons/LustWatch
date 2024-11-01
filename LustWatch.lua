local addonName, LW = ...

-- initialize LWDB
LWDB = LWDB or { enabled = true }

-- local state
LW.combatRegistered = false
LW.chatRegistered = false
LW.channel = "LustWatchChannel"

-- addon settings
setmetatable(LW, {
    __index = function(t, k)
        if k == "options" then
            t.options = {
                enabled = LWDB.enabled or true,
                debug = LWDB.debug or false,
                isAnnouncer = LWDB.isAnnouncer or false
            }
            return t.options
        end
    end
})

-- set/get announcer
function LW:setAnnouncer(state)
    LW.options.isAnnouncer = state
    LWDB.isAnnouncer = state
end
function LW:getAnnouncer()
    return LW.options.isAnnouncer
end

-- register or unregister combat log events
function LW:registerCombat()
    if LW.options.enabled and (IsInGroup() or IsInRaid()) then
        if not LW.combatRegistered then
            LW.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            LW.combatRegistered = true
            LW:log("Combat log registered.")
        end
    else
        LW.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        LW.combatRegistered = false
        LW:setAnnouncer(false)
        LW:log("Combat log unregistered.")
    end
end

-- assign announcer role and broadcast to the group
function LW:assignAnnouncer()
    if LW.options.enabled and (IsInGroup() or IsInRaid()) then
        LW:setAnnouncer(true)
        LW:log("Assigned as the announcer. Broadcasting to group.")
        C_ChatInfo.SendAddonMessage(LW.channel, "LustWatchAnnouncer", LW:getChatType())
    else
        LW:setAnnouncer(false)
        LW:log("Not in group or raid.")
    end
end

-- announce lust
function LW:announceLust(spellID, sourceGUID, sourceName)
    if LW:getAnnouncer() then
        local spellLink = C_Spell.GetSpellLink(spellID)
        local chatType = LW:getChatType()
        LW:log('Announcing to ' .. chatType .. ' channel.')

        if UnitInParty(sourceName) then
            if LW.hasteItems[spellID] then
                SendChatMessage("{rt1} [" .. UnitClass(sourceName) .. "] " .. sourceName .. " used " .. spellLink .. " {rt1}", chatType)
            elseif LW.warpSpells[spellID] then
                SendChatMessage("{rt2} [" .. UnitClass(sourceName) .. "] " .. sourceName .. " cast " .. spellLink .. " {rt2}", chatType)
            end
        end

        if LW.warpSpells[spellID] and string.match(sourceGUID, "Pet") then
            local petName, ownerName = LW:getHunterPetOwner(sourceGUID)
            if petName and ownerName then
                SendChatMessage("{rt2} Pet [" .. petName .. "] from " .. ownerName .. " cast " .. spellLink .. " {rt2}", chatType)
            end
        end
    end
end

-- register events
LW.frame = CreateFrame("Frame")
LW.frame:RegisterEvent("CHAT_MSG_ADDON")
LW.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
LW.frame:RegisterEvent("GROUP_ROSTER_UPDATE")

-- event listener
LW.frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        LW:log("PLAYER_ENTERING_WORLD triggered.")
        LW:registerChat()
        LW:registerCombat()
        LW:assignAnnouncer()

    elseif event == "GROUP_ROSTER_UPDATE" then
        LW:log("GROUP_ROSTER_UPDATE triggered.")
        LW:registerChat()
        LW:registerCombat()
        LW:assignAnnouncer()

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and LW:getAnnouncer() then
        local _, eventType, _, sourceGUID, sourceName, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        if eventType == "SPELL_CAST_SUCCESS" and (LW.hasteItems[spellID] or LW.warpSpells[spellID]) then
            LW:announceLust(spellID, sourceGUID, sourceName)
        end

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, distribution, sender = ...
        LW:OnCommReceived(prefix, message, distribution, sender)
    end
end)

-- toggle lust watch
local function toggle(enabled)
    LW.options.enabled = enabled
    LWDB.enabled = enabled
    LW:registerChat()
    LW:registerCombat()
    if enabled then
        LW:assignAnnouncer()
    else
        LW:setAnnouncer(false)
    end
    print("|cffb48ef9LustWatch:|r has been turned " .. LW:stateColor(enabled))
end

-- commands
local function cmdHandler(msg)
    msg = msg:trim():upper()
    if msg == 'ON' then
        toggle(true)
    elseif msg == 'OFF' then
        toggle(false)
    elseif msg == 'DEBUG' then
        LW.options.debug = not LW.options.debug
        LWDB.debug = LW.options.debug
        print("|cffb48ef9LustWatch:|r Debug mode is now " .. LW:stateColor(LW.options.debug))
    else
        print("|cffb48ef9LustWatch:|r -----------------------------")
        print("|cffb48ef9LustWatch:|r is " .. LW:stateColor(LW.options.enabled))
        print("|cffb48ef9LustWatch:|r debug mode is " .. LW:stateColor(LW.options.debug))
        print("|cffb48ef9LustWatch:|r commands: /lw on, /lw off")
        print("|cffb48ef9LustWatch:|r -----------------------------")
        if IsInGroup() or IsInRaid() then
            print("|cffb48ef9LustWatch:|r you " .. (LW:getAnnouncer() and "|cff1cb619are|r" or "|cffbfbfbfare not|r") .. " the announcer.")
            print("|cffb48ef9LustWatch:|r -----------------------------")
        end
    end
end
SLASH_LUSTWATCH1 = "/lw"
SLASH_LUSTWATCH2 = "/lustwatch"
SlashCmdList["LW"] = cmdHandler
SlashCmdList["LUSTWATCH"] = cmdHandler