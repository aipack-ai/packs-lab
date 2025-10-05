-- fectch_ctx: {page_counter, total_orig_size, total_slim_size, total_md_raw_size}
function process_url(url_str, fetch_ctx)
  local settings  = fetch_ctx.settings
  local max_pages = fetch_ctx.settings.config.max_pages

  local url_obj   = aip.web.parse_url(url_str)
  aip.run.pin("process", 1, {label = "Processing:", content = url_str})

  local url       = url_obj.url
  local host      = url_obj.host

  local html_res     = aip.web.get(url)
  local html_content = html_res.content

  local res = process_content(url_obj.path, html_content, fetch_ctx)

  return res

end

-- fectch_ctx: {page_counter, total_orig_size, total_slim_size}
function process_links(links, page_urls_map, current_page_url, fetch_ctx) 
  local max_pages         = fetch_ctx.settings.config.max_pages
  local base_url          = fetch_ctx.settings.config.base_url
  local filter_path       = fetch_ctx.settings.config.filter_path or "/"
  local exclude_globs     = fetch_ctx.settings.config.exclude_globs or {}
  local has_exclude_globs = fetch_ctx.has_exclude_globs

  local links_queue = {}
  for i, link in ipairs(links) do
      -- Resolve relative hrefs against the current page URL to preserve directory context
      local href      = aip.web.resolve_href(link.attrs.href, current_page_url)
      local url_obj   = aip.web.parse_url(href)
      local page_url  = url_obj.page_url
      local url_path  = url_obj.path
      local url       = url_obj.url

      if fetch_ctx.page_counter >= max_pages then
        return links_queue
      end

      -- if href starts with FILTER_PATH
      if url:sub(1, #base_url) == base_url and url_path:sub(1, #filter_path) == filter_path then
        -- if not already processed
        local pass = not page_urls_map[page_url]
        
        -- if not in exclude (make sure to test pass so that we do not double print)
        if pass and has_exclude_globs then
          if aip.path.matches_glob(url_path, exclude_globs) then 
            print("Exclude glob path (from exclude_globs) " .. url_path)
            page_urls_map[page_url] = true
            pass = false
          end
        end

        -- make sure we do not process twice
        if pass then
          local res_links = process_url(page_url, fetch_ctx).links
          table.insert(links_queue, { links = res_links, page_url = page_url })
          page_urls_map[page_url] = true
        end
      end

      ::continue::
  end
  return links_queue
end

-- Private
-- Common orig to raw_md process. Used for src_type = "web" | "file"
function process_content(src_path, html_content, fetch_ctx)
  local config    = fetch_ctx.settings.config
  local max_pages = config.max_pages

  -- TODO: eventually should support "stream save" (copy when file, stream save for web get)
  local original_html_path = fetch_ctx:path_0_orig_html(src_path)
  local orig_html_file = aip.file.save(original_html_path, html_content)
  
  fetch_ctx.total_orig_size = fetch_ctx.total_orig_size + orig_html_file.size

  local links = aip.html.select(html_content, "a[href]")

  local slim_html_path =  fetch_ctx:path_1_slim_html(src_path)
  local html_slim_file = aip.file.save_html_to_slim(original_html_path, slim_html_path)
  fetch_ctx.total_slim_size = fetch_ctx.total_slim_size + html_slim_file.size

  local raw_md_path = fetch_ctx:path_2_raw_md(src_path)

  local raw_md_file = aip.file.save_html_to_md(slim_html_path, raw_md_path)
  fetch_ctx.total_md_raw_size = fetch_ctx.total_md_raw_size + raw_md_file.size

  fetch_ctx.page_counter = fetch_ctx.page_counter + 1

  local pages_msg = nil
  if fetch_ctx.page_counter >= max_pages then
    pages_msg = "✔ "
  else 
    pages_msg = "▶ "
  end
  pages_msg = pages_msg .. fetch_ctx.page_counter .. "/" .. max_pages

  aip.run.pin("num_pages", 0, {label = "     Pages:", content = pages_msg})

  local progress_msg = ""
  progress_msg =  progress_msg ..   "Original HTMLs: " .. aip.text.format_size(fetch_ctx.total_orig_size, "MB")
  progress_msg  = progress_msg .. "\n Slimmed HTMLs: " .. aip.text.format_size(fetch_ctx.total_slim_size, "MB")
  progress_msg  = progress_msg .. "\n Raw Markdowns: " .. aip.text.format_size(fetch_ctx.total_md_raw_size, "MB")
  aip.run.pin("progress", 0, {label = "     Sizes:", content = progress_msg})

  return {
    orig_html_file     = orig_html_file,
    html_slim_file     = html_slim_file,
    raw_md_file        = raw_md_file,
    links              = links,
  }
end

-- file: FileInfo object with {path, stem, ..}
function process_file(file, fetch_ctx)
  local config    = fetch_ctx.settings.config
  local base_dir  = config.base_dir
  
  local src_rel_path = aip.path.diff(file.path, base_dir)

  local file_content = aip.file.load(file.path).content

  process_content(src_rel_path, file_content, fetch_ctx)

  aip.run.pin("process", 1, {label = "Processing:", content = src_rel_path})
end


return {
  process_url   = process_url,
  process_links = process_links,

  process_file  = process_file
}