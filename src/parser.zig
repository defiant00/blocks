const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = @import("debug.zig");
const Lexer = @import("lexer.zig").Lexer;
const Node = @import("ast.zig").Node;
const VM = @import("vm.zig").VM;

pub fn parse(vm: *VM, source: []const u8) !void {
    var lexer = Lexer.init(source);
    try parseHelper(vm, &lexer, &vm.root);
}

fn parseHelper(vm: *VM, lexer: *Lexer, parent: *Node) !void {
    var parent_list = parent.asList();
    while (true) {
        const tok = lexer.lexToken();
        if (debug.print_tokens) {
            std.debug.print("{} - '{s}'\n", .{ tok.type, tok.value });
        }
        switch (tok.type) {
            .left_paren => {
                var list = try Node.List(vm.allocator, tok.start_line, tok.start_column);
                try parseHelper(vm, lexer, &list);
                try parent_list.append(list);
            },
            .right_paren => {
                parent.end_line = tok.end_line;
                parent.end_column = tok.end_column;
                return;
            },
            .literal => {
                const val = try vm.copyString(tok.value);
                const node = Node.Literal(val, tok.start_line, tok.start_column);
                try parent_list.append(node);
            },
            .string => {
                const val = try vm.copyEscapeString(tok.value);
                const node = Node.String(val, tok.start_line, tok.start_column, tok.end_line, tok.end_column);
                try parent_list.append(node);
            },
            .error_ => {
                std.debug.print("[{d}, {d}] {s}\n", .{ tok.start_line, tok.start_column, tok.value });
                return error.ErrorToken;
            },
            .eof => return,
        }
    }
}
