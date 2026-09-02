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
 
