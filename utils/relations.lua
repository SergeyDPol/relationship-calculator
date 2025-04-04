-- Pre-defined relations
function male_iterator_factory(self)
	assert(type(self) == "table", "invalid input for iterator factory function")
	assert(type(self.properties) == "table", "invalid input for iterator factory function")
	if self.properties["gender"] == nil then return function() return nil end end
	local has_been_called = false
	return function()
		if has_been_called then return nil end
		has_been_called = true
		if self.properties["gender"] == "male" then
			return self
		else
			return nil
		end
	end
end

function female_iterator_factory(self)
	assert(type(self) == "table", "invalid input for iterator factory function")
	assert(type(self.properties) == "table", "invalid input for iterator factory function")
	if self.properties["gender"] == nil then return function() return nil end end
	local has_been_called = false
	return function()
		if has_been_called then return nil end
		has_been_called = true
		if self.properties["gender"] == "female" then
			return self
		else
			return nil
		end
	end
end

function spouse_iterator_factory(self)
	assert(type(self) == "table", "invalid input for iterator factory function")
	assert(type(self.properties) == "table", "invalid input for iterator factory function")
	if self.properties["spouse"] == nil then return function() return nil end end
	local has_been_called = false
	return function()
		if has_been_called then return nil end
		has_been_called = true
		return self.properties["spouse"]
	end
end

function child_iterator_factory(self)
	assert(type(self) == "table", "invalid input for iterator factory function")
	assert(type(self.properties) == "table", "invalid input for iterator factory function")
	if self.properties["child"] == nil then return function() return nil end end
	local i = 0
	return function()
		if i > #self.properties["child"] then return nil end
		i = i + 1
		return self.properties["child"][i]
	end
end

function parent_iterator_factory(self)
	assert(type(self) == "table", "invalid input for iterator factory function")
	assert(type(self.properties) == "table", "invalid input for iterator factory function")
	if self.properties["parent"] == nil then return function() return nil end end
	local i = 0
	return function()
		if i > #self.properties["parent"] then return nil end
		i = i + 1
		return self.properties["parent"][i]
	end
end

-- A prototype for creating people
person = {
	male = male_iterator_factory,
	female = female_iterator_factory,
	spouse = spouse_iterator_factory,
	child = child_iterator_factory,
	parent = parent_iterator_factory
}

local cache_mt = { __mode = "v" }
function person:new(properties)
	assert((type(properties) == "table") or (type(properties) == "nil"),
		"please provide a valid argument to create a person")
	local person = {}
	person.properties = properties or {}
	person.cache = {}
	setmetatable(person.cache, cache_mt)
	self.__index = self
	setmetatable(person, self)
	return person
end

-- A table to keep track of circular relation definitions
local being_processed = {}

function register_relations(relation_name, path)
	-- Validate inputs
	assert(type(relation_name) == "string", "trying to register a relation with an invalid name")
	assert(type(path) == "table", "please provide a path to register relation " .. relation_name)
	assert(person[relation_name] == nil, "attempt to redefine " .. relation_name)
	-- Saves the factory for the current generator
	local path_factory = nil

	for i, relation in ipairs(path) do
		-- Create a non-local variable for closures
		local closed_path_factory = path_factory
		-- The first relation is just the iterator returned by the object itself
		if closed_path_factory == nil then
			path_factory = function(self) return self[relation](self) end
			goto continue
		end
		-- The creation of an iterator factory for all other relations in the path
		path_factory = function(self)
			-- A check for circular relation definition
			if being_processed[relation] then error("detected circular relation definition for " .. relation) end
			being_processed[relation] = true

			-- The iterator needs to keep track of the current element we're getting
			-- the rest of the path for. To get it, we first save the iterator for
			-- the current level, and call it each time we need to process a new person
			-- on the current level
			assert(self[relation], "unknown relation " .. relation)
			local current_iterator = self[relation](self)
			being_processed[relation] = nil
			local current = current_iterator()

			if current == nil then return function() return nil end end

			-- Then we initialize the path iterator, which returns the next item in the
			-- path we've constructed so far for the current element
			local path_iterator = closed_path_factory(current)

			-- We return an iterator that
			return function()
				-- Returns the next item in the path for the current element
				tmp = path_iterator()
				while tmp == nil do
					-- If the whole path has been covered for the current element
					-- we move on to the next element on the current level
					current = current_iterator()
					-- If this was the last element on the current level then we've returned everything we could
					if current == nil then return nil end
					-- Otherwise, we traverse all the items produced by the path for the current element until a non-nil
					path_iterator = closed_path_factory(current)
					tmp = path_iterator()
				end
				return tmp
			end
		end
		::continue::
	end
	-- Finally, we enclose the resulting finciton with a filter to remove self-relations
	-- As always, we return an iterator factory
	do
		local closed_path_factory = path_factory
		path_factory = function(self)
			-- We get the path iterator for the element we provide
			local iterator = closed_path_factory(self)
			-- We return an iterator that just returns the same elements the path iterator returns
			return function()
				local tmp = nil
				-- Unless we return the element we generated the iterator for, in which case we skip it
				repeat tmp = iterator() until tmp ~= self
				return tmp
			end
		end
	end
	person[relation_name] = function(self)
		if self.cache[relation_name] ~= nil then
			local i = 0
			-- Prevent cache from being garbage-collected while it's being iterated upon
			local relatives = self.cache[relation_name]
			return function()
				i = i + 1
				return self.cache[relation_name][i]
			end
		end
		return path_factory(self)
	end
end

function remove_relation(relation_name)
	assert(type(relation_name) == "string", "relation_name must be a string")
	assert(person[relation_name] ~= nil, "relation_name " .. relation_name .. " does not exists")
	person[relation_name] = nil
end

-- This function returns the table with the relatives of type relation
-- for person named person_name. Requires a filled-out table person_by_name
function get_relatives_for_person(person_name, relation)
	local person = person_by_name[person_name]
	assert(person, "person named " .. person_name .. " does not exist")
	local result = person.properties[relation] or person.cache[relation]
	if result ~= nil then
		if result.properties then
			return {result}
		else
			return result
		end
	end
	result = {}
	local relative_iterator = person[relation]
	if relative_iterator == nil then return nil end
	for relative in relative_iterator(person) do
		result[#result + 1] = relative
	end
	person.cache[relation] = result
	return result
end

-- This function runs the user-provided file containing the calls to register_relations in a secure environment
function process_relations(filename)
	assert(type(filename) == "string", "please provide a sting argument as the filename")
	-- Restrict the environment user-provided code runs in
	local accessible_functions = { register_relations = register_relations }
	local get_relations = assert(loadfile(filename, "t", accessible_functions))
	-- Set limitations on the sandboxed envinronment's execution
	local steplimit = 1000
	local count = 0
	local memlimit = 1000 -- Memory limit in KB
	local function hook(event)
		if collectgarbage("count") > memlimit then error("script uses too much memory") end
		if event == "count" then count = count + 1 end
		if count > steplimit then
			error("script uses too much CPU")
		end
	end

	debug.sethook(hook, "c", 100)
	get_relations()
	debug.sethook()
end

function print_properties(person)
	local properties = person.properties
	print(properties.name, properties.gender)
	if properties.spouse ~= nil then print("Spouse: ", properties.spouse.properties.name) end
	if properties.parent ~= nil then
		print("Parents")
		for _, v in pairs(properties.parent) do
			if v ~= nil then print(v.properties.name, v.properties.gender) end
		end
	end
	if properties.child ~= nil then
		print("Children")
		for _, v in pairs(properties.child) do
			if v ~= nil then print(v.properties.name, v.properties.gender) end
		end
	end
end
return {
	get_relatives_for_person = get_relatives_for_person,
	process_relations = process_relations,
	person = person
}
