const std = @import("std");

const shared_acclocator = @import("./shared_allocator.zig");
const allocator = shared_acclocator.allocator;
const deinit_allocator = shared_acclocator.deinit;

const logger = @import("./logger.zig");
const server = @import("./server.zig");
const j2y = @import("./json_to_yaml.zig");

const app_name = "hello world";

pub fn main() void {
    defer _ = deinit_allocator();

    const l = logger.new_logger();
    l.debugln("hello world");
    l.debugf("launching {s}\n", .{app_name});

    var may_json = std.os.getenv("JSON");
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

    var may_host = std.os.getenv("HOST");
    var may_port = std.os.getenv("PORT");
    if (may_host != null and may_port != null) {
        const port = std.fmt.parseInt(u16, may_port.?, 10) catch |err| {
            l.printf("could not execute std.fmt.parseInt for '{s}'', error: {}", .{may_port.?, err});
            return;
        };
        server.launch(may_host.?, port);
        return;
    }
}

test "sample struct" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
