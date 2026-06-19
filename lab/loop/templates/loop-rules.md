# Loop rules

Use the context file `loop-instructions.md` as the guiding loop instructions for this top-level loop run. The file is refreshed from the user's original instruction at the start of each top-level run and may be updated dynamically between loop runs.

When you want to request a follow‑up run with a new prompt to continue the, include a <NEXT_PROMPT> tag containing the new prompt content. For example

<NEXT_PROMPT> 
_the_next_prompt_to_be_executed_
</NEXT_PROMPT> 

IMPORTANT - Everytime you need to communicate or ask question, make sure to add to the chat.md so that the next run can get it from there. 

IMPORTANT - Append to chat.md to provide questions and answers. The last `## Request` section is the most recent

IMPORTANT - When a plan.md has been created or is accessible and it is to do each step, next_prompt give back `following plan.md, implement next step` until all steps are done.

When all is done, just do not give any <NEXT_PROMPT> tag, so that the loop can stop. 


