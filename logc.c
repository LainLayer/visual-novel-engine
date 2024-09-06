#include <stdio.h>
#include "raylib.h"

extern void raylib_log(int level, char *text);

void custom_log_callback(int message_type, const char *text, va_list args) {
    char buffer[4096];
    vsnprintf(buffer, 4096, text, args);
    raylib_log(message_type, buffer);
}

void set_raylib_tracelog_callback() {
    SetTraceLogCallback(custom_log_callback);
}
