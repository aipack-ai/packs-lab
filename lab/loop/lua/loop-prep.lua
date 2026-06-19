-- Shared utilities for the loop-prep agent
-- Provides functions to load preparation data and save the generated files.

local function get_prep_data(loop_dir, agent_file_dir)
	-- Load original prompt
	local original_path = loop_dir .. "/prompt-original.md"
	local original_load = aip.file.load(original_path)
	local original_content = original_load and original_load.content or ""

	-- Load loop rules template
	local rules_path = aip.path.join(agent_file_dir, "templates/loop-rules.md")
	local rules_load = aip.file.load(rules_path)
	local rules_content = rules_load and rules_load.content or ""

	return {
		original_prompt = original_content,
		loop_rules = rules_content,
	}
end

local function save_prep_files(response_content, loop_dir)
	local instructions_path = loop_dir .. "/loop-instructions.md"
	local prompt_path = loop_dir .. "/prompt-next.md"

	local content = response_content or ""

	-- Split by delimiter
	local delim = "=====PROMPT====="
	local i1, i2 = content:find(delim, 1, true)
	if i1 then
		local instructions = content:sub(1, i1 - 1):gsub("\n$", "")
		local prompt = content:sub(i2 + 1):gsub("^\n+", ""):gsub("\n+$", "")

		aip.file.save(instructions_path, instructions)
		aip.file.save(prompt_path, prompt)
	else
		-- Fallback: save whole content as instructions (old behavior)
		aip.file.save(instructions_path, content)
	end
	return true
end

return {
	get_prep_data = get_prep_data,
	save_prep_files = save_prep_files,
}
