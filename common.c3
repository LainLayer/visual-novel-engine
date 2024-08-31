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

def BackgroundIndex = int;
List(<SpriteData>) backgrounds;

BackgroundIndex current_background = -1;

HashMap(<char[], BackgroundIndex>) background_name_table;

macro bool background_exists(char[] name) {
    return background_name_table.has_key(name);
}

macro void add_background(char[] name, char[] filename) {
    backgrounds.push(SpriteData { .filename = filename });
    background_name_table[name] = (int)(backgrounds.len() - 1);
}

fn uint number_of_sprite_data() {
    uint result = 0;
    foreach(character : characters) {
        result += (uint)character.emotion_sprite_table.len();
    }

    result += (uint)backgrounds.len();

    return result;
}
