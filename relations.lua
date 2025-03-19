-- Pre-defined relations
function male_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(typeof(self.properties) == "table", "invalid input for iterator factory function")
	assert(self.properties["gender"], "the table doesn't have the necessary field to filter on")
	local has_been_called = false
	return function()
		if has_been_called then return nil end
		has_been_called = true
		if self.properties["gender"] == "male" then return self
		else return nil end
	end
end

function female_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(typeof(self.properties) == "table", "invalid input for iterator factory function")
	assert(sef.properties["gender"], "the table doesn't have the necessary field to filter on")
	local has_been_called = false
	return function()
		if has_been_called then return nil end
		has_been_called = true
		if sef.properties["gender"] == "female" then return self
		else return nil end
	end
end

function spouse_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(typeof(self.properties) == "table", "invalid input for iterator factory function")
	assert(sef.properties["spouse"], "the table doesn't have the necessary field to iterate on")
	local has_been_called = false
	return function()
		if has_been_called then return nil end
		has_been_called = true
		return sef.properties["spouse"]
	end
end

function child_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(typeof(self.properties) == "table", "invalid input for iterator factory function")
	assert(sef.properties["child"], "the table doesn't have the necessary field to iterate on")
	local i = 0
	return function()
		if i > #sef.properties["child"] then return nil end
		i = i + 1
		return sef.properties["child"][i]
	end
end

function parent_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(typeof(self.properties) == "table", "invalid input for iterator factory function")
	assert(sef.properties["parent"], "the table doesn't have the necessary field to iterate on")
	local i = 0
	return function()
		if i > #sef.properties["parent"] then return nil end
		i = i + 1
		return sef.properties["parent"][i]
	end
end

-- A prototype for creating people
local person = {
	male = male_iterator_factory,
	female = female_iterator_factory,
	spouse = spouse_iterator_factory,
	child = child_iterator_factory,
	parent = parent_iterator_factory
}

local cache_mt = {__mode = "v"}
function person:new(properties)
	assert((typeof(properties) == "table") or (typeof(properties) == "nil"), "please provide a valid argument to create a person")
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

function register_relations (relation_name, path)
	-- Validate inputs
	assert(typeof(relation_name) == "string", "trying to register a relation with an invalid name")
	assert(typeof(path) == "table", "please provide a path to register relation" .. relation_name)
	assert(person[relation_name] == nil, "attempt to redefine" .. relation_name)
	-- Create a non-local variable for the closures
	local func = nil

	for _, relation in ipairs(path) do
		-- The first relation is just the iterator returned by the object itself
		if func == nil then
			func = function (self) return self[relation](self) end
			goto continue
		end
		-- The creation of an iterator factory for all other relations in the path
		func = function(self)
			-- A check for circular relation definition
			if being_prosessed[relation] then error("detected circular relation definition for " .. relation) end
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
			local path_iterator = func(current)

			-- We return an iterator that
			return function()
				-- Returns the next item in the path for the current element
				tmp = chain_iterator()
				while tmp == nil do
					-- If the whole path has been covered for the current element
					-- we move on to the next element on the current level
					current = current_iterator()
					-- If this was the last element on the current level then we've returned everything we could
					if current == nil then return nil end
					-- Otherwise, we traverse all the items produced by the path for the current element until a non-nil
					path_iterator = func(current)
					tmp = chain_iterator()
				end
				return tmp
			end
			
		end
	::continue::
	end
	-- Finally, we enclose the resulting finciton with a filter to remove self-relations
	-- As always, we return an iterator factory
	func = function (self)
		-- We get the path iterator for the element we provide
		local iterator = func(self)
		-- We return an iterator that just returns the same elements the path iterator returns 
		return function()
			local tmp = nil
			-- Unless we return the element we generated the iterator for, in which case we skip it
			repeat tmp = iterator() until tmp ~= self
			return tmp
		end
	end
	person[relation_name] = function(self)
		if self.cache[relation_name] ~= nil then
			local i = 0
			return function() i = i + 1 return self.cache[relation][i] end
		end
		return func(self)
	end
end

-- This function returns the table with the relatives of type relation
-- for person named person_name. Requires a filled-out table person_by_name
function get_relation_for_person(person_name, relation)
	local person = person_by_name[person_name]
	assert(person, "person named " .. person_name .. " does not exist")
	local result = person.properties[relation] or person.cache[relation]
	if result ~= nil then return result end
	result = {}
	local relative_iterator = person[relation]
	assert(relative_iterator, "failed to find relation " .. relation)
	for relative in relative_iterator(person) do
		result[#result + 1] = relative
	end
	person.cache[relation] = result
	return result
end

-- This function runs the user-provided file containing the calls to register_relations in a secure environment
function process_relations(filename)
	assert(typeof(filename) == "string", "please provide a sting argument as the filename")
	-- Restrict the environment user-provided code runs in
	local accessible_functions = {register_relations}
	local get_relations = assert(loadfile(filename, "t", accessible_functions))
	-- Set limitations on the sandboxed envinronment's execution
	local steplimit = 1000
	local count = 0
	local memlimit = 1000 -- Memory limit in KB
	local function hook()
		if collectgarbage("count") > memlimit then error("script uses too much memory") end
		count = count + 1
		if count > steplimit then
			error ("script uses too much CPU")
		end
	end

	debug.sethook(hook, "c", 100)
	get_relations()
	debug.sethook()
end
