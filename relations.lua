-- Pre-defined relations
function male_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(self["gender"], "the table doesn't have the necessary field to filter on")
	local has_been_called = false
	return function()
		if has_been_called then return nil end
		has_been_called = true
		if self["gender"] == "male" then return self
		else return nil end
	end
end

function female_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(self["gender"], "the table doesn't have the necessary field to filter on")
	local has_been_called = false
	return function()
		if has_been_called then return nil end
		has_been_called = true
		if self["gender"] == "female" then return self
		else return nil end
	end
end

function spouse_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(self["spouse"], "the table doesn't have the necessary field to iterate on")
	local has_been_called = false
	return function()
		if has_been_called then return nil end
		has_been_called = true
		return self["spouse"]
	end
end

function child_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(self["child"], "the table doesn't have the necessary field to iterate on")
	local i = 0
	return function()
		if i > #self["child"] then return nil end
		i = i + 1
		return self["child"][i]
	end
end

function parent_iterator_factory(self)
	assert(typeof(self) == "table", "invalid input for iterator factory function")
	assert(self["parent"], "the table doesn't have the necessary field to iterate on")
	local i = 0
	return function()
		if i > #self["parent"] then return nil end
		i = i + 1
		return self["parent"][i]
	end
end

-- A table to keep track of circular relation definitions
local being_processed = {}

-- A table with all relation finction iterator factories
local relation_functions = {
	male = male_iterator_factory,
	female = female_iterator_factory,
	spouse = spouse_iterator_factory,
	child = child_iterator_factory,
	parent = parent_iterator_factory
}

function register_relaions (relation_name, path)
	-- Validate inputs
	assert(relation_name, "trying to register a relation without a name")
	assert(typeof(path) == "table", "please provide a path to register a relation")
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
			if being_prosessed[relation] then error("Detected circular relation definition for " .. relation) end
			being_processed[relation] = true

			-- The iterator needs to keep track of the current element we're getting
			-- the rest of the path for. To get it, we first save the iterator for
			-- the current level, and call it each time we need to process a new person
			-- on the current level
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
	relation_functions[relation_name] = function (self)
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
end
