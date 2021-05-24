# odin-brackettree
Brackettree interface for Odin

## Brackettree
Brackettree is a simple markup language that allows you to concisely express the structure of a tree.

### Features
<ul>
  <li>Syntactically minimalist</li>
  <li>Human readable</li>
  <li>Whitespace insensitive</li>
  <li>No need to codepoint escaping/encoding</li>
  <li>No type inference at the general level</li>
</ul>

### Notation
```node1[ node2 ]``` &#x21e6; 'node2' is a child of 'node1'. 'node1' is a child of root<br><br><br>
```node3[ node4 [] node5 ]``` &#x21e6; 'node4' and 'node5' are children of 'node3'. 'node3' is a child of root. '[]' idiom is required to separate 'node4' from 'node5'<br><br>
```
nodeA[ 
  nodeB[ nodeC ]
  nodeD[]
]
nodeE[ nodeF ]
```
&#x21e7; 'nodeC' is a child of 'nodeB'. 'nodeB' and 'nodeD' are children of 'nodeA'. '[]' idiom after last child is optional. 'nodeF' is a child of 'nodeE'. 'nodeA' and 'nodeE' are children of root<br><br><br>
```| nodeG | [ nodeH ]``` &#x21e6; 'nodeH' is a child of ' nodeG '. Leading and trailing whitespaces are cleared unless text dimension is activated. A text dimension is opened by using '|' character<br><br><br>
```|nodeJ | [ ~~| node|~ |~~ ]``` &#x21e6; 'nodeJ ' is a child of ' node|~ '. String which appear direct before '|' character is a portal password. Text dimension is closed by password preceded by '|' character. For ' node|~ ' portal password is '\~~', for 'nodeJ ' portal password is empty string<br><br><br>


