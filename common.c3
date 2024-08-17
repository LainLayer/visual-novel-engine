module common;

import raylib;
import std::collections::map;

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

