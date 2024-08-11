module arena;

import libc;
import std::io;

const usz REGION_DEFAULT_CAPACITY = 8 * 1024;

struct Region {
    Region* next;
    usz count;
    usz capacity;
    uptr[*] data;
}

struct Arena {
    Region* begin;
    Region* end;
}

fn Region* new_region(usz capacity)
{
    usz size_bytes = $sizeof(Region.typeid) + $sizeof(uptr.typeid)*capacity;
    Region *r = (Region*)libc::malloc(size_bytes);
    assert(r != null);
    r.next = null;
    r.count = 0;
    r.capacity = capacity;
    return r;
}

fn void Region.free(&region) {
    libc::free(region);
}

fn void* Arena.alloc(&arena, usz size_bytes)
{
    usz size = (size_bytes + $sizeof(uptr.typeid) - 1)/$sizeof(uptr.typeid);

    if (arena.end == null) {
        assert(arena.begin == null);
        usz capacity = REGION_DEFAULT_CAPACITY;
        if (capacity < size) capacity = size;
        arena.end = new_region(capacity);
        arena.begin = arena.end;
    }

    while (arena.end.count + size > arena.end.capacity && arena.end.next != null) {
        arena.end = arena.end.next;
    }

    if (arena.end.count + size > arena.end.capacity) {
        assert(arena.end.next == null);
        usz capacity = REGION_DEFAULT_CAPACITY;
        if (capacity < size) capacity = size;
        arena.end.next = new_region(capacity);
        arena.end = arena.end.next;
    }

    void* result = &arena.end.data[arena.end.count];
    arena.end.count += size;
    return result;
}

fn void* Arena.realloc(&arena, void* old_pointer, usz old_size, usz new_size)
{
    if (new_size <= old_size) return old_pointer;
    void* new_pointer = arena.alloc(new_size);
    char* new_pointer_char = (char*)new_pointer;
    char* old_pointer_char = (char*)old_pointer;
    for (usz i = 0; i < old_size; ++i) {
        new_pointer_char[i] = old_pointer_char[i];
    }
    return new_pointer;
}

fn void Arena.reset(&arena)
{
    for (Region* region = arena.begin; region != null; region = region.next) {
        region.count = 0;
    }

    arena.end = arena.begin;
}

fn void Arena.free(&arena)
{
    Region *region = arena.begin;
    while (region != null) {
        Region *region0 = region;
        region = region.next;
        region0.free();
    }
    arena.begin = null;
    arena.end = null;
}
