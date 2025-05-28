local BASE_OUT_DIR = "_ako-out"

-- returns { config, base_data_dir, url_obj, dir_... }
function load_settings(input) 

  local config_path = "ako-config.json"

  config_path = type(input) == "string" and input or config_path
  local config = aip.file.load_json(config_path)

  local url_obj   = aip.web.parse_url(config.base_url)

  local base_data_dir = BASE_OUT_DIR .. "/" .. url_obj.host



  return {
    config         = config,
    base_url_obj   = base_url_obj,

    base_data_dir   = base_data_dir,
    dir_0_original  = base_data_dir .. "/0-original",
    dir_1_slim_html = base_data_dir .. "/1-slim-html",
    dir_2_raw_md    = base_data_dir .. "/2-raw-md",
    dir_3_final_md  = base_data_dir .. "/3-final-md",
  }

end

-- == Return the functions for this module
return {
  load_settings  = load_settings,
}