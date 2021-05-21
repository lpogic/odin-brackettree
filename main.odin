package brackettree

import "core:fmt"
import "core:reflect"
import "core:strings"

main :: proc() {
    // escaping_test();
    // parsing_encoding_test();

    a : any;
    a = "echoja";
    
    t := any_cast(&a, string);
    T := strings.to_upper(t^);
    fmt.println(t^);
    fmt.println(T);
    any_accept("str");
    any_accept(1);
}

any_accept :: proc(a : any) {
    fmt.println(a.id);
    return;
}

any_cast :: proc(a : ^any, $T : typeid) -> ^T {
    if a.id == T do return transmute(^T)a.data;
    return nil;
}

@(private)
escaping_test :: proc() {
    fmt.println(escape_string("ao", '~'));
    fmt.println(escape_string("a|o", '~'));
    fmt.println(escape_string("a||o", '~'));
    fmt.println(escape_string("a|~~o", '~'));
    fmt.println(escape_string("a[]o", '~'));
    fmt.println(escape_string("a[~|]o", '~'));
    fmt.println(escape_string("", '~'));
    fmt.println(escape_string(" ", '~'));
    fmt.println(escape_string(" ao \n", '~'));
}

@(private)
parsing_encoding_test :: proc() {
    node := parse("1[2]3[4[5][6[10][11][~~|very[]sophisticated|~|string|~~]][7]]");
    fmt.println(to_string(node, false));
    destroy(node);
}