module animation;

import common;
import imgui;

import std::io;
import std::math;
import std::collections::list;

enum AnimationType : char {
    SEQUENCE,
    GROUP,
    LOOP,

    SLIDE,
    PAUSE,
    TURN,

    IDLE
}

def AnimationIndex = usz;

struct Animation {
    AnimationType animation_type;

    union {

        List(<AnimationIndex>) animations;

        AnimationIndex animation_to_loop;

        struct {
            float step;
            float duration;

            CharacterIndex character_index;

            union {
                /* SLIDE */
                struct {
                    Vector2 slide_to;
                    Vector2 slide_from;
                }

                /* TURN */
                Direction turn_to;
            }
        }
    }
}

List(<Animation>) animation_list;

fn void init_animation_system() {
    animation_list.push({ .animation_type = IDLE });
}

fault AnimationFault {
    ANIMATION_NOT_GROUP_OR_SEQUENCE
}

fn void! Animation.push(&animation, Animation new_animation) {
    switch(animation.animation_type) {
    case SEQUENCE:
    case GROUP:
        animation_list.push(new_animation);
        animation.animations.push(animation_list.size - 1);
    case LOOP:
        animation_list.push(new_animation);
        animation.animation_to_loop = animation_list.size - 1;
    default:
        return AnimationFault.ANIMATION_NOT_GROUP_OR_SEQUENCE?;
    }
}

fn void Animation.reset(&animation) {
    switch(animation.animation_type) {
    case SEQUENCE:
    case GROUP:
        foreach(AnimationIndex index : animation.animations) {
            animation_list[index].reset();
        }
    case IDLE: break;
    case LOOP:
        animation_list[animation.animation_to_loop].reset();
    case SLIDE:
    case PAUSE:
    case TURN:
        animation.step = 0.0;
    }
    animation.apply();
}

fn void Animation.skip(&animation) {
    switch(animation.animation_type) {
    case SEQUENCE:
    case GROUP:
        foreach(AnimationIndex index : animation.animations) {
            animation_list[index].skip();
        }
    case IDLE: break;
    case LOOP: break;
    case SLIDE:
    case PAUSE:
        animation.step = animation.duration;
    case TURN:
        animation.step = 1.0;
    }
    animation.apply();
}

fn bool Animation.is_finished(animation) {
    switch(animation.animation_type) {
    case SEQUENCE:
    case GROUP:
        foreach(AnimationIndex index : animation.animations) {
            if(!animation_list[index].is_finished()) {
                return false;
            }
        }
        return true;
    case IDLE:
        return true;
    case LOOP:
        return false;
    case SLIDE:
    case PAUSE:
        return animation.step >= animation.duration;
    case TURN:
        return animation.step != 0.0;
    }
}

fn void Animation.tick(&animation, float delta_time) {
    switch(animation.animation_type) {
    case SEQUENCE:
        foreach(AnimationIndex index : animation.animations) {
            if(!animation_list[index].is_finished()) {
                animation_list[index].tick(delta_time);
                break;
            }
        }
    case GROUP:
        foreach(AnimationIndex index : animation.animations) {
            if(!animation_list[index].is_finished()) {
                animation_list[index].tick(delta_time);
            }
        }
    case IDLE: break;
    case LOOP:
        if(animation_list[animation.animation_to_loop].is_finished()) {
            animation_list[animation.animation_to_loop].reset();
        } else {
            animation_list[animation.animation_to_loop].tick(delta_time);
        }
    case SLIDE:
    case PAUSE:
        if(!animation.is_finished()) {
            animation.step += delta_time;
            if(animation.step > animation.duration) animation.step = animation.duration;
        }
    case TURN:
        animation.step = 1.0;
    }
    animation.apply();
}

fn void Animation.apply(animation) {
    switch(animation.animation_type) {
    case SEQUENCE:
        for (int i = (int)animation.animations.len()-1; i >= 0; i--) {
            if(!animation_list[animation.animations[i]].is_finished()) {
                animation_list[animation.animations[i]].apply();
            }
        }
    case GROUP:
        foreach(AnimationIndex index : animation.animations) animation_list[index].apply();

    case SLIDE:
        float progress  = animation.step / animation.duration;
        common::characters[animation.character_index].position = animation.slide_from.lerp(animation.slide_to, progress);

    case LOOP:
        animation_list[animation.animation_to_loop].apply();
    case TURN:
        Character* character = &common::characters[animation.character_index];
        if(animation.step == 0.0) {
            character.direction = animation.turn_to.flip();
        } else {
            character.direction = animation.turn_to;
        }
    case IDLE:  break;
    case PAUSE: break;
    }
}

fn void animation_list_debug_tab() {
    if(imgui::begin_tab_item("Animation List")) {
        if(imgui::begin_table("Animation List table", 4, imgui::TABLE_BORDERS | imgui::TABLE_ROWBG | imgui::TABLE_SIZINGFIXEDFIT, { 0, 0 }, 0)) {

            imgui::table_setup_column("Index");
            imgui::table_setup_column("Animation Type");
            imgui::table_setup_column("Details");
            imgui::table_setup_column("Step");

            imgui::table_headers_row();

            AnimationIndex index = 0;
            foreach(&animation : animation_list) {
                imgui::table_next_row(0, 0);

                if(index == common::current_animation) {
                    for(CInt i = 0; i < 4; i++) imgui::table_set_background_color(3, Color { 25, 75, 25, 255}, i);
                }

                @pool() {

                    imgui::table_set_column_index(0);
                    imgui::text(string::tformat_zstr("%d", index));

                    imgui::table_set_column_index(1);
                    imgui::text(string::tformat_zstr("%s", animation.animation_type));

                    imgui::table_set_column_index(2);
                    switch(animation.animation_type) {
                    case SEQUENCE:
                    case GROUP:
                        imgui::text(string::tformat_zstr("animations: %s", animation.animations));

                    case LOOP:
                        imgui::text(string::tformat_zstr("animation: %s", animation.animation_to_loop));

                    case SLIDE:
                        imgui::text(string::tformat_zstr(
                            "character: %s, slide from %d,%d to %d,%d, over %.2f seconds",
                            common::characters[animation.character_index].name,
                            animation.slide_from.x,
                            animation.slide_from.y,
                            animation.slide_to.x,
                            animation.slide_to.y,
                            animation.duration

                        ));

                        imgui::table_set_column_index(3);

                        imgui::text(string::tformat_zstr("%.2f", animation.step));

                    case PAUSE:
                        imgui::text(string::tformat_zstr("duration: %d", animation.duration));

                        imgui::table_set_column_index(3);
                        imgui::text(string::tformat_zstr("%.2f", animation.step));

                    case TURN:
                        imgui::text(string::tformat_zstr(
                            "character: %s, turn %s",
                            common::characters[animation.character_index].name,
                            animation.turn_to.value
                        ));

                        imgui::table_set_column_index(3);
                        imgui::text(string::tformat_zstr("%.2f", animation.step));

                    case IDLE:
                    }
                };

                index++;
            }
            imgui::end_table();
        }
        imgui::end_tab_item();
    }
}

fn void Animation.imgui_debug_visualize(&animation, AnimationIndex list_index) {
    @pool() {
        if(imgui::tree_node(string::tformat_zstr("%s##%s", animation.animation_type, list_index))) {

            if(animation.animation_type != IDLE) {
                if(imgui::button(string::tformat_zstr("reset##%s", list_index))) animation.reset();
                imgui::same_line();
                if(imgui::button(string::tformat_zstr("skip##%s", list_index)))  animation.skip();
            }


            switch(animation.animation_type) {
            case SEQUENCE:
            case GROUP:
                foreach(AnimationIndex index : animation.animations) animation_list[index].imgui_debug_visualize(index);
            case LOOP:
                animation_list[animation.animation_to_loop].imgui_debug_visualize(list_index);
            case SLIDE:
                imgui::same_line();
                imgui::text(string::tformat_zstr(
                    "slide '%s' from %.2f,%.2f to %.2f,%.2f",
                    common::characters[animation.character_index].name,
                    animation.slide_from.x,
                    animation.slide_from.y,
                    animation.slide_to.x,
                    animation.slide_to.y
                ));
                imgui::progress_bar(animation.step / animation.duration, {0.0, 0.0}, null);
            case PAUSE:
                imgui::progress_bar(animation.step / animation.duration, {0.0, 0.0}, null);
            case TURN:
                imgui::same_line();
                imgui::text(string::tformat_zstr(
                    "turn '%s' %s",
                    common::characters[animation.character_index].name,
                    animation.turn_to.value
                ));
                imgui::progress_bar(animation.step, { 0.0, 0.0 }, null);
            case IDLE: break;
            }

            imgui::tree_pop();
        }
    };
}
