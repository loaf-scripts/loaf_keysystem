# loaf_keysystem
Key system / API for ESX. 

This is a resource that is used by some of the resources I sell.
You are free to do whatever you want with this resource, however, **you are not allowed to sell this resource**. You are allowed to modify the resource and upload on other sites, but you are not allowed to profit off of this resource.

## ALPHA
Please not that this resource is in alpha. Expect bugs and issues. 

## Usage for resource developers
This guide is not finished. This resource is a W.I.P.

You can only generate keys from server side code (security reasons). To generate a key, do like this:
```lua
TriggerEvent("generateKey", source, key_id, key_label, function()
  print("key has been generated")
end)
```

To get a list of all keys, do like this:
```lua
TriggerEvent("getKeys", 1, function(keys)
    if keys then
        for k, v in pairs(keys) do
            local doing = true
            TriggerEvent("removeKey", 1, k, function()
                doing = false
            end)
            while doing do Wait(50) end
        end
    end
end)
```

To set the usage of a key, do like this (client side)
```lua
TriggerEvent("loaf_keysystem:setUsage", key_id, function(key_id)
  print("Used key: " .. key)
end)
```
