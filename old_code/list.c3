module list(<Type>);

import arena;

const usz INITIAL_CAPACITY = 256;

struct List {
    usz size;
    usz capacity;
    Arena arena;
    Type* items;
}

fn void List.push(&list, Type item) {
    if (list.size >= list.capacity) {
        usz new_capacity = list.capacity == 0 ? INITIAL_CAPACITY : (list.capacity * 2);

        list.items = list.arena.realloc(
            list.items,
            list.capacity * $sizeof(Type.typeid),
            new_capacity  * $sizeof(Type.typeid)
        );

        list.capacity = new_capacity;
    }

    list.items[list.size++] = item;
}

fn void List.free(&list) {
    list.capacity = 0;
    list.size     = 0;
    list.items    = null;

    list.arena.free();
}

fn Type List.pop(&list) {
    Type item = list.items[list.size - 1];
    list.size -= 1;
    return item;
}

macro Type List.@item_at(&list, usz index) @operator([]) {
	return list.items[index];
}

macro Type* List.@get_ref(&list, usz index) @operator(&[])  {
	return &list.items[index];
}

macro void List.@set(&list, usz index, Type value) @operator([]=) {
	list.items[index] = value;
}

macro usz List.@get_size(list) @operator(len) {
    return list.size;
}
