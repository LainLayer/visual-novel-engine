module render;

import std::io;
import std::math;

import compiler;
import vm;
import raylib;
import common;

struct TextAnimation {
    float duration;
    float step;
    char[] text;
}

TextAnimation text = {
    .duration = 0.35,
    .step     = 0.0,
    .text     = ""
};

Rectangle textbox_rectangle;

const usz MAX_TEXT_SIZE = 1024;
char[MAX_TEXT_SIZE] message_box_buffer;

const float FONT_SIZE    = 32.0;
const float TEXT_PADDING = 20.0;
const float LINE_SPACING =  5.0;

fn Rectangle Rectangle.shrink(rectangle, float n) @inline {
    return {
        .x      = rectangle.x + n,
        .y      = rectangle.y + n,
        .width  = rectangle.width  - n*2,
        .height = rectangle.height - n*2,
    };
}

fn void TextAnimation.render(&animation) {
    if(animation.step >= animation.duration) {
        io::bprintf(&message_box_buffer, "%s\0", animation.text);
    } else {
        animation.step     += raylib::get_frame_time();
        float percentage    = animation.step / animation.duration;
        uint  chars_to_draw = (uint)math::ceil((float)animation.text.len * percentage);

        if(chars_to_draw < 1)                      return;
        if(chars_to_draw > animation.text.len - 1) chars_to_draw = animation.text.len - 1;
        if(chars_to_draw > MAX_TEXT_SIZE - 1)      chars_to_draw = MAX_TEXT_SIZE      - 1;

        message_box_buffer[0..chars_to_draw-1] = animation.text[0..chars_to_draw-1];
        message_box_buffer[chars_to_draw] = '\0';
    }
    raylib::draw_text_boxed(
        raylib::get_font_default(),
        (ZString)&message_box_buffer,
        textbox_rectangle.shrink(TEXT_PADDING),
        FONT_SIZE,
        LINE_SPACING,
        true,
        raylib::WHITE
    );
}

fn void update_textbox_rectangle() @inline {
    textbox_rectangle = {
        .x = 10,
        .y = ((float)(raylib::get_screen_height()) * 0.66),
        .width  = (float)(raylib::get_screen_width()  - 20),
        .height = ((float)raylib::get_screen_height() / 3.0)
    };
}

fn bool step_program(Program* program) {
    Instruction inst = program.instructions[(usz)program.instruction_pointer];
    InstructionIndex old_instruction_pointer = program.instruction_pointer;

    bool no_push = false;

    switch(inst.instruction_type) {
    case InstructionType.SHOW_TEXT:
        inst.previously_shown_text = text.text;
        text.text = inst.text_to_show;
        text.step = 0;
        program.instruction_pointer += 1;
    case InstructionType.GOTO_LABEL:
        program.instruction_pointer = inst.label_to_go_to;
    case InstructionType.CHARACTER_VISIBILITY_SET:
        Character temp_character = program.character_table[inst.character_name]!!;

        inst.previous_visibility = temp_character.visible;
        temp_character.visible   = inst.set_visibility_to;

        program.character_table[inst.character_name] = temp_character;
        program.instruction_pointer += 1;
    case InstructionType.CHARACTER_POSITION:
        Character temp_character = program.character_table[inst.character_name]!!;

        inst.previous_position  = temp_character.position;
        temp_character.position = inst.set_position_to;

        program.character_table[inst.character_name] = temp_character;
        program.instruction_pointer += 1;
    case InstructionType.CHARACTER_EMOTE:
        Character temp_character = program.character_table[inst.character_name]!!;

        inst.previous_emotion          = temp_character.current_emotion;
        temp_character.current_emotion = inst.set_emotion_to;

        program.character_table[inst.character_name] = temp_character;
        program.instruction_pointer += 1;
    case InstructionType.END_SCENARIO:
        inst.previously_shown_text = text.text;
        text.text = "END.";
        text.step = 0;
        no_push = (program.history[program.history.size - 1].instruction_type == InstructionType.END_SCENARIO);
    }
    inst.previous_instruction_pointer = old_instruction_pointer;
    if(!no_push) program.history.push(inst);
    return inst.blocking;
}

fn bool Program.last_instruction_blocking(program) {
    if(program.history.size < 2) return true;
    return program.history[program.history.size - 1].blocking;
}

fn void step_back(Program* program) {
    if(program.history.size < 2) return;

    Instruction inst = program.history.pop();
    switch(inst.instruction_type) {
    case InstructionType.SHOW_TEXT:
    case InstructionType.END_SCENARIO:
        text.text = inst.previously_shown_text;

    case InstructionType.CHARACTER_VISIBILITY_SET:
        Character temp_character = program.character_table[inst.character_name]!!;

        temp_character.visible = inst.previous_visibility;

        program.character_table[inst.character_name] = temp_character;
    case InstructionType.CHARACTER_POSITION:
        Character temp_character = program.character_table[inst.character_name]!!;

        temp_character.position = inst.previous_position;

        program.character_table[inst.character_name] = temp_character;
    case InstructionType.CHARACTER_EMOTE:
        Character temp_character = program.character_table[inst.character_name]!!;

        temp_character.current_emotion = inst.previous_emotion;

        program.character_table[inst.character_name] = temp_character;
    case InstructionType.GOTO_LABEL:
        break;
    }
    program.instruction_pointer = inst.previous_instruction_pointer;
}

fn void main() {
    io::printn("test!");

    Program program = compiler::compile_file("test.balls")!!;
    step_program(&program);

    io::printf("instruction size: %d\n", $sizeof(Instruction.typeid));

    raylib::init_window(1920, 1080, "Visual Novel Renderer");
    defer raylib::close_window();

    program.load_assets();

    raylib::set_target_fps(60);

    while(!raylib::window_should_close()) {
        update_textbox_rectangle();

        if(raylib::is_key_pressed(KeyboardKey.SPACE.value)) {
            io::printn("steping forward");
            while(!step_program(&program));
        } else if(raylib::is_key_pressed(KeyboardKey.F1.value)) {
            io::printn("steping backwards");
            do {
                step_back(&program);
            } while(!program.last_instruction_blocking());
        }

        raylib::begin_drawing();

            raylib::clear_background({0x18, 0x18, 0x18, 255});
            raylib::draw_text("Sample Text!", 50, 50, 24, raylib::WHITE);

            program.character_table.@each(; char[] name, Character character) {
                if(character.visible ) {
                    raylib::draw_texture(
                        character.emotion_sprite_table[character.current_emotion]!!.texture,
                        (CInt)character.position.x,
                        (CInt)character.position.y,
                        raylib::WHITE
                    );
                }
            };

            raylib::draw_rectangle_rec(textbox_rectangle, {0x11,0x11,0x11,180});
            raylib::draw_rectangle_lines_ex(textbox_rectangle, 5.0, raylib::WHITE);
            text.render();

        raylib::end_drawing();
    }

}
