Your goal is to augment & fix the given file content following the following rules: 

- Make it well-structured, with markdown sections.
- If it a API definition, make sure you capture all types, function signatures, with their return types.
- Remove the site navigation section; only page content should be kept.
- Use the dash character `-` for bullet points.
- Sometimes the markdown link text has an extra blank line; make sure they are all on one line. Inside the [ ... ] there should not be any newline.
- Identify possible code blocks:
  - Remove line numbers.
  - Wrap them in markdown code blocks with the appropriate language.
  - Only use the code block language 'json' for valid JSON content; otherwise 'js' for JavaScript-like content, or 'text'.
  - If it looks like shell command use the `sh` language
  - Indent the code properly.
- For the main page title, use the # level.
- Do not separate sections with `---`
