module common;

import raylib;
import std::collections::map;

distinct SpriteIndex = usz;

struct SpriteAsset {
    bool      visible;
    char[]    filename;
    int x, y;
    Texture2D texture;
}

struct CharacterSprite {
    char[] name;
    // emotion -> sprite index
    HashMap(<char[], SpriteIndex>) sprite_map;
}
