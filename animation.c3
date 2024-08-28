module animation;

import common;
import imgui;

import std::io;
import std::math;
import std::collections::list;

enum AnimationType : char {
    SEQUENCE,
    GROUP,
    SLIDE,

    IDLE
}

def AnimationIndex = usz;

struct Animation {
    AnimationType animation_type;

    union {
        struct {

            List(<AnimationIndex>) animations;

            // union here maybe?
        }

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
    case GROUP:
        foreach(AnimationIndex index : animation.animations) animation_list[index].apply();

    case SLIDE:
        float      progress  = animation.step / animation.duration;
        Character* character = common::character_table.get_ref(animation.character_name)!!;

        character.position = animation.slide_from.lerp(animation.slide_to, progress);
    case IDLE: break;
    }
}

char[1024] debug_buffer;
fn void Animation.imgui_debug_visualize(animation, AnimationIndex list_index) {
    io::bprintf(&debug_buffer, "%s##%s\0", animation.animation_type, list_index);
    if(imgui::tree_node((ZString)&debug_buffer)) {
        switch(animation.animation_type) {
        case SEQUENCE:
        case GROUP:
            foreach(AnimationIndex index : animation.animations) animation_list[index].imgui_debug_visualize(index);
        case SLIDE:
            io::bprintf(
                &debug_buffer,
                "slide '%s' from %.2f,%.2f to %.2f,%.2f\0",
                animation.character_name,
                animation.slide_from.x,
                animation.slide_from.y,
                animation.slide_to.x,
                animation.slide_to.y
            );
            imgui::text((ZString)&debug_buffer);
            imgui::progress_bar(animation.step / animation.duration, {0.0, 0.0}, null);
        default: break;
        }
        imgui::tree_pop();
    }
}
