const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const NodeType = enum {
    list,
    literal,
    string,
};

pub const Node = struct {
    as: union(NodeType) {
        list: *ArrayList(Node),
        literal: []const u8,
        string: []const u8,
    },
    start_line: usize,
    start_column: usize,
    end_line: usize,
    end_column: usize,

    pub fn getType(self: Node) NodeType {
        return self.as;
    }

    pub fn deinit(self: Node) void {
        switch (self.getType()) {
            .list => {
                const list = self.asList();
                const alloc = list.allocator;
                for (list.items) |node| {
                    node.deinit();
                }
                list.deinit();
                alloc.destroy(list);
            },
            else => {},
        }
    }

    pub fn List(alloc: Allocator, line: usize, col: usize) !Node {
        var new_list = try alloc.create(ArrayList(Node));
        new_list.* = ArrayList(Node).init(alloc);
        return .{
            .as = .{ .list = new_list },
            .start_line = line,
            .start_column = col,
            .end_line = line,
            .end_column = col,
        };
    }

    pub fn Literal(val: []const u8, line: usize, col: usize) Node {
        return .{
            .as = .{ .literal = val },
            .start_line = line,
            .start_column = col,
            .end_line = line,
            .end_column = col + val.len,
        };
    }

    pub fn String(val: []const u8, s_line: usize, s_col: usize, e_line: usize, e_col: usize) Node {
        return .{
            .as = .{ .string = val },
            .start_line = s_line,
            .start_column = s_col,
            .end_line = e_line,
            .end_column = e_col,
        };
    }

    pub fn isList(self: Node) bool {
        return self.as == .list;
    }

    pub fn isLiteral(self: Node) bool {
        return self.as == .literal;
    }

    pub fn isString(self: Node) bool {
        return self.as == .string;
    }

    pub fn asList(self: Node) *ArrayList(Node) {
        return self.as.list;
    }

    pub fn asLiteral(self: Node) []const u8 {
        return self.as.literal;
    }

    pub fn asString(self: Node) []const u8 {
        return self.as.string;
    }

    pub fn print(self: Node) void {
        switch (self.getType()) {
            .list => {
                const list = self.asList();
                std.debug.print("(", .{});
                var first = true;
                for (list.items) |node| {
                    if (first) {
                        first = false;
                    } else {
                        std.debug.print(" ", .{});
                    }
                    node.print();
                }
                std.debug.print(")", .{});
            },
            .literal => std.debug.print("{s}", .{self.asLiteral()}),
            .string => std.debug.print("\"{s}\"", .{self.asString()}),
        }
    }
};
