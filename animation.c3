module animation;

import common;

import std::io;
import std::math;
import std::collections::list;

const usz MAX_TASKS_PER_NODE = 32;

enum AnimationType : char {
    SEQUENCE,
    GROUP,
    SLIDE
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
    }
}
