module render;

import std::io;
import std::math;

import compiler;
import vm;
import raylib;

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
const float FONT_SIZE   = 32.0;

char[MAX_TEXT_SIZE] message_box_buffer;

const float TEXT_PADDING = 20.0;

fn Rectangle Rectangle.shrink(self, float n) @inline {
    return {
        .x = self.x + n,
        .y = self.y + n,
        .width  = self.width  - n*2,
        .height = self.height - n*2,
    };
}

fn void TextAnimation.render(&animation) {
    if(animation.step >= animation.duration) {
        io::bprintf(&message_box_buffer, "%s", animation.text);
        message_box_buffer[animation.text.len] = '\0';
        raylib::draw_text_boxed(
            raylib::get_font_default(),
            (ZString)&message_box_buffer,
            textbox_rectangle.shrink(TEXT_PADDING),
            FONT_SIZE,
            1,
            true,
            raylib::WHITE
        );
    } else {
        animation.step += raylib::get_frame_time();
        float percentage = animation.step / animation.duration;
        uint chars_to_draw = (uint)math::ceil((float)animation.text.len * percentage);

        if(chars_to_draw < 1)                      return;
        if(chars_to_draw > animation.text.len - 1) chars_to_draw = animation.text.len-1;
        if(chars_to_draw > MAX_TEXT_SIZE - 1)      chars_to_draw = MAX_TEXT_SIZE - 1;

        message_box_buffer[0..chars_to_draw-1] = animation.text[0..chars_to_draw-1];
        message_box_buffer[chars_to_draw] = '\0';

        raylib::draw_text_boxed(
            raylib::get_font_default(),
            (ZString)&message_box_buffer,
            textbox_rectangle.shrink(TEXT_PADDING),
            FONT_SIZE,
            1,
            true,
            raylib::WHITE
        );
    }
}

fn void update_textbox_rectangle() @inline {
    textbox_rectangle = {
        .x = 10,
        .y = ((float)(raylib::get_screen_height()) * 0.66),
        .width  = (float)(raylib::get_screen_width()  - 20),
        .height = ((float)raylib::get_screen_height() / 3.0)
    };
}

fn void step_program(Program* program) {
    program.instruction_pointer += 1;
}

fn bool render_current_program_state(Program* program) {
    Instruction inst = program.instructions[(usz)program.instruction_pointer];
    switch(inst.instruction_type) {
    case InstructionType.SHOW_TEXT:
        inst.previously_shown_text = text.text;
        text.text = inst.text_to_show;
        text.step = 0;
    case InstructionType.GOTO_LABEL:
        inst.previous_instruction_pointer = program.instruction_pointer;
        program.instruction_pointer = inst.label_to_go_to;
    case InstructionType.END_SCENARIO:
        inst.previously_shown_text = text.text;
        text.text = "END.";
        text.step = 0;
    }
    inst.has_undo_data = true;
    program.history.push(inst);
    return inst.blocking;
}

fn void main() {
    io::printn("test!");

    Program program = compiler::compile_file("test.balls")!!;
    render_current_program_state(&program);

    raylib::init_window(1920, 1080, "Visual Novel Renderer");
    raylib::set_target_fps(60);

    while(!raylib::window_should_close()) {
        update_textbox_rectangle();

        if(raylib::is_key_pressed(KeyboardKey.SPACE.value)) {
            step_program(&program);
            while(!render_current_program_state(&program));
        }

        raylib::begin_drawing();
            raylib::clear_background({0x18, 0x18, 0x18, 255});
            raylib::draw_text("Sample Text!", 50, 50, 24, raylib::WHITE);

            raylib::draw_rectangle_lines_ex(textbox_rectangle, 5.0, raylib::WHITE);
            text.render();

        raylib::end_drawing();
    }

    raylib::close_window();
}
