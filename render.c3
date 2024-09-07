module render;

import std::io;
import std::math;
import std::thread;

import compiler;
import vm;
import common;
import animation;
import log;

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

usz total_assets_to_load = 0;
usz loaded_assets        = 0;

fn void load_single_sprite_data(void* arg) {
    SpriteData* sprite_data = (SpriteData*) arg;

    @pool() {
        sprite_data.image = raylib::load_image(string::tformat_zstr("%s", sprite_data.filename));
    };

    if(sprite_data.needs_flip) raylib::image_flip_horizontal(&sprite_data.image);

    // log::info("Successfully loaded image %s", sprite_data.filename);
    loaded_assets++;
}

fn void load_single_music_data(void* arg) {
    MusicData* music_data = (MusicData*) arg;

    @pool() {
        music_data.music = raylib::load_music_stream(string::tformat_zstr("%s", music_data.filename));
    };

    loaded_assets++;
}

fn void assets_to_textures() {
    foreach(&sprite_data : common::sprite_data_list) {
        sprite_data.texture = raylib::load_texture_from_image(sprite_data.image);
        raylib::unload_image(sprite_data.image);
    }
}

fn void main() {

    animation::init_animation_system();
    log::init();

    compiler::compile_file("test.chickenmilk");

    io::printf("\ninstruction size: %d\n", Instruction.sizeof);
    io::printf("instruction index size: %d\n", InstructionIndex.sizeof);

    log::set_raylib_tracelog_callback();

    raylib::set_config_flags(
        raylib::FLAG_WINDOW_HIGHDPI |
        raylib::FLAG_MSAA_4X_HINT   |
        raylib::FLAG_VSYNC_HINT
    );

    raylib::init_window(1920, 1080, "Visual Novel Renderer");
    defer raylib::close_window();

    raylib::init_audio_device();

    imgui::raylib_setup(true);
    defer imgui::raylib_shutdown();

    handle_window_resize();

    game_texture = raylib::load_render_texture((CInt)GAME_WIDTH, (CInt)GAME_HEIGHT);
    defer raylib::unload_render_texture(game_texture);

    {
        ThreadPool(<16384>) thread_pool;

        total_assets_to_load = common::sprite_data_list.len() + common::music_data_list.len();

        thread_pool.init()!!;
        defer thread_pool.destroy()!!;

        foreach(&sprite_data : common::sprite_data_list) {
            thread_pool.push((ThreadFn) &load_single_sprite_data, sprite_data)!!;
        }

        foreach(&music_data : common::music_data_list) {
            thread_pool.push((ThreadFn) &load_single_music_data, music_data)!!;
        }

        while(!raylib::window_should_close() && !(loaded_assets == total_assets_to_load)) {
            raylib::begin_drawing();
                raylib::clear_background({0x25, 0x25, 0x25, 255});
                @pool() {
                    ZString loading_text = string::tformat_zstr("loading %d/%d assets...",loaded_assets, total_assets_to_load);
                    CInt    text_width   = raylib::measure_text(loading_text, 24);
                    raylib::draw_text(
                        loading_text,
                        raylib::get_screen_width()  / 2 - text_width/2,
                        raylib::get_screen_height() / 2 - 12,
                        24,
                        common::WHITE
                    );
                };
            raylib::end_drawing();
        }

        assets_to_textures(); // OpenGL is shit! It crashes if you try loading textures in a separate thread.
    }

    vm::step();

    while(!raylib::window_should_close()) {
        if(raylib::is_key_pressed(KeyboardKey.SPACE.value)) {
            (&animation::animation_list[common::current_animation]).skip();
            vm::step();
        } else if(raylib::is_key_pressed(KeyboardKey.F1.value)) {
            vm::step_back();
        }

        if(common::current_music != common::NO_MUSIC) {
            raylib::update_music_stream(common::music_data_list[common::current_music].music);
        }

        if(raylib::is_window_resized()) handle_window_resize();

        if(common::animaton_enabled) {
            (&animation::animation_list[common::current_animation]).tick(raylib::get_frame_time());
        }

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
                @pool() {
                    imgui::text(string::tformat_zstr("FPS: %s", raylib::get_fps()));
                };

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

                    imgui::same_line();

                    @pool() {
                        if(imgui::button(string::tformat_zstr("%s", common::animaton_enabled ? "Disable animation" : "Enable animation"))) {
                            common::animaton_enabled = !common::animaton_enabled;
                        }
                    };

                    imgui::same_line();

                    if(imgui::button("Tick animation")) {
                        (&animation::animation_list[common::current_animation]).tick(raylib::get_frame_time());
                    }

                    (&animation::animation_list[common::current_animation]).imgui_debug_visualize(common::current_animation);

                    imgui::end_tab_item();
                }

                if(imgui::begin_tab_item("Characters")) {

                    if(imgui::begin_table("Character table", 7, imgui::TABLE_BORDERS | imgui::TABLE_ROWBG | imgui::TABLE_SIZINGFIXEDFIT, { 0, 0 }, 0)) {

                        imgui::table_setup_column("Name");
                        imgui::table_setup_column("X");
                        imgui::table_setup_column("Y");
                        imgui::table_setup_column("Emotion");
                        imgui::table_setup_column("Visible");
                        imgui::table_setup_column("Direction");
                        imgui::table_setup_column("Controls");

                        imgui::table_headers_row();

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

                                imgui::table_set_column_index(6);
                                if(imgui::button(string::tformat_zstr("flip##%s", character.name))) {
                                    character.direction = character.direction.flip();
                                }
                            };
                        }

                        imgui::end_table();
                    }
                    imgui::end_tab_item();
                }

                if(imgui::begin_tab_item("Music")) {

                    if(common::current_music == common::NO_MUSIC) {
                        imgui::text("No Music");
                    } else {
                        @pool() {
                            imgui::text(string::tformat_zstr(
                                "Music index: %s - %s",
                                common::current_music,
                                common::music_data_list[common::current_music].name
                            ));
                        };
                    }


                    imgui::end_tab_item();
                }


                vm::debug_tab();

                log::debug_tab();

                imgui::end_tab_bar();
            imgui::end();
            imgui::raylib_end();
        raylib::end_drawing();
    }

}
