package brackettree

import "core:strings"
import "core:unicode/utf8"

_PORTAL_RUNE :: '|';
_BRANCH_RUNE :: '[';
_ROOT_RUNE :: ']';

Dimension :: enum{
    TREE,
    TEXT,
}

parse :: proc(str :string) -> Tree(string) {
    branch : [dynamic]int;
    branch_size := 0;
    tree := tree_make(string);
    node := 0;
    dimension := Dimension.TREE;
    primary_builder := strings.make_builder(); 
    secondary_builder := strings.make_builder();
    secondary_builder_empty := true;
    portal : string;

    for r in str {
        if dimension == Dimension.TREE {
            switch r {
                case _BRANCH_RUNE:
                    s := strings.trim_space(strings.to_string(primary_builder));
                    if len(s) > 0 {
                        strings.write_string(&secondary_builder, s);
                        secondary_builder_empty = false;
                    }
                    new_node : int;
                    if secondary_builder_empty {
                        new_node = tree_add_child(&tree, node);
                    } else {
                        s = strings.to_string(secondary_builder);
                        new_node = tree_add_child_value(&tree, node, s);
                    }
                    if branch_size >= len(branch) {
                        append(&branch, node);
                    } else {
                        branch[branch_size] = node;
                    }
                    branch_size += 1;
                    
                    node = new_node;
                    strings.init_builder(&primary_builder);
                    strings.init_builder(&secondary_builder);
                    secondary_builder_empty = true;
                case _ROOT_RUNE:
                    s := strings.trim_space(strings.to_string(primary_builder));
                    if len(s) > 0 {
                        strings.write_string(&secondary_builder, s);
                        secondary_builder_empty = false;
                    }
                    if !secondary_builder_empty {
                        s = strings.to_string(secondary_builder);
                        tree_add_child_value(&tree, node, s);
                    }
                    if branch_size > 0 {
                        branch_size -= 1;
                        node = branch[branch_size];
                    }
                    strings.init_builder(&primary_builder);
                    strings.init_builder(&secondary_builder);
                    secondary_builder_empty = true;
                case _PORTAL_RUNE:
                    s := strings.trim_space(strings.to_string(primary_builder));
                    portal = strings.concatenate([]string{utf8.runes_to_string([]rune{_PORTAL_RUNE}), s});
                    strings.init_builder(&primary_builder);
                    dimension = Dimension.TEXT;
                case:
                    strings.write_rune_builder(&primary_builder, r);
            }
        } else if dimension == Dimension.TEXT {
            strings.write_rune_builder(&primary_builder, r);
            portal_start_index := strings.builder_len(primary_builder) - len(portal);
            if portal_start_index >= 0 && strings.has_suffix(strings.to_string(primary_builder), portal) {
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
                tree_set_value(&tree, node, s);
            }
        case .TEXT:
            s := strings.to_string(primary_builder);
            strings.write_string(&secondary_builder, s);
            s = strings.to_string(secondary_builder);
            tree_set_value(&tree, node, s);
    }

    return tree;
}

to_string_escaped :: proc(tree : ^Tree(string), compress := false) -> string {
    builder := strings.make_builder();
    encoder := proc(str : string) -> string do return escape_string(str, '~');
    if compress do build_compressed_string(&builder, tree, 0, encoder);
    else do build_string(&builder, tree, 0, 0, encoder);
    str := strings.to_string(builder);
    return str;
}

to_string_encoded :: proc(tree : ^Tree($Value), compress := false, encoder : proc(value : Value) -> string) -> string {
    builder := strings.make_builder();
    if compress do build_compressed_string(&builder, tree, 0, encoder);
    else do build_string(&builder, tree, 0, 0, encoder);
    str := strings.to_string(builder);
    return str;
}

to_string :: proc{to_string_escaped, to_string_encoded};

@(private)
build_string :: proc(builder : ^strings.Builder, tree : ^Tree($Value), key : int, depth : int, 
                    encoder : proc(str: Value) -> string) {
    using strings;
    write_string_builder(builder, encoder(tree_get_value(tree, key)));
    children := tree_get_children(tree, key);
    if len(children) > 1 {
        write_rune_builder(builder, _BRANCH_RUNE);
        write_rune_builder(builder, '\n');
        tabs := repeat("\t", depth + 1);
        for child in tree_get_children(tree, key) {
            write_string_builder(builder, tabs);
            build_string(builder, tree, child, depth + 1, encoder);
        }
        write_string_builder(builder, repeat("\t", depth));
        write_rune_builder(builder, _ROOT_RUNE);
        write_rune_builder(builder, '\n');
    } else if len(children) > 0 {
        if len(tree_get_children(tree, children[0])) > 0 {
            write_rune_builder(builder, _BRANCH_RUNE);
            write_rune_builder(builder, '\n');
            build_string(builder, tree, children[0], depth + 1, encoder);
            write_string_builder(builder, repeat("\t", depth + 1));
            write_rune_builder(builder, _ROOT_RUNE);
            write_rune_builder(builder, '\n');
        } else {
            write_rune_builder(builder, _BRANCH_RUNE);
            write_rune_builder(builder, ' ');
            write_string_builder(builder, encoder(tree_get_value(tree, children[0])));
            write_rune_builder(builder, ' ');
            write_rune_builder(builder, _ROOT_RUNE);
            write_rune_builder(builder, '\n');
        }
    } else {
        write_rune_builder(builder, _BRANCH_RUNE);
        write_rune_builder(builder, _ROOT_RUNE);
        write_rune_builder(builder, '\n');
    }
}


@(private)
build_compressed_string :: proc(builder : ^strings.Builder, tree : ^Tree($Value), key : int, 
                    encoder : proc(str: Value) -> string) {
    using strings;
    write_string_builder(builder, encoder(tree_get_value(tree, key)));
    children := tree_get_children(tree, key);
    if len(children) > 1 {
        write_rune_builder(builder, _BRANCH_RUNE);
        for child in tree_get_children(tree, key) {
            build_compressed_string(builder, tree, child, encoder);
        }
        write_rune_builder(builder, _ROOT_RUNE);
    } else if len(children) > 0 {
        if len(tree_get_children(tree, children[0])) > 0 {
            write_rune_builder(builder, _BRANCH_RUNE);
            build_compressed_string  (builder, tree, children[0], encoder);
            write_rune_builder(builder, _ROOT_RUNE);
        } else {
            write_rune_builder(builder, _BRANCH_RUNE);
            write_string_builder(builder, encoder(tree_get_value(tree, children[0])));
            write_rune_builder(builder, _ROOT_RUNE);
        }
    } else {
        write_rune_builder(builder, _BRANCH_RUNE);
        write_rune_builder(builder, _ROOT_RUNE);
    }
}

escape_string :: proc(str: string, escape_rune : rune) -> string {

    if len(str) == 0 do return str;
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
                if c == _PORTAL_RUNE {
                    escapes = 1;
                } else {
                    escapes = 0;
                }
            }
        } else {
            switch c {
                case _PORTAL_RUNE: escapes = 1;
                case _BRANCH_RUNE, _ROOT_RUNE: escapes = 0;
            }
        }
	}
    escapes = max_escapes > escapes ? max_escapes : escapes;

    using strings;

    if escapes == -1 {
        if is_space(utf8.rune_at(str, 0)) || is_space(utf8.rune_at(str, len(str) - 1)) {
            builder := make_builder(len(str) + 2);
            write_rune_builder(&builder, _PORTAL_RUNE);
            write_string_builder(&builder, str);
            write_rune_builder(&builder, _PORTAL_RUNE);
            return to_string(builder);
        }
        return str;
    }
    escape_pad := repeat(utf8.runes_to_string([]rune{escape_rune}), escapes);
    builder := make_builder(len(str) + 2 * len(escape_pad) + 2);
    write_string_builder(&builder, escape_pad);
    write_rune_builder(&builder, _PORTAL_RUNE);
    write_string_builder(&builder, str);
    write_rune_builder(&builder, _PORTAL_RUNE);
    write_string_builder(&builder, escape_pad);
    return to_string(builder);
}