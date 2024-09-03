module vm;

import std::collections::map;
import std::collections::list;

import std::io;
import common;
import raylib;
import animation;

distinct InstructionIndex = usz;

enum InstructionType : char {
    SHOW_TEXT,
    GOTO_LABEL,
    END_SCENARIO,

    CHARACTER_VISIBILITY_SET,
    CHARACTER_POSITION,
    CHARACTER_EMOTE,
    CHARACTER_FACE,

    BACKGROUND,

    ANIMATE,
}

struct Instruction {
    InstructionType instruction_type;

    bool blocking;

    InstructionIndex previous_instruction_pointer;

    union {
        /* SHOW_TEXT */
        struct {
            char[] text_to_show;
            char[] previously_shown_text;
        }

        /* GOTO_LABEL */
        union {
            InstructionIndex label_to_go_to;
            usz              scene_index;
        }

        struct {
            CharacterIndex character_index;

            union {
                /* CHARACTER_VISIBILITY_SET */
                struct {
                    bool   set_visibility_to;
                    bool   previous_visibility;
                }

                /* CHARACTER_POSITION */
                struct {
                    Vector2 set_position_to;
                    Vector2 previous_position;
                }

                /* CHARACTER_EMOTE */
                struct {
                    char[] set_emotion_to;
                    char[] previous_emotion;
                }

                /* CHARACTER_FACE */
                struct {
                    Direction direction_to_face;
                    Direction previous_direction;
                }
            }
        }

        /* ANIMATE */
        struct {
            AnimationIndex animation_index;
            AnimationIndex previous_animation_index;
        }

        /* BACKGROUND */
        struct {
            SpriteDataIndex background_index;
            SpriteDataIndex previous_background_index;
        }

        /* END_SCENARIO */
        // nothing needed
    }
}


InstructionIndex    instruction_pointer;
List(<Instruction>) instructions;
List(<Instruction>) instruction_history;

fn bool last_instruction_blocking() {
    if(vm::instruction_history.size < 2) return true; // fix case where starting from non blocking instruction lets you rewind too far
    return vm::instruction_history[vm::instruction_history.size - 1].blocking;
}
