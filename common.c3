module common;

import raylib;
import animation;
import std::collections::map;

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

    HashMap(<char[], SpriteData>) emotion_sprite_table;
}

HashMap(<char[], Character>) character_table;

AnimationIndex current_animation = 0;
