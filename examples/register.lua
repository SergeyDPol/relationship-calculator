-- Родители и дети
register_relations("father", {"male", "parent"});
register_relations("mother", {"female", "parent"});
register_relations("son", {"male", "child"});
register_relations("daughter", {"female", "child"});

-- Супруги
register_relations("husband", {"male", "spouse"});
register_relations("wife", {"female", "spouse"});

-- Братья и сестры
register_relations("brother", {"male", "child", "parent"});
register_relations("sister", {"female", "child", "parent"});

-- Бабушки и дедушки
register_relations("grandfather", {"male", "parent", "parent"});
register_relations("grandmother", {"female", "parent", "parent"});

-- Внуки и внучки
register_relations("grandson", {"male", "child", "child"});
register_relations("granddaughter", {"female", "child", "child"});

-- Родственники через брак
register_relations("father-in-law", {"male", "parent", "spouse"});
register_relations("mother-in-law", {"female", "parent", "spouse"});
register_relations("son-in-law", {"male", "spouse", "child"});
register_relations("daughter-in-law", {"female", "spouse", "child"});
register_relations("brother-in-law", {"male", "child", "parent", "spouse"});
register_relations("sister-in-law", {"female", "child", "parent", "spouse"});
