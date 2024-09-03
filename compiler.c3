module compiler;

import libc;
import std::collections::map;
import std::collections::list;

import std::io;

import common;
import vm;
import raylib;
import animation;

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
    DIRECTION_LITERAL,

    TYPE,

    KEYWORD_HEADER,
    KEYWORD_SCENE,
    KEYWORD_CHARACTER,
    KEYWORD_BACKGROUND,
    KEYWORD_FLAG,

    KEYWORD_SAY,
    KEYWORD_GOTO,

    KEYWORD_SPAWN,
    KEYWORD_SHOW,
    KEYWORD_HIDE,
    KEYWORD_MOVE,
    KEYWORD_EMOTE,
    KEYWORD_FACE,

    KEYWORD_SEQUENCE,
    KEYWORD_GROUP,
    KEYWORD_SLIDE,
    KEYWORD_LOOP,

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
        char[]    string_value;
        int       integer_value;
        float     float_value;
        char[]    identifier_value;
        bool      boolean_value;
        TypeType  type_value;
        Direction direction_value;
    }
}

enum ActionType : char {
    SAY,
    GOTO,

    SPAWN,
    SET_VISIBILITY,
    MOVE,
    EMOTE,
    FACE,

    SET_BACKGROUND,

    ANIMATION,

    END,
}

struct Action {
    ActionType action_type;

    union {
        char[] text_to_say; /* SAY   */
        char[] scene_id;    /* GOTO  */

        struct {            /* SPAWN */
            char[]    character_name;
            char[]    emotion_name;   /* EMOTE          */
            Vector2   position;       /* MOVE           */
            bool      visibility;     /* SET_VISIBILITY */
            Direction direction;      /* FACE           */
        }

        AnimationIndex  animation;        /* ANIMATION      */
        SpriteDataIndex background_index; /* SET_BACKGROUND */
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

macro bool character_exists(char[] name) {
    return common::character_name_table.has_key(name);
}

macro bool character_has_emotion(char[] name, char[] emotion) {
    return common::get_character_by_name(name).emotion_sprite_table.has_key(emotion);
}

fn bool has_flag(char[] name) @inline {
    foreach(Flag f : flags) {
        if (f.name == name) return true;
    }

    return false;
}

fn bool is_whitespace(char c) @inline { return c == ' ' || c == '\n' || c == '\t'; }

fn bool is_identifier_start_character(char c) @inline {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') || c == '_';
}

fn bool is_numeric(char c) @inline { return c >= '0' && c <= '9'; }

fn void die(String format, args...) @noreturn {
    io::printf("ERROR:%s:%d:%d: ", filename, current_token.location.line + 1, current_token.location.character);
    io::printf(format, ...args);
    io::print("\n");
    libc::exit(1);
    unreachable();
}

fn void die_with_location(Location location, String format, args...) @noreturn {
    io::printf("ERROR:%s:%d:%d: ", filename, location.line + 1, location.character);
    io::printf(format, ...args);
    io::print("\n");
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

    do {
        bump_tokenizer();
    } while(has_more_text() && (is_identifier_start_character(file_data[tokenizing_cursor]) || is_numeric(file_data[tokenizing_cursor])));

    result.text_length = tokenizing_location.character - result.location.character;
    char[] text = file_data[tokenizing_cursor-result.text_length..tokenizing_cursor-1];

    switch(text) {

    /* Keywords */
    case "background": result.token_type = TokenType.KEYWORD_BACKGROUND;
    case "character":  result.token_type = TokenType.KEYWORD_CHARACTER;
    case "sequence":   result.token_type = TokenType.KEYWORD_SEQUENCE;
    case "header":     result.token_type = TokenType.KEYWORD_HEADER;
    case "spawn":      result.token_type = TokenType.KEYWORD_SPAWN;
    case "slide":      result.token_type = TokenType.KEYWORD_SLIDE;
    case "group":      result.token_type = TokenType.KEYWORD_GROUP;
    case "scene":      result.token_type = TokenType.KEYWORD_SCENE;
    case "emote":      result.token_type = TokenType.KEYWORD_EMOTE;
    case "loop":       result.token_type = TokenType.KEYWORD_LOOP;
    case "flag":       result.token_type = TokenType.KEYWORD_FLAG;
    case "show":       result.token_type = TokenType.KEYWORD_SHOW;
    case "hide":       result.token_type = TokenType.KEYWORD_HIDE;
    case "move":       result.token_type = TokenType.KEYWORD_MOVE;
    case "goto":       result.token_type = TokenType.KEYWORD_GOTO;
    case "face":       result.token_type = TokenType.KEYWORD_FACE;
    case "say":        result.token_type = TokenType.KEYWORD_SAY;
    case "end":        result.token_type = TokenType.KEYWORD_END;

    /* Literals */
    case "true":       result.token_type = TokenType.BOOLEAN_LITERAL;   result.boolean_value    = true;
    case "false":      result.token_type = TokenType.BOOLEAN_LITERAL;   result.boolean_value    = false;
    case "right":      result.token_type = TokenType.DIRECTION_LITERAL; result.direction_value  = Direction.RIGHT;
    case "left":       result.token_type = TokenType.DIRECTION_LITERAL; result.direction_value  = Direction.LEFT;
    case "bool":       result.token_type = TokenType.TYPE;              result.type_value       = TypeType.BOOLEAN;
    case "int" :       result.token_type = TokenType.TYPE;              result.type_value       = TypeType.INTEGER;
    default:           result.token_type = TokenType.IDENTIFIER;        result.identifier_value = text;
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

fn void parse_animation(Animation* animation, uint recursion_level = 0) {
    switch(current_token.token_type) {
    case TokenType.KEYWORD_SLIDE:
        char[] character_name = expect(TokenType.IDENTIFIER).identifier_value;

        if(!character_exists(character_name)) die("Trying to slide animate non-existent character '%s'", character_name);

        Vector2 slide_from = {
            (float)expect(TokenType.INTEGER_LITERAL).integer_value,
            (float)expect(TokenType.INTEGER_LITERAL).integer_value
        };

        Vector2 slide_to = {
            (float)expect(TokenType.INTEGER_LITERAL).integer_value,
            (float)expect(TokenType.INTEGER_LITERAL).integer_value
        };

        float duration = (float)expect(TokenType.INTEGER_LITERAL).integer_value;

        expect(TokenType.SEMICOLON);

        animation.animation_type  = AnimationType.SLIDE;
        animation.step            = 0.0;
        animation.duration        = duration;
        animation.character_index = common::character_name_table[character_name]!!;
        animation.slide_to        = slide_to;
        animation.slide_from      = slide_from;
    case TokenType.KEYWORD_LOOP:
        if(recursion_level > 0) die("Looping animations are only allowed at the top level");
        bump_lexer();
        animation.animation_type = AnimationType.LOOP;
        Animation sub_animation;
        parse_animation(&sub_animation, recursion_level + 1);
        animation.push(sub_animation)!!;

    case TokenType.KEYWORD_SEQUENCE:
        animation.animation_type = AnimationType.SEQUENCE;
        expect(TokenType.OPEN_BRACKET);
        bump_lexer();

        if(current_token.token_type == TokenType.CLOSE_BRACKET) {
            die("Empty animation sequences are not allowed");
        }

        while(current_token.token_type != TokenType.CLOSE_BRACKET) {
            Animation sub_animation;
            parse_animation(&sub_animation, recursion_level + 1);
            animation.push(sub_animation)!!;
            bump_lexer();
        }
    case TokenType.KEYWORD_GROUP:
        animation.animation_type = AnimationType.GROUP;
        expect(TokenType.OPEN_BRACKET);
        bump_lexer();

        if(current_token.token_type == TokenType.CLOSE_BRACKET) {
            die("Empty animation groups are not allowed");
        }

        while(current_token.token_type != TokenType.CLOSE_BRACKET) {
            Animation sub_animation;
            parse_animation(&sub_animation, recursion_level + 1);
            animation.push(sub_animation)!!;
            bump_lexer();
        }

    default:
        die("Unexpected token %s during animation declaration", current_token.token_type);
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

        case TokenType.KEYWORD_SPAWN:
            action.action_type = ActionType.SPAWN;
            char[] name    = expect(TokenType.IDENTIFIER).identifier_value;
            char[] emotion = expect(TokenType.IDENTIFIER).identifier_value;

            if(character_exists(name) && character_has_emotion(name, emotion)) {
                action.character_name = name;
                action.emotion_name   = emotion;
                action.position.x     = expect(TokenType.INTEGER_LITERAL).integer_value;
                action.position.y     = expect(TokenType.INTEGER_LITERAL).integer_value;
                action.direction      = expect(TokenType.DIRECTION_LITERAL).direction_value;
            } else {
                die("Unknown emotion %s emotion for character %s", emotion, name);
            }


            expect(TokenType.SEMICOLON);

        case TokenType.KEYWORD_SHOW:
            action.action_type    = ActionType.SET_VISIBILITY;
            action.character_name = expect(TokenType.IDENTIFIER).identifier_value;
            action.visibility     = true;

            if(!character_exists(action.character_name)) die("Trying to show non-existent character '%s'", action.character_name);

            expect(TokenType.SEMICOLON);

        case TokenType.KEYWORD_HIDE:
            action.action_type    = ActionType.SET_VISIBILITY;
            action.character_name = expect(TokenType.IDENTIFIER).identifier_value;
            action.visibility     = false;

            if(!character_exists(action.character_name)) die("Trying to hide non-existent character '%s'", action.character_name);

            expect(TokenType.SEMICOLON);

        case TokenType.KEYWORD_EMOTE:
            action.action_type    = ActionType.EMOTE;
            action.character_name = expect(TokenType.IDENTIFIER).identifier_value;

            if(!character_exists(action.character_name)) die("Trying to emote non-existent character '%s'", action.character_name);

            action.emotion_name = expect(TokenType.IDENTIFIER).identifier_value;

            if(!character_has_emotion(action.character_name, action.emotion_name)) {
                die("Trying to emote character '%s' with non-existent emotion %s", action.character_name, action.emotion_name);
            }

            expect(TokenType.SEMICOLON);

        case TokenType.KEYWORD_MOVE:
            action.action_type    = ActionType.MOVE;
            action.character_name = expect(TokenType.IDENTIFIER).identifier_value;

            if(!character_exists(action.character_name)) die("Trying to move non-existent character '%s'", action.character_name);

            action.position.x = expect(TokenType.INTEGER_LITERAL).integer_value;
            action.position.y = expect(TokenType.INTEGER_LITERAL).integer_value;

            expect(TokenType.SEMICOLON);

        case TokenType.KEYWORD_SLIDE:
        case TokenType.KEYWORD_LOOP:
        case TokenType.KEYWORD_GROUP:
        case TokenType.KEYWORD_SEQUENCE:
            action.action_type = ActionType.ANIMATION;

            Animation animation;
            parse_animation(&animation);
            animation::animation_list.push(animation);

            action.animation = animation::animation_list.len() - 1;

        case TokenType.KEYWORD_BACKGROUND:
            action.action_type = ActionType.SET_BACKGROUND;

            char[] background_name = expect(TokenType.IDENTIFIER).identifier_value;

            if(!common::background_exists(background_name)) die("Referencing non-existent background '%s'", background_name);

            expect(TokenType.SEMICOLON);

            action.background_index = common::background_name_table[background_name]!!;
        case TokenType.KEYWORD_FACE:
            action.action_type = ActionType.FACE;

            char[] character_name = expect(TokenType.IDENTIFIER).identifier_value;

            if(!character_exists(character_name)) die("Trying to face non-existent character '%s'", character_name);

            action.character_name = character_name;
            action.direction      = expect(TokenType.DIRECTION_LITERAL).direction_value;

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

fn void parse_character() {

    // TODO: Handle redefinition of character
    char[] character_name = expect(TokenType.IDENTIFIER).identifier_value;

    int count = 0;
    while(true) {
        bump_lexer();

        if(current_token.token_type == TokenType.SEMICOLON) {
            if(count == 0) {
                die("Sprites with no files are not allowed");
            } else {
                break;
            }
        } else if(current_token.token_type == TokenType.STRING_LITERAL) {
            char[] filename = current_token.string_value; // @cleanup validate filename
            char[] emotion  = expect(TokenType.IDENTIFIER).identifier_value;

            if(character_exists(character_name) && character_has_emotion(character_name, emotion)) {
                die("Redefinition of emotion '%s' for character '%s'", emotion, character_name);
            }

            if(!character_exists(character_name)) {
                common::characters.push(Character {
                    .visible         = false,
                    .current_emotion = emotion,
                    .name            = character_name,
                    .direction       = common::DEFAULT_DIRECTION,
                });
                common::character_name_table[character_name] = (uint)(common::characters.len() - 1);
            }

            Direction direction = expect(TokenType.DIRECTION_LITERAL).direction_value;

            SpriteDataIndex sprite_date_index = common::push_sprite_data(SpriteData {
                .filename   = filename,
                .needs_flip = (direction != common::DEFAULT_DIRECTION),
            });
            common::get_character_by_name(character_name).emotion_sprite_table[emotion] = sprite_date_index;

            count++;
        } else {
            die("Unexpected token %s in character sprite declaration", current_token.token_type);
        }
    }
}

fn void parse_background() {
    char[] background_name = expect(TokenType.IDENTIFIER).identifier_value;
    if(common::background_exists(background_name)) die("Redefinition of existing background named '%s'", background_name);

    char[] filename = expect(TokenType.STRING_LITERAL).string_value; // @cleanup validate filename
    expect(TokenType.SEMICOLON);

    common::background_name_table[background_name] = common::push_sprite_data(SpriteData { .filename = filename, .needs_flip = false });
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

fn void compile_file(String path) {

    filename = path;
    load_file(path)!!;

    for(current_token = next_token(); current_token.token_type != TokenType.EOF; bump_lexer()) {
        switch(current_token.token_type) {
        // each parse function must finish on it's last token,
        // since the for loop calls lexer.bump() at the end
        case TokenType.KEYWORD_HEADER:     parse_header();
        case TokenType.KEYWORD_SCENE:      parse_scene();
        case TokenType.KEYWORD_FLAG:       parse_flag();
        case TokenType.KEYWORD_CHARACTER:  parse_character();
        case TokenType.KEYWORD_BACKGROUND: parse_background();
        default:                           die("unknown token %s", current_token.token_type);
        }
    }

    defer {
        foreach(Scene scene : scenes) scene.actions.free();
        scenes.free();
    }

    if(goto_promises.size > 0) {
        foreach(Token goto_promise : goto_promises) {
            if(!has_scene_with_id(goto_promise.identifier_value)) {
                die_with_location(goto_promise.location, "goto pointing to non-existent scene '%s'", goto_promise.identifier_value);
            }
        }

        goto_promises.free();
    }

    List(<InstructionIndex>) labels;
    defer labels.free();

    foreach(Scene scene : scenes) {
        labels.push((InstructionIndex)vm::instructions.size);
        foreach(Action action : scene.actions) {
            switch(action.action_type) {
            case SAY:
                vm::instructions.push({
                    .instruction_type = InstructionType.SHOW_TEXT,
                    .text_to_show     = action.text_to_say,
                    .blocking         = true,
                });
            case GOTO:
                vm::instructions.push({
                    .instruction_type = InstructionType.GOTO_LABEL,
                    .scene_index      = get_index_of_scene_with_id(action.scene_id),
                    .blocking         = false,
                });
            case END:
                vm::instructions.push({
                    .instruction_type = InstructionType.END_SCENARIO,
                    .blocking         = true,
                });
            case SPAWN:
                vm::instructions.push({
                    .instruction_type  = InstructionType.CHARACTER_VISIBILITY_SET,
                    .character_index   = common::character_name_table[action.character_name]!!,
                    .set_visibility_to = true,
                    .blocking          = false,
                });

                vm::instructions.push({
                    .instruction_type  = InstructionType.CHARACTER_POSITION,
                    .character_index   = common::character_name_table[action.character_name]!!,
                    .set_position_to   = action.position,
                    .blocking          = false,
                });

                vm::instructions.push({
                    .instruction_type  = InstructionType.CHARACTER_EMOTE,
                    .character_index   = common::character_name_table[action.character_name]!!,
                    .set_emotion_to    = action.emotion_name,
                    .blocking          = false,
                });

                vm::instructions.push({
                    .instruction_type  = InstructionType.CHARACTER_FACE,
                    .character_index   = common::character_name_table[action.character_name]!!,
                    .direction_to_face = action.direction,
                    .blocking          = false,
                });
            case SET_VISIBILITY:
                vm::instructions.push({
                    .instruction_type  = InstructionType.CHARACTER_VISIBILITY_SET,
                    .character_index   = common::character_name_table[action.character_name]!!,
                    .set_visibility_to = action.visibility,
                    .blocking          = false,
                });
            case EMOTE:
                vm::instructions.push({
                    .instruction_type  = InstructionType.CHARACTER_EMOTE,
                    .character_index   = common::character_name_table[action.character_name]!!,
                    .set_emotion_to    = action.emotion_name,
                    .blocking          = false,
                });
            case MOVE:
                vm::instructions.push({
                    .instruction_type  = InstructionType.CHARACTER_POSITION,
                    .character_index   = common::character_name_table[action.character_name]!!,
                    .set_position_to   = action.position,
                    .blocking          = false,
                });
            case ANIMATION:
                vm::instructions.push({
                    .instruction_type  = InstructionType.ANIMATE,
                    .animation_index   = action.animation,
                    .blocking          = false,
                });
            case SET_BACKGROUND:
                vm::instructions.push({
                    .instruction_type  = InstructionType.BACKGROUND,
                    .background_index  = action.background_index,
                    .blocking          = false,
                });
            case FACE:
                vm::instructions.push({
                    .instruction_type  = InstructionType.CHARACTER_FACE,
                    .character_index   = common::character_name_table[action.character_name]!!,
                    .direction_to_face = action.direction,
                    .blocking          = false,
                });
            }
        }
    }

    for(usz i = 0; i < vm::instructions.size; i++) {
        if(vm::instructions[i].instruction_type == InstructionType.GOTO_LABEL) {

            // @cleanup workaround for https://github.com/c3lang/c3c/issues/1357
            // change to one line when this issue is fixed.
            Instruction* goto_instruction   = &vm::instructions[i];
            goto_instruction.label_to_go_to = labels[vm::instructions[i].scene_index];
        }
    }

}
