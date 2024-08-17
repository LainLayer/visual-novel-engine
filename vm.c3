module vm;

import std::io;
import list;
import common;
import raylib;

distinct InstructionIndex = usz;

enum InstructionType : char {
    SHOW_TEXT,
    GOTO_LABEL,
    END_SCENARIO,
    SPAWN_SPRITE,
}

struct Instruction {
    InstructionType instruction_type;

    bitstruct : char {
        bool has_undo_data;
        bool blocking;
    }

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

        /* SPAWN_SPRITE */
        struct {
            SpriteIndex sprite_index;
            int         sprite_x;
            int         sprite_y;
        }

        /* END_SCENARIO */
        // nothing needed
    }
}

struct Program {
    InstructionIndex    instruction_pointer;
    List(<Instruction>) instructions;
    List(<Instruction>) history;

    List(<SpriteAsset>) sprites;
}

fn void Program.print(program) {
    foreach(Instruction instruction : program.instructions) {
        io::printf("%s :: ", instruction.instruction_type);
        switch(instruction.instruction_type) {
        case InstructionType.SHOW_TEXT:
            io::printf("%s\n", instruction.text_to_show);
        case InstructionType.GOTO_LABEL:
            io::printf("%d\n", (usz)instruction.label_to_go_to);
        case InstructionType.SPAWN_SPRITE:
            io::printf(
                "sprite index %d, x: %d, y: %d\n",
                instruction.sprite_index,
                instruction.sprite_x,
                instruction.sprite_y
            );
        case InstructionType.END_SCENARIO:
            break;
        }
    }
}

fn void Program.load_assets(&program) {
    for(usz i = 0; i < program.sprites.size; i++) {
        char[2048] buffer;
        io::bprintf(&buffer, "%s\0", program.sprites[i].filename);
        SpriteAsset* asset = &program.sprites[i];
        asset.texture = raylib::load_texture((ZString)&buffer);
    }
}
