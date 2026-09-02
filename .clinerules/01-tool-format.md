---
description: Force XML tool-call format (fixes Ollama JSON parser bug)
---
 
# Tool invocation format
 
CRITICAL: Never output tool calls as JSON objects. Do not output patterns like:
{"name": "write_to_file", "arguments": {...}}
{"name": "read_file", "arguments": {...}}
{"name": "execute_command", "arguments": {...}}
 
You MUST use only XML tags for all tool invocations:
 
<read_file>
<path>path/to/file</path>
</read_file>
 
<write_to_file>
<path>path/to/file</path>
<content>
file content here
</content>
</write_to_file>
 
<execute_command>
<command>ls -la</command>
</execute_command>
 
<list_files>
<path>path/to/directory</path>
</list_files>
 
JSON output is silently ignored by the parser and wastes your turn. XML tags
are the only format that actually executes.
 
# One tool call per message — no exceptions
 
CRITICAL: Output exactly ONE tool call per message. Never stack multiple
<execute_command>, <read_file>, or other tool blocks in the same response.
 
Wrong (do not do this):
<execute_command><command>docker ps -a</command></execute_command>
<execute_command><command>docker logs audiobookshelf</command></execute_command>
<execute_command><command>ss -tulpn</command></execute_command>
 
Right:
<execute_command>
<command>docker ps -a</command>
</execute_command>
 
Then STOP. Wait for the result. Only after seeing that result do you decide
what the next single tool call should be — the result of command 1 often
changes what command 2 should even be. Planning five steps ahead and dumping
them all at once means you're guessing blind at steps 2 through 5 before you
know what step 1 actually returned.
 
If you have a multi-step plan, say so in one sentence, then execute only the
first step as a single tool call and stop there.
