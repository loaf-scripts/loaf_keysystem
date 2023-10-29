lib = exports.loaf_lib:GetLib()

-- Debug prints
local _print = print
function print(...)
    if not Config.Debug then
        return
    end

    local args = {...}
    for i = 1, #args do
        if type(args[i]) == "table" then
            args[i] = json.encode(args[i])
        end
    end

    _print("[^3DEBUG^0]", table.unpack(args))
end

function printf(s, ...)
    print(s:format(table.unpack({...})))
end

-- Locales
function L(path, args)
    local translation = Locales[Config.Language]?[path] or Locales.en[path] or path

    if args then
        for k, v in pairs(args) do
            local safe_v = tostring(v):gsub("%%", "%%%%")
            translation = translation:gsub("{" .. k .. "}", safe_v)
        end
    end

    return translation
end
