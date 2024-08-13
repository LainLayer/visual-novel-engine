module render;

import std::io;
import std::math;
import raylib;

struct TextAnimation {
    float duration;
    float step;
    char[] text;
}

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
        raylib::draw_text_boxed(
            raylib::get_font_default(),
            (ZString)animation.text,
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

fn void main() {
    io::printn("test!");

    raylib::init_window(1920, 1080, "Visual Novel Renderer");
    raylib::set_target_fps(60);

    char[] short_text = "This is a short bit of text.";
    char[] long_text = "A ball stretcher is a sex toy that is used to elongate the scrotum and provide a feeling of weight pulling the testicles away from the body. This can be particularly enjoyable for the wearer as it can make an orgasm more intense, as testicles are prevented from moving up. Intended to make one's testicles permanently hang much lower than before (if used regularly for extended periods of time), this sex toy can be potentially harmful to the genitals as the circulation of blood can be easily cut off if over-tightened. While leather stretchers are most common, other models consist of an assortment of steel rings that fastens with screws, causing additional but only mildly uncomfortable weight to the wearer's testicles. The length of the stretcher may vary from 2.5 to 10 centimetres (1 to 4 in).[5] A more dangerous type of ball stretcher can be home-made simply by wrapping rope or string around one's scrotum until it is eventually stretched to the desired length.";

    bool is_short = true;

    TextAnimation text = {
        .duration = 0.35,
        .step     = 0.0,
        .text     = short_text
    };

    int a = raylib::measure_text("Hello Testing Text",   24);
    int b = raylib::measure_text("Hello \nTesting Text", 24);

    io::printf("a: %d, b: %d\n", a, b);

    while(!raylib::window_should_close()) {
        update_textbox_rectangle();

        if(raylib::is_key_pressed(KeyboardKey.SPACE.value)) {
            text.step = 0;
            text.text = is_short ? long_text : short_text;
            is_short = !is_short;
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
