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

RenderTexture2D game_texture;
Rectangle       game_rectangle;

const float GAME_WIDTH  = 1280;
const float GAME_HEIGHT = 720;

const Rectangle TEXTBOX_RECTANGLE = {
    .x      = 10,
    .y      = GAME_HEIGHT * 0.75,
    .width  = GAME_WIDTH  - 20,
    .height = GAME_HEIGHT / 4.0 - 10
};

const usz MAX_TEXT_SIZE = 1024;
char[MAX_TEXT_SIZE] message_box_buffer;

const float FONT_SIZE    = 18.0;
const float TEXT_PADDING = 10.0;
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
        TEXTBOX_RECTANGLE.shrink(TEXT_PADDING),
        FONT_SIZE,
        LINE_SPACING,
        true,
        raylib::WHITE
    );
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
        inst.previous_visibility = program.character_table[inst.character_name]!!.visible;
        program.character_table.get_ref(inst.character_name)!!.visible = inst.set_visibility_to;

        program.instruction_pointer += 1;
    case InstructionType.CHARACTER_POSITION:
        inst.previous_position = program.character_table[inst.character_name]!!.position;
        program.character_table.get_ref(inst.character_name)!!.position = inst.set_position_to;

        program.instruction_pointer += 1;
    case InstructionType.CHARACTER_EMOTE:
        inst.previous_emotion = program.character_table[inst.character_name]!!.current_emotion;
        program.character_table.get_ref(inst.character_name)!!.current_emotion = inst.set_emotion_to;

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

    case InstructionType.CHARACTER_VISIBILITY_SET: program.character_table.get_ref(inst.character_name)!!.visible         = inst.previous_visibility;
    case InstructionType.CHARACTER_POSITION:       program.character_table.get_ref(inst.character_name)!!.position        = inst.previous_position;
    case InstructionType.CHARACTER_EMOTE:          program.character_table.get_ref(inst.character_name)!!.current_emotion = inst.previous_emotion;
    case InstructionType.GOTO_LABEL:               break;
    }
    program.instruction_pointer = inst.previous_instruction_pointer;
}

fn void handle_window_resize() {
    float current_window_width  = (float)raylib::get_screen_width();
    float current_window_height = (float)raylib::get_screen_height();
    float scale_x = current_window_width  / GAME_WIDTH;
    float scale_y = current_window_height / GAME_HEIGHT;
    float scale   = (scale_x < scale_y) ? scale_x : scale_y;

    float destination_width  = GAME_WIDTH  * scale;
    float destination_height = GAME_HEIGHT * scale;

    game_rectangle = {
        (current_window_width  - destination_width)  / 2,
        (current_window_height - destination_height) / 2,
        destination_width,
        destination_height
    };
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

    handle_window_resize();

    game_texture = raylib::load_render_texture((CInt)GAME_WIDTH, (CInt)GAME_HEIGHT);
    defer raylib::unload_render_texture(game_texture);

    while(!raylib::window_should_close()) {
        if(raylib::is_key_pressed(KeyboardKey.SPACE.value)) {
            io::printn("steping forward");
            while(!step_program(&program));
        } else if(raylib::is_key_pressed(KeyboardKey.F1.value)) {
            io::printn("steping backwards");
            do {
                step_back(&program);
            } while(!program.last_instruction_blocking());
        }

        if(raylib::is_window_resized()) handle_window_resize();

        raylib::begin_drawing();
            raylib::clear_background({0x25, 0x25, 0x25, 255});

            raylib::begin_texture_mode(game_texture);
                raylib::clear_background({0x18, 0x18, 0x18, 255});

                program.character_table.@each(; char[] name, Character character) {
                    if(character.visible) {
                        Texture2D sprite_texture = character.emotion_sprite_table[character.current_emotion]!!.texture;
                        raylib::draw_texture_ex(sprite_texture, character.position, 0.0, GAME_HEIGHT / (float)sprite_texture.height, raylib::WHITE);
                    }
                };

                raylib::draw_rectangle_rec(TEXTBOX_RECTANGLE, {0x11,0x11,0x11,180});
                raylib::draw_rectangle_lines_ex(TEXTBOX_RECTANGLE, 5.0, raylib::WHITE);
                text.render();
            raylib::end_texture_mode();

            raylib::draw_texture_pro(
                game_texture.texture,
                { 0, 0, GAME_WIDTH, -GAME_HEIGHT },
                game_rectangle,
                { 0, 0 },
                0.0,
                raylib::WHITE
            );

        raylib::end_drawing();
    }

}
