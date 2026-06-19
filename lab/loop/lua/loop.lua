-- Shared path utility for loop agents
-- Returns the loop directory inside the workbench cache.
local function get_loop_dir(wb)
	return wb.cache_dir .. "/loop"
end

-- Return a table with all loop-related paths.
-- wb must be a workbench table with a cache_dir field.
local function get_loop_paths(wb)
	local dir = get_loop_dir(wb)
	return {
		dir = dir,
		original_prompt = dir .. "/prompt-original.md",
		instructions = dir .. "/loop-instructions.md",
		prompt = dir .. "/prompt-next.md",
	}
end

return {
	get_loop_dir = get_loop_dir,
	get_loop_paths = get_loop_paths
}
