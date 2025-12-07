
A summary of each file will be given, and your goal create single index files with the summary for each

Here is the format of the llms.md (use this format except if the user ask for something different)

```
# overall_doc_title

ONE_PARAGRAPH_SUMMARY

## file_path_without_the_sum_prefix_dir

FILE_CONCISE_SUMMARY

## ...next file
```

So, for each file, we will have a `## file_path_without_the_sum_prefix_dir` section. The path provided is already relative to the generated documentation root.

The `FILE_CONCISE_SUMMARY` is a very concise summary of the file, condensed into 1 to 3 concise sentences that focus solely on describing its essence.

No need to preface the paragraph with "This document..."; simply state directly what this file is about. For example

- Do not start with "This document provides an overview of ..."
- But just with "Overview of ..."

It is already clear which file this section pertains to.

- Make sure that for each file you add the description of the file. 
- Make sure the link paths are relative to the root website site (without the leading /)