const std = @import("std");
const fs = std.fs;
const json = std.json;
const io = std.io;
const net = std.net;
const os = std.os;
const time = std.time;

const shared_acclocator = @import("./shared_allocator.zig");
const allocator = shared_acclocator.allocator;
const deinit_allocator = shared_acclocator.deinit;

const logger = @import("./logger.zig");
const person = @import("./person.zig");
const server = @import("./server.zig");
const malw = @import("./multi_array_list_wrapper.zig");
const j2y = @import("./json_to_yaml.zig");

const debug = std.debug;

const l = logger.new_logger();

const app_name = "hello world";

pub fn main() !void {
    defer _ = deinit_allocator();

    l.debugln("hello world");
    l.printf("launching {s}\n", .{app_name});

    var may_json = os.getenv("JSON");
    if (may_json != null) {
        var buf = std.ArrayList(u8).init(allocator());
        defer buf.deinit();

        const yaml = j2y.json_file_to_yaml(may_json.?, &buf) catch |err| {
            l.debugf("json_file_to_yaml error: {}", .{err});
            return;
        };
        l.debugln(yaml);
        return;
    }

    var may_host = os.getenv("HOST");
    var may_port = os.getenv("PORT");
    if (may_host != null and may_port != null) {
        const port = try std.fmt.parseInt(u16, may_port.?, 10);
        try server.launch(may_host.?, port);
        return;
    }
}

test "sample struct" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
