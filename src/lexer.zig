pub const TokenType = enum {
    left_paren,
    right_paren,
    literal,
    string,
    error_,
    eof,
};

pub const Token = struct {
    type: TokenType,
    value: []const u8,
    start_line: usize,
    start_column: usize,
    end_line: usize,
    end_column: usize,
};

pub const Lexer = struct {
    source: []const u8,
    line: usize,
    column: usize,
    start_index: usize,
    current_index: usize,

    pub fn init(source: []const u8) Lexer {
        return .{
            .source = source,
            .line = 0,
            .column = 0,
            .start_index = 0,
            .current_index = 0,
        };
    }

    pub fn isAtEnd(self: *Lexer) bool {
        return self.current_index >= self.source.len;
    }

    fn incrLine(self: *Lexer) void {
        self.line += 1;
        self.column = 0;
    }

    fn advance(self: *Lexer) void {
        self.current_index += 1;
        self.column += 1;
        if (self.isAtEnd()) self.current_index = self.source.len;
    }

    fn peek(self: *Lexer) u8 {
        return if (self.current_index < self.source.len) self.source[self.current_index] else 0;
    }

    fn peekNext(self: *Lexer) u8 {
        const index = self.current_index + 1;
        return if (index < self.source.len) self.source[index] else 0;
    }

    fn discard(self: *Lexer) void {
        self.start_index = self.current_index;
    }

    fn token(self: *Lexer, token_type: TokenType) Token {
        return .{
            .type = token_type,
            .value = self.source[self.start_index..self.current_index],
            .start_line = self.line,
            .start_column = self.column + self.start_index - self.current_index,
            .end_line = self.line,
            .end_column = self.column,
        };
    }

    fn multilineToken(self: *Lexer, token_type: TokenType, s_line: usize, s_col: usize) Token {
        return .{
            .type = token_type,
            .value = self.source[self.start_index..self.current_index],
            .start_line = s_line,
            .start_column = s_col,
            .end_line = self.line,
            .end_column = self.column,
        };
    }

    fn errorToken(self: *Lexer, message: []const u8) Token {
        return .{
            .type = .error_,
            .value = message,
            .start_line = self.line,
            .start_column = self.column,
            .end_line = self.line,
            .end_column = self.column,
        };
    }

    fn isLiteral(c: u8) bool {
        return switch (c) {
            ' ', '\t', '\r', '\n', '(', ')', ';', 0 => false,
            else => true,
        };
    }

    fn literal(self: *Lexer) Token {
        while (isLiteral(self.peek())) self.advance();
        return self.token(.literal);
    }

    fn string(self: *Lexer) Token {
        // discard opening quote
        self.discard();

        const start_line = self.line;
        const start_col = self.column;

        while (!self.isAtEnd()) {
            if (self.peek() == '"') {
                if (self.peekNext() == '"') {
                    self.advance();
                } else {
                    break;
                }
            }
            if (self.peek() == '\n') self.incrLine();
            self.advance();
        }

        if (self.isAtEnd()) return self.errorToken("Unterminated string");

        const tok = self.multilineToken(.string, start_line, start_col);

        // discard closing quote
        self.advance();
        self.discard();

        return tok;
    }

    pub fn lexToken(self: *Lexer) Token {
        self.discard();

        while (!self.isAtEnd()) {
            const c = self.peek();
            self.advance();

            switch (c) {
                ' ', '\t', '\r' => self.discard(),
                '\n' => {
                    self.incrLine();
                    self.discard();
                },
                '(' => return self.token(.left_paren),
                ')' => return self.token(.right_paren),
                ';' => {
                    while (self.peek() != '\n' and !self.isAtEnd()) self.advance();
                    self.discard();
                },
                '"' => return self.string(),
                else => return self.literal(),
            }
        }

        return self.token(.eof);
    }
};
