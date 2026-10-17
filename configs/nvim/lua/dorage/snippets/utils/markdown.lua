local M = {}

local entities = {
	["&amp;"] = "&",
	["&lt;"] = "<",
	["&gt;"] = ">",
	["&quot;"] = '"',
	["&#39;"] = "'",
}

--- url 의 html <title> 을 가져옴, 실패하면 빈 문자열
---@param url string
---@return string
M.get_url_title = function(url)
	if not url:match("^https?://") then
		return ""
	end

	local ok, result = pcall(function()
		return vim.system({ "curl", "-sL", "--max-time", "3", url }, { text = true }):wait()
	end)
	if not ok or result.code ~= 0 or not result.stdout then
		return ""
	end

	local title = result.stdout:match("<[Tt][Ii][Tt][Ll][Ee][^>]*>(.-)</[Tt][Ii][Tt][Ll][Ee]>")
	if not title then
		return ""
	end

	title = title:gsub("[\n\r]", " "):gsub("%s+", " "):gsub("&[#%w]+;", entities)
	return vim.trim(title)
end

return M
