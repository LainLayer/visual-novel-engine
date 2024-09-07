module log;

import std::io;
import std::thread;
import libc;

import imgui;
import raylib;

Mutex mutex;
DString storage;

const String DEBUG_LABEL = "[\x1b[36mDEBUG\x1b[0m]: "; // Cyan
const String WARN_LABEL  = "[\x1b[33m WARN\x1b[0m]: "; // Yellow
const String ERROR_LABEL = "[\x1b[31mERROR\x1b[0m]: "; // Red
const String INFO_LABEL  = "[\x1b[34m INFO\x1b[0m]: "; // Blue
const String OK_LABEL    = "[\x1b[32m   OK\x1b[0m]: "; // Green

const String DEBUG_LABEL_PLAIN = "[DEBUG]: ";
const String WARN_LABEL_PLAIN  = "[ WARN]: ";
const String ERROR_LABEL_PLAIN = "[ERROR]: ";
const String INFO_LABEL_PLAIN  = "[ INFO]: ";
const String OK_LABEL_PLAIN    = "[   OK]: ";

enum LogLevel : char (String colored, String plain) {
    DEBUG = { DEBUG_LABEL, DEBUG_LABEL_PLAIN },
    WARN  = { WARN_LABEL,  WARN_LABEL_PLAIN  },
    ERROR = { ERROR_LABEL, ERROR_LABEL_PLAIN },
    INFO  = { INFO_LABEL,  INFO_LABEL_PLAIN  },
    OK    = { OK_LABEL,    OK_LABEL_PLAIN    },
}

macro void init() {
    mutex.init()!!;
}

fn void log_core(LogLevel label, String format, args...) {
    mutex.lock()!!;
    defer mutex.unlock()!!;

    $if env::POSIX:
    io::print(label.colored);
    $else
    io::print(label.plain);
    $endif

    io::printfn(format, ...args);

    storage.append(label.plain);
    storage.appendfn(format, ...args);
}

macro void debug(String format, args...) => log_core(LogLevel.DEBUG, format, ...args);
macro void warn(String format, args...)  => log_core(LogLevel.WARN,  format, ...args);
macro void error(String format, args...) => log_core(LogLevel.ERROR, format, ...args);
macro void info(String format, args...)  => log_core(LogLevel.INFO,  format, ...args);
macro void ok(String format, args...)    => log_core(LogLevel.OK,    format, ...args);

fn void raylib_log(CInt level, char* text) @extern("raylib_log") @export {
    switch(level) {
        case raylib::LOG_DEBUG:   debug("%s", (ZString)text);
        case raylib::LOG_INFO:    info("%s",  (ZString)text);
        case raylib::LOG_WARNING: warn("%s",  (ZString)text);
        default:                  error("%s", (ZString)text);
    }
}

fn void debug_tab() {
    if(imgui::begin_tab_item("Logs")) {
        imgui::begin_disabled();
        imgui::input_text_multiline(
            "##log_view",
            log::storage.zstr_view(),
            log::storage.len(),
            { 800, 600 },
            0
        );
        imgui::end_disabled();
        imgui::end_tab_item();
    }
}
extern fn void set_raylib_tracelog_callback() @extern("set_raylib_tracelog_callback");
