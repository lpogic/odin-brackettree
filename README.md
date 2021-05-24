# odin-brackettree
Brackettree interface for Odin

## Brackettree
Brackettree is a simple markup language that allows you to concisely express the structure of a tree.

### Features
<ul>
  <li>Syntactically minimalist</li>
  <li>Human readable</li>
  <li>Whitespace insensitive</li>
  <li>No type inference at the general level</li>
</ul>

### Notation
<ul>
<li>branch_token = "["</li>
<li>root_token = "]"</li>
<li>portal_token = "|"</li>
<li>whitespace = /* any of the whitespace Unicode */</li>
<li>character = /* an arbitrary Unicode code point except whitespaces, portal_token, root_token and branch_token */</li>
<li>IN PROGRESS..</li>
</ul>
<!--
raw_string = character | character { character | whitespace } character
escaped_string = raw_string portal_token { whitespace | raw_string | branch_token | root_token } portal_token raw_string
-->
