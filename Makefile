BUILD=./build
CC=clang
CXX=clang++
C3C=c3c

C3CFLAGS=-O0 -g
CFLAGS=-pipe -O0 -ggdb
RAYLIB_FLAGS=-I./raylib/src -I./raylib/src/external/glfw/include -DPLATFORM_DESKTOP -D_GLFW_X11 -w $(CFLAGS)

IMGUI_FLAGS=-DPLATFORM_DRM -DCIMGUI_USE_GLFW -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 -I./cimgui/ -I./rlImGui/ -I./cimgui/imgui/ $(CFLAGS)

raylib_objects := $(BUILD)/rcore.o $(BUILD)/rglfw.o $(BUILD)/rshapes.o $(BUILD)/rtext.o $(BUILD)/rtextures.o $(BUILD)/utils.o

c3_files := arena.c3 common.c3 compiler.c3 list.c3 vm.c3 raylib.c3 animation.c3 imgui.c3

all: render

render: $(c3_files) render.c3  $(BUILD)/libraylib.a $(BUILD)/libimgui.a
	$(C3C) compile $(C3CFLAGS) -o render $(c3_files) render.c3 -l $(BUILD)/libraylib.a -l $(BUILD)/libimgui.a -z -lstdc++

# == raylib == #
$(BUILD)/libraylib.a: $(raylib_objects)
	ar rcs $(BUILD)/libraylib.a $(raylib_objects)

$(BUILD)/rcore.o: raylib/src/rcore.c
	$(CC) -c $(RAYLIB_FLAGS) raylib/src/rcore.c -o $(BUILD)/rcore.o

$(BUILD)/rglfw.o: raylib/src/rglfw.c
	$(CC) -c $(RAYLIB_FLAGS) raylib/src/rglfw.c -o $(BUILD)/rglfw.o

$(BUILD)/rshapes.o: raylib/src/rshapes.c
	$(CC) -c $(RAYLIB_FLAGS) raylib/src/rshapes.c -o $(BUILD)/rshapes.o

$(BUILD)/rtext.o: raylib/src/rtext.c
	$(CC) -c $(RAYLIB_FLAGS) raylib/src/rtext.c -o $(BUILD)/rtext.o

$(BUILD)/rtextures.o: raylib/src/rtextures.c
	$(CC) -c $(RAYLIB_FLAGS) raylib/src/rtextures.c -o $(BUILD)/rtextures.o

$(BUILD)/utils.o: raylib/src/utils.c
	$(CC) -c $(RAYLIB_FLAGS) raylib/src/utils.c -o $(BUILD)/utils.o
# == raylib == #


# == ImGui == #
$(BUILD)/imgui.o: cimgui/imgui/imgui.cpp
	$(CXX) $(IMGUI_FLAGS) -c cimgui/imgui/imgui.cpp -o $(BUILD)/imgui.o

$(BUILD)/imgui_demo.o: cimgui/imgui/imgui_demo.cpp
	$(CXX) $(IMGUI_FLAGS) -c cimgui/imgui/imgui_demo.cpp -o $(BUILD)/imgui_demo.o

$(BUILD)/imgui_draw.o: cimgui/imgui/imgui_draw.cpp
	$(CXX) $(IMGUI_FLAGS) -c cimgui/imgui/imgui_draw.cpp -o $(BUILD)/imgui_draw.o

$(BUILD)/imgui_tables.o: cimgui/imgui/imgui_tables.cpp
	$(CXX) $(IMGUI_FLAGS) -c cimgui/imgui/imgui_tables.cpp -o $(BUILD)/imgui_tables.o

$(BUILD)/imgui_widgets.o: cimgui/imgui/imgui_widgets.cpp
	$(CXX) $(IMGUI_FLAGS) -c cimgui/imgui/imgui_widgets.cpp -o $(BUILD)/imgui_widgets.o

$(BUILD)/cimgui.o: cimgui/cimgui.cpp
	$(CXX) $(IMGUI_FLAGS) -c cimgui/cimgui.cpp -o $(BUILD)/cimgui.o

$(BUILD)/imgui_impl_glfw.o: cimgui/imgui/backends/imgui_impl_glfw.cpp
	$(CXX) $(IMGUI_FLAGS) -I./cimgui/imgui/backends -c cimgui/imgui/backends/imgui_impl_glfw.cpp -o $(BUILD)/imgui_impl_glfw.o

$(BUILD)/imgui_impl_opengl3.o: cimgui/imgui/backends/imgui_impl_opengl3.cpp
	$(CXX) $(IMGUI_FLAGS) -I./cimgui/imgui/backends -c cimgui/imgui/backends/imgui_impl_opengl3.cpp -o $(BUILD)/imgui_impl_opengl3.o

$(BUILD)/rlImGui.o: rlImGui/rlImGui.cpp
	$(CXX) $(IMGUI_FLAGS) -c rlImGui/rlImGui.cpp -o $(BUILD)/rlImGui.o

$(BUILD)/libimgui.a: $(BUILD)/imgui_widgets.o $(BUILD)/imgui_tables.o $(BUILD)/imgui_draw.o $(BUILD)/imgui_demo.o $(BUILD)/imgui.o $(BUILD)/cimgui.o $(BUILD)/rlImGui.o $(BUILD)/imgui_impl_glfw.o $(BUILD)/imgui_impl_opengl3.o
	ar rcs $(BUILD)/libimgui.a $(BUILD)/imgui_widgets.o $(BUILD)/imgui_tables.o $(BUILD)/imgui_draw.o $(BUILD)/imgui_demo.o $(BUILD)/imgui.o $(BUILD)/cimgui.o $(BUILD)/rlImGui.o $(BUILD)/imgui_impl_glfw.o $(BUILD)/imgui_impl_opengl3.o
# == ImGui == #
