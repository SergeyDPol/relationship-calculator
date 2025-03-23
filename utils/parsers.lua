function ParseName(input)
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    local startBracket = string.find(input, "%(")

    if startBracket then
        local name = string.sub(input, 1, startBracket-1)
        local genderBracket = string.sub(input, startBracket+1, -2)

        name = string.gsub(name, "^%s*(.-)%s*$", "%1")
        genderBracket = string.gsub(genderBracket, "^%s*(.-)%s*$", "%1")

        return name, genderBracket
    else
        return nil
    end
end

function ParseSpouse(input)
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")

    local startSpouseSymbols = string.find(input, "%<%-%>")

    if startSpouseSymbols then
        local husband = string.sub(input, 1, startSpouseSymbols-2)
        local wife = string.sub(input, startSpouseSymbols+4, string.len(input))

        return husband, wife
    else
        return nil, nil
    end
end

function ParseChild(input)
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    local startChildSymbol = string.find(input, "%-%>")

    if startChildSymbol then
        local child = string.sub(input, 1, startChildSymbol-2)
        local parent = string.sub(input, startChildSymbol+3, string.len(input))

        return child, parent
    else
        return nil, nil
    end
end
