# Configuration Reference

The primary configuration is defined in `ako-config.jsonc`.

## Configuration Notes

- **Activation:** Ensure only ONE JSON configuration object is uncommented in `ako-config.jsonc`.
- **Customization:** You can create or customize your own section.
- **Max Pages Recommendation:** Start with a relatively low `max_pages` number, like 10, and then increase it when you have achieved the desired result on the small subset.
- **Model Recommendation:** 
    - Use a small model like `haiku` or `flash` for the augment and LLM index. They are plenty good enough. 
    - Use `flash` if possible when the final content is large (> 2MB), so that it is not context limited.
- **`$ako_config_dir`:** Points to the directory of the ako config. Otherwise, if relative, it is relative to the workspace directory (the parent directory of the `.aipack/`).
- **`fetch_filter_path`:** Filters fetched URLs to only include those whose path starts with this value.
    - If relative (no leading `/`), it is relative to the `base_url` path.
    - If absolute (starts with `/`), it matches from the URL root.
    - Example: If `base_url` is "https://docs.example.com/api/v2/" and `fetch_filter_path` is "reference/", only URLs under "https://docs.example.com/api/v2/reference/" will be fetched.

## Configuration Options

The ako-config.jsonc file supports the following options:

- `out_dir`: Output directory for processed files. Supports `$ako_config_dir/` prefix to reference the config directory.
- `do_fetch_slim`: (default: true) Enable or skip the fetch/slim step. Set to false to skip if data is already there.
- `base_url`: Base URL for web-based documentation (use for fetching from websites).
- `base_dir`: Base directory for local file processing (use for processing local HTML files).
- `globs`: Glob patterns for local file selection (used with `base_dir`).
- `first_page`: Starting URL for web fetching.
- `max_pages`: Maximum number of pages to fetch and process.
- `fetch_filter_path`: Filter to include only URLs matching this path (relative or absolute).
- `fetch_exclude_globs`: Glob patterns for excluding URLs from fetching.
- `do_augment`: (default: true) Enable AI augmentation of markdown files.
- `aug_exclude_globs`: Glob patterns for excluding files from augmentation.
- `max_size_kb`: Maximum file size in KB; files larger than this will be skipped during augmentation.
- `augment_model`: Model to use for augmentation (e.g., `gemini-flash-latest`).
- `concurrency`: Number of concurrent augmentation tasks.
- `do_llms`: (default: true) Enable generation of LLM index file (llms.md).
- `llms_model`: Model to use for LLM index generation.
- `do_docaify`: (default: true) Enable single document consolidation (docaify).
- `docaify_model`: Model to use for docaify.
- `docaify_target_path`: Optional custom output path for the docaified document (by default in `$ako_out_dir/5-docaify/doc-for-llm.md`).

## Example Configurations

The following examples are available for reference. Copy the desired block into `ako-config.jsonc` to use it.

## OpenAI Cookbook

```jsonc
{
               "out_dir": "$ako_config_dir/out",
// -- Fetch & Slim
         "do_fetch_slim": true, // allows skipping the fetch/slim step (assumes the data is already there)
              "base_url": "https://cookbook.openai.com/examples/",
            "first_page": "https://cookbook.openai.com/examples/",
             "max_pages": 10,
//   "fetch_filter_path": "/base/path/only/",
// "fetch_exclude_globs": ["**/{debug,llms,changelog}*"],
// -- Clean & Augment
            "do_augment": true,
     "aug_exclude_globs": ["*all*"],
           "max_size_kb": 200, // in KB, above which the file will be skipped
         "augment_model": "gemini-flash-latest",
           "concurrency": 6,
// -- llms index
               "do_llms": true,
            "llms_model": "gemini-flash-latest",
// -- docaify (single doc consolidation)
            "do_docaify": true,
         "docaify_model": "gemini-flash-latest",
// "docaify_target_path": ".doc-libs/lib_name-api-reference-for-llm.md",	// Optional - By default in `$ako_out_dir/5-docaify/doc-for-llm.md`)
}
```

## Alchemy (Blockchain)

```jsonc
{
               "out_dir": "$ako_config_dir/out",
// -- Fetch & Slim
         "do_fetch_slim": true, // allows skipping the fetch/slim step (assumes the data is already there)
              "base_url": "https://www.alchemy.com/docs/",
            "first_page": "https://www.alchemy.com/docs/reference/token-api-quickstart",
             "max_pages": 10, // put to 300 to download the full alchemy doc (sub MB when optimized!)
//   "fetch_filter_path": "/base/path/only/",
   "fetch_exclude_globs": ["**/{debug,llms,changelog}*"],
// -- Clean & Augment
            "do_augment": true,
     "aug_exclude_globs": ["*all*"],
           "max_size_kb": 200, // in KB, above which the file will be skipped
         "augment_model": "gemini-flash-latest", // Models can be any providers "gemini-2.5-flash"
           "concurrency": 6,
// -- llms index
               "do_llms": true,
            "llms_model": "gemini-flash-latest",
// -- docaify (single doc consolidation)
            "do_docaify": true,
         "docaify_model": "gemini-flash-latest",
// "docaify_target_path": ".doc-libs/lib_name-api-reference-for-llm.md",	// Optional - By default in `$ako_out_dir/5-docaify/doc-for-llm.md`)
}
```

## Local Files

```jsonc
{
               "out_dir": "$ako_config_dir/out",
// -- Fetch & Slim
         "do_fetch_slim": true, // allows skipping the fetch/slim step (assumes the data is already there)
              "base_dir": "path/to/dir/",
                 "globs": "**/*.html",
             "max_pages": 10,
   "fetch_exclude_globs": ["**/{debug,llms}*"],
// -- Clean & Augment
            "do_augment": true,
     "aug_exclude_globs": ["*all*"],
           "max_size_kb": 200, // in KB, above which the file will be skipped
         "augment_model": "gemini-flash-latest", // Models can be any providers "gemini-2.5-flash"
           "concurrency": 16,
// -- llms index
               "do_llms": true,
            "llms_model": "gemini-flash-latest",
// -- docaify (single doc consolidation)
            "do_docaify": true,
         "docaify_model": "gemini-flash-latest",
// "docaify_target_path": ".doc-libs/lib_name-api-reference-for-llm.md",	// Optional - By default in `$ako_out_dir/5-docaify/doc-for-llm.md`)
}
```

## Tauri Web Site

```jsonc
{
               "out_dir": "$ako_config_dir/out",
// -- Fetch & Slim
         "do_fetch_slim": true, // allows skipping the fetch/slim step (assumes the data is already there)
              "base_url": "https://tauri.app/reference/",
            "first_page": "https://tauri.app/reference/acl/capability/",
             "max_pages": 10,
//   "fetch_filter_path": "/base/path/only/",
// "fetch_exclude_globs": ["**/{debug,llms,changelog}*"],
// -- Clean & Augment
            "do_augment": true,
     "aug_exclude_globs": ["*all*"],
           "max_size_kb": 200, // in KB, above which the file will be skipped
         "augment_model": "gemini-flash-latest",
           "concurrency": 6,
// -- llms index
               "do_llms": true,
            "llms_model": "gemini-flash-latest",
// -- docaify (single doc consolidation)
            "do_docaify": true,
         "docaify_model": "gemini-flash-latest",
// "docaify_target_path": ".doc-libs/lib_name-api-reference-for-llm.md",	// Optional - By default in `$ako_out_dir/5-docaify/doc-for-llm.md`)
}
```

## IMFusion (C++ SDK, medical imaging)

```jsonc
{
               "out_dir": "$ako_config_dir/out",
// -- Fetch & Slim
         "do_fetch_slim": true, // allows skipping the fetch/slim step (assumes the data is already there)
              "base_url": "https://docs.imfusion.com/cppsdk/",
            "first_page": "https://docs.imfusion.com/cppsdk/index.html",
             "max_pages": 10,
//   "fetch_filter_path": "/base/path/only/",
   "fetch_exclude_globs": ["**/{doxygen_crawl,namespace_im_fusion,_changelog}*"],
// -- Clean & Augment
            "do_augment": true,
           "max_size_kb": 200, // in KB, above which the file will be skipped
         "augment_model": "gemini-flash-latest", // Models can be any providers "gemini-2.5-flash"
           "concurrency": 6,
// -- llms index
               "do_llms": true,
            "llms_model": "gemini-flash-latest",
// -- docaify (single doc consolidation)
            "do_docaify": true,
         "docaify_model": "gemini-flash-latest",
// "docaify_target_path": ".doc-libs/lib_name-api-reference-for-llm.md",	// Optional - By default in `$ako_out_dir/5-docaify/doc-for-llm.md`)
}
```
