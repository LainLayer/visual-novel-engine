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

struct Program {
    InstructionIndex    instruction_pointer;
    List(<Instruction>) instructions;
    List(<Instruction>) history;
}

fn void Program.print(program) {
    foreach(Instruction instruction : program.instructions) {
        io::printf("%s :: ", instruction.instruction_type);
        switch(instruction.instruction_type) {
        case InstructionType.SHOW_TEXT:
            io::printf("%s\n", instruction.text_to_show);
        case InstructionType.GOTO_LABEL:
            io::printf("%d\n", (usz)instruction.label_to_go_to);
        case InstructionType.CHARACTER_VISIBILITY_SET:
            io::printf("visibility: %s\n", instruction.set_visibility_to);
        case InstructionType.CHARACTER_POSITION:
            io::printf("position: %s\n", instruction.set_position_to);
        case InstructionType.CHARACTER_EMOTE:
            io::printf("emotion: %s\n", instruction.set_emotion_to);
        case InstructionType.CHARACTER_FACE:
            io::printf("direction_to_face: %s\n", instruction.direction_to_face.value);
        case InstructionType.ANIMATE:
            io::printf("animation index: %s\n", instruction.animation_index);
        case InstructionType.BACKGROUND:
            io::printf("background index: %s\n", instruction.background_index);
        case InstructionType.END_SCENARIO:
            break;
        }
    }
}
