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

            union {
                /* SLIDE */
                struct {
                    char[]  character_name;
                    Vector2 slide_to;
                    Vector2 slide_from;
                }
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
            (&animation_list[index]).reset();
        }
    case IDLE: break;
    case LOOP:
        (&animation_list[animation.animation_to_loop]).reset();
    default:
        animation.step = 0.0;
    }
}

fn void Animation.skip(&animation) {
    switch(animation.animation_type) {
    case SEQUENCE:
    case GROUP:
        foreach(AnimationIndex index : animation.animations) {
            (&animation_list[index]).skip();
        }
    case IDLE: break;
    case LOOP: break;
    default:
        animation.step = animation.duration;
    }
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
    default:
        return animation.step >= animation.duration;
    }
}

fn void Animation.tick(&animation, float delta_time) {
    switch(animation.animation_type) {
    case SEQUENCE:
        foreach(AnimationIndex index : animation.animations) {
            if(!animation_list[index].is_finished()) {
                (&animation_list[index]).tick(delta_time);
                break;
            }
        }
    case GROUP:
        foreach(AnimationIndex index : animation.animations) {
            if(!animation_list[index].is_finished()) {
                (&animation_list[index]).tick(delta_time);
            }
        }
    case IDLE: break;
    case LOOP:
        if(animation_list[animation.animation_to_loop].is_finished()) {
            (&animation_list[animation.animation_to_loop]).reset();
        } else {
            (&animation_list[animation.animation_to_loop]).tick(delta_time);
        }
    default:
        if(!animation.is_finished()) {
            animation.step += delta_time;
            if(animation.step > animation.duration) animation.step = animation.duration;
        }
    }
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
        float      progress  = animation.step / animation.duration;
        Character* character = common::character_table.get_ref(animation.character_name)!!;

        character.position = animation.slide_from.lerp(animation.slide_to, progress);
    case LOOP:
        animation_list[animation.animation_to_loop].apply();
    case IDLE: break;
    }
}

fn void Animation.imgui_debug_visualize(animation, AnimationIndex list_index) {
    @pool() {
        if(imgui::tree_node(string::tformat_zstr("%s##%s", animation.animation_type, list_index))) {
            switch(animation.animation_type) {
            case SEQUENCE:
            case GROUP:
                foreach(AnimationIndex index : animation.animations) animation_list[index].imgui_debug_visualize(index);
            case LOOP:
                animation_list[animation.animation_to_loop].imgui_debug_visualize(list_index);
            case SLIDE:
                imgui::text(string::tformat_zstr(
                    "slide '%s' from %.2f,%.2f to %.2f,%.2f",
                    animation.character_name,
                    animation.slide_from.x,
                    animation.slide_from.y,
                    animation.slide_to.x,
                    animation.slide_to.y
                ));
                imgui::progress_bar(animation.step / animation.duration, {0.0, 0.0}, null);
            case IDLE: break;
            }
            imgui::tree_pop();
        }
    };
}
