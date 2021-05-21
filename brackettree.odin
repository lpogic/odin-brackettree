package brackettree

import "core:strings"
import "core:unicode/utf8"

portal_rune :: '|';
branch_rune :: '[';
root_rune :: ']';


to_string :: proc(node : ^Node, compress := false, string_encoder := escape_string) -> string {
    builder := strings.make_builder();
    if compress do build_compressed_string(&builder, node, string_encoder);
    else do build_string(&builder, node, 0, string_encoder);
    str := strings.to_string(builder);
    return str;
}

@(private)
build_string :: proc(builder : ^strings.Builder, node : ^Node, depth : int, 
                    string_encoder : proc(str: string, escape_rune := '~') -> string) {
    switch t in node.val {
        case rawptr:
        case string:
            strings.write_string_builder(builder, string_encoder(t));
        case map[^Node]^Node:
            tabs := strings.repeat("\t", depth);
            for k, v in t {
                if len(t) > 1 {
                    strings.write_string_builder(builder, tabs);
                }
                build_string(builder, k, depth + 1, string_encoder);
                switch t1 in v.val {
                    case rawptr:
                        if len(t) > 1 {
                            strings.write_rune_builder(builder, branch_rune);
                            strings.write_rune_builder(builder, root_rune);
                            strings.write_rune_builder(builder, '\n');
                        } else {
                            strings.write_rune_builder(builder, ' ');
                        }
                    case string:
                        strings.write_rune_builder(builder, branch_rune);
                        strings.write_rune_builder(builder, ' ');
                        strings.write_string_builder(builder, string_encoder(t1));
                        strings.write_rune_builder(builder, ' ');
                        strings.write_rune_builder(builder, root_rune);
                        strings.write_rune_builder(builder, '\n');
                    case map[^Node]^Node:
                        if len(t1) > 1 {
                            strings.write_rune_builder(builder, branch_rune);
                            strings.write_rune_builder(builder, '\n');
                            build_string(builder, v, depth + 1, string_encoder);
                            strings.write_string_builder(builder, tabs);
                            strings.write_rune_builder(builder, root_rune);
                            strings.write_rune_builder(builder, '\n');
                        } else {
                            strings.write_rune_builder(builder, branch_rune);
                            strings.write_rune_builder(builder, ' ');
                            build_string(builder, v, depth + 1, string_encoder);
                            strings.write_rune_builder(builder, ' ');
                            strings.write_rune_builder(builder, root_rune);
                            strings.write_rune_builder(builder, '\n');
                        }
                }
            }
    }
}

@(private)
build_compressed_string :: proc(builder : ^strings.Builder, node : ^Node,
                    string_encoder : proc(str: string, escape_rune := '~') -> string) {
    switch t in node.val {
        case rawptr:
        case string:
            strings.write_string_builder(builder, string_encoder(t));
        case map[^Node]^Node:
            for k, v in t {
                build_compressed_string(builder, k, string_encoder);
                switch t1 in v.val {
                    case rawptr:
                        if len(t) > 1 {
                            strings.write_rune_builder(builder, branch_rune);
                            strings.write_rune_builder(builder, root_rune);
                        }
                    case string:
                        strings.write_rune_builder(builder, branch_rune);
                        strings.write_string_builder(builder, string_encoder(t1));
                        strings.write_rune_builder(builder, root_rune);
                    case map[^Node]^Node:
                        if len(t1) > 1 {
                            strings.write_rune_builder(builder, branch_rune);
                            build_compressed_string(builder, v, string_encoder);
                            strings.write_rune_builder(builder, root_rune);
                        } else {
                            strings.write_rune_builder(builder, branch_rune);
                            build_compressed_string(builder, v, string_encoder);
                            strings.write_rune_builder(builder, root_rune);
                        }
                }
            }
    }
}

escape_string :: proc(str: string, escape_rune : rune) -> string {

    escapes := -1;
    max_escapes := -1;

    for c in str {
        if escapes > 0 {
            if(c == escape_rune) {
                escapes += 1;
            } else {
                if max_escapes < escapes {
                    max_escapes = escapes;
                }
                if c == portal_rune {
                    escapes = 1;
                } else {
                    escapes = 0;
                }
            }
        } else {
            switch c {
                case portal_rune: escapes = 1;
                case branch_rune, root_rune: escapes = 0;
            }
        }
	}
    escapes = max_escapes > escapes ? max_escapes : escapes;

    if escapes == -1 {
        if len(str) == 0 || strings.is_space(utf8.rune_at(str, 0)) || strings.is_space(utf8.rune_at(str, len(str) - 1)) {
            builder := strings.make_builder(len(str) + 2);
            strings.write_rune_builder(&builder, portal_rune);
            strings.write_string_builder(&builder, str);
            strings.write_rune_builder(&builder, portal_rune);
            return strings.to_string(builder);
        }
        return str;
    }
    escape_pad := strings.repeat(utf8.runes_to_string([]rune{escape_rune}), escapes);
    builder := strings.make_builder(len(str) + 2 * len(escape_pad) + 2);
    strings.write_string_builder(&builder, escape_pad);
    strings.write_rune_builder(&builder, portal_rune);
    strings.write_string_builder(&builder, str);
    strings.write_rune_builder(&builder, portal_rune);
    strings.write_string_builder(&builder, escape_pad);
    return strings.to_string(builder);
}


Node :: struct {
    val : Value,
}

Value :: union {
    rawptr,
    string,
    map[^Node]^Node,
}

Dimension :: enum {
    TREE,
    TEXT,
}

destroy :: proc(node : ^Node, allocator := context.allocator) {
    switch v in node.val {
        case map[^Node]^Node:
            for key, val in v {
                destroy(key, allocator);
                destroy(val, allocator);
            }
            delete(v);
        case string:
            delete(v, allocator);
        case rawptr:
    }
    free(node, allocator);
}

parse :: proc(str :string) -> ^Node {
    branch : [dynamic]^Node;
    branchSize := 0;
    node := new(Node);
    dimension := Dimension.TREE;
    primary_builder := strings.make_builder(); 
    secondary_builder := strings.make_builder();
    primary_builder_empty, secondary_builder_empty := true, true;
    portal : string;

    inset_string :: proc(node : ^Node, key : string, value : ^Node) {
        n := new(Node);
        n.val = key;
        inset_node(node, n, value);
    }

    inset_node :: proc(node : ^Node, key : ^Node, value : ^Node) {
        switch v in node.val {
            case map[^Node]^Node:
                m := make(map[^Node]^Node);
                for k, v1 in v {
                    m[k] = v1;
                }
                m[key] = value;
                node.val = m;
            case string:
                m := make(map[^Node]^Node);
                n := new(Node);
                n.val = v;
                m[n] = new(Node);
                m[key] = value;
                node.val = m;
            case rawptr:
                m := make(map[^Node]^Node);
                m[key] = value;
                node.val = m;
            case:
                m := make(map[^Node]^Node);
                m[key] = value;
                node.val = m;
        }
    }

    inset :: proc{inset_string, inset_node};

    for r in str {
        if dimension == Dimension.TREE {
            switch r {
                case branch_rune:
                    s := strings.trim_space(strings.to_string(primary_builder));
                    if len(s) > 0 {
                        strings.write_string(&secondary_builder, s);
                        secondary_builder_empty = false;
                    }
                    newNode := new(Node);
                    if secondary_builder_empty {
                        inset(node, new(Node), newNode);
                    } else {
                        s = strings.to_string(secondary_builder);
                        inset(node, s, newNode);
                    }
                    if branchSize >= len(branch) {
                        append(&branch, node);
                    } else {
                        branch[branchSize] = node;
                    }
                    branchSize += 1;
                    
                    node = newNode;
                    strings.init_builder(&primary_builder);
                    strings.init_builder(&secondary_builder);
                    secondary_builder_empty = true;
                case root_rune:
                    s := strings.trim_space(strings.to_string(primary_builder));
                    if len(s) > 0 {
                        strings.write_string(&secondary_builder, s);
                        secondary_builder_empty = false;
                    }
                    if !secondary_builder_empty {
                        s = strings.to_string(secondary_builder);
                        inset(node, s, new(Node));
                    }
                    if branchSize > 0 {
                        branchSize -= 1;
                        node = branch[branchSize];
                    }
                    strings.init_builder(&primary_builder);
                    strings.init_builder(&secondary_builder);
                    secondary_builder_empty = true;
                case portal_rune:
                    s := strings.trim_space(strings.to_string(primary_builder));
                    portal = strings.concatenate([]string{utf8.runes_to_string([]rune{portal_rune}), s});
                    strings.init_builder(&primary_builder);
                    dimension = Dimension.TEXT;
                case:
                    strings.write_rune_builder(&primary_builder, r);
            }
        } else if dimension == Dimension.TEXT {
            strings.write_rune_builder(&primary_builder, r);
            portalStartIndex := strings.builder_len(primary_builder) - len(portal);
            if portalStartIndex >= 0 && strings.has_suffix(strings.to_string(primary_builder), portal) {
                s := strings.to_string(primary_builder);
                strings.write_string(&secondary_builder, s[:len(s)-len(portal)]);
                secondary_builder_empty = false;
                strings.init_builder(&primary_builder);
                dimension = Dimension.TREE;
            }
        }
    }

    switch dimension {
        case .TREE:
            s := strings.trim_space(strings.to_string(primary_builder));
            if len(s) > 0 {
                strings.write_string(&secondary_builder, s);
                secondary_builder_empty = false;
            }
            if !secondary_builder_empty {
                s = strings.to_string(secondary_builder);
                inset(node, s, new(Node));
            }
        case .TEXT:
            s := strings.to_string(primary_builder);
            strings.write_string(&secondary_builder, s[:len(s)-len(portal)]);
            s = strings.to_string(secondary_builder);
            inset(node, s, new(Node));
    }

    return len(branch) > 0 ? branch[0] : node;
}