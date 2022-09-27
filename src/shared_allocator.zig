const std = @import("std");

var initialized_shared_allocator = false;
var shared_heap_allocator: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var shared_allocator: std.mem.Allocator = undefined;

pub fn allocator() std.mem.Allocator {
    if (!initialized_shared_allocator) {
        shared_heap_allocator = std.heap.GeneralPurposeAllocator(.{}){};
        shared_allocator = shared_heap_allocator.allocator();
        initialized_shared_allocator = true;
    }
    return shared_allocator;
}

pub fn deinit() bool {
    if (initialized_shared_allocator) {
        return shared_heap_allocator.deinit();
    }
    return false;
}