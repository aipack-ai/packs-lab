local loop_check = {}

-- Returns a table with boolean flags for build, test, clippy from agent_config.
function loop_check.get_check_flags(agent_config)
	return {
		build = value_or(agent_config.build, false),
		test  = value_or(agent_config.test, false),
		lint  = value_or(agent_config.clippy, false),
	}
end

-- Returns true if any check is enabled.
function loop_check.any_check_enabled(check_flags)
	return check_flags.build or check_flags.test or check_flags.lint
end

-- List of all possible check definitions.
local all_checks = {
	{ key = "build", cmd = "cargo", file_name = "cargo-build.txt", args = { "build", "--examples" } },
	{ key = "test",  cmd = "cargo", file_name = "cargo-test.txt",  args = { "test", "--", "--nocapture" } },
	{ key = "lint",  cmd = "cargo", file_name = "cargo-lint.txt",  args = { "clippy", "--all-targets", "--", "-D", "warnings" } },
}

-- Returns only the enabled check definitions for the given flags.
function loop_check.get_enabled_checks(check_flags)
	local enabled = {}
	for _, c in ipairs(all_checks) do
		if check_flags[c.key] then
			table.insert(enabled, c)
		end
	end
	return enabled
end

function loop_check.get_data_check_dir(workbench)
	if not workbench or not workbench.data_dir then
		return nil
	end
	return workbench.data_dir .. "/check"
end

function loop_check.run_checks(check_flags, data_check_dir, check_args)
	local failing_paths = {}
	check_args = check_args or {}

	for _, c in ipairs(all_checks) do
		local enabled = check_flags[c.key]
		local file_path = data_check_dir .. "/" .. c.file_name

		if enabled then
			-- Build the list of arguments for the cargo subcommand
			local cmd_args = {}
			if c.args then
				for _, a in ipairs(c.args) do
					table.insert(cmd_args, a)
				end
			end
			local extra = check_args[c.key]
			if extra then
				if type(extra) == "table" then
					for _, a in ipairs(extra) do
						table.insert(cmd_args, a)
					end
				else
					table.insert(cmd_args, extra)
				end
			end
			-- Build a display string for error messages
			local full_cmd = c.cmd
			if #cmd_args > 0 then
				full_cmd = full_cmd .. " " .. table.concat(cmd_args, " ")
			end
			local result = aip.cmd.exec(c.cmd, cmd_args)
			if not result.error then
				local combined = (result.stdout or "") .. "\n" .. (result.stderr or "")
				if result.exit ~= 0 then
					aip.file.ensure_dir(data_check_dir)
					aip.file.save(file_path, combined)
					table.insert(failing_paths, file_path)
				else
					if aip.file.exists(file_path) then
						aip.file.delete(file_path)
					end
				end
			else
				aip.run.pin("loop-check-error", { label = c.key, content = result.error })
			end
		else
			-- Clean up stale file for disabled check
			if aip.file.exists(file_path) then
				aip.file.delete(file_path)
			end
		end
	end

	return failing_paths
end

-- Returns the path to the fix-prompt.md file inside the loop directory.
local function fix_prompt_path(loop_dir)
	return loop_dir .. "/check/fix-prompt.md"
end

-- Checks whether fix mode is active by looking for fix-prompt.md.
-- Returns fix_mode (boolean) and, if active, the trimmed content of the fix prompt.
function loop_check.is_fix_mode(loop_dir)
	local path = fix_prompt_path(loop_dir)
	if aip.file.exists(path) then
		local raw = aip.file.load(path)
		if raw and raw.content then
			return true, aip.text.trim(raw.content)
		end
	end
	return false, nil
end

function loop_check.update_fix_mode(loop_dir, failing_paths)
	local fix_dir = loop_dir .. "/check"
	local path = fix_prompt_path(loop_dir)

	if #failing_paths > 0 then
		aip.file.ensure_dir(fix_dir)
		local lines = {}
		table.insert(lines, "Build/test/link checks have FAILED.")
		table.insert(lines, "")

		-- Collect source files referenced in the error output.
		local source_files = {}
		local source_seen = {}
		for _, p in ipairs(failing_paths) do
			local record = aip.file.load(p)
			if record and record.content then
				local spaths = loop_check.extract_source_file_paths(record.content)
				for _, sp in ipairs(spaths) do
					if not source_seen[sp] then
						source_seen[sp] = true
						table.insert(source_files, sp)
					end
				end
			end
		end

		table.insert(lines, "The following check output files contain full error details (provided in context):")
		table.insert(lines, "")
		for _, p in ipairs(failing_paths) do
			local rel = aip.path.diff(p, CTX.WORKSPACE_DIR)
			if not rel or rel == "" then
				rel = p
			end
			table.insert(lines, "- " .. rel)
		end
		table.insert(lines, "")

		if #source_files > 0 then
			table.insert(lines, "Source files referenced in the errors:")
			table.insert(lines, "")
			for _, sp in ipairs(source_files) do
				table.insert(lines, "- " .. sp)
			end
			table.insert(lines, "")
			table.insert(lines, "Review the check output files to understand what needs fixing in the source files above.")
		else
			table.insert(lines, "Review the check output files to understand what needs fixing.")
		end
		table.insert(lines, "")
		table.insert(lines, "Do not emit a <NEXT_PROMPT> tag; the loop will re-run checks automatically.")
		local content = table.concat(lines, "\n")
		aip.file.save(path, content)
		aip.run.pin("loop-fix-mode", "Entering fix mode due to check failures")
		return { fix_mode = true, should_redo = true }
	else
		if aip.file.exists(path) then
			aip.file.delete(path)
			loop_check.cleanup_empty_dir(fix_dir)
			aip.run.pin("loop-fix-mode", "Exiting fix mode; all checks passed or checks disabled.")
			return { fix_mode = false, should_redo = true }
		end
		return { fix_mode = false, should_redo = false }
	end
end

-- Returns a list of existing check output file paths from the data check directory.
-- Useful for including in context_globs_post.
function loop_check.get_check_file_paths(data_check_dir)
	if not data_check_dir or not aip.file.exists(data_check_dir) then
		return {}
	end
	local paths = {}
	for _, c in ipairs(all_checks) do
		local p = data_check_dir .. "/" .. c.file_name
		if aip.file.exists(p) then
			table.insert(paths, p)
		end
	end
	return paths
end

-- Removes the given directory if it exists and is empty.
function loop_check.cleanup_empty_dir(dir_path)
	if not dir_path then return end
	if not aip.path.is_dir(dir_path) then return end
	local files = aip.file.list("*", { base_dir = dir_path })
	if #files == 0 then
		aip.cmd.exec("rmdir", dir_path)
	end
end

-- Extracts source file paths (e.g., .rs, .toml, .lua) referenced in cargo error output.
-- Scans the text for patterns like `--> src/main.rs:10:5` or paths ending with those extensions.
-- Returns a deduplicated list of relative file paths.
function loop_check.extract_source_file_paths(text)
	local paths = {}
	local seen = {}
	for _, ext in ipairs({ "rs", "toml", "lua" }) do
		for file in string.gmatch(text, "([%w_/%.%-]+%." .. ext .. ")") do
			if not seen[file] then
				seen[file] = true
				table.insert(paths, file)
			end
		end
	end
	return paths
end

return loop_check
