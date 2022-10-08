const std = @import("std");

const allocator = @import("./shared_allocator.zig").allocator;
const util = @import("./util.zig");

const HEADER_KEY_SEPARATOR = ':';
const WHITE_SPACE = ' ';
const CR = '\r';
const LF = '\n';
const HEADER_KEY_CONTENT_LENGTH = "Content-Length";

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
    // const cap = 353;
    // const cap = 16;
    var buf = allocator().alloc(u8, cap) catch |err| {
        std.debug.print("could not allocate request reader buffer ({d}), error: {}\n", .{cap, err});
        return;
    };
    defer allocator().free(buf);

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
}

fn serverLoop(conn: *std.net.StreamServer.Connection, buf: []u8) !void {
    var header: []u8 = try allocator().alloc(u8, 0);
    defer allocator().free(header);
    var body: []u8 = try allocator().alloc(u8, 0);
    defer allocator().free(body);
    var header_indices: []usize = try allocator().alloc(usize, 1);
    defer allocator().free(header_indices);
    header_indices[0] = 0;

    var headers = std.StringArrayHashMap([]u8).init(allocator());
    defer headers.deinit();

    // header_indices = try util.appendOne(usize, header_indices, 0, true);

    var header_end = false;
    var request_content_length: usize = 0;
    var offset: usize = 0;

    var chunk_length = buf.len;

    // read header
    while (!header_end and (offset == 0 or (chunk_length == buf.len))) {
        if (
            request_content_length > 0 and offset > 0 and header.len > 0 and
            (offset == (header.len + request_content_length))
        ) {
            break;
        }

        chunk_length = try conn.stream.read(buf);
        if (chunk_length == 0) {
            break;
        }

        // parse header
        var i: usize = 0;
        while (i < chunk_length) : (i += 1) {
            const ch = buf[i];
            if (ch != LF) {
                continue;
            }

            if (i >= 3) {
                header_end = (
                    buf[i - 3] == CR
                    and buf[i - 2] == LF
                    and buf[i - 1] == CR
                );
            } else if (i == 2 and header.len >= 1) {
                header_end = (
                    header[header.len - 1] == CR
                    and buf[i - 2] == LF
                    and buf[i - 1] == CR
                );
            } else if (i == 1 and header.len >= 2) {
                header_end = (
                    header[header.len - 2] == CR
                    and header[header.len - 1] == LF
                    and buf[i - 1] == CR
                );
            } else if (i == 0 and header.len >= 3) {
                header_end = (
                    header[header.len - 3] == CR
                    and header[header.len - 2] == LF
                    and header[header.len - 1] == CR
                );
            }

            if (header_end) {
                header = try util.appendStr(header, buf[0..(i + 1)], true);

                try parseHeaderLine(header, header_indices, &headers);

                if ((i + 1) < chunk_length) {
                    body = try util.appendStr(body, buf[(i + 1)..chunk_length], true);
                }

                break;
            }

            header_indices = try util.appendOne(usize, header_indices, offset + i + 1, true);
        }

        if (!header_end) {
            header = try util.appendStr(header, buf, true);
        }

        offset += chunk_length;
    }

    const entry = headers.getEntry(HEADER_KEY_CONTENT_LENGTH);
    if (entry != null) {
        request_content_length = try std.fmt.parseInt(usize, entry.?.value_ptr.*, 10);
    }

    // read body
    while (offset < (header.len + request_content_length)) {
        chunk_length = try conn.stream.read(buf);
        if (chunk_length == 0) {
            break;
        }

        body = try util.appendStr(body, buf[0..chunk_length], true);

        offset += chunk_length;
    }

    std.debug.print("Header:\n{s}\n\n", .{header});
    std.debug.print("Body:\n{s}\n\n", .{body});

    var resp_array = std.ArrayList(u8).init(allocator());
    var content_array = std.ArrayList(u8).init(allocator());
    defer resp_array.deinit();
    defer content_array.deinit();

    var resp_writer = resp_array.writer();
    var content_writer = content_array.writer();

    try content_writer.print("hello world !\nYou sent me following body;\n{s}\n", .{body});

    try createResponse(content_array.items, resp_writer);

    _ = try conn.stream.write(resp_array.items);

    std.debug.print("Reponse\n{s}\n\n", .{resp_array.items});
}

fn parseHeaderLine(header: []u8, indices: []usize, out: *std.StringArrayHashMap([]u8)) !void {
    var j: usize = 0;
    while (j < (indices.len - 1)) : (j += 1) {
        const index = indices[j];
        const next_index = indices[j + 1];
        const header_line = header[index..next_index];
        
        var h_i: usize = 0;
        var key_to: usize = 0;
        var value_from: usize = 0;
        while (h_i < header_line.len) : (h_i += 1) {
            if (key_to == 0) {
                if (header_line[h_i] == HEADER_KEY_SEPARATOR) {
                    key_to = h_i;
                    continue;
                }
            } else {
                if (header_line[h_i] != WHITE_SPACE) {
                    value_from = h_i;
                    break;
                }
            }
        }

        const key = header_line[0..key_to];
        const value = header_line[value_from..(header_line.len - 2)];

        try out.put(key, value);
    }
}

fn createResponse(content: []const u8, writer: std.ArrayList(u8).Writer) !void {
    try writer.print("HTTP/1.1 200 OK\nContent-Length: {d}\nContent-Type: text/plain; charset=utf-8\n\n{s}", .{content.len, content});
}

