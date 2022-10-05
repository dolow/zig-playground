const std = @import("std");

const allocator = @import("./shared_allocator.zig").allocator;
const append = @import("./util.zig").append;

pub fn launch(address: []const u8, port: u16) !void {
    var server = std.net.StreamServer.init(.{});
    defer server.deinit();

    const addr = try std.net.Address.parseIp4(address, port);
    server.listen(addr) catch |err| {
        std.debug.print("failed to listen {s}:{d}, {}\n", .{address, port, err});
        return;
    };
    std.debug.print("Listening on http://{s}:{d}\n\n", .{ address, port });

    var running = true;

    defer {
        running = false;
    }

    const cap = 16;
    var buf = try allocator().alloc(u8, cap);

    while (running) {
        try serverLoop(&server, buf);
    }

    allocator().free(buf);
}

fn serverLoop(server: *std.net.StreamServer, buf: []u8) !void {
    const conn = try server.accept();
    var length = try conn.stream.read(buf);
    if (length == 0) {
        return;
    }

    var header: []u8 = try allocator().alloc(u8, 0);
    var body: []u8 = try allocator().alloc(u8, 0);

    var header_end = false;
    while (length == buf.len and length != 0) {
        length = try conn.stream.read(buf);
        
        if (header_end) {
            body = try append(body, buf[0..length]);
            continue;
        }

        // parse header
        var i: usize = 0;
        var append_end_index = length;
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
                append_end_index = i;
            }
        }

        
        header = try append(header, buf[0..append_end_index]);

        if (header_end) {
            if ((append_end_index + 1) < length) {
                body = try append(body, buf[(append_end_index + 1)..length]);
            }
        }
    }

    std.debug.print("Header\n{s}\n", .{header});
    std.debug.print("Body\n{s}\n", .{body});

    var resp_array = std.ArrayList(u8).init(allocator());
    defer resp_array.deinit();
    var content_array = std.ArrayList(u8).init(allocator());
    defer content_array.deinit();
    
    var resp_writer = resp_array.writer();
    var content_writer = content_array.writer();

    try content_writer.print("hello world !\nYou sent me following body;\n{s}\n", .{body});
    try createResponse(content_array.items, resp_writer);

    _ = try conn.stream.write(resp_array.items);

    std.debug.print("Reponse\n{s}\n", .{resp_array.items});

    allocator().free(header);
    allocator().free(body);
}

fn createResponse(content: []const u8, writer: std.ArrayList(u8).Writer) !void {
    try writer.print("HTTP/1.1 200 OK\nContent-Length: {d}\nContent-Type: text/plain; charset=utf-8\n\n{s}", .{content.len, content});
}

