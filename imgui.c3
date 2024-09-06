module imgui;

def SomeFlags = CInt;
def ImVec2 = float[2];

distinct ImGuiTableFlags = CInt;

const ImGuiTableFlags TABLE_NONE                       = 0;
const ImGuiTableFlags TABLE_RESIZABLE                  = 1 << 0;   // Enable resizing columns.
const ImGuiTableFlags TABLE_REORDERABLE                = 1 << 1;   // Enable reordering columns in header row (need calling TableSetupColumn() + TableHeadersRow() to display headers)
const ImGuiTableFlags TABLE_HIDEABLE                   = 1 << 2;   // Enable hiding/disabling columns in context menu.
const ImGuiTableFlags TABLE_SORTABLE                   = 1 << 3;   // Enable sorting. Call TableGetSortSpecs() to obtain sort specs. Also see ImGuiTableFlags_SortMulti and ImGuiTableFlags_SortTristate.
const ImGuiTableFlags TABLE_NOSAVEDSETTINGS            = 1 << 4;   // Disable persisting columns order, width and sort settings in the .ini file.
const ImGuiTableFlags TABLE_CONTEXTMENUINBODY          = 1 << 5;   // Right-click on columns body/contents will display table context menu. By default it is available in TableHeadersRow().
const ImGuiTableFlags TABLE_ROWBG                      = 1 << 6;   // Set each RowBg color with ImGuiCol_TableRowBg or ImGuiCol_TableRowBgAlt (equivalent of calling TableSetBgColor with ImGuiTableBgFlags_RowBg0 on each row manually)
const ImGuiTableFlags TABLE_BORDERSINNERH              = 1 << 7;   // Draw horizontal borders between rows.
const ImGuiTableFlags TABLE_BORDERSOUTERH              = 1 << 8;   // Draw horizontal borders at the top and bottom.
const ImGuiTableFlags TABLE_BORDERSINNERV              = 1 << 9;   // Draw vertical borders between columns.
const ImGuiTableFlags TABLE_BORDERSOUTERV              = 1 << 10;  // Draw vertical borders on the left and right sides.
const ImGuiTableFlags TABLE_BORDERSH                   = TABLE_BORDERSINNERH | TABLE_BORDERSOUTERH; // Draw horizontal borders.
const ImGuiTableFlags TABLE_BORDERSV                   = TABLE_BORDERSINNERV | TABLE_BORDERSOUTERV; // Draw vertical borders.
const ImGuiTableFlags TABLE_BORDERSINNER               = TABLE_BORDERSINNERV | TABLE_BORDERSINNERH; // Draw inner borders.
const ImGuiTableFlags TABLE_BORDERSOUTER               = TABLE_BORDERSOUTERV | TABLE_BORDERSOUTERH; // Draw outer borders.
const ImGuiTableFlags TABLE_BORDERS                    = TABLE_BORDERSINNER  | TABLE_BORDERSOUTER;  // Draw all borders.
const ImGuiTableFlags TABLE_NOBORDERSINBODY            = 1 << 11;  // [ALPHA] Disable vertical borders in columns Body (borders will always appear in Headers). -> May move to style
const ImGuiTableFlags TABLE_NOBORDERSINBODYUNTILRESIZE = 1 << 12;  // [ALPHA] Disable vertical borders in columns Body until hovered for resize (borders will always appear in Headers). -> May move to style
const ImGuiTableFlags TABLE_SIZINGFIXEDFIT             = 1 << 13;  // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching contents width.
const ImGuiTableFlags TABLE_SIZINGFIXEDSAME            = 2 << 13;  // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching the maximum contents width of all columns. Implicitly enable ImGuiTableFlags_NoKeepColumnsVisible.
const ImGuiTableFlags TABLE_SIZINGSTRETCHPROP          = 3 << 13;  // Columns default to _WidthStretch with default weights proportional to each columns contents widths.
const ImGuiTableFlags TABLE_SIZINGSTRETCHSAME          = 4 << 13;  // Columns default to _WidthStretch with default weights all equal, unless overridden by TableSetupColumn().
const ImGuiTableFlags TABLE_NOHOSTEXTENDX              = 1 << 16;  // Make outer width auto-fit to columns, overriding outer_size.x value. Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.
const ImGuiTableFlags TABLE_NOHOSTEXTENDY              = 1 << 17;  // Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit). Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.
const ImGuiTableFlags TABLE_NOKEEPCOLUMNSVISIBLE       = 1 << 18;  // Disable keeping column always minimally visible when ScrollX is off and table gets too small. Not recommended if columns are resizable.
const ImGuiTableFlags TABLE_PRECISEWIDTHS              = 1 << 19;  // Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.
const ImGuiTableFlags TABLE_NOCLIP                     = 1 << 20;  // Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with TableSetupScrollFreeze().
const ImGuiTableFlags TABLE_PADOUTERX                  = 1 << 21;  // Default if BordersOuterV is on. Enable outermost padding. Generally desirable if you have headers.
const ImGuiTableFlags TABLE_NOPADOUTERX                = 1 << 22;  // Default if BordersOuterV is off. Disable outermost padding.
const ImGuiTableFlags TABLE_NOPADINNERX                = 1 << 23;  // Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off).
const ImGuiTableFlags TABLE_SCROLLX                    = 1 << 24;  // Enable horizontal scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size. Changes default sizing policy. Because this creates a child window, ScrollY is currently generally recommended when using ScrollX.
const ImGuiTableFlags TABLE_SCROLLY                    = 1 << 25;  // Enable vertical scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size.
const ImGuiTableFlags TABLE_SORTMULTI                  = 1 << 26;  // Hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).
const ImGuiTableFlags TABLE_SORTTRISTATE               = 1 << 27;  // Allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).
const ImGuiTableFlags TABLE_HIGHLIGHTHOVEREDCOLUMN     = 1 << 28;  // Highlight column headers when hovered (may evolve into a fuller highlight)

extern fn void raylib_setup(bool)                            @extern("rlImGuiSetup");
extern fn void raylib_shutdown()                             @extern("rlImGuiShutdown");
extern fn void raylib_begin()                                @extern("rlImGuiBegin");
extern fn void raylib_end()                                  @extern("rlImGuiEnd");
extern fn void begin(ZString   title,
                     bool*     open  = null,
                     SomeFlags flasg = 0)                    @extern("igBegin");
extern fn void end()                                         @extern("igEnd");
extern fn void show_demo_window(bool*)                       @extern("igShowDemoWindow");
extern fn void text(ZString)                                 @extern("igText");
extern fn bool button(ZString, ImVec2 size = {0.0, 0.0})     @extern("igButton");
extern fn bool begin_tab_bar(ZString, SomeFlags flag = 0)    @extern("igBeginTabBar");
extern fn void end_tab_bar()                                 @extern("igEndTabBar");
extern fn bool begin_tab_item(ZString  text         ,
                             bool*     p_open = null,
                             SomeFlags flags  = 0   )        @extern("igBeginTabItem");
extern fn void end_tab_item()                                @extern("igEndTabItem");
extern fn bool tree_node(ZString, SomeFlags flags = 1 << 5)  @extern("igTreeNodeEx_Str");
extern fn void tree_pop()                                    @extern("igTreePop");
extern fn bool is_item_clicked(CInt mouse_button = 0)        @extern("igIsItemClicked");
extern fn void same_line(float a=0.0, float b=3.0)           @extern("igSameLine");
extern fn void progress_bar(float, ImVec2, ZString)          @extern("igProgressBar");
extern fn bool begin_table(ZString   str_id,
                           CInt      columns,
                           ImGuiTableFlags flags,
                           ImVec2    outer_size,
                           float     inner_width)            @extern("igBeginTable");
extern fn void end_table()                                   @extern("igEndTable");
extern fn void table_next_row(SomeFlags flags,
                              float     min_row_height)      @extern("igTableNextRow");
extern fn bool table_set_column_index(CInt index)            @extern("igTableSetColumnIndex");
extern fn bool input_float(ZString   label             ,
                           float*    v                 ,
                           float     step      = 1.0f  ,
                           float     step_fast = 10.0f ,
                           ZString   format    = "%.2f",
                           SomeFlags flags     = 0     )     @extern("igInputFloat");
extern fn bool input_text_multiline(ZString   label,
                                    ZString   buf,
                                    usz       buf_size,
                                    ImVec2    size,
                                    SomeFlags flags,
                                    void* callback  = null,
                                    void* user_data = null)  @extern("igInputTextMultiline");
extern fn void begin_disabled(bool disabled = true)          @extern("igBeginDisabled");
extern fn void end_disabled()                                @extern("igEndDisabled");
extern fn void table_set_column_width(CInt  column_n,
                                      float width)           @extern("igTableSetColumnWidth");
extern fn void set_scroll_here_x(float center_x_ratio)       @extern("igSetScrollHereX");
extern fn void set_scroll_here_y(float center_y_ratio)       @extern("igSetScrollHereY");
extern fn void table_headers_row()                           @extern("igTableHeadersRow");
extern fn void table_setup_column(ZString   label,
                                  SomeFlags flags = 0,
                                  float     init_width_or_weight = 0,
                                  CInt   user_id = 0)     @extern("igTableSetupColumn");
