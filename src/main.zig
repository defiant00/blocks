const std = @import("std");
const Allocator = std.mem.Allocator;

const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len == 3 and std.mem.eql(u8, args[1], "build")) {
        try buildFile(alloc, args[2]);
    } else if (args.len == 3 and std.mem.eql(u8, args[1], "run")) {
        // todo
    } else if (args.len == 2 and std.mem.eql(u8, args[1], "help")) {
        printUsage();
    } else if (args.len == 2 and std.mem.eql(u8, args[1], "version")) {
        std.debug.print("{}\n", .{version});
    } else {
        printUsage();
        return error.InvalidCommand;
    }
}

fn buildFile(alloc: Allocator, path: []const u8) !void {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const source = try file.readToEndAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(source);

    var buffered_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = buffered_writer.writer();

    // todo
    try stdout.writeAll(source);

    try buffered_writer.flush();
}

fn printUsage() void {
    std.debug.print(
        \\Usage: blocks [command] [options]
        \\
        \\Commands:
        \\  build       Build specified file
        \\  run         Build and run specified file
        \\
        \\  help        Print this help and exit
        \\  version     Print version and exit
        \\
    , .{});
}
