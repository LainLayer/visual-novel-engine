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
}

struct Character {
    Vector2 position;
    bool    visible;
    char[]  current_emotion;
    char[]  name;

    HashMap(<char[], SpriteData>) emotion_sprite_table;
}

def CharacterIndex = uint;
List(<Character>) characters;
HashMap(<char[], CharacterIndex>) character_name_table;

macro Character* get_character_by_name(char[] name) {
    return &characters[common::character_name_table[name]!!];
}

AnimationIndex current_animation = 0;
