module vm;

import std::io;
import list;

distinct InstructionIndex = usz;

enum InstructionType : char {
    SHOW_TEXT,
    GOTO_LABEL,
    END_SCENARIO,
}

struct Instruction {
    InstructionType instruction_type;

    bitstruct : char {
        bool has_undo_data;
        bool blocking;
    }

    union {
        /* SHOW_TEXT */
        struct {
            char[] text_to_show;

            char[] previously_shown_text;
        }

        /* GOTO_LABEL */
        struct {
            usz label_to_go_to;

            usz previous_instruction_pointer;
        }

        /* END_SCENARIO */
        // nothing needed, for undo just ip -= 1
    }
}

struct Program {
    InstructionIndex instruction_pointer;
    List(<Instruction>) instructions;
}

fn void Program.print(program) {
    foreach(Instruction instruction : program.instructions) {
        io::printf("%s :: ", instruction.instruction_type);
        switch(instruction.instruction_type) {
        case InstructionType.SHOW_TEXT:
            io::printf("%s\n", instruction.text_to_show);
        case InstructionType.GOTO_LABEL:
            io::printf("%d\n", (usz)instruction.label_to_go_to);
        case InstructionType.END_SCENARIO:
            break;
        }
    }
}
