BUILD=./build
CC=clang
C3C=c3c

C3CFLAGS=-O0 -g
CFLAGS=-pipe -O0 -ggdb
RAYLIB_FLAGS=-I./raylib/src -I./raylib/src/external/glfw/include -DPLATFORM_DESKTOP -D_GLFW_X11 -w $(CFLAGS)

raylib_objects := $(BUILD)/rcore.o $(BUILD)/rglfw.o $(BUILD)/rshapes.o $(BUILD)/rtext.o $(BUILD)/rtextures.o $(BUILD)/utils.o

c3_files := arena.c3 common.c3 compiler.c3 list.c3 vm.c3 raylib.c3 animation.c3

all: render

render: $(c3_files) render.c3  $(BUILD)/libraylib.a
	$(C3C) compile $(C3CFLAGS) -o render $(c3_files) render.c3 -l $(BUILD)/libraylib.a

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
