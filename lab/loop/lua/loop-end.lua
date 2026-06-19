local loop = require("loop")
local loop_check = require("loop-check")

local function loop_end(params)
	aip.run.set_label("loop-end")

	local workbench = params.workbench
	local inputs = params.inputs
	---@cast inputs -nil

	-- Read check flags from agent config (build, test, clippy)
	local agent_config = value_or(inputs.agent_config, {})
	local check_flags = loop_check.get_check_flags(agent_config)

	-- Workbench absent: skip
	if workbench == nil then
		return { success = true, coder_redo = false }
	end

	local loop_paths = params.loop_paths or loop.get_loop_paths(workbench)

	---@cast loop_paths -nil

	-- Run cargo checks and manage fix mode (directory is created only when files are written)
	local data_check_dir = loop_check.get_data_check_dir(workbench)
	if data_check_dir and loop_check.any_check_enabled(check_flags) then
		local check_args = agent_config.args
		local failing_paths = loop_check.run_checks(check_flags, data_check_dir, check_args)
		local fix_result = loop_check.update_fix_mode(loop_paths.dir, failing_paths)
		loop_check.cleanup_empty_dir(data_check_dir)
		if fix_result.should_redo then
			return { coder_redo = true, success = true }
		end
	end

	aip.file.ensure_dir(loop_paths.dir)
	aip.file.ensure_exists(loop_paths.prompt, "")

	-- Scan extruded AI responses for <NEXT_PROMPT> tags
	local next_tags = {}
	local responses = value_or(inputs.coder_responses, {})
	for _, resp in ipairs(responses) do
		local extruded = value_or(resp.content_extruded, "")
		local tags = aip.tag.extract(extruded, "NEXT_PROMPT")
		for _, tag in ipairs(tags) do
			table.insert(next_tags, tag.content or "")
		end
	end

	-- Find the first non‑empty tag content
	local new_content = ""
	for _, c in ipairs(next_tags) do
		local trimmed = aip.text.trim(c)
		if trimmed ~= nil and trimmed ~= "" then
			new_content = trimmed
			break
		end
	end

	if new_content == "" and #next_tags > 0 then
		new_content = next_tags[1]
	end

	if #next_tags > 0 then
		aip.file.save(loop_paths.prompt, new_content)
		aip.run.pin("loop-end", { label = "Next prompt:", content = new_content })
		return {
			coder_redo = true,
			success = true,
		}
	end

	-- No next prompt requested: write THE_END marker and pin
	-- No next prompt requested: remove the prompt file to indicate loop completion
	if aip.file.exists(loop_paths.prompt) then
		aip.file.delete(loop_paths.prompt)
	end
	aip.run.pin("loop-end", "No next prompt requested. Loop ended.")

	return {
		coder_redo = false,
		success = true,
	}
end

return {
	loop_end = loop_end,
}
