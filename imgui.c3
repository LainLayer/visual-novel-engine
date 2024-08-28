module imgui;

def ImGuiTabItemFlags = CInt;

extern fn void raylib_setup(bool)      @extern("rlImGuiSetup");
extern fn void raylib_shutdown()       @extern("rlImGuiShutdown");
extern fn void raylib_begin()          @extern("rlImGuiBegin");
extern fn void raylib_end()            @extern("rlImGuiEnd");

extern fn void begin(ZString)          @extern("igBegin");
extern fn void end()                   @extern("igEnd");

extern fn void show_demo_window(bool*) @extern("igShowDemoWindow");
extern fn void text(ZString)           @extern("igText");

extern fn bool button(ZString)         @extern("igButton");

extern fn bool begin_tab_bar(ZString, ImGuiTabItemFlags flag = 0)                          @extern("igBeginTabBar");
extern fn void end_tab_bar() @extern("igEndTabBar");
extern fn bool begin_tab_item(ZString , bool* p_open = null , ImGuiTabItemFlags flags = 0) @extern("igBeginTabItem");
extern fn void end_tab_item() @extern("igEndTabItem");

extern fn bool tree_node(ZString, CInt flags = 1 << 5) @extern("igTreeNodeEx_Str");
extern fn void tree_pop() @extern("igTreePop");
extern fn bool is_item_clicked(CInt mouse_button = 0) @extern("igIsItemClicked");

extern fn void same_line() @extern("igSameLine");
extern fn void progress_bar(float, float[2], ZString) @extern("igProgressBar");
