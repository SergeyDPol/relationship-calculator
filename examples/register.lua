-- Родители и дети
register_relations("father", {"male", "parent"});
register_relations("mother", {"female", "parent"});
register_relations("son", {"male", "child"});
register_relations("daughter", {"female", "child"});

-- Супруги
register_relations("husband", {"male", "spouse"});
register_relations("wife", {"female", "spouse"});

-- Братья и сестры
register_relations("sibling", {"child", "parent"});
register_relations("brother", {"male", "sibling"});
register_relations("sister", {"female", "sibling"});

-- Бабушки и дедушки
register_relations("grandparent", {"parent", "parent"});
register_relations("grandfather", {"male", "grandparent"});
register_relations("grandmother", {"female", "grandparent"});

-- Внуки и внучки
register_relations("grandchild", {"child", "child"});
register_relations("grandson", {"male", "grandchild"});
register_relations("granddaughter", {"female", "grandchild"});

-- Родственники через брак
register_relations("father-in-law", {"father", "spouse"});
register_relations("mother-in-law", {"mother", "spouse"});
register_relations("son-in-law", {"husband", "child"});
register_relations("daughter-in-law", {"wife", "child"});
register_relations("brother-in-law", {"brother", "spouse"});
register_relations("sister-in-law", {"sister", "spouse"});

-- Прародители
local prefix = "great"
local name = "grandparent"

for i=1,10 do
	local new_name = prefix .. name
	register_relations(new_name, {"parent", name})
	name = new_name
end
