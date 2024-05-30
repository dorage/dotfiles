local function join(p1, p2)
	local path = p1 .. "/" .. p2
	return string.gsub(path, "//", "/")
end

-- To find subpackage's root in monorepo
-- findPackageJson(vim.fn.expand('%'), 'package.json')
local function findDirectoryByFilename(directory, filename)
	local filePath = join(directory, filename)

	local file = io.open(filePath, "r")
	if file then
		file:close()
		return directory
	end

	local parentDirectory = directory:match("(.*)/")

	if not parentDirectory or parentDirectory == directory then
		-- We've reached the root directory
		return nil
	end

	return findDirectoryByFilename(parentDirectory, filename)
end

return { findDirectoryByFilename = findDirectoryByFilename }
