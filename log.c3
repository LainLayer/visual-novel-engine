module log;

import std::io;
import std::thread;
import libc;

import raylib;

Mutex mutex;

const String DEBUG_LABEL = "[\x1b[36mDEBUG\x1b[0m]: "; // Cyan
const String WARN_LABEL  = "[\x1b[33m WARN\x1b[0m]: "; // Yellow
const String ERROR_LABEL = "[\x1b[31mERROR\x1b[0m]: "; // Red
const String INFO_LABEL  = "[\x1b[34m INFO\x1b[0m]: "; // Blue
const String OK_LABEL    = "[\x1b[32m   OK\x1b[0m]: "; // Green

macro void init() {
    mutex.init()!!;
}

fn void info(String format, args...) {
    mutex.lock()!!;
    io::printf(INFO_LABEL);
    io::printfn(format, ...args);
    mutex.unlock()!!;
}

fn void raylib_log(CInt level, char* text) @extern("raylib_log") @export {
    mutex.lock()!!;
    switch(level) {
        case raylib::LOG_DEBUG:   io::printfn("%s%s", DEBUG_LABEL, (ZString)text);
        case raylib::LOG_INFO:    io::printfn("%s%s", INFO_LABEL,  (ZString)text);
        case raylib::LOG_WARNING: io::printfn("%s%s", WARN_LABEL,  (ZString)text);
        case raylib::LOG_ERROR:   io::printfn("%s%s", ERROR_LABEL, (ZString)text);
    }
    mutex.unlock()!!;
}

extern fn void set_raylib_tracelog_callback() @extern("set_raylib_tracelog_callback");
