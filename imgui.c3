module imgui;

def SomeFlags = CInt;
def ImVec2 = float[2];

extern fn void raylib_setup(bool)      @extern("rlImGuiSetup");
extern fn void raylib_shutdown()       @extern("rlImGuiShutdown");
extern fn void raylib_begin()          @extern("rlImGuiBegin");
extern fn void raylib_end()            @extern("rlImGuiEnd");

extern fn void begin(ZString, bool* open = null, SomeFlags flasg = 0) @extern("igBegin");
extern fn void end()                                                  @extern("igEnd");

extern fn void show_demo_window(bool*) @extern("igShowDemoWindow");
extern fn void text(ZString)           @extern("igText");

extern fn bool button(ZString, ImVec2 size = {0.0, 0.0}) @extern("igButton");

extern fn bool begin_tab_bar(ZString, SomeFlags flag = 0)                          @extern("igBeginTabBar");
extern fn void end_tab_bar()                                                       @extern("igEndTabBar");
extern fn bool begin_tab_item(ZString , bool* p_open = null , SomeFlags flags = 0) @extern("igBeginTabItem");
extern fn void end_tab_item()                                                      @extern("igEndTabItem");

extern fn bool tree_node(ZString, SomeFlags flags = 1 << 5) @extern("igTreeNodeEx_Str");
extern fn void tree_pop()                                   @extern("igTreePop");
extern fn bool is_item_clicked(CInt mouse_button = 0)       @extern("igIsItemClicked");

extern fn void same_line(float a=0.0, float b=3.0)                          @extern("igSameLine");
extern fn void progress_bar(float, ImVec2, ZString) @extern("igProgressBar");

extern fn bool begin_table(ZString str_id, CInt columns, SomeFlags flags, ImVec2 outer_size, float inner_width) @extern("igBeginTable");
extern fn void end_table() @extern("igEndTable");
extern fn void table_next_row(SomeFlags flags, float min_row_height) @extern("igTableNextRow");
extern fn bool table_set_column_index(CInt index) @extern("igTableSetColumnIndex");

extern fn bool input_float(ZString label, float* v, float step=1.0f, float step_fast=10.0f, ZString format="%.2f", SomeFlags flags=0) @extern("igInputFloat");
