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

tree_get :: proc(t: ^$T/Tree($Value), parent : int) -> (res: Value, ok: bool) #optional_ok {
    return t.vals[parent];
}

tree_get_default :: proc(t: $T/Tree($Value), parent : int, default: Value) -> (res: Value, ok: bool) #optional_ok {
    if res, ok := t.vals[parent]; ok do return;
    else do return default, false;
}

tree_set :: proc(t: ^$T/Tree($Value), parent : int, value: Value) {
    t.vals[parent] = value;
}

tree_add_child :: proc(t: ^$T/Tree($Value), parent : int) -> (id : int) {
    t.id_provider += 1;
    id = t.id_provider;
    if a, ok := t.indc[parent]; ok do append(a, id);
    else {
        a := new([dynamic]int);
        append(a, id);
        t.indc[parent] = a;
    }
    return;
}

tree_add_child_value :: proc(t: ^$T/Tree($Value), parent : int, value : Value) -> (id : int) {
    child := tree_add_child(t, parent);
    tree_set(t, child, value);
    return child;
}

tree_get_children :: proc(t: ^$T/Tree($Value), parent : int) -> [dynamic]int {
    children := t.indc[parent];
    return children == nil ? [dynamic]int{} : children^;
}

tree_find_child :: proc(t: ^$T/Tree($Value), parent : int, value : Value) -> (id : int, ok : bool) #optional_ok {
    for ch in tree_get_children(t, parent) {
        if tree_get(t, ch) == value do return ch, true;
    }
    return -1, false;
}

tree_remove :: proc(t: ^$T/Tree($Value), parent : int) {
    delete_key(&t.indc, parent);
    delete_key(&t.vals, parent);
}

tree_clear :: proc(t: ^$T/Tree($Value)) {
    for k, v in t.indc {
        free(v);
    }
}