module common;

import raylib;
import animation;
import std::collections::map;
import std::collections::list;

def Color   = char[<4>];
def Vector2 = float[<2>];

const Color WHITE = { 255, 255, 255, 255 };
const Color RED   = { 255,   0,   0, 255 };

struct SpriteData {
    char[]    filename;
    Texture2D texture;
    Image     image;
    bool      needs_flip;
}

List(<SpriteData>) sprite_data_list;

def SpriteDataIndex = usz;

macro SpriteDataIndex push_sprite_data(SpriteData data) {
    sprite_data_list.push(data);
    return sprite_data_list.len() - 1;
}

enum Direction : char (String value) {
    LEFT  = "left",
    RIGHT = "right"
}

const Direction DEFAULT_DIRECTION = Direction.LEFT;

struct Character {
    Vector2   position;
    bool      visible;
    char[]    current_emotion;
    char[]    name;
    Direction direction;

    HashMap(<char[], SpriteDataIndex>) emotion_sprite_table;
}

def CharacterIndex = uint;
List(<Character>) characters;
HashMap(<char[], CharacterIndex>) character_name_table;

macro Character* get_character_by_name(char[] name) {
    return &characters[common::character_name_table[name]!!];
}

AnimationIndex current_animation = 0;

const SpriteDataIndex INVALID_BACKGROUND = ~0;
SpriteDataIndex current_background = INVALID_BACKGROUND;

HashMap(<char[], SpriteDataIndex>) background_name_table;

macro bool background_exists(char[] name) {
    return background_name_table.has_key(name);
}
