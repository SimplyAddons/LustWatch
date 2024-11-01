local addonName, LW = ...

-- register chat channel
function LW:registerChat()
    if LW.options.enabled and not LW.chatRegistered then
        local result = C_ChatInfo.RegisterAddonMessagePrefix(LW.channel)
        if result == Enum.RegisterAddonMessagePrefixResult.Success then
            LW.chatRegistered = true
            LW:log("Chat channel registered.")
        elseif result == Enum.RegisterAddonMessagePrefixResult.DuplicatePrefix then
            LW:log("Chat channel registration skipped (already registered).")
        elseif result == Enum.RegisterAddonMessagePrefixResult.InvalidPrefix then
            LW:log("Failed to register chat channel: Invalid prefix.")
        elseif result == Enum.RegisterAddonMessagePrefixResult.MaxPrefixes then
            LW:log("Failed to register chat channel: Max prefixes reached.")
        end
    end
end

-- handle addon communication
function LW:OnCommReceived(prefix, message, distribution, sender)
    if prefix == LW.channel then
        LW:log("CHAT_MSG_ADDON triggered.")
        if message == "LustWatchAnnouncer" then
            -- ignore self-broadcasted messages
            if not LW:isSelf(sender) then
                LW.isAnnouncer = false
                LW:log(sender .. " has become the new announcer.")
            else
                LW:log("Confirmed as announcer from own message.")
            end
        end
    end
end
