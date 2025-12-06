local CONFIG_PATH  = "./ako-config.jsonc"

function config_edit_msg(config_path)
  return "Edit the prompt file:\n\n➜ " .. config_path .. "\n\n(Activate or customize the section you want to run and press 'r')"
end

-- Init or check that the config is present
-- `input` can be the path of a json file with the config
--         or the default will be `./ako-config.jsonc`
-- Returns 
--  - { type = "message", data = string } if something needs to be done by the user
--  - { type = "config",  data = {... config ...} }
function init_config(input)
  config_path = type(input) == "string" and input or CONFIG_PATH

  -- == If the config does not exist, create it, and prompt user
  if not aip.path.exists(config_path) then
    local xp_config_path = CTX.AGENT_FILE_DIR .. "/config/ako-config-template.jsonc"
    local config_content = aip.file.load(xp_config_path).content
    aip.file.save(CONFIG_PATH, config_content)

    msg = config_edit_msg(CONFIG_PATH)

    return {
      type = "message",
      data = msg
    }
  end

  -- == Load config
  local config = aip.file.load_json(config_path)

  -- == If config empty, prompt user to edit it 
  if config == nil then
      msg = config_edit_msg(config_path)
      return {
        type = "message",
        data = msg
      }
  end

  -- == Needs to remove the starting "./" as aip.path.diff will create wrong path (will be solved in future aipack)
  if config.base_dir and type(config.base_dir) == "string" then
    config.base_dir = config.base_dir:gsub("^%./", "")
  end

  -- == Otherise, we can return the config
  -- Add config_path
  config.config_path = config_path
  return {
    type = "config",
    data = config
  }

end

-- Build the settings from a config data
-- returns { config, base_data_dir, url_obj, dir_... }
function build_settings(config) 

  local src_type = nil -- "web" | "dir"
  local base_data_dir = nil
  local base_url_path_prefix = nil
  
  if config.base_url then
    local url_obj   = aip.web.parse_url(config.base_url)
    base_data_dir = config.out_dir .. "/" .. url_obj.host
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
    base_data_dir = config.out_dir .. "/" .. base_dir_obj.stem
  else
    error("ako-config.jsonc must have base_url or _base_dir")
  end

  local settings = {
    src_type        = src_type,
    config          = config,

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

-- == Return the functions for this module
return {
  validate_aip_version = validate_aip_version, 
  init_config          = init_config,
  build_settings       = build_settings,
}