/**********************************************************************************************
*
*   raylibExtras * Utilities and Shared Components for Raylib
*
*   rlImGui * basic ImGui integration
*
*   LICENSE: ZLIB
*
*   Copyright (c) 2024 Jeffery Myers
*
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*
**********************************************************************************************/
#include "rlImGui.h"

#include "imgui_impl_raylib.h"

#include "raylib.h"
#include "rlgl.h"

#include <math.h>
#include <limits>
#include <cstdint>

#ifndef NO_FONT_AWESOME
#include "extras/FA6FreeSolidFontData.h"
#endif

#define STB_DS_IMPLEMENTATION
#include "stb_ds.h"

static ImGuiMouseCursor CurrentMouseCursor = ImGuiMouseCursor_COUNT;
static MouseCursor MouseCursorMap[ImGuiMouseCursor_COUNT];

ImGuiContext* GlobalContext = nullptr;

typedef struct { KeyboardKey key; ImGuiKey value; } KeyboardPair;

static KeyboardPair *RaylibKeyMap = nullptr;

static bool LastFrameFocused = false;

static bool LastControlPressed = false;
static bool LastShiftPressed = false;
static bool LastAltPressed = false;
static bool LastSuperPressed = false;

// internal only functions
bool rlImGuiIsControlDown() { return IsKeyDown(KEY_RIGHT_CONTROL) || IsKeyDown(KEY_LEFT_CONTROL); }
bool rlImGuiIsShiftDown() { return IsKeyDown(KEY_RIGHT_SHIFT) || IsKeyDown(KEY_LEFT_SHIFT); }
bool rlImGuiIsAltDown() { return IsKeyDown(KEY_RIGHT_ALT) || IsKeyDown(KEY_LEFT_ALT); }
bool rlImGuiIsSuperDown() { return IsKeyDown(KEY_RIGHT_SUPER) || IsKeyDown(KEY_LEFT_SUPER); }

void ReloadFonts(void)
{
    ImGuiIO& io = ImGui::GetIO();
    unsigned char* pixels = nullptr;

    int width;
    int height;
    io.Fonts->GetTexDataAsRGBA32(&pixels, &width, &height, nullptr);
    Image image = GenImageColor(width, height, BLANK);
    memcpy(image.data, pixels, width * height * 4);

    Texture2D* fontTexture = (Texture2D*)io.Fonts->TexID;
    if (fontTexture && fontTexture->id != 0)
    {
        UnloadTexture(*fontTexture);
        MemFree(fontTexture);
    }

    fontTexture = (Texture2D*)MemAlloc(sizeof(Texture2D));
    *fontTexture = LoadTextureFromImage(image);
    UnloadImage(image);
    io.Fonts->TexID = fontTexture;
}

static const char* GetClipTextCallback(void*)
{
    return GetClipboardText();
}

static void SetClipTextCallback(void*, const char* text)
{
    SetClipboardText(text);
}

static void ImGuiNewFrame(float deltaTime)
{
    ImGuiIO& io = ImGui::GetIO();


    Vector2 resolutionScale = GetWindowScaleDPI();

#ifndef PLATFORM_DRM
    if (IsWindowFullscreen())
    {
        int monitor = GetCurrentMonitor();
        io.DisplaySize.x = float(GetMonitorWidth(monitor));
        io.DisplaySize.y = float(GetMonitorHeight(monitor));
    }
    else
    {
        io.DisplaySize.x = float(GetScreenWidth());
        io.DisplaySize.y = float(GetScreenHeight());
    }

#if !defined(__APPLE__)
    if (!IsWindowState(FLAG_WINDOW_HIGHDPI))
        resolutionScale = Vector2{ 1,1 };
#endif
#else
    io.DisplaySize.x = float(GetScreenWidth());
    io.DisplaySize.y = float(GetScreenHeight());
#endif

    io.DisplayFramebufferScale = ImVec2(resolutionScale.x, resolutionScale.y);

    io.DeltaTime = deltaTime;

    if (io.WantSetMousePos)
    {
        SetMousePosition((int)io.MousePos.x, (int)io.MousePos.y);
    }
    else
    {
        io.AddMousePosEvent((float)GetMouseX(), (float)GetMouseY());
    }

    auto setMouseEvent = [&io](int rayMouse, int imGuiMouse)
        {
            if (IsMouseButtonPressed(rayMouse))
                io.AddMouseButtonEvent(imGuiMouse, true);
            else if (IsMouseButtonReleased(rayMouse))
                io.AddMouseButtonEvent(imGuiMouse, false);
        };

    setMouseEvent(MOUSE_BUTTON_LEFT, ImGuiMouseButton_Left);
    setMouseEvent(MOUSE_BUTTON_RIGHT, ImGuiMouseButton_Right);
    setMouseEvent(MOUSE_BUTTON_MIDDLE, ImGuiMouseButton_Middle);
    setMouseEvent(MOUSE_BUTTON_FORWARD, ImGuiMouseButton_Middle+1);
    setMouseEvent(MOUSE_BUTTON_BACK, ImGuiMouseButton_Middle+2);

    {
        Vector2 mouseWheel = GetMouseWheelMoveV();
        io.AddMouseWheelEvent(mouseWheel.x, mouseWheel.y);
    }

    if (ImGui::GetIO().BackendFlags & ImGuiBackendFlags_HasMouseCursors)
    {
        if ((io.ConfigFlags & ImGuiConfigFlags_NoMouseCursorChange) == 0)
        {
            ImGuiMouseCursor imgui_cursor = ImGui::GetMouseCursor();
            if (imgui_cursor != CurrentMouseCursor || io.MouseDrawCursor)
            {
                CurrentMouseCursor = imgui_cursor;
                if (io.MouseDrawCursor || imgui_cursor == ImGuiMouseCursor_None)
                {
                    HideCursor();
                }
                else
                {
                    ShowCursor();

                    if (!(io.ConfigFlags & ImGuiConfigFlags_NoMouseCursorChange))
                    {
                        SetMouseCursor((imgui_cursor > -1 && imgui_cursor < ImGuiMouseCursor_COUNT) ? MouseCursorMap[imgui_cursor] : MOUSE_CURSOR_DEFAULT);
                    }
                }
            }
        }
    }
}

static void ImGuiTriangleVert(ImDrawVert& idx_vert)
{
    Color* c;
    c = (Color*)&idx_vert.col;
    rlColor4ub(c->r, c->g, c->b, c->a);
    rlTexCoord2f(idx_vert.uv.x, idx_vert.uv.y);
    rlVertex2f(idx_vert.pos.x, idx_vert.pos.y);
}

static void ImGuiRenderTriangles(unsigned int count, int indexStart, const ImVector<ImDrawIdx>& indexBuffer, const ImVector<ImDrawVert>& vertBuffer, void* texturePtr)
{
    if (count < 3)
        return;

    Texture* texture = (Texture*)texturePtr;

    unsigned int textureId = (texture == nullptr) ? 0 : texture->id;

    rlBegin(RL_TRIANGLES);
    rlSetTexture(textureId);

    for (unsigned int i = 0; i <= (count - 3); i += 3)
    {
        ImDrawIdx indexA = indexBuffer[indexStart + i];
        ImDrawIdx indexB = indexBuffer[indexStart + i + 1];
        ImDrawIdx indexC = indexBuffer[indexStart + i + 2];

        ImDrawVert vertexA = vertBuffer[indexA];
        ImDrawVert vertexB = vertBuffer[indexB];
        ImDrawVert vertexC = vertBuffer[indexC];

        ImGuiTriangleVert(vertexA);
        ImGuiTriangleVert(vertexB);
        ImGuiTriangleVert(vertexC);
    }
    rlEnd();
}

static void EnableScissor(float x, float y, float width, float height)
{
    rlEnableScissorTest();
    ImGuiIO& io = ImGui::GetIO();

    ImVec2 scale = io.DisplayFramebufferScale;
#if !defined(__APPLE__)
    if (!IsWindowState(FLAG_WINDOW_HIGHDPI))
    {
        scale.x = 1;
        scale.y = 1;
    }
#endif

    rlScissor((int)(x * scale.x),
        int((io.DisplaySize.y - (int)(y + height)) * scale.y),
        (int)(width * scale.x),
        (int)(height * scale.y));
}

static void SetupMouseCursors(void)
{
    MouseCursorMap[ImGuiMouseCursor_Arrow] = MOUSE_CURSOR_ARROW;
    MouseCursorMap[ImGuiMouseCursor_TextInput] = MOUSE_CURSOR_IBEAM;
    MouseCursorMap[ImGuiMouseCursor_Hand] = MOUSE_CURSOR_POINTING_HAND;
    MouseCursorMap[ImGuiMouseCursor_ResizeAll] = MOUSE_CURSOR_RESIZE_ALL;
    MouseCursorMap[ImGuiMouseCursor_ResizeEW] = MOUSE_CURSOR_RESIZE_EW;
    MouseCursorMap[ImGuiMouseCursor_ResizeNESW] = MOUSE_CURSOR_RESIZE_NESW;
    MouseCursorMap[ImGuiMouseCursor_ResizeNS] = MOUSE_CURSOR_RESIZE_NS;
    MouseCursorMap[ImGuiMouseCursor_ResizeNWSE] = MOUSE_CURSOR_RESIZE_NWSE;
    MouseCursorMap[ImGuiMouseCursor_NotAllowed] = MOUSE_CURSOR_NOT_ALLOWED;
}

void SetupFontAwesome(void)
{
#ifndef NO_FONT_AWESOME
    static const ImWchar icons_ranges[] = { ICON_MIN_FA, ICON_MAX_FA, 0 };
    ImFontConfig icons_config;
    icons_config.MergeMode = true;
    icons_config.PixelSnapH = true;
    icons_config.FontDataOwnedByAtlas = false;

    icons_config.GlyphMaxAdvanceX = std::numeric_limits<float>::max();
    icons_config.RasterizerMultiply = 1.0f;
    icons_config.OversampleH = 2;
    icons_config.OversampleV = 1;

    icons_config.GlyphRanges = icons_ranges;

    ImGuiIO& io = ImGui::GetIO();

    io.Fonts->AddFontFromMemoryCompressedTTF((void*)fa_solid_900_compressed_data, fa_solid_900_compressed_size, FONT_AWESOME_ICON_SIZE, &icons_config, icons_ranges);
#endif

}

void SetupBackend(void)
{
    ImGuiIO& io = ImGui::GetIO();
    io.BackendPlatformName = "imgui_impl_raylib";
    io.BackendFlags |= ImGuiBackendFlags_HasGamepad | ImGuiBackendFlags_HasSetMousePos;

#ifndef PLATFORM_DRM
    io.BackendFlags |= ImGuiBackendFlags_HasMouseCursors;
#endif

    io.MousePos = ImVec2(0, 0);

    ImGuiPlatformIO& platformIO = ImGui::GetPlatformIO();

    io.SetClipboardTextFn = SetClipTextCallback;
    io.GetClipboardTextFn = GetClipTextCallback;

    io.ClipboardUserData = nullptr;
}

void rlImGuiEndInitImGui(void)
{
    ImGui::SetCurrentContext(GlobalContext);

    SetupFontAwesome();

    SetupMouseCursors();

    SetupBackend();

    ReloadFonts();
}

static void SetupKeymap(void)
{
    //if (!RaylibKeyMap.empty())
    if(hmlen(RaylibKeyMap) > 0)
        return;

    // build up a map of raylib keys to ImGuiKeys
    KeyboardKey key;
    key = KEY_APOSTROPHE;    hmput(RaylibKeyMap, key, ImGuiKey_Apostrophe);
    key = KEY_COMMA;         hmput(RaylibKeyMap, key, ImGuiKey_Comma);
    key = KEY_MINUS;         hmput(RaylibKeyMap, key, ImGuiKey_Minus);
    key = KEY_PERIOD;        hmput(RaylibKeyMap, key, ImGuiKey_Period);
    key = KEY_SLASH;         hmput(RaylibKeyMap, key, ImGuiKey_Slash);
    key = KEY_ZERO;          hmput(RaylibKeyMap, key, ImGuiKey_0);
    key = KEY_ONE;           hmput(RaylibKeyMap, key, ImGuiKey_1);
    key = KEY_TWO;           hmput(RaylibKeyMap, key, ImGuiKey_2);
    key = KEY_THREE;         hmput(RaylibKeyMap, key, ImGuiKey_3);
    key = KEY_FOUR;          hmput(RaylibKeyMap, key, ImGuiKey_4);
    key = KEY_FIVE;          hmput(RaylibKeyMap, key, ImGuiKey_5);
    key = KEY_SIX;           hmput(RaylibKeyMap, key, ImGuiKey_6);
    key = KEY_SEVEN;         hmput(RaylibKeyMap, key, ImGuiKey_7);
    key = KEY_EIGHT;         hmput(RaylibKeyMap, key, ImGuiKey_8);
    key = KEY_NINE;          hmput(RaylibKeyMap, key, ImGuiKey_9);
    key = KEY_SEMICOLON;     hmput(RaylibKeyMap, key, ImGuiKey_Semicolon);
    key = KEY_EQUAL;         hmput(RaylibKeyMap, key, ImGuiKey_Equal);
    key = KEY_A;             hmput(RaylibKeyMap, key, ImGuiKey_A);
    key = KEY_B;             hmput(RaylibKeyMap, key, ImGuiKey_B);
    key = KEY_C;             hmput(RaylibKeyMap, key, ImGuiKey_C);
    key = KEY_D;             hmput(RaylibKeyMap, key, ImGuiKey_D);
    key = KEY_E;             hmput(RaylibKeyMap, key, ImGuiKey_E);
    key = KEY_F;             hmput(RaylibKeyMap, key, ImGuiKey_F);
    key = KEY_G;             hmput(RaylibKeyMap, key, ImGuiKey_G);
    key = KEY_H;             hmput(RaylibKeyMap, key, ImGuiKey_H);
    key = KEY_I;             hmput(RaylibKeyMap, key, ImGuiKey_I);
    key = KEY_J;             hmput(RaylibKeyMap, key, ImGuiKey_J);
    key = KEY_K;             hmput(RaylibKeyMap, key, ImGuiKey_K);
    key = KEY_L;             hmput(RaylibKeyMap, key, ImGuiKey_L);
    key = KEY_M;             hmput(RaylibKeyMap, key, ImGuiKey_M);
    key = KEY_N;             hmput(RaylibKeyMap, key, ImGuiKey_N);
    key = KEY_O;             hmput(RaylibKeyMap, key, ImGuiKey_O);
    key = KEY_P;             hmput(RaylibKeyMap, key, ImGuiKey_P);
    key = KEY_Q;             hmput(RaylibKeyMap, key, ImGuiKey_Q);
    key = KEY_R;             hmput(RaylibKeyMap, key, ImGuiKey_R);
    key = KEY_S;             hmput(RaylibKeyMap, key, ImGuiKey_S);
    key = KEY_T;             hmput(RaylibKeyMap, key, ImGuiKey_T);
    key = KEY_U;             hmput(RaylibKeyMap, key, ImGuiKey_U);
    key = KEY_V;             hmput(RaylibKeyMap, key, ImGuiKey_V);
    key = KEY_W;             hmput(RaylibKeyMap, key, ImGuiKey_W);
    key = KEY_X;             hmput(RaylibKeyMap, key, ImGuiKey_X);
    key = KEY_Y;             hmput(RaylibKeyMap, key, ImGuiKey_Y);
    key = KEY_Z;             hmput(RaylibKeyMap, key, ImGuiKey_Z);
    key = KEY_SPACE;         hmput(RaylibKeyMap, key, ImGuiKey_Space);
    key = KEY_ESCAPE;        hmput(RaylibKeyMap, key, ImGuiKey_Escape);
    key = KEY_ENTER;         hmput(RaylibKeyMap, key, ImGuiKey_Enter);
    key = KEY_TAB;           hmput(RaylibKeyMap, key, ImGuiKey_Tab);
    key = KEY_BACKSPACE;     hmput(RaylibKeyMap, key, ImGuiKey_Backspace);
    key = KEY_INSERT;        hmput(RaylibKeyMap, key, ImGuiKey_Insert);
    key = KEY_DELETE;        hmput(RaylibKeyMap, key, ImGuiKey_Delete);
    key = KEY_RIGHT;         hmput(RaylibKeyMap, key, ImGuiKey_RightArrow);
    key = KEY_LEFT;          hmput(RaylibKeyMap, key, ImGuiKey_LeftArrow);
    key = KEY_DOWN;          hmput(RaylibKeyMap, key, ImGuiKey_DownArrow);
    key = KEY_UP;            hmput(RaylibKeyMap, key, ImGuiKey_UpArrow);
    key = KEY_PAGE_UP;       hmput(RaylibKeyMap, key, ImGuiKey_PageUp);
    key = KEY_PAGE_DOWN;     hmput(RaylibKeyMap, key, ImGuiKey_PageDown);
    key = KEY_HOME;          hmput(RaylibKeyMap, key, ImGuiKey_Home);
    key = KEY_END;           hmput(RaylibKeyMap, key, ImGuiKey_End);
    key = KEY_CAPS_LOCK;     hmput(RaylibKeyMap, key, ImGuiKey_CapsLock);
    key = KEY_SCROLL_LOCK;   hmput(RaylibKeyMap, key, ImGuiKey_ScrollLock);
    key = KEY_NUM_LOCK;      hmput(RaylibKeyMap, key, ImGuiKey_NumLock);
    key = KEY_PRINT_SCREEN;  hmput(RaylibKeyMap, key, ImGuiKey_PrintScreen);
    key = KEY_PAUSE;         hmput(RaylibKeyMap, key, ImGuiKey_Pause);
    key = KEY_F1;            hmput(RaylibKeyMap, key, ImGuiKey_F1);
    key = KEY_F2;            hmput(RaylibKeyMap, key, ImGuiKey_F2);
    key = KEY_F3;            hmput(RaylibKeyMap, key, ImGuiKey_F3);
    key = KEY_F4;            hmput(RaylibKeyMap, key, ImGuiKey_F4);
    key = KEY_F5;            hmput(RaylibKeyMap, key, ImGuiKey_F5);
    key = KEY_F6;            hmput(RaylibKeyMap, key, ImGuiKey_F6);
    key = KEY_F7;            hmput(RaylibKeyMap, key, ImGuiKey_F7);
    key = KEY_F8;            hmput(RaylibKeyMap, key, ImGuiKey_F8);
    key = KEY_F9;            hmput(RaylibKeyMap, key, ImGuiKey_F9);
    key = KEY_F10;           hmput(RaylibKeyMap, key, ImGuiKey_F10);
    key = KEY_F11;           hmput(RaylibKeyMap, key, ImGuiKey_F11);
    key = KEY_F12;           hmput(RaylibKeyMap, key, ImGuiKey_F12);
    key = KEY_LEFT_SHIFT;    hmput(RaylibKeyMap, key, ImGuiKey_LeftShift);
    key = KEY_LEFT_CONTROL;  hmput(RaylibKeyMap, key, ImGuiKey_LeftCtrl);
    key = KEY_LEFT_ALT;      hmput(RaylibKeyMap, key, ImGuiKey_LeftAlt);
    key = KEY_LEFT_SUPER;    hmput(RaylibKeyMap, key, ImGuiKey_LeftSuper);
    key = KEY_RIGHT_SHIFT;   hmput(RaylibKeyMap, key, ImGuiKey_RightShift);
    key = KEY_RIGHT_CONTROL; hmput(RaylibKeyMap, key, ImGuiKey_RightCtrl);
    key = KEY_RIGHT_ALT;     hmput(RaylibKeyMap, key, ImGuiKey_RightAlt);
    key = KEY_RIGHT_SUPER;   hmput(RaylibKeyMap, key, ImGuiKey_RightSuper);
    key = KEY_KB_MENU;       hmput(RaylibKeyMap, key, ImGuiKey_Menu);
    key = KEY_LEFT_BRACKET;  hmput(RaylibKeyMap, key, ImGuiKey_LeftBracket);
    key = KEY_BACKSLASH;     hmput(RaylibKeyMap, key, ImGuiKey_Backslash);
    key = KEY_RIGHT_BRACKET; hmput(RaylibKeyMap, key, ImGuiKey_RightBracket);
    key = KEY_GRAVE;         hmput(RaylibKeyMap, key, ImGuiKey_GraveAccent);
    key = KEY_KP_0;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad0);
    key = KEY_KP_1;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad1);
    key = KEY_KP_2;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad2);
    key = KEY_KP_3;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad3);
    key = KEY_KP_4;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad4);
    key = KEY_KP_5;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad5);
    key = KEY_KP_6;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad6);
    key = KEY_KP_7;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad7);
    key = KEY_KP_8;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad8);
    key = KEY_KP_9;          hmput(RaylibKeyMap, key, ImGuiKey_Keypad9);
    key = KEY_KP_DECIMAL;    hmput(RaylibKeyMap, key, ImGuiKey_KeypadDecimal);
    key = KEY_KP_DIVIDE;     hmput(RaylibKeyMap, key, ImGuiKey_KeypadDivide);
    key = KEY_KP_MULTIPLY;   hmput(RaylibKeyMap, key, ImGuiKey_KeypadMultiply);
    key = KEY_KP_SUBTRACT;   hmput(RaylibKeyMap, key, ImGuiKey_KeypadSubtract);
    key = KEY_KP_ADD;        hmput(RaylibKeyMap, key, ImGuiKey_KeypadAdd);
    key = KEY_KP_ENTER;      hmput(RaylibKeyMap, key, ImGuiKey_KeypadEnter);
    key = KEY_KP_EQUAL;      hmput(RaylibKeyMap, key, ImGuiKey_KeypadEqual);
}

static void SetupGlobals(void)
{
    LastFrameFocused = IsWindowFocused();
    LastControlPressed = false;
    LastShiftPressed = false;
    LastAltPressed = false;
    LastSuperPressed = false;
}

void rlImGuiBeginInitImGui(void)
{
    SetupGlobals();
    if (GlobalContext == nullptr)
        GlobalContext = ImGui::CreateContext(nullptr);
    SetupKeymap();

    ImGuiIO& io = ImGui::GetIO();
    io.Fonts->AddFontDefault();
}

void rlImGuiSetup(bool dark)
{
    rlImGuiBeginInitImGui();

    if (dark)
        ImGui::StyleColorsDark();
    else
        ImGui::StyleColorsLight();

    rlImGuiEndInitImGui();
}

void rlImGuiReloadFonts(void)
{
    ImGui::SetCurrentContext(GlobalContext);

    ReloadFonts();
}

void rlImGuiBegin(void)
{
    ImGui::SetCurrentContext(GlobalContext);
    rlImGuiBeginDelta(GetFrameTime());
}

void rlImGuiBeginDelta(float deltaTime)
{
    ImGui::SetCurrentContext(GlobalContext);
    ImGuiNewFrame(deltaTime);
    ImGui_ImplRaylib_ProcessEvents();
    ImGui::NewFrame();
}

void rlImGuiEnd(void)
{
    ImGui::SetCurrentContext(GlobalContext);
    ImGui::Render();
    ImGui_ImplRaylib_RenderDrawData(ImGui::GetDrawData());
}

void rlImGuiShutdown(void)
{
    if (GlobalContext == nullptr)
        return;

    ImGui::SetCurrentContext(GlobalContext);
    ImGui_ImplRaylib_Shutdown();

    ImGui::DestroyContext(GlobalContext);
    GlobalContext = nullptr;
}

void rlImGuiImage(const Texture* image)
{
    if (!image)
        return;

    if (GlobalContext)
        ImGui::SetCurrentContext(GlobalContext);

    ImGui::Image((ImTextureID)image, ImVec2(float(image->width), float(image->height)));
}

bool rlImGuiImageButton(const char* name, const Texture* image)
{
    if (!image)
        return false;

    if (GlobalContext)
        ImGui::SetCurrentContext(GlobalContext);

    return ImGui::ImageButton(name, (ImTextureID)image, ImVec2(float(image->width), float(image->height)));
}

bool rlImGuiImageButtonSize(const char* name, const Texture* image, ImVec2 size)
{
    if (!image)
        return false;

    if (GlobalContext)
        ImGui::SetCurrentContext(GlobalContext);

    return ImGui::ImageButton(name, (ImTextureID)image, size);
}

void rlImGuiImageSize(const Texture* image, int width, int height)
{
    if (!image)
        return;

    if (GlobalContext)
        ImGui::SetCurrentContext(GlobalContext);

    ImGui::Image((ImTextureID)image, ImVec2(float(width), float(height)));
}

void rlImGuiImageSizeV(const Texture* image, Vector2 size)
{
    if (!image)
        return;

    if (GlobalContext)
        ImGui::SetCurrentContext(GlobalContext);

    ImGui::Image((ImTextureID)image, ImVec2(size.x, size.y));
}

void rlImGuiImageRect(const Texture* image, int destWidth, int destHeight, Rectangle sourceRect)
{
    if (!image)
        return;

    if (GlobalContext)
        ImGui::SetCurrentContext(GlobalContext);

    ImVec2 uv0;
    ImVec2 uv1;

    if (sourceRect.width < 0)
    {
        uv0.x = -((float)sourceRect.x / image->width);
        uv1.x = (uv0.x - (float)(fabs(sourceRect.width) / image->width));
    }
    else
    {
        uv0.x = (float)sourceRect.x / image->width;
        uv1.x = uv0.x + (float)(sourceRect.width / image->width);
    }

    if (sourceRect.height < 0)
    {
        uv0.y = -((float)sourceRect.y / image->height);
        uv1.y = (uv0.y - (float)(fabs(sourceRect.height) / image->height));
    }
    else
    {
        uv0.y = (float)sourceRect.y / image->height;
        uv1.y = uv0.y + (float)(sourceRect.height / image->height);
    }

    ImGui::Image((ImTextureID)image, ImVec2(float(destWidth), float(destHeight)), uv0, uv1);
}

void rlImGuiImageRenderTexture(const RenderTexture* image)
{
    if (!image)
        return;

    if (GlobalContext)
        ImGui::SetCurrentContext(GlobalContext);

    rlImGuiImageRect(&image->texture, image->texture.width, image->texture.height, Rectangle{ 0,0, float(image->texture.width), -float(image->texture.height) });
}

void rlImGuiImageRenderTextureFit(const RenderTexture* image, bool center)
{
    if (!image)
        return;

    if (GlobalContext)
        ImGui::SetCurrentContext(GlobalContext);

    ImVec2 area = ImGui::GetContentRegionAvail();

    float scale =  area.x / image->texture.width;

    float y = image->texture.height * scale;
    if (y > area.y)
    {
        scale = area.y / image->texture.height;
    }

    int sizeX = int(image->texture.width * scale);
    int sizeY = int(image->texture.height * scale);

    if (center)
    {
        ImGui::SetCursorPosX(0);
        ImGui::SetCursorPosX(area.x/2 - sizeX/2);
        ImGui::SetCursorPosY(ImGui::GetCursorPosY() + (area.y / 2 - sizeY / 2));
    }

    rlImGuiImageRect(&image->texture, sizeX, sizeY, Rectangle{ 0,0, float(image->texture.width), -float(image->texture.height) });
}

// raw ImGui backend API
bool ImGui_ImplRaylib_Init(void)
{
    SetupGlobals();

    SetupKeymap();

    SetupMouseCursors();

    SetupBackend();

    return true;
}

void Imgui_ImplRaylib_BuildFontAtlas(void)
{
    ReloadFonts();
}

void ImGui_ImplRaylib_Shutdown()
{
    ImGuiIO& io =ImGui::GetIO();
    Texture2D* fontTexture = (Texture2D*)io.Fonts->TexID;

    if (fontTexture)
    {
        UnloadTexture(*fontTexture);
        MemFree(fontTexture);
    }

    io.Fonts->TexID = 0;
}

void ImGui_ImplRaylib_NewFrame(void)
{
    ImGuiNewFrame(GetFrameTime());
}

void ImGui_ImplRaylib_RenderDrawData(ImDrawData* draw_data)
{
    rlDrawRenderBatchActive();
    rlDisableBackfaceCulling();

    for (int l = 0; l < draw_data->CmdListsCount; ++l)
    {
        const ImDrawList* commandList = draw_data->CmdLists[l];

        for (const auto& cmd : commandList->CmdBuffer)
        {
            EnableScissor(cmd.ClipRect.x - draw_data->DisplayPos.x, cmd.ClipRect.y - draw_data->DisplayPos.y, cmd.ClipRect.z - (cmd.ClipRect.x - draw_data->DisplayPos.x), cmd.ClipRect.w - (cmd.ClipRect.y - draw_data->DisplayPos.y));
            if (cmd.UserCallback != nullptr)
            {
                cmd.UserCallback(commandList, &cmd);

                continue;
            }

            ImGuiRenderTriangles(cmd.ElemCount, cmd.IdxOffset, commandList->IdxBuffer, commandList->VtxBuffer, cmd.TextureId);
            rlDrawRenderBatchActive();
        }
    }

    rlSetTexture(0);
    rlDisableScissorTest();
    rlEnableBackfaceCulling();
}

void HandleGamepadButtonEvent(ImGuiIO& io, GamepadButton button, ImGuiKey key)
{
    if (IsGamepadButtonPressed(0, button))
        io.AddKeyEvent(key, true);
    else if (IsGamepadButtonReleased(0, button))
        io.AddKeyEvent(key, false);
}

void HandleGamepadStickEvent(ImGuiIO& io, GamepadAxis axis, ImGuiKey negKey, ImGuiKey posKey)
{
    constexpr float deadZone = 0.20f;

    float axisValue = GetGamepadAxisMovement(0, axis);

    io.AddKeyAnalogEvent(negKey, axisValue < -deadZone, axisValue < -deadZone ? -axisValue : 0);
    io.AddKeyAnalogEvent(posKey, axisValue > deadZone, axisValue > deadZone ? axisValue : 0);
}

bool ImGui_ImplRaylib_ProcessEvents(void)
{
    ImGuiIO& io = ImGui::GetIO();

    bool focused = IsWindowFocused();
    if (focused != LastFrameFocused)
        io.AddFocusEvent(focused);
    LastFrameFocused = focused;

    // handle the modifyer key events so that shortcuts work
    bool ctrlDown = rlImGuiIsControlDown();
    if (ctrlDown != LastControlPressed)
        io.AddKeyEvent(ImGuiMod_Ctrl, ctrlDown);
    LastControlPressed = ctrlDown;

    bool shiftDown = rlImGuiIsShiftDown();
    if (shiftDown != LastShiftPressed)
        io.AddKeyEvent(ImGuiMod_Shift, shiftDown);
    LastShiftPressed = shiftDown;

    bool altDown = rlImGuiIsAltDown();
    if (altDown != LastAltPressed)
        io.AddKeyEvent(ImGuiMod_Alt, altDown);
    LastAltPressed = altDown;

    bool superDown = rlImGuiIsSuperDown();
    if (superDown != LastSuperPressed)
        io.AddKeyEvent(ImGuiMod_Super, superDown);
    LastSuperPressed = superDown;

    for (int keyId = KEY_NULL; keyId < KeyboardKey::KEY_KP_EQUAL; keyId++)
    {
        if (!IsKeyPressed(keyId))
            continue;

        // stb_ds equivalent of std::map find
        KeyboardPair *mappedKey = (KeyboardPair*)hmgetp_null(RaylibKeyMap, keyId);
        if (mappedKey)
            io.AddKeyEvent(mappedKey->value, true);
    }

    for (int i = 0; i < hmlen(RaylibKeyMap); i++)
    {
        if (IsKeyReleased(RaylibKeyMap[i].key))
            io.AddKeyEvent(RaylibKeyMap[i].value, false);
    }

    if (io.WantCaptureKeyboard)
    {
        // add the text input in order
        unsigned int pressed = GetCharPressed();
        while (pressed != 0)
        {
            io.AddInputCharacter(pressed);
            pressed = GetCharPressed();
        }
    }

    if (io.ConfigFlags & ImGuiConfigFlags_NavEnableGamepad && IsGamepadAvailable(0))
    {
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_LEFT_FACE_UP, ImGuiKey_GamepadDpadUp);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_LEFT_FACE_RIGHT, ImGuiKey_GamepadDpadRight);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_LEFT_FACE_DOWN, ImGuiKey_GamepadDpadDown);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_LEFT_FACE_LEFT, ImGuiKey_GamepadDpadLeft);

        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_RIGHT_FACE_UP, ImGuiKey_GamepadFaceUp);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_RIGHT_FACE_RIGHT, ImGuiKey_GamepadFaceLeft);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_RIGHT_FACE_DOWN, ImGuiKey_GamepadFaceDown);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_RIGHT_FACE_LEFT, ImGuiKey_GamepadFaceRight);

        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_LEFT_TRIGGER_1, ImGuiKey_GamepadL1);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_LEFT_TRIGGER_2, ImGuiKey_GamepadL2);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_RIGHT_TRIGGER_1, ImGuiKey_GamepadR1);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_RIGHT_TRIGGER_2, ImGuiKey_GamepadR2);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_LEFT_THUMB, ImGuiKey_GamepadL3);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_RIGHT_THUMB, ImGuiKey_GamepadR3);

        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_MIDDLE_LEFT, ImGuiKey_GamepadStart);
        HandleGamepadButtonEvent(io, GAMEPAD_BUTTON_MIDDLE_RIGHT, ImGuiKey_GamepadBack);

        // left stick
        HandleGamepadStickEvent(io, GAMEPAD_AXIS_LEFT_X, ImGuiKey_GamepadLStickLeft, ImGuiKey_GamepadLStickRight);
        HandleGamepadStickEvent(io, GAMEPAD_AXIS_LEFT_Y, ImGuiKey_GamepadLStickUp, ImGuiKey_GamepadLStickDown);

        // right stick
        HandleGamepadStickEvent(io, GAMEPAD_AXIS_RIGHT_X, ImGuiKey_GamepadRStickLeft, ImGuiKey_GamepadRStickRight);
        HandleGamepadStickEvent(io, GAMEPAD_AXIS_RIGHT_Y, ImGuiKey_GamepadRStickUp, ImGuiKey_GamepadRStickDown);
    }

    return true;
}
