const std = @import("std");

const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len == 1) {
        var buffered_reader = std.io.bufferedReader(std.io.getStdIn().reader());
        const stdin = buffered_reader.reader();

        const source = try stdin.readAllAlloc(alloc, std.math.maxInt(usize));
        defer alloc.free(source);

        var buffered_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
        const stdout = buffered_writer.writer();

        // todo
        try stdout.writeAll(source);

        try buffered_writer.flush();
    } else if (args.len == 2 and std.mem.eql(u8, args[1], "help")) {
        printUsage();
    } else if (args.len == 2 and std.mem.eql(u8, args[1], "version")) {
        std.debug.print("{}\n", .{version});
    } else {
        printUsage();
        return error.InvalidCommand;
    }
}

fn printUsage() void {
    std.debug.print(
        \\Usage:
        \\  blocks            Run from stdin to stdout
        \\  blocks help       Print this help and exit
        \\  blocks version    Print version and exit
        \\
    , .{});
}
