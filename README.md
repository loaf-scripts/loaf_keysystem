# loaf_keysystem
Key system for ESX. 

This is a resource that is going to be used by some of the resources I make.
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
TriggerEvent("getKeys", source, function(keys)
  if keys then
    for k, v in pairs(keys) do
      local key_id = v.key_id
      local unique_id = v.unique_id
    end
  else
    print("Couldn't get keys")
  end
end)
```

To remove a key, do like this:
```lua
TriggerEvent("removeKey", source, unique_id, function(removed)
  if removed then
    print("Key removed!")
  else
    print("Key couldn't be removed :/")
  end
end)
```

To set the usage of a key, do like this (client side)
```lua
TriggerEvent("loaf_keysystem:setUsage", key_id, function(key_id)
  print("Used key: " .. key)
end)
```
