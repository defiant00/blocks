const std = @import("std");
const Allocator = std.mem.Allocator;

const Lexer = @import("lexer.zig").Lexer;
const VM = @import("vm.zig").VM;

pub fn parse(vm: *VM, source: []const u8) void {
    _ = vm;
    var lexer = Lexer.init(source);
    while (true) {
        const tok = lexer.lexToken();
        std.debug.print("{} - '{s}'\n", .{ tok.type, tok.value });
        if (tok.type == .eof) break;
    }
}

// pub fn parse(vm: *VM, source: []const u8) !Node {
//     var lexer = Lexer.init(source);
//     var root = try Node.File(vm.allocator);

//     try parseHelper(vm, &lexer, &root, root.asFile());

//     return root;
// }

// fn parseHelper(vm: *VM, lexer: *Lexer, parent_node: *Node, parent: *ArrayList(Node)) !void {
//     while (true) {
//         const tok = lexer.lexToken();
//         switch (tok.type) {
//             .left_paren => {
//                 var list = try Node.List(vm.allocator, tok.start_line, tok.start_column);
//                 try parseHelper(vm, lexer, &list, list.asList());
//                 try parent.append(list);
//             },
//             .right_paren => {
//                 if (!parent_node.isList()) {
//                     // todo - error
//                 }
//                 parent_node.end_line = tok.end_line;
//                 parent_node.end_column = tok.end_column;
//                 return;
//             },
//             .comment => {
//                 const val = try vm.copyString(tok.value);
//                 const node = Node.Comment(val, tok.start_line, tok.start_column);
//                 try parent.append(node);
//             },
//             .literal => {
//                 const val = try vm.copyString(tok.value);
//                 const node = Node.Literal(val, tok.start_line, tok.start_column);
//                 try parent.append(node);
//             },
//             .string => {
//                 const val = try vm.copyString(tok.value);
//                 const node = Node.String(val, tok.start_line, tok.start_column, tok.end_line, tok.end_column);
//                 try parent.append(node);
//             },
//             else => return,
//         }
//     }
// }
