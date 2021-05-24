package brackettree

import "core:fmt"
import "core:strings"


main :: proc() {
    fmt.println("\n\n################### TREE BUILD TEST ###################\n");
    tree_test();
    fmt.println("\n\n################# STRING ESCAPE TEST ##################\n");
    escaping_test();
    fmt.println("\n\n############ BRACKETTREE PARSE ENCODE TEST ############\n");
    parsing_encoding_test();
}

@(private)
tree_test :: proc() {
    tree := tree_make(int);

    tree_set_value(&tree, ROOT, 0);
    child := tree_add_child_value(&tree, ROOT, 1);
    tree_add_child_value(&tree, ROOT, 2);
    tree_add_child_value(&tree, child, 5);
    tree_add_child_value(&tree, child, 6);

    fmt.println(tree_find_child(&tree, child, 6));

    fmt.println(to_string(&tree, false, proc(i : int) -> string {
        return strings.repeat("X", i);
    }));
    tree_clear(&tree);
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
    tree := parse(`
        1[2]
        3[
            4[5]
            [
                6[10]
                [|escaped ]] string [[ |]
                [  pwd| very [] sophisticated |~| string |pwd  ]
            ]
            [7]
        ]
    `);
    fmt.println(to_string(&tree));
    fmt.println(to_string(&tree, true));
    tree_clear(&tree);
}