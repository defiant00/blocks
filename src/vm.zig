const std = @import("std");
const Allocator = std.mem.Allocator;
const debug = @import("debug.zig");
const GcAllocator = @import("memory.zig").GcAllocater;
const Node = @import("ast.zig").Node;
const Parser = @import("parser.zig");
const StringPool = @import("string_pool.zig").StringPool;

pub const VM = struct {
    parent_allocator: Allocator,
    gc: GcAllocator,
    allocator: Allocator,

    root: Node,
    source_strings: StringPool,

    pub fn init(self: *VM, allocator: Allocator) !void {
        self.parent_allocator = allocator;
        self.gc = GcAllocator.init(self);
        self.allocator = self.gc.allocator();

        self.root = try Node.List(self.allocator, 0, 0);
        self.source_strings = StringPool.init(self.allocator);
    }

    pub fn deinit(self: *VM) void {
        self.root.deinit();
        self.source_strings.deinit();
    }

    pub fn collectGarbage(self: *VM) void {
        _ = self;
    }

    pub fn load(self: *VM, source: []const u8) !void {
        try Parser.parse(self, source);
        if (debug.print_ast) self.root.print();
    }

    pub fn run(self: *VM) !void {
        _ = self;
    }
};
