module raylib;

import common;

struct Rectangle {
    float x;
    float y;
    float width;
    float height;
}

struct Texture {
    CUInt id;
    CInt  width;
    CInt  height;
    CInt  mipmaps;
    CInt  format;
}

def Texture2D = Texture;

struct RenderTexture {
    CUInt   id;
    Texture texture;
    Texture depth;
}

def RenderTexture2D = RenderTexture;

struct Image {
    void* data;
    CInt  width;
    CInt  height;
    CInt  mipmaps;
    CInt  format;
}

struct GlyphInfo {
    CInt value;
    CInt offsetX;
    CInt offsetY;
    CInt advanceX;
    Image image;
}

struct Font {
    CInt       baseSize;
    CInt       glyphCount;
    CInt       glyphPadding;
    Texture2D  texture;
    Rectangle* recs;
    GlyphInfo* glyphs;
}

def CVector2 = float[2];

enum KeyboardKey : CInt (CInt value) {
    NULL            = 0,        // Key: NULL, used for no key pressed
    // Alphanumeric keys
    APOSTROPHE      = 39,       // Key: '
    COMMA           = 44,       // Key: ,
    MINUS           = 45,       // Key: -
    PERIOD          = 46,       // Key: .
    SLASH           = 47,       // Key: /
    ZERO            = 48,       // Key: 0
    ONE             = 49,       // Key: 1
    TWO             = 50,       // Key: 2
    THREE           = 51,       // Key: 3
    FOUR            = 52,       // Key: 4
    FIVE            = 53,       // Key: 5
    SIX             = 54,       // Key: 6
    SEVEN           = 55,       // Key: 7
    EIGHT           = 56,       // Key: 8
    NINE            = 57,       // Key: 9
    SEMICOLON       = 59,       // Key: ;
    EQUAL           = 61,       // Key: =
    A               = 65,       // Key: A | a
    B               = 66,       // Key: B | b
    C               = 67,       // Key: C | c
    D               = 68,       // Key: D | d
    E               = 69,       // Key: E | e
    F               = 70,       // Key: F | f
    G               = 71,       // Key: G | g
    H               = 72,       // Key: H | h
    I               = 73,       // Key: I | i
    J               = 74,       // Key: J | j
    K               = 75,       // Key: K | k
    L               = 76,       // Key: L | l
    M               = 77,       // Key: M | m
    N               = 78,       // Key: N | n
    O               = 79,       // Key: O | o
    P               = 80,       // Key: P | p
    Q               = 81,       // Key: Q | q
    R               = 82,       // Key: R | r
    S               = 83,       // Key: S | s
    T               = 84,       // Key: T | t
    U               = 85,       // Key: U | u
    V               = 86,       // Key: V | v
    W               = 87,       // Key: W | w
    X               = 88,       // Key: X | x
    Y               = 89,       // Key: Y | y
    Z               = 90,       // Key: Z | z
    LEFT_BRACKET    = 91,       // Key: [
    BACKSLASH       = 92,       // Key: '\'
    RIGHT_BRACKET   = 93,       // Key: ]
    GRAVE           = 96,       // Key: `
    // Function keys
    SPACE           = 32,       // Key: Space
    ESCAPE          = 256,      // Key: Esc
    ENTER           = 257,      // Key: Enter
    TAB             = 258,      // Key: Tab
    BACKSPACE       = 259,      // Key: Backspace
    INSERT          = 260,      // Key: Ins
    DELETE          = 261,      // Key: Del
    RIGHT           = 262,      // Key: Cursor right
    LEFT            = 263,      // Key: Cursor left
    DOWN            = 264,      // Key: Cursor down
    UP              = 265,      // Key: Cursor up
    PAGE_UP         = 266,      // Key: Page up
    PAGE_DOWN       = 267,      // Key: Page down
    HOME            = 268,      // Key: Home
    END             = 269,      // Key: End
    CAPS_LOCK       = 280,      // Key: Caps lock
    SCROLL_LOCK     = 281,      // Key: Scroll down
    NUM_LOCK        = 282,      // Key: Num lock
    PRINT_SCREEN    = 283,      // Key: Print screen
    PAUSE           = 284,      // Key: Pause
    F1              = 290,      // Key: F1
    F2              = 291,      // Key: F2
    F3              = 292,      // Key: F3
    F4              = 293,      // Key: F4
    F5              = 294,      // Key: F5
    F6              = 295,      // Key: F6
    F7              = 296,      // Key: F7
    F8              = 297,      // Key: F8
    F9              = 298,      // Key: F9
    F10             = 299,      // Key: F10
    F11             = 300,      // Key: F11
    F12             = 301,      // Key: F12
    LEFT_SHIFT      = 340,      // Key: Shift left
    LEFT_CONTROL    = 341,      // Key: Control left
    LEFT_ALT        = 342,      // Key: Alt left
    LEFT_SUPER      = 343,      // Key: Super left
    RIGHT_SHIFT     = 344,      // Key: Shift right
    RIGHT_CONTROL   = 345,      // Key: Control right
    RIGHT_ALT       = 346,      // Key: Alt right
    RIGHT_SUPER     = 347,      // Key: Super right
    KB_MENU         = 348,      // Key: KB menu
    // Keypad keys
    KP_0            = 320,      // Key: Keypad 0
    KP_1            = 321,      // Key: Keypad 1
    KP_2            = 322,      // Key: Keypad 2
    KP_3            = 323,      // Key: Keypad 3
    KP_4            = 324,      // Key: Keypad 4
    KP_5            = 325,      // Key: Keypad 5
    KP_6            = 326,      // Key: Keypad 6
    KP_7            = 327,      // Key: Keypad 7
    KP_8            = 328,      // Key: Keypad 8
    KP_9            = 329,      // Key: Keypad 9
    KP_DECIMAL      = 330,      // Key: Keypad .
    KP_DIVIDE       = 331,      // Key: Keypad /
    KP_MULTIPLY     = 332,      // Key: Keypad *
    KP_SUBTRACT     = 333,      // Key: Keypad -
    KP_ADD          = 334,      // Key: Keypad +
    KP_ENTER        = 335,      // Key: Keypad Enter
    KP_EQUAL        = 336,      // Key: Keypad =
    // Android key buttons
    BACK            = 4,        // Key: Android back button
    MENU            = 5,        // Key: Android menu button
    VOLUME_UP       = 24,       // Key: Android volume up button
    VOLUME_DOWN     = 25        // Key: Android volume down button
}

extern fn void  init_window(CInt, CInt, ZString)                 @extern("InitWindow");
extern fn bool  is_window_resized()                              @extern("IsWindowResized");
extern fn void  set_target_fps(CInt)                             @extern("SetTargetFPS");
extern fn bool  window_should_close()                            @extern("WindowShouldClose");
extern fn void  begin_drawing()                                  @extern("BeginDrawing");
extern fn void  end_drawing()                                    @extern("EndDrawing");
extern fn void  clear_background(Color)                          @extern("ClearBackground");
extern fn void  close_window()                                   @extern("CloseWindow");
extern fn void  draw_text(ZString, CInt, CInt, CInt, Color)      @extern("DrawText");
extern fn void  draw_line_v(CVector2, CVector2, CUInt)           @extern("DrawLineV");
extern fn void  draw_rectangle_rec(Rectangle, Color)             @extern("DrawRectangleRec");
extern fn void  draw_rectangle_lines_ex(Rectangle, float, Color) @extern("DrawRectangleLinesEx");
extern fn CInt  get_screen_width()                               @extern("GetScreenWidth");
extern fn CInt  get_screen_height()                              @extern("GetScreenHeight");
extern fn float get_frame_time()                                 @extern("GetFrameTime");
extern fn bool  is_key_pressed(CInt)                             @extern("IsKeyPressed");
extern fn CInt  measure_text(ZString, CInt)                      @extern("MeasureText");
extern fn CUInt text_length(ZString)                             @extern("TextLength");
extern fn CInt  get_codepoint(ZString, CInt*)                    @extern("GetCodepoint");
extern fn CInt  get_glyph_index(Font, CInt)                      @extern("GetGlyphIndex");
extern fn void  draw_text_codepoint(Font,     CInt,
                                    CVector2, float, Color)      @extern("DrawTextCodepoint");
extern fn Font      get_font_default()                           @extern("GetFontDefault");
extern fn Texture2D load_texture_from_image(Image)               @extern("LoadTextureFromImage");
extern fn Image     load_image(ZString)                          @extern("LoadImage");
extern fn void      unload_image(Image)                          @extern("UnloadImage");
extern fn Texture2D load_texture(ZString)                        @extern("LoadTexture");
extern fn void unload_render_texture(RenderTexture2D)            @extern("UnloadRenderTexture");
extern fn void begin_texture_mode(RenderTexture2D)               @extern("BeginTextureMode");
extern fn void end_texture_mode()                                @extern("EndTextureMode");
extern fn void draw_texture(Texture2D, CInt, CInt, Color)        @extern("DrawTexture");
extern fn void draw_texture_v(Texture2D, CVector2, Color)        @extern("DrawTextureV");
extern fn void draw_texture_rec(Texture2D, Rectangle,
                                CVector2,  Color)                @extern("DrawTextureRec");
extern fn RenderTexture2D load_render_texture(CInt, CInt)        @extern("LoadRenderTexture");
extern fn void draw_texture_ex(Texture2D texture,
                               CVector2  position,
                               float     rotation,
                               float     scale,
                               Color     tint)                   @extern("DrawTextureEx");
extern fn void draw_texture_pro(Texture2D texture,
                                Rectangle source,
                                Rectangle dest,
                                CVector2  origin,
                                float     rotation,
                                Color     tint)                  @extern("DrawTexturePro");
extern fn void image_flip_vertical(Image* image)                 @extern("ImageFlipVertical");
extern fn void image_flip_horizontal(Image* image)               @extern("ImageFlipHorizontal");

fn void draw_text_boxed(Font font, ZString text, Rectangle rec, float fontSize, float spacing, bool wordWrap, Color tint) {
    draw_text_boxed_selectable(font, text, rec, fontSize, spacing, wordWrap, tint, 0, 0, common::WHITE, common::WHITE);
}

enum DrawState {
    MEASURE_STATE,
    DRAW_STATE,
}

fn void draw_text_boxed_selectable(Font font, ZString text, Rectangle rec, float fontSize, float spacing, bool wordWrap, Color tint, int selectStart, int selectLength, Color selectTint, Color selectBackTint) {
    CInt length = text_length(text);

    float textOffsetY = 0;
    float textOffsetX = 0.0f;

    float scaleFactor = fontSize/(float)font.baseSize;

    DrawState state = wordWrap ? DrawState.MEASURE_STATE : DrawState.DRAW_STATE;

    CInt startLine = -1;
    CInt endLine = -1;
    CInt lastk = -1;

    for (CInt i = 0, CInt k = 0; i < length; i++, k++)
    {

        CInt codepointByteCount = 0;
        CInt codepoint = get_codepoint((ZString)&text[i], &codepointByteCount);
        CInt index = get_glyph_index(font, codepoint);



        if (codepoint == 0x3f) codepointByteCount = 1;
        i += (codepointByteCount - 1);

        float glyphWidth = 0;
        if (codepoint != '\n')
        {
            glyphWidth = (font.glyphs[index].advanceX == 0) ? font.recs[index].width*scaleFactor : font.glyphs[index].advanceX*scaleFactor;

            if (i + 1 < length) glyphWidth = glyphWidth + spacing;
        }

        if (state == DrawState.MEASURE_STATE)
        {


            if ((codepoint == ' ') || (codepoint == '\t') || (codepoint == '\n')) endLine = i;

            if ((textOffsetX + glyphWidth) > rec.width)
            {
                endLine = (endLine < 1)? i : endLine;
                if (i == endLine) endLine -= codepointByteCount;
                if ((startLine + codepointByteCount) == endLine) endLine = (i - codepointByteCount);

                state = state == DrawState.DRAW_STATE ? DrawState.MEASURE_STATE : DrawState.DRAW_STATE;
            }
            else if ((i + 1) == length)
            {
                endLine = i;
                state = state == DrawState.DRAW_STATE ? DrawState.MEASURE_STATE : DrawState.DRAW_STATE;
            }
            else if (codepoint == '\n') state = state == DrawState.DRAW_STATE ? DrawState.MEASURE_STATE : DrawState.DRAW_STATE;

            if (state == DrawState.DRAW_STATE)
            {
                textOffsetX = 0;
                i = startLine;
                glyphWidth = 0;


                CInt tmp = lastk;
                lastk = k - 1;
                k = tmp;
            }
        }
        else
        {
            if (codepoint == '\n')
            {
                if (!wordWrap)
                {
                    textOffsetY += (float)(font.baseSize + font.baseSize/2)*scaleFactor;
                    textOffsetX = 0;
                }
            }
            else
            {
                if (!wordWrap && ((textOffsetX + glyphWidth) > rec.width))
                {
                    textOffsetY += (float)(font.baseSize + font.baseSize/2)*scaleFactor;
                    textOffsetX = 0;
                }


                if ((textOffsetY + font.baseSize*scaleFactor) > rec.height) break;


                bool isGlyphSelected = false;
                if ((selectStart >= 0) && (k >= selectStart) && (k < (selectStart + selectLength)))
                {
                    draw_rectangle_rec({ rec.x + textOffsetX - 1, rec.y + textOffsetY, glyphWidth, (float)font.baseSize*scaleFactor }, selectBackTint);
                    isGlyphSelected = true;
                }


                if ((codepoint != ' ') && (codepoint != '\t'))
                {
                    draw_text_codepoint(font, codepoint, { rec.x + textOffsetX, rec.y + textOffsetY }, fontSize, isGlyphSelected? selectTint : tint);
                }
            }

            if (wordWrap && (i == endLine))
            {
                textOffsetY += (float)(font.baseSize + font.baseSize/2)*scaleFactor;
                textOffsetX = 0;
                startLine = endLine;
                endLine = -1;
                glyphWidth = 0;
                selectStart += lastk - k;
                k = lastk;

                state = state == DrawState.DRAW_STATE ? DrawState.MEASURE_STATE : DrawState.DRAW_STATE;
            }
        }

        if ((textOffsetX != 0) || (codepoint != ' ')) textOffsetX += glyphWidth;
    }
}
