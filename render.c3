module render;

import std::io;
import std::math;
import std::thread;

import compiler;
import vm;
import common;
import animation;

import raylib;
import imgui;

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

fn void TextAnimation.render(&animation) {
    if(animation.step >= animation.duration) {
        io::bprintf(&common::message_box_buffer, "%s\0", animation.text);
    } else {
        animation.step     += raylib::get_frame_time();
        float percentage    = animation.step / animation.duration;
        uint  chars_to_draw = (uint)math::ceil((float)animation.text.len * percentage);

        if(chars_to_draw < 1)                         return;
        if(chars_to_draw > animation.text.len    - 1) chars_to_draw = animation.text.len    - 1;
        if(chars_to_draw > common::MAX_TEXT_SIZE - 1) chars_to_draw = common::MAX_TEXT_SIZE - 1;

        common::message_box_buffer[0..chars_to_draw-1] = animation.text[0..chars_to_draw-1];
        common::message_box_buffer[chars_to_draw]      = '\0';
    }
    raylib::draw_text_boxed(
        raylib::get_font_default(),
        (ZString)&common::message_box_buffer,
        TEXTBOX_RECTANGLE.shrink(common::TEXT_PADDING),
        common::FONT_SIZE,
        common::LINE_SPACING,
        true,
        common::WHITE
    );
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

usz total_sprites_to_load = 0;
usz loaded_sprites        = 0;

fn void load_single_sprite_data(void* arg) {
    SpriteData* sprite_data = (SpriteData*) arg;

    @pool() {
        sprite_data.image = raylib::load_image(string::tformat_zstr("%s", sprite_data.filename));
    };

    if(sprite_data.needs_flip) raylib::image_flip_horizontal(&sprite_data.image);

    loaded_sprites++;
}

fn void assets_to_textures() {
    foreach(&sprite_data : common::sprite_data_list) {
        sprite_data.texture = raylib::load_texture_from_image(sprite_data.image);
        raylib::unload_image(sprite_data.image);
    }
}

fn void main() {

    animation::init_animation_system();

    compiler::compile_file("test.chickenmilk");

    while(!vm::step());

    io::printf("\ninstruction size: %d\n", Instruction.sizeof);
    io::printf("instruction index size: %d\n", InstructionIndex.sizeof);

    raylib::init_window(1920, 1080, "Visual Novel Renderer");
    defer raylib::close_window();

    raylib::set_target_fps(160);

    imgui::raylib_setup(true);
    defer imgui::raylib_shutdown();

    handle_window_resize();

    game_texture = raylib::load_render_texture((CInt)GAME_WIDTH, (CInt)GAME_HEIGHT);
    defer raylib::unload_render_texture(game_texture);

    {
        ThreadPool(<32>) sprite_loading_thread_pool;

        total_sprites_to_load = common::sprite_data_list.len();

        sprite_loading_thread_pool.init()!!;
        defer sprite_loading_thread_pool.destroy()!!;

        foreach(&sprite_data : common::sprite_data_list) {
            sprite_loading_thread_pool.push((ThreadFn) &load_single_sprite_data, sprite_data)!!;
        }

        while(!raylib::window_should_close() && !(loaded_sprites == total_sprites_to_load)) {
            raylib::begin_drawing();
                raylib::clear_background({0x25, 0x25, 0x25, 255});
                @pool() {
                    ZString loading_text = string::tformat_zstr("loading %d/%d sprites...",loaded_sprites, total_sprites_to_load);
                    CInt    text_width   = raylib::measure_text(loading_text, 24);
                    raylib::draw_text(
                        loading_text,
                        raylib::get_screen_width()/2 - text_width/2,
                        raylib::get_screen_height()/2 - 12,
                        24,
                        common::WHITE
                    );
                };
            raylib::end_drawing();
        }

        assets_to_textures(); // OpenGL is shit! It crashes if you try loading textures in a separate thread.
    }


    while(!raylib::window_should_close()) {
        if(raylib::is_key_pressed(KeyboardKey.SPACE.value)) {
            io::printn("steping forward");
            (&animation::animation_list[common::current_animation]).skip();
            while(!vm::step());
        } else if(raylib::is_key_pressed(KeyboardKey.F1.value)) {
            io::printn("steping backwards");
            do {
                vm::step_back();
            } while(!vm::last_instruction_blocking());
        }

        if(raylib::is_window_resized()) handle_window_resize();

        raylib::begin_drawing();
            raylib::clear_background({0x25, 0x25, 0x25, 255});

            raylib::begin_texture_mode(game_texture);
                raylib::clear_background({0x18, 0x18, 0x18, 255});

                if(common::current_background != common::INVALID_BACKGROUND) {
                    Texture2D background_texture = common::sprite_data_list[common::current_background].texture;
                    raylib::draw_texture_pro(
                        background_texture,
                        { 0, 0, background_texture.width, background_texture.height },
                        { 0, 0, GAME_WIDTH, GAME_HEIGHT },
                        { 0, 0 },
                        0.0,
                        common::WHITE
                    );
                }

                foreach(&character : common::characters) {
                    if(character.visible) {
                        Texture2D sprite_texture = common::sprite_data_list[character.emotion_sprite_table[character.current_emotion]!!].texture;
                        float scale = GAME_HEIGHT / (float)sprite_texture.height;

                        (&animation::animation_list[common::current_animation]).tick(raylib::get_frame_time());
                        animation::animation_list[common::current_animation].apply();
                        raylib::draw_texture_pro(
                            sprite_texture,
                            {
                                0,
                                0,
                                (float)(character.direction == common::DEFAULT_DIRECTION ? sprite_texture.width : -sprite_texture.width),
                                sprite_texture.height
                            },
                            {
                                character.position.x,
                                character.position.y,
                                sprite_texture.width  * scale,
                                sprite_texture.height * scale
                            },
                            { 0, 0 },
                            0.0,
                            common::WHITE
                        );
                    }
                }

                raylib::draw_rectangle_rec(TEXTBOX_RECTANGLE, {0x11,0x11,0x11,180});
                raylib::draw_rectangle_lines_ex(TEXTBOX_RECTANGLE, 5.0, common::WHITE);
                common::text.render();
            raylib::end_texture_mode();

            raylib::draw_texture_pro(
                game_texture.texture,
                { 0, 0, GAME_WIDTH, -GAME_HEIGHT },
                game_rectangle,
                { 0, 0 },
                0.0,
                common::WHITE
            );

            imgui::raylib_begin();
            imgui::begin("debug system");
                imgui::begin_tab_bar("debug tab bar");

                if(imgui::begin_tab_item("Animation")) {
                    @pool() {
                        imgui::text(string::tformat_zstr(
                            "Current animation index: %d, type: %s\0",
                            common::current_animation,
                            animation::animation_list[common::current_animation].animation_type
                        ));
                    };

                    if(imgui::button("Reset animation")) {
                        (&animation::animation_list[common::current_animation]).reset();
                    }

                    animation::animation_list[common::current_animation].imgui_debug_visualize(common::current_animation);

                    imgui::end_tab_item();
                }

                if(imgui::begin_tab_item("Characters")) {

                    if(imgui::begin_table("Character table", 6, (1 << 6) | (1 << 7) | (1 << 8) | (1 << 9) | (1 << 10), { 0, 0 }, 0)) {
                        foreach(&character : common::characters) {
                            @pool() {
                                imgui::table_next_row(0, 0);

                                imgui::table_set_column_index(0);
                                imgui::text(string::tformat_zstr("%s", character.name));

                                imgui::table_set_column_index(1);
                                imgui::text(string::tformat_zstr("%d", (int)character.position.x));

                                imgui::table_set_column_index(2);
                                imgui::text(string::tformat_zstr("%d", (int)character.position.y));

                                imgui::table_set_column_index(3);
                                imgui::text(string::tformat_zstr("%s", character.current_emotion));

                                imgui::table_set_column_index(4);
                                imgui::text(string::tformat_zstr("%s", character.visible));

                                imgui::table_set_column_index(5);
                                imgui::text(string::tformat_zstr("%s", character.direction.value));
                                if(imgui::button(string::tformat_zstr("flip##%s", character.name))) {
                                    switch(character.direction) {
                                    case LEFT:  character.direction = RIGHT;
                                    case RIGHT: character.direction = LEFT;
                                    }
                                }
                            };
                        }

                        imgui::end_table();
                    }
                    imgui::end_tab_item();
                }

                imgui::end_tab_bar();
            imgui::end();
            imgui::raylib_end();
        raylib::end_drawing();
    }

}
