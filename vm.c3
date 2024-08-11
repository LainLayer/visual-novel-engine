module vm;

import list;

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
    usz instruction_pointer;
    List(<Instruction>) instructions;
}
