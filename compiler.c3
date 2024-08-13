module compiler;

import libc;

import std::io;
def printf = io::printf;
def printn = io::printn;
def print  = io::print;

import common;
import vm;
import arena;
import list;

enum TokenType : char {
    INVALID_TOKEN,

    IDENTIFIER,

    OPEN_PAREN,
    CLOSE_PAREN,

    OPEN_BRACKET,
    CLOSE_BRACKET,

    COMMA,
    SEMICOLON,

    STRING_LITERAL,
    INTEGER_LITERAL,
    FLOAT_LITERAL,
    BOOLEAN_LITERAL,

    TYPE,

    KEYWORD_HEADER,
    KEYWORD_SCENE,
    KEYWORD_SAY,
    KEYWORD_FLAG,
    KEYWORD_GOTO,
    KEYWORD_END,

    EOF
}

enum TypeType : char {
    BOOLEAN,
    INTEGER,
}

struct Flag {
    char[]   name;
    TypeType flag_type;

    union {
        char[] string_value;
        int    integer_value;
        float  float_value;
        bool   boolean_value;
    }
}

struct Location {
    uint line;
    uint character;
}

struct Token {
    TokenType token_type;
    Location  location;
    uint      text_length;

    union {
        char[]   string_value;
        int      integer_value;
        float    float_value;
        char[]   identifier_value;
        bool     boolean_value;
        TypeType type_value;
    }
}


enum ActionType : char {
    SAY,
    GOTO,
    END,
}

struct Action {
    ActionType action_type;

    union {
        char[] text_to_say;
        char[] scene_id;
    }
}

struct Scene {
    char[]         scene_id;
    char[]         description;
    List(<Action>) actions;
}

uint           tokenizing_cursor;
Location       tokenizing_location;
char[]         file_data;
char[]         scenario_title;
char[]         author;
String         filename;
List(<Flag>)   flags;
List(<char[]>) languages;
List(<Scene>)  scenes;
List(<Token>)  goto_promises;
Token          current_token;

fn bool has_flag(char[] name) @inline {
    foreach(Flag f : flags) {
        if (f.name == name) return true;
    }

    return false;
}

fn void print_syntax_tree() {
    printf("scenario title: %s\n", scenario_title);
    printn("scenario languages:");

    foreach(char[] language : languages) {
        printf(" - %s\n", language);
    }

    printn("flags:");
    foreach(Flag flag : flags) {
        printf(" - %s - ", flag.name);
        switch(flag.flag_type) {
        case TypeType.BOOLEAN:
            printf("%s\n", flag.boolean_value);
        case TypeType.INTEGER:
            printf("%d\n", flag.integer_value);
        }
    }

    printn("Scenes:");
    foreach(Scene scene : scenes) {
        printf(" - %s :: '%s'\n", scene.scene_id, scene.description);
        foreach(Action action : scene.actions) {
            printf("   + %s: ", action.action_type);
            switch(action.action_type) {
            case ActionType.SAY:
                printf("%s\n", action.text_to_say);
            case ActionType.GOTO:
                printf("%s\n", action.scene_id);
            case ActionType.END:
                printf("end\n");
            }
        }
    }
}

fn bool is_whitespace(char c) @inline { return c == ' ' || c == '\n' || c == '\t'; }

fn bool is_identifier_start_character(char c) @inline {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') || c == '_';
}

fn bool is_numeric(char c) @inline { return c >= '0' && c <= '9'; }

fn void die(String format, args...) @noreturn {
    printf("ERROR:%s:%d:%d: ", filename, current_token.location.line + 1, current_token.location.character);
    printf(format, ...args);
    print("\n");
    libc::exit(1);
    unreachable();
}

fn void die_with_location(Location location, String format, args...) @noreturn {
    printf("ERROR:%s:%d:%d: ", filename, location.line + 1, location.character);
    printf(format, ...args);
    print("\n");
    libc::exit(1);
    unreachable();
}

fn void! load_file(String path) {
    tokenizing_cursor   = 0;
    tokenizing_location = { 0, 0 };
    filename            = path;
    file_data = io::file::load_new(path)!;
}

fn bool has_more_text() @inline { return tokenizing_cursor < file_data.len; }

fn void bump_tokenizer(uint n = 1) @inline {
    tokenizing_location.character += n;
    tokenizing_cursor             += n;
}

fn Token parse_identifier() {
    Token result;

    result.location = tokenizing_location;

    bump_tokenizer();
    while(has_more_text() && (is_identifier_start_character(file_data[tokenizing_cursor]) || is_numeric(file_data[tokenizing_cursor]))) {
        bump_tokenizer();
    }

    result.text_length = tokenizing_location.character - result.location.character;
    char[] text = file_data[(tokenizing_cursor-result.text_length)..tokenizing_cursor-1];

    switch(text) {
    case "header": result.token_type       = TokenType.KEYWORD_HEADER;
    case "scene":  result.token_type       = TokenType.KEYWORD_SCENE;
    case "flag":   result.token_type       = TokenType.KEYWORD_FLAG;
    case "goto":   result.token_type       = TokenType.KEYWORD_GOTO;
    case "say":    result.token_type       = TokenType.KEYWORD_SAY;
    case "end":    result.token_type       = TokenType.KEYWORD_END;

    case "true":   result.token_type       = TokenType.BOOLEAN_LITERAL;
                   result.boolean_value    = true;

    case "false":  result.token_type       = TokenType.BOOLEAN_LITERAL;
                   result.boolean_value    = false;

    case "bool":   result.token_type       = TokenType.TYPE;
                   result.type_value       = TypeType.BOOLEAN;

    case "int" :   result.token_type       = TokenType.TYPE;
                   result.type_value       = TypeType.INTEGER;

    default:       result.token_type       = TokenType.IDENTIFIER;
                   result.identifier_value = text;
    }

    return result;
}

fn Token parse_number_literal() {
    Token result;

    result.location = tokenizing_location;

    usz start = tokenizing_cursor;

    do {
        bump_tokenizer();
    } while(has_more_text() && is_numeric(file_data[tokenizing_cursor]));

    result.text_length = tokenizing_location.character - result.location.character;
    result.token_type  = TokenType.INTEGER_LITERAL;

    result.integer_value = ((String)file_data[start..tokenizing_cursor-1]).to_int()!!;

    return result;
}

fn Token parse_string_literal() {
    Token result;

    result.location = tokenizing_location;

    bump_tokenizer();
    while(has_more_text()) {
        if(file_data[tokenizing_cursor] == '\"') {
            bump_tokenizer();
            result.text_length  = tokenizing_location.character - result.location.character;
            result.token_type   = TokenType.STRING_LITERAL;
            result.string_value = file_data[(tokenizing_cursor-result.text_length+1)..tokenizing_cursor-2];

            return result;
        } else {
            bump_tokenizer();
        }
    }

    die("Unclosed string");
}

fn void eat_whitespace() {
    while(has_more_text() && is_whitespace(file_data[tokenizing_cursor])) {
        if(file_data[tokenizing_cursor] == '\n') {
            tokenizing_location.line     += 1;
            tokenizing_location.character = 0;
            tokenizing_cursor            += 1;
        } else {
            bump_tokenizer();
        }
    }
}

fn Token quick_single(TokenType token_type) {
    Token result = { .token_type = token_type, .location = tokenizing_location, .text_length = 1 };
    bump_tokenizer();
    return result;
}

fn Token next_token() {
    eat_whitespace();

    if(!has_more_text()) return { .token_type = TokenType.EOF, .location = tokenizing_location, .text_length = 0 };


    if (is_identifier_start_character(file_data[tokenizing_cursor])) {
        return parse_identifier();
    } else if (is_numeric(file_data[tokenizing_cursor])) {
        return parse_number_literal();
    } else {
        switch(file_data[tokenizing_cursor]) {
        case '{':  return quick_single(TokenType.OPEN_BRACKET);
        case '}':  return quick_single(TokenType.CLOSE_BRACKET);
        case '(':  return quick_single(TokenType.OPEN_PAREN);
        case ')':  return quick_single(TokenType.CLOSE_PAREN);
        case ',':  return quick_single(TokenType.COMMA);
        case ';':  return quick_single(TokenType.SEMICOLON);
        case '\"': return parse_string_literal();
        default:
            die("error: Invalid character '%c'", file_data[tokenizing_cursor]);
        }
    }
}

fn void bump_lexer() @inline {
    current_token = next_token();
}

fn Token expect(TokenType token_type) {
    bump_lexer();
    if(current_token.token_type == token_type) {
        return current_token;
    } else {
        die("expected token %s, got token %s", token_type, current_token.token_type);
    }
}

fn void parse_header() {
    Token identifier = expect(TokenType.IDENTIFIER);
    switch(identifier.identifier_value) {
    case "name":
        scenario_title = expect(TokenType.STRING_LITERAL).string_value;
        expect(TokenType.SEMICOLON);
    case "languages":
        languages.push(expect(TokenType.STRING_LITERAL).string_value);
        while(true) {
            bump_lexer();
            if (current_token.token_type == TokenType.STRING_LITERAL) {
                languages.push(current_token.string_value);
            } else if (current_token.token_type == TokenType.SEMICOLON) {
                break;
            } else {
                die("expecting string or semicolon but found %s", current_token.token_type);
            }
        }
    default:
        die("unknown header field %s", current_token.identifier_value);
    }
}

fn void parse_scene() {
    Scene scene;

    scene.scene_id    = expect(TokenType.IDENTIFIER).identifier_value;
    scene.description = expect(TokenType.STRING_LITERAL).string_value;
    expect(TokenType.OPEN_BRACKET);

    bump_lexer();

    if(current_token.token_type == TokenType.CLOSE_BRACKET) {
        die("Empty scenes are not allowed");
    }

    while(current_token.token_type != TokenType.CLOSE_BRACKET) {
        Action action;

        switch(current_token.token_type) {
        case TokenType.KEYWORD_SAY:
            action.action_type = ActionType.SAY;
            action.text_to_say = expect(TokenType.STRING_LITERAL).string_value;
            expect(TokenType.SEMICOLON);
        case TokenType.KEYWORD_GOTO:
            action.action_type  = ActionType.GOTO;
            Token goto_scene_id = expect(TokenType.IDENTIFIER);
            action.scene_id     = goto_scene_id.identifier_value;
            goto_promises.push(goto_scene_id);
            expect(TokenType.SEMICOLON);
        case TokenType.KEYWORD_END:
            action.action_type = ActionType.END;
            expect(TokenType.SEMICOLON);
        default:
            die("unimplemented action %s", current_token.token_type);
        }

        scene.actions.push(action);

        bump_lexer();
    }

    scenes.push(scene);
}

fn void parse_flag() {
    Flag flag;

    flag.name      = expect(TokenType.IDENTIFIER).identifier_value;
    flag.flag_type = expect(TokenType.TYPE).type_value;

    if(has_flag(flag.name)) {
        die("redefinition of existing flag '%s'", flag.name);
    }

    switch(flag.flag_type) {
    case TypeType.BOOLEAN:
        flag.boolean_value = expect(TokenType.BOOLEAN_LITERAL).boolean_value;
    case TypeType.INTEGER:
        flag.integer_value = expect(TokenType.INTEGER_LITERAL).integer_value;
    default:
        die("Unexpected type %s in flag declaration, likely unimplemented", flag.flag_type);
    }

    expect(TokenType.SEMICOLON);

    flags.push(flag);
}

fn bool has_scene_with_id(char[] id) {
    foreach(Scene scene : scenes) {
        if(scene.scene_id == id) return true;
    }

    return false;
}

fn usz get_index_of_scene_with_id(char[] id) {
    assert(has_scene_with_id(id));
    for(usz i = 0; i < scenes.size; i++) {
        if(scenes[i].scene_id == id) return i;
    }
    unreachable();
}

fn Program! compile_file(String path) {

    filename = path;
    load_file(path)!;

    for(current_token = next_token(); current_token.token_type != TokenType.EOF; bump_lexer()) {
        switch(current_token.token_type) {
        // each parse function must finish on it's last token,
        // since the for loop calls lexer.bump() at the end
        case TokenType.KEYWORD_HEADER: parse_header();
        case TokenType.KEYWORD_SCENE:  parse_scene();
        case TokenType.KEYWORD_FLAG:   parse_flag();
        default:                       die("unknown token %s", current_token.token_type);
        }
    }

    if(goto_promises.size > 0) {
        foreach(Token goto_promise : goto_promises) {
            if(!has_scene_with_id(goto_promise.identifier_value)) {
                die_with_location(goto_promise.location, "goto pointing to non-existent scene '%s'", goto_promise.identifier_value);
            }
        }

        goto_promises.free();
    }

    Program program;

    List(<InstructionIndex>) labels;

    foreach(Scene scene : scenes) {
        labels.push((InstructionIndex)program.instructions.size);

        foreach(Action action : scene.actions) {
            switch(action.action_type) {
            case SAY:
                program.instructions.push({
                    .instruction_type = InstructionType.SHOW_TEXT,
                    .text_to_show     = action.text_to_say,
                    .blocking         = true,
                    .has_undo_data    = false,
                });
            case GOTO:
                program.instructions.push({
                    .instruction_type = InstructionType.GOTO_LABEL,
                    .label_to_go_to   = get_index_of_scene_with_id(action.scene_id),
                    .blocking         = false,
                    .has_undo_data    = false,
                });
            case END:
                program.instructions.push({
                    .instruction_type = InstructionType.END_SCENARIO,
                    .blocking         = true,
                    .has_undo_data    = false,
                });
            }
        }
    }

    program.print();

    return program;
}
