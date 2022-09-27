const std = @import("std");
const fs = std.fs;
const json = std.json;
const io = std.io;

const shared_acclocator = @import("./shared_allocator.zig");
const allocator = shared_acclocator.allocator;
const deinit_allocator = shared_acclocator.deinit;

const logger = @import("./logger.zig");
const person = @import("./person.zig");
// const company = @import("./company.zig");
const malw = @import("./multi_array_list_wrapper.zig");
const j2y = @import("./json_to_yaml.zig");

const debug = std.debug;

const app_name = "hello world";

pub fn main() !void {
    defer _ = deinit_allocator();

    const l = logger.new_logger();

    var may_json = std.os.getenv("JSON");
    if (may_json == null) {
        l.debugln("JSON is required");
        return;
    }

    const sample_file_name = may_json.?;
    
    l.debugln("hello world");
    l.printf("launching {s}\n", .{app_name});

    var buf = std.ArrayList(u8).init(allocator());
    defer buf.deinit();

    const yaml = j2y.json_file_to_yaml(sample_file_name, &buf) catch |err| {
        l.debugf("json_file_to_yaml error: {}", .{err});
        return;
    };
    l.debugln(yaml);
}

test "sample struct" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
