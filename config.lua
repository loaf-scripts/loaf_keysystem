Config = {
    Debug = false,
    Framework = "esx", -- esx or qb
    Align = "bottom-right", -- menu alignment (esx)
    Command = "keys", -- false to disable
    Keybind = "PAGEUP", -- false to disable, requires command
    UseRPName = true, -- use the in-game name instead of fivem name + id?
}

Strings = {
    ["keybind"] = "Menu with all your keys.",
    ["no_keys"] = "You don't have any keys.",

    -- menu
    ["main_menu"] = "Your keys",

    ["transfer_nearby"] = "Give the key",
    ["use_key"] = "Use the key",
    ["delete_key"] = "Delete the key",

    ["confirm_delete"] = "Delete key %s?",
    ["yes"] = "Yes",
    ["no"] = "No",

    ["give_to"] = "Give to %s (%i)",
    ["noone_nearby"] = "There's no one nearby.",
    
    ["confirm_give"] = "Are you sure you want to give the key to %s?",
    ["couldnt_transfer"] = "Couldn't transfer the key.",
    ["transferred"] = "Transferred key %s to %s.",

    -- notifications
    ["not_your_key"] = "You don't have that key.",
    ["couldnt_delete"] = "Could not delete the key",
    ["deleted"] = "~r~Deleted~s~ key \"%s\".",
    ["received_key"] = "You received a key.",

    -- logs
    ["LOG_transferred_key"] = "Transferred their key %s (unique id: %s) to %s [id %i]",
    ["LOG_received_key"] = "Received key %s (unique id: %s) via transfer from %s [id %i]",
    ["LOG_removed_key"] = "Removed their key %s (unique id: %s)",
    ["LOG_create_key"] = "Received a key created by script %s. Key data:\nname: %s\nkey id: %s\nunique id: %s",
    ["LOG_delete_all"] = "All keys with id %s has been deleted by script %s",
    ["LOG_delete_specific"] = "Script %s deleted key with unique id %s",
    ["LOG_delete_key"] = "Had their key %s (unique id: %s) deleted by script %s."
}

-- IGNORE EVERYTHING BELOW THIS LINE --
setmetatable(Strings, {
    __index = function(self, key)
        return "Error: Missing translation for \""..key.."\""
    end
})

_print = print
function print(...)
    if not Config.Debug then return end
    _print("[^3DEBUG^0]", ...)
end

function printf(s, ...)
    if not Config.Debug then return end
    print(s:format(table.unpack({...})))
end