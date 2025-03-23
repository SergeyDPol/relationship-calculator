require('relations')

function Split(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local function help()
    print([[
1. get {name} {relation} - find person for {name} by {relation}.
Example: get Анатолий father
Output: Митрофан

2. help - call help
]])
end

Actions = {
    ["get"] = function(cmd)
        local success, result = pcall(get_relatives_for_person, cmd[2], cmd[3])
        if (success) then
            if (type(result) == "table") then
                for _, value in ipairs(result) do
                    print(value.properties.name)
                end
            elseif (type(result) == "person") then
                print(result.properties.name)
            else
                print("not found relation " .. cmd[3] " for " .. cmd[2])
            end
        else
            print("got failure: " .. result)
        end
    end,
    ["help"] = function()
        help()
    end
}
