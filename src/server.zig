const std = @import("std");

const allocator = @import("./shared_allocator.zig").allocator;
const util = @import("./util.zig");

pub const Header = struct {
    key: []u8,
    lower_key: []u8,
    value: []u8,
};

pub fn launch(address: []const u8, port: u16) void {
    var server = std.net.StreamServer.init(.{});
    defer server.deinit();

    const addr = std.net.Address.parseIp4(address, port) catch |err| {
        std.debug.print("std.net.Address.parseIp4 error: {}\n", .{err});
        return;
    };
    server.listen(addr) catch |err| {
        std.debug.print("failed to listen {s}:{d}, {}\n", .{address, port, err});
        return;
    };
    std.debug.print("Listening on http://{s}:{d}\n\n", .{ address, port });

    const cap = 4096;
    // const cap = 706;
    // const cap = 16;
    var buf = allocator().alloc(u8, cap) catch |err| {
        std.debug.print("could not allocate request reader buffer ({d}), error: {}\n", .{cap, err});
        return;
    };

    var running = true;
    defer {
        running = false;
    }

    var conn = server.accept() catch |err| {
        std.debug.print("error occured on server.accept: {}\n", .{err});
        return;
    };

    while (running) {
        serverLoop(&conn, buf) catch |err| {
            std.debug.print("error occured on serverLoop: {}\n", .{err});
            return;
        };
    }

    allocator().free(buf);
}

fn serverLoop(conn: *std.net.StreamServer.Connection, buf: []u8) !void {
    var length = buf.len;
    
    var header: []u8 = try allocator().alloc(u8, 0);
    var body: []u8 = try allocator().alloc(u8, 0);
    var header_indices: []usize = try allocator().alloc(usize, 0);

    var header_end = false;
    var initial_run = true;

    // TODO:
    // get request content-length while retrieving headers.
    // current implementation stacks when the http message size equals to reading buffer size.

    while (initial_run or (length == buf.len)) {
        if (initial_run) {
            initial_run = false;
            header_indices = try util.appendOne(usize, header_indices, 0);
        }
        length = try conn.stream.read(buf);
        if (length == 0) {
            break;
        }
        // TODO: just length
        if (header_end) {
            body = try util.appendStr(body, buf[0..length]);
            continue;
        }

        // parse header
        var i: usize = 0;
        while (i < length) : (i += 1) {
            const ch = buf[i];
            if (ch != '\n') {
                continue;
            }

            if (i >= 3) {
                header_end = (
                    buf[i - 3] == '\r'
                    and buf[i - 2] == '\n'
                    and buf[i - 1] == '\r'
                );
            } else if (i == 2 and header.len >= 1) {
                header_end = (
                    header[header.len - 1] == '\r'
                    and buf[i - 2] == '\n'
                    and buf[i - 1] == '\r'
                );
            } else if (i == 1 and header.len >= 2) {
                header_end = (
                    header[header.len - 2] == '\r'
                    and header[header.len - 1] == '\n'
                    and buf[i - 1] == '\r'
                );
            } else if (i == 0 and header.len >= 3) {
                header_end = (
                    header[header.len - 3] == '\r'
                    and header[header.len - 2] == '\n'
                    and header[header.len - 1] == '\r'
                );
            }

            if (header_end) {
                header = try util.appendStr(header, buf[0..(i + 1)]);
                if ((i + 1) < length) {
                    body = try util.appendStr(body, buf[(i + 1)..length]);
                }
                break;
            } else {
                header_indices = try util.appendOne(usize, header_indices, i + 1);
            }
        }

        if (!header_end) {
            header = try util.appendStr(header, buf);
        }
    }

    std.debug.print("Header\n{s}\n", .{header});
    std.debug.print("Body\n{s}\n\n", .{body});

    var resp_array = std.ArrayList(u8).init(allocator());
    defer resp_array.deinit();
    var content_array = std.ArrayList(u8).init(allocator());
    defer content_array.deinit();

    var resp_writer = resp_array.writer();
    var content_writer = content_array.writer();

    try content_writer.print("hello world !\nYou sent me following body;\n{s}\n", .{body});
    try createResponse(content_array.items, resp_writer);

    _ = try conn.stream.write(resp_array.items);

    std.debug.print("Reponse\n{s}\n\n", .{resp_array.items});

    allocator().free(header);
    allocator().free(body);
}

fn createResponse(content: []const u8, writer: std.ArrayList(u8).Writer) !void {
    try writer.print("HTTP/1.1 200 OK\nContent-Length: {d}\nContent-Type: text/plain; charset=utf-8\n\n{s}", .{content.len, content});
}

