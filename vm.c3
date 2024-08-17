module vm;

import std::collections::map;
import std::io;
import list;
import common;
import raylib;

distinct InstructionIndex = usz;

enum InstructionType : char {
    SHOW_TEXT,
    GOTO_LABEL,
    END_SCENARIO,

    CHARACTER_VISIBILITY_SET,
    CHARACTER_POSITION,
    CHARACTER_EMOTE,
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
            char[] character_name;

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
            }
        }

        /* END_SCENARIO */
        // nothing needed
    }
}

struct Program {
    InstructionIndex    instruction_pointer;
    List(<Instruction>) instructions;
    List(<Instruction>) history;

    HashMap(<char[], Character>) character_table;
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
        case InstructionType.END_SCENARIO:
            break;
        }
    }
}

fn void Program.load_assets(&program) {
    program.character_table.@each(; char[] name, Character character) {
        character.emotion_sprite_table.@each(; char[] emotion, SpriteData sprite_data) {
            char[2048] buffer;
            io::bprintf(&buffer, "%s\0", sprite_data.filename);

            Character temp_character = program.character_table[name]!!;
            SpriteData temp_sprite_data = temp_character.emotion_sprite_table[emotion]!!;
            temp_sprite_data.texture = raylib::load_texture((ZString)&buffer);
            temp_character.emotion_sprite_table[emotion] = temp_sprite_data;
            program.character_table[name] = temp_character;

        };
    };
}
