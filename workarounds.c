#include <stdio.h>
#include "raylib.h"

#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
#include "cimgui/cimgui.h"

extern void raylib_log(int level, char *text);

void custom_log_callback(int message_type, const char *text, va_list args) {
    char buffer[4096];
    vsnprintf(buffer, 4096, text, args);
    raylib_log(message_type, buffer);
}

void set_raylib_tracelog_callback() {
    SetTraceLogCallback(custom_log_callback);
}

typedef struct ImGuiWantsSomething {
    bool WantCaptureMouse;
    bool WantCaptureKeyboard;
    bool WantTextInput;
    bool WantSetMousePos;
} ImGuiWantsSomething;

ImGuiWantsSomething get_imgui_wants(ImGuiIO *io) {
    return (ImGuiWantsSomething) {
        .WantCaptureMouse    = io->WantCaptureMouse,
        .WantCaptureKeyboard = io->WantCaptureKeyboard,
        .WantTextInput       = io->WantTextInput,
        .WantSetMousePos     = io->WantSetMousePos,
    };
}
