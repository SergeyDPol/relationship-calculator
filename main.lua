require('utils.parsers')
require('utils.commands')
require('relations')

person_by_name = {}
process_relations("examples/register.lua")

local file = io.open("examples/input.txt", "r")
if (file == nil) then
    print("file not found")
else
    for line in file:lines() do
        local name, gender = ParseName(line)
        local husband, wife = ParseSpouse(line)
        local parent, child = ParseChild(line)

        if (name ~= nil and gender ~= nil) then
            local gender_for_person = "male"
            if (gender == "Ж") then
                gender_for_person = "female"
            end
            local new_person = person:new({
                name = name,
                gender = gender_for_person
            })
            person_by_name[new_person.properties.name] = new_person
        elseif (husband ~= nil and wife ~= nil) then
            local husband_person = person_by_name[husband]
            local wife_person = person_by_name[wife]

            husband_person.properties.spouse = wife_person
            wife_person.properties.spouse = husband_person
        elseif (child ~= nil and parent ~= nil) then
            local child_person = person_by_name[child]
            local parent_person = person_by_name[parent]

            if (child_person.properties.parent == nil) then
                child_person.properties.parent = {}
            end

            if (parent_person.properties.child == nil) then
                parent_person.properties.child = {}
            end

            child_person.properties.parent[#child_person.properties.parent + 1] = parent_person
            parent_person.properties.child[#parent_person.properties.child + 1] = child_person
        end
    end
    file:close()
end


-- call help first
Actions["help"]()

while true do
    io.write("Команда (или 'exit' для выхода): ")
    local input = io.read()

    if input == "exit" then
        break
    end

    local cmd = Split(input, " ")

    local output = Actions[cmd[1]]
    if (output == nil) then
        print("unknown command: " .. input)
    else
        output(cmd)
    end
end
