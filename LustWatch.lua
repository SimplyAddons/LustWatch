local addonName, LW = ...

-- initialize LWDB
LWDB = LWDB or { enabled = true }

-- local state
LW.combatRegistered = false
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

-- toggle combat log events
-- this function differs slightly from registerCombat() in that its meant
-- to be used after bloodlust is cast in a raid, and when the player leaves combat.
-- this helps optimize performance since we dont need to listen to combat log events
-- after bloodlust is cast. we do need to listen again when combat ends, as the
-- raid can always reset the bloodlust cooldown.
function LW:toggleCombat(enable)
    if enable then
        if not LW.combatRegistered then
            LW.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            LW.combatRegistered = true
            LW:log("Combat log listener re-enabled.")
        end
    else
        LW.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        LW.combatRegistered = false
        LW:log("Combat log listener disabled.")
    end
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
-- note: SendChatMessage() does not permit using colorized strings |cff...|r
function LW:announceLust(spellID, sourceGUID, sourceName)
    local chatType = LW:getChatType()
    LW:log('Announcing to ' .. chatType .. ' channel.')

    local spellLink = C_Spell.GetSpellLink(spellID)

    if UnitInParty(sourceName) then
        if LW.lustItems[spellID] then
            SendChatMessage("LustWatch: {rt3} [" .. UnitClass(sourceName) .. "] " .. sourceName .. " used " .. spellLink, chatType)
        elseif LW.lustSpells[spellID] then
            SendChatMessage("LustWatch: {rt3} [" .. UnitClass(sourceName) .. "] " .. sourceName .. " cast " .. spellLink, chatType)
        end
    end

    if LW.lustSpells[spellID] and string.match(sourceGUID, "Pet") then
        local petName, ownerName = LW:getHunterPetOwner(sourceGUID)
        if petName and ownerName then
            SendChatMessage("LustWatch: {rt3} Pet [" .. petName .. "] from " .. ownerName .. " cast " .. spellLink, chatType)
        end
    end
end

-- register events
LW.frame = CreateFrame("Frame")
LW.frame:RegisterEvent("CHAT_MSG_ADDON")
LW.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
LW.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
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

    elseif event == "PLAYER_REGEN_ENABLED" then
        LW:log("PLAYER_REGEN_ENABLED triggered.")
        if IsInRaid() then
            LW:toggleCombat(true)
        end

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and LW:getAnnouncer() then
        local _, eventType, _, sourceGUID, sourceName, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        if eventType == "SPELL_CAST_SUCCESS" and (LW.lustItems[spellID] or LW.lustSpells[spellID]) then
            LW:announceLust(spellID, sourceGUID, sourceName)
            -- Disable listener after bloodlust is used in raid for performance.
            -- will be re-enabled when player leaves combat.
            if IsInRaid() then
                LW:toggleCombat(false)
            end
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
    print(LW:name() .. ": has been turned " .. LW:stateColor(enabled))
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
        print(LW:name() .. ": Debug mode is now " .. LW:stateColor(LW.options.debug))
    else
        print(LW:name() .. ": ------------------------------------------")
        print(LW:name() .. ": is " .. LW:stateColor(LW.options.enabled) .. ".")
        print(LW:name() .. ": combat monitoring is " .. LW:stateColor(LW.combatRegistered) .. ".")
        print(LW:name() .. ": debug mode is " .. LW:stateColor(LW.options.debug) .. ".")
        if IsInGroup() or IsInRaid() then
            print(LW:name() .. ": you " .. (LW:getAnnouncer() and "|cff00d1b2ARE|r" or "|cffbfbfbfARE NOT|r") .. " the announcer.")
        end
        print(LW:name() .. ": commands: |cff00d1b2/lw on|r , |cff00d1b2/lw off|r , |cff00d1b2/lw debug|r")
        print(LW:name() .. ": ------------------------------------------")
    end
end
SLASH_LUSTWATCH1 = "/lw"
SLASH_LUSTWATCH2 = "/lust"
SLASH_LUSTWATCH3 = "/lustwatch"
SlashCmdList["LW"] = cmdHandler
SlashCmdList["LUST"] = cmdHandler
SlashCmdList["LUSTWATCH"] = cmdHandler
