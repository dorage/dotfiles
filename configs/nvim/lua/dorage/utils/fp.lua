local M = {}

---------------------------------------------------------------------------------------
--
-- high-order functions
--
---------------------------------------------------------------------------------------

---return true if some item in array satisfies condition
---@generic T
---@param array T[]
---@param condition fun(value:T, index:number, array:T[]): boolean
---@return boolean
M.some = function(array, condition)
	for index, value in ipairs(array) do
		if condition(value, index, array) then
			return true
		end
	end
	return false
end

---return true if every item in array satisfies condition
---@generic T
---@param array T[]
---@param condition fun(value:T, index:number, array:T[]): boolean
---@return boolean
M.every = function(array, condition)
	for index, value in ipairs(array) do
		if not condition(value, index, array) then
			return false
		end
	end
	return true
end
--

---return new array with items that satisfy condition
---@generic T
---@param array T[]
---@param condition fun(value:T, index:number, array:T[]): boolean
---@return T[]
M.filter = function(array, condition)
	local result = {}
	for index, value in ipairs(array) do
		if condition(value, index, array) then
			result[#result + 1] = value
		end
	end
	return result
end

---run iteratee for each item in array
---@generic T
---@param array T
---@param iteratee fun(value:T, index:number, array:T[]): nil
M.each = function(array, iteratee)
	for index, value in ipairs(array) do
		iteratee(value, index, array)
	end
end

---return a new array with each value of array transformed by iteratee
---@generic T
---@param array T[]
---@param iteratee fun(value:T, index:number, array:T[]): nil
---@return T[]
M.map = function(array, iteratee)
	local result = {}
	for index, value in ipairs(array) do
		result[#result + 1] = iteratee(value, index, array)
	end
	return result
end

---execute functions, passed by arguments, in sequence
---@param ... unknown
---@return function
M.pipe = function(...)
	local funcs = { ... }
	return function(...)
		local result = { ... }
		for _, func in ipairs(funcs) do
			result = { func(unpack(result)) }
		end
		return unpack(result)
	end
end

---pass arguments to function in pipe
---@param func any
---@param ... unknown
---@return function
M.pipe_curry = function(func, ...)
	local curry_args = { ... }
	return function(...)
		local pipe_args = { ... }
		return func(unpack(pipe_args), unpack(curry_args))
	end
end

---------------------------------------------------------------------------------------
--
-- table manipulation
--
---------------------------------------------------------------------------------------

---comment
---@param o table
---@return string
M.dump = function(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. M.dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

---combine tables
---@param ... any
---@return any[]
M.combine = function(...)
	local tables = { ... }
	local combined_table = {}

	for _, table in ipairs(tables) do
		for key, value in pairs(table) do
			if combined_table[key] ~= nil then
				combined_table[#combined_table + 1] = value
			else
				combined_table[key] = value
			end
		end
	end

	return combined_table
end

---------------------------------------------------------------------------------------
--
-- return
--
---------------------------------------------------------------------------------------

return M
