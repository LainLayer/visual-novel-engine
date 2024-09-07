module vm;

import std::collections::map;
import std::collections::list;

import std::io;
import common;
import raylib;
import animation;
import imgui;
import log;

def InstructionIndex = usz;

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

    PLAY_MUSIC,
    STOP_MUSIC,
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

        /* PLAY_MUSIC, STOP_MUSIC */
        struct {
            MusicDataIndex music_index;
            MusicDataIndex previous_music_index;
        }

        /* END_SCENARIO */
        // nothing needed
    }
}


InstructionIndex    instruction_pointer;
List(<Instruction>) instructions;
List(<Instruction>) instruction_history;

fn bool apply_instruction(Instruction inst) {

    InstructionIndex old_instruction_pointer = instruction_pointer;
    bool no_push = false;
    switch(inst.instruction_type) {
    case InstructionType.SHOW_TEXT:
        inst.previously_shown_text = common::text.text;
        common::text.text = inst.text_to_show;
        common::text.step = 0;
        instruction_pointer += 1;
    case InstructionType.GOTO_LABEL:
        instruction_pointer = inst.label_to_go_to;
    case InstructionType.CHARACTER_VISIBILITY_SET:
        inst.previous_visibility = common::characters[inst.character_index].visible;
        (&common::characters[inst.character_index]).visible = inst.set_visibility_to;

        instruction_pointer += 1;
    case InstructionType.CHARACTER_POSITION:
        inst.previous_position = common::characters[inst.character_index].position;
        (&common::characters[inst.character_index]).position = inst.set_position_to;

        instruction_pointer += 1;
    case InstructionType.CHARACTER_EMOTE:
        inst.previous_emotion = common::characters[inst.character_index].current_emotion;
        (&common::characters[inst.character_index]).current_emotion = inst.set_emotion_to;

        instruction_pointer += 1;
    case InstructionType.ANIMATE:
        inst.previous_animation_index = common::current_animation;
        common::current_animation     = inst.animation_index;

        (&animation::animation_list[inst.animation_index]).reset();

        instruction_pointer += 1;
    case InstructionType.BACKGROUND:
        inst.previous_background_index = common::current_background;
        common::current_background     = inst.background_index;

        instruction_pointer += 1;
    case InstructionType.CHARACTER_FACE:
        inst.previous_direction = common::characters[inst.character_index].direction;
        (&common::characters[inst.character_index]).direction = inst.direction_to_face;

        instruction_pointer += 1;
    case InstructionType.PLAY_MUSIC:
        log::debug("Playing music track %s", inst.music_index);
        inst.previous_music_index = common::current_music;
        if(common::current_music != common::NO_MUSIC) {
            log::debug("Stopping previous music track - %s", common::current_music);
            raylib::stop_music_stream(common::music_data_list[common::current_music].music);
        } else {
            log::debug("No previous music track to stop");
        }

        common::current_music = inst.music_index;
        raylib::play_music_stream(common::music_data_list[common::current_music].music);

        instruction_pointer += 1;
    case InstructionType.STOP_MUSIC:
        inst.previous_music_index = common::current_music;
        if(common::current_music != common::NO_MUSIC) {
            raylib::stop_music_stream(common::music_data_list[common::current_music].music);
        }

        common::current_music = common::NO_MUSIC;

        instruction_pointer += 1;
    case InstructionType.END_SCENARIO:
        inst.previously_shown_text = common::text.text;
        common::text.text = "END.";
        common::text.step = 0;
        no_push = (instruction_history[^1].instruction_type == InstructionType.END_SCENARIO);
    }
    inst.previous_instruction_pointer = old_instruction_pointer;
    if(!no_push) instruction_history.push(inst);

    return inst.blocking;
}

bool step_back_failed = false;
bool need_to_scroll_instruction_table = false;

macro void step() {
    step_back_failed = false;
    need_to_scroll_instruction_table = true;
    while(!apply_instruction(instructions[instruction_pointer]));
}

fn bool can_step_back() {
    if(instruction_history.len() < 2) return false;

    for(InstructionIndex i = 0; i < instruction_history.len() - 1; i++) {
        if(instructions[i].blocking) return true;
    }

    return false;
}

fn void step_back() {
    if(!can_step_back()) {
        step_back_failed = true;
        return;
    } else {
        step_back_failed = false;
    }

    need_to_scroll_instruction_table = true;

    do {
        Instruction inst = instruction_history.pop()!!;

        switch(inst.instruction_type) {
        case InstructionType.SHOW_TEXT:
        case InstructionType.END_SCENARIO:
            common::text.text = inst.previously_shown_text;

        case InstructionType.ANIMATE:
            (&animation::animation_list[inst.animation_index]).reset();
            animation::animation_list[inst.animation_index].apply();

            common::current_animation = inst.previous_animation_index;

            (&animation::animation_list[common::current_animation]).reset();

        case InstructionType.BACKGROUND:
            common::current_background = inst.previous_background_index;

        case InstructionType.PLAY_MUSIC:
            if(common::current_music != common::NO_MUSIC) {
                raylib::stop_music_stream(common::music_data_list[common::current_music].music);
            }

            common::current_music = inst.previous_music_index;

            if(common::current_music != common::NO_MUSIC) {
                raylib::play_music_stream(common::music_data_list[common::current_music].music);
            }

        case InstructionType.STOP_MUSIC:
            common::current_music = inst.previous_music_index;

            if(common::current_music != common::NO_MUSIC) {
                raylib::play_music_stream(common::music_data_list[common::current_music].music);
            }

        case InstructionType.CHARACTER_VISIBILITY_SET: (&common::characters[inst.character_index]).visible         = inst.previous_visibility;
        case InstructionType.CHARACTER_POSITION:       (&common::characters[inst.character_index]).position        = inst.previous_position;
        case InstructionType.CHARACTER_EMOTE:          (&common::characters[inst.character_index]).current_emotion = inst.previous_emotion;
        case InstructionType.CHARACTER_FACE:           (&common::characters[inst.character_index]).direction       = inst.previous_direction;
        case InstructionType.GOTO_LABEL:               break;
        }
        instruction_pointer = inst.previous_instruction_pointer;
    } while(!instruction_history[^1].blocking);
}

fn void debug_tab() {
    if(imgui::begin_tab_item("Instructions")) {

        if(imgui::button("Step forward")) step();

        imgui::same_line();

        if(imgui::button("Step backwards")) step_back();

        if(step_back_failed) {
            imgui::same_line();
            imgui::text("Cannot step back any further");
        }

        if(imgui::begin_table("Instruction list", 3, imgui::TABLE_ROWBG | imgui::TABLE_BORDERS | imgui::TABLE_SCROLLY | imgui::TABLE_SIZINGFIXEDFIT, { 0, 0 }, 0)) {

            imgui::table_setup_column("IP");
            imgui::table_setup_column("Index");
            imgui::table_setup_column("Instruction Type");

            imgui::table_headers_row();

            for(InstructionIndex i = 0; i < instructions.len(); i++) {
                @pool() {
                    imgui::table_next_row(0, 0);

                    imgui::table_set_column_index(0);
                        if(i == instruction_pointer) {
                            imgui::text("-->");
                            if(need_to_scroll_instruction_table) {
                                imgui::set_scroll_here_y(1.0);
                                need_to_scroll_instruction_table = false;
                            }
                        } else {
                            imgui::text("");
                        }

                    imgui::table_set_column_index(1);
                        imgui::text(string::tformat_zstr("%d", i));

                    imgui::table_set_column_index(2);
                        imgui::text(string::tformat_zstr("%s", instructions[i].instruction_type));

                };
            }
            imgui::end_table();
        }
        imgui::end_tab_item();
    }
}
