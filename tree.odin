package brackettree

import "core:container"

ROOT :: 0;

Tree :: struct(Value: typeid) {
    indc : map[int]^[dynamic]int,
    vals : map[int]Value,
    id_provider : int,
}

tree_make :: proc($T : typeid) -> Tree(T) {
    return Tree(T){};
}

tree_get_value :: proc(t: ^$T/Tree($Value), id : int) -> (res: Value, ok: bool) #optional_ok {
    return t.vals[id];
}

tree_get_default :: proc(t: $T/Tree($Value), id : int, default: Value) -> (res: Value, ok: bool) #optional_ok {
    if res, ok := t.vals[id]; ok do return;
    else do return default, false;
}

tree_set_value :: proc(t: ^$T/Tree($Value), id : int, value: Value) {
    t.vals[id] = value;
}

tree_add_child :: proc(t: ^$T/Tree($Value), parent_id : int) -> (id : int) {
    t.id_provider += 1;
    id = t.id_provider;
    if a, ok := t.indc[parent_id]; ok do append(a, id);
    else {
        a := new([dynamic]int);
        append(a, id);
        t.indc[parent_id] = a;
    }
    return;
}

tree_add_child_value :: proc(t: ^$T/Tree($Value), parent_id : int, value : Value) -> (id : int) {
    child := tree_add_child(t, parent_id);
    tree_set_value(t, child, value);
    return child;
}

tree_get_children :: proc(t: ^$T/Tree($Value), parent_id : int) -> ([dynamic]int, bool) #optional_ok {
    children := t.indc[parent_id];
    if children == nil {
        return [dynamic]int{}, false;
    } else {
        return children^, true;
    }
}

tree_find_child :: proc(t: ^$T/Tree($Value), parent_id : int, value : Value) -> (int, bool) #optional_ok {
    for ch in tree_get_children(t, parent_id) {
        if tree_get_value(t, ch) == value do return ch, true;
    }
    return -1, false;
}

tree_remove :: proc(t: ^$T/Tree($Value), id : int) {
    if children, ok := t.indc[id]; ok {
        for ch in children {
            tree_remove(t, ch);    
        }
        free(children);
        delete_key(&t.indc, id);
    }
    delete_key(&t.vals, id);
}

tree_clear :: proc(t: ^$T/Tree($Value)) {
    for k, v in t.indc {
        free(v);
    }
}