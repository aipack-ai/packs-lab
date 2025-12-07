local CONFIG_PATH  = ".aipack/.prompt/" .. (CTX.PACK_IDENTITY or "lab@ako") .. "/ako-config.jsonc"

-- Converts a string (URL, path, etc.) into a folder-friendly canonical form.
-- All single or consecutive special characters are collapsed to `-`.
-- Example: "docs.rs/xmltree/0.12.0/xmltree/" -> "docs-rs-xmltree-0-12-0-xmltree"
function canonicize(some_string)
  if some_string == nil then
    return nil
  end
  
  -- Remove protocol prefix if present (http://, https://, etc.)
  local str = some_string:gsub("^%w+://", "")
  
  -- Replace any sequence of non-alphanumeric characters with a single dash
  str = str:gsub("[^%w]+", "-")
  
  -- Remove leading and trailing dashes
  str = str:gsub("^%-+", ""):gsub("%-+$", "")
  
  return str
end

function config_edit_msg(config_path)
  return "Edit the prompt file:\n\n➜ " .. config_path .. "\n\n(Activate or customize the section you want to run and press 'r')"
end

-- Init or check that the config is present
-- `input` can be the path of a json file with the config
--         or the default will be `.aipack/.prompt/lab@ako/ako-config.jsonc`
-- Returns 
--  - { type = "message", data = string } if something needs to be done by the user
--  - { type = "config",  data = {... config ...} }
function init_config(input)
  local config_path = type(input) == "string" and input or CONFIG_PATH
  local res = { config_path = config_path }

  -- == If the config does not exist, create it, and prompt user
  if not aip.path.exists(config_path) then
    local xp_config_path = CTX.AGENT_FILE_DIR .. "/config/ako-config-template.jsonc"
    local config_content = aip.file.load(xp_config_path).content
    aip.file.save(config_path, config_content)

    res.data = config_edit_msg(config_path)
    res.type = "message"
    return res
  end

  -- == Load config
  local config = aip.file.load_json(config_path)

  -- == If config empty, prompt user to edit it 
  if config == nil then
      res.data = config_edit_msg(config_path)
      res.type = "message"
      return res
  end

  -- == Needs to remove the starting "./" as aip.path.diff will create wrong path (will be solved in future aipack)
  if config.base_dir and type(config.base_dir) == "string" then
    config.base_dir = config.base_dir:gsub("^%./", "")
  end

  -- == Otherise, we can return the config
  -- Add config_path
  config.config_path = config_path
  res.data = config
  res.type = "config"
  return res
end

-- Resolves out_base_dir, supporting $ako_config_dir/ prefix
-- $ako_config_dir/ is replaced with the directory containing the ako-config.jsonc file
function resolve_out_base_dir(config)
  local out_base_dir = config.out_base_dir
  
  if out_base_dir and out_base_dir:sub(1, 16) == "$ako_config_dir/" then
    -- Get the directory of the config file
    local config_dir = aip.path.parent(config.config_path) or "."
    -- Replace the prefix with the actual directory
    out_base_dir = config_dir .. "/" .. out_base_dir:sub(17)
  end
  
  return out_base_dir
end

-- Build the settings from a config data
-- returns { config, base_data_dir, url_obj, dir_... }
function build_settings(config) 

  local src_type = nil -- "web" | "dir"
  local base_data_dir = nil
  local base_url_path_prefix = nil
  
  -- Resolve out_base_dir with potential $ako_config_dir/ prefix
  local out_base_dir = resolve_out_base_dir(config)
  
  if config.base_url then
    local url_obj   = aip.web.parse_url(config.base_url)
    -- Use canonicize to create folder name from host + path
    local canonical_name = canonicize(url_obj.host .. (url_obj.path or ""))
    base_data_dir = out_base_dir .. "/" .. canonical_name
    src_type = "web"
    
    -- Extract path part from base_url to be used as a prefix to strip off from fetched URLs' paths
    base_url_path_prefix = url_obj.path or "/"

    -- Ensure base_url_path_prefix ends with a slash if it's not just "/"
    -- This helps in stripping the prefix cleanly from full URL paths.
    if base_url_path_prefix ~= "/" and not base_url_path_prefix:match("/$") then
      base_url_path_prefix = base_url_path_prefix .. "/"
    end

  elseif config.base_dir then
    src_type = "file"
    local base_dir_obj = aip.path.parse(config.base_dir)
    base_data_dir = out_base_dir .. "/" .. base_dir_obj.stem
  else
    error("ako-config.jsonc must have base_url or _base_dir")
  end

  local settings = {
    src_type        = src_type,
    config          = config,

    out_base_dir    = out_base_dir,
    base_data_dir   = base_data_dir,
    base_url_path_prefix = base_url_path_prefix, -- nil for src_type="file"
    dir_0_original  = base_data_dir .. "/0-original",
    dir_1_slim_html = base_data_dir .. "/1-slim-html",
    dir_2_raw_md    = base_data_dir .. "/2-raw-md",
    dir_3_sum_md    = base_data_dir .. "/3-sum-md",
    dir_4_final_md  = base_data_dir .. "/4-final-md",
    dir_5_docaify   = base_data_dir .. "/5-docaify-md",
  }

  return settings

end

-- Resolves target paths supporting $ako_out_dir/ prefix
-- $ako_out_dir/ is replaced with the resolved base_data_dir (from build_settings)
function resolve_target_path(target_path, settings)
  if target_path == nil or type(target_path) ~= "string" then
    return nil
  end
  
  local resolved_path = target_path
  
  if resolved_path:sub(1, 13) == "$ako_out_dir/" then
    -- $ako_out_dir now maps to base_data_dir (which includes the canonical name folder)
    local out_dir = settings.base_data_dir or "." 
    -- Replace the prefix with the actual directory
    resolved_path = out_dir .. "/" .. resolved_path:sub(14)
  end
  
  return resolved_path
end


-- Returns
-- true if it is valid
-- string if not ok and user need to 
function validate_aip_version() 
  if not aip.semver.compare(CTX.AIPACK_VERSION, ">=", "0.7.18") then
      local msg = "\nWARNING - lab/ako pack requires AIPACK_VERSION 0.7.19 or above, but " .. CTX.AIPACK_VERSION .. " is currently installed"
      msg = msg .. "\n\nACTION  - Update your aipack via `aip self update` (for Mac/Linux), or from https//aipack.ai)"
      return msg
  else
      return true
  end
end

-- Ensures instruction files exist in the config directory's instructions folder
-- Copies from template if they don't exist
-- Returns table of created file paths
function ensure_instruction_files(config_path)
  local config_dir = aip.path.parent(config_path) or "."
  local instructions_dir = config_dir .. "/instructions"
  print(config_dir)
  
  local instruction_files = {
    { src = "instruction-1-aug.md", dest = "instruction-1-aug.md" },
    { src = "instruction-2-llms-index.md", dest = "instruction-2-llms-index.md" },
    { src = "instruction-3-docaify.md", dest = "instruction-3-docaify.md" },
  }
  
  local created = {}
  
  for _, file_info in ipairs(instruction_files) do
    local dest_path = instructions_dir .. "/" .. file_info.dest
    if not aip.path.exists(dest_path) then
      local src_path = CTX.AGENT_FILE_DIR .. "/config/" .. file_info.src
      if aip.path.exists(src_path) then
        local content = aip.file.load(src_path).content
        aip.file.save(dest_path, content)
        table.insert(created, dest_path)
      end
    end
  end
  
  return created
end

-- Loads instruction content from the config directory's instructions folder
-- Returns the content string or nil if not found
function load_instruction(config_path, instruction_filename)
  local config_dir = aip.path.parent(config_path) or "."
  local instruction_path = config_dir .. "/instructions/" .. instruction_filename
  
  if aip.path.exists(instruction_path) then
    return aip.file.load(instruction_path).content
  end
  
  return nil
end

-- SetupInfo type:
-- {
--   type: "skip" | "message" | "ready",
--   skip_reason?: string,        -- when type == "skip"
--   message?: string,            -- when type == "message"
--   config?: table,              -- when type == "ready"
--   settings?: table,            -- when type == "ready"
--   config_path?: string,        -- when type == "ready"
--   readme_created?: boolean,    -- when type == "ready"
--   instructions_created?: string[], -- when type == "ready"
-- }

-- Main setup function that handles all initialization logic
-- `input` can be the path of a json file with the config, or nil for default
-- Returns SetupInfo
function setup(input)
  -- Validate AIP version first
  local valid = validate_aip_version()
  if type(valid) == "string" then
    return {
      type = "skip",
      skip_reason = valid
    }
  end

  -- Initialize config
  local init_res = init_config(input)
  local config_path = init_res.config_path

  -- Create README.md from template if it doesn't exist
  local config_dir = aip.path.parent(config_path) or "."
  local readme_path = config_dir .. "/README.md"
  local readme_created = false
  if not aip.path.exists(readme_path) then
    local readme_template_path = CTX.AGENT_FILE_DIR .. "/config/readme-template.md"
    local readme_content = aip.file.load(readme_template_path).content
    aip.file.save(readme_path, readme_content)
    readme_created = true
  end

  -- Ensure instruction files exist
  local instructions_created = ensure_instruction_files(config_path)

  if init_res.type == "message" then
    return {
      type = "message",
      message = init_res.data,
      config_path = config_path,
      readme_path = readme_path,
      readme_created = readme_created,
      instructions_created = instructions_created
    }
  end

  -- Assuming type == "config"
  local config = init_res.data
  local settings = build_settings(config)

  return {
    type = "ready",
    config = config,
    settings = settings,
    config_path = config_path,
    readme_path = readme_path,
    readme_created = readme_created,
    instructions_created = instructions_created
  }
end

-- == Return the functions for this module
return {
  canonicize                = canonicize,
  validate_aip_version      = validate_aip_version, 
  init_config               = init_config,
  build_settings            = build_settings,
  setup                     = setup,
  ensure_instruction_files  = ensure_instruction_files,
  load_instruction          = load_instruction,
  resolve_target_path       = resolve_target_path,
}