local addonName, LW = ...

-- log messages to chat
function LW:log(message)
    if LW.options.debug then
        print("|cffb48ef9LustWatch:|r " .. message)
    end
end

-- colorize the on/off states
function LW:stateColor(state)
    if state then
        return "|cff1cb619On|r"
    else
        return "|cffbfbfbfOff|r"
    end
end

-- check if sender is the player
function LW:isSelf(sender)
    local playerName, playerRealm = UnitFullName("player")
    local fullPlayerName = playerName .. "-" .. playerRealm
    return sender == fullPlayerName
end

-- get chat type
function LW:getChatType()
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        return "PARTY"
    end
    return "SAY"
end

-- get the owner of a hunter pet
function LW:getHunterPetOwner(sourceGUID)
    for i = 1, GetNumGroupMembers() do
        local unit = "party" .. i
        if UnitGUID(unit .. "pet") == sourceGUID then
            return UnitName(unit .. "pet"), UnitName(unit)
        end
    end
    return nil, nil
end