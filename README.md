# Visual novel engine (currently unnamed)

This is a smally hobby visual novel I am working on.

## compiling

NOTE: C3 is an experimental language, this project requires using the latest commit of the c3c compiler.
This is due to bugs in the compiler being frequent and me using this project partially to find and report them.

You may get the c3c compiler from here: https://github.com/c3lang/c3c

```sh
make
```

## TODO

### high
- [ ] Command to turn textbox on and off
- [ ] Implement saying text as characters, i.e `bob "Hello!"`.
- [ ] Refactor `vm::Instruction` to store only 1 piece of information, instead of 2. They are never needed at the same time.
- [ ] Custom build system using wren https://wren.io/
- [ ] Add `block` keyword that will block without doing anything.

### medium
- [ ] Overlay over the game and ability to animate it
- [ ] Implement more interpolators, and add some form of syntax for them.
- [ ] Apply passive effects onto sprites.
- [ ] Implement player choices (BIG)
- [ ] sound effects, fade audio in and out.
- [ ] Load custom fonts from chickenmilk.

### low
- [ ] Refactor text displaying system to duplicate strings from the file and store them separetely, then free the file contents.
- [ ] Dialog history menu where you can scroll through all previously spoken lines.
- [ ] Main menu.
- [ ] Save Game state.
- [ ] Custom menus from inside chickenmilk.
- [ ] Target Platforms (depends on the custom build system)
  + [X] Linux
  + [ ] Windows
  + [ ] iToddler OS
  + [ ] OpenBSD and other BSD types

## Done

- [X] Refactor big imgui chunk of code into its own module and put it behind a keybind
- [X] Playing music
- [X] Logging module.
  + [X] Handles multithreading.
  + [X] Cross-platform terminal colors. (Fuck windows you dont get colors, get a better terminal)
  + [X] Log into both terminal STDOUT and into the debug system in a text box.
- [X] Refactor multi-threaded asset loading to not use `ThreadPool` but instead just create and detach a bunch of threads to avoid blocking in the case where there are more than 32 assets.
  + Instead just increased threadpool cap to ridiculous amount, stack memory is cheap.
- [X] Implement animation type for flipping the character direction.
- [X] Add `pause` animation type
- [X] Fix stepping through VM.
- [X] Move the vm stepping code into `vm.c3`.
