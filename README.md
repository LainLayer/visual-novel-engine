# Visual novel engine (currently unnamed)

This is a smally hobby visual novel I am working on.

## compiling

```sh
make
```

## TODO

- [ ] Refactor `vm::Instruction` to store only 1 piece of information, instead of 2. They are never needed at the same time.
- [ ] Move the vm stepping code into `vm.c3`.
- [ ] Custom build system using wren https://wren.io/
- [ ] Implement saying text as characters, i.e `bob "Hello!"`.
- [ ] Implement animation type for flipping the character direction.
- [ ] Target Platforms (depends on the custom build system)
  + [X] Linux
  + [ ] Windows
  + [ ] iToddler OS
  + [ ] OpenBSD and other BSD types
- [ ] Apply passive effects onto sprites.
- [ ] Main menu.
- [ ] Dialog history menu where you can scroll through all previously spoken lines.
- [ ] Save Game state.
- [ ] Playing music and sound effects, fade audio in and out.
- [ ] Load custom fonts from chickenmilk.
- [ ] Logging module.
  + [ ] Handles multithreading.
  + [ ] Cross-platform terminal colors.
  + [ ] Log into both terminal STDOUT and into the debug system in a text box.
- [ ] Refactor multi-threaded asset loading to not use `ThreadPool` but instead just create and detach a bunch of threads to avoid blocking in the case where there are more than 32 assets.
- [ ] Add `block` keyword that will block without doing anything.
- [ ] Refactor text displaying system to duplicate strings from the file and store them separetely, then free the file contents.
- [ ] Refactor big imgui chunk of code into its own module and put it behind a keybind
- [ ] Implement more interpolators, and add some form of syntax for them.
- [ ] Implement player choices (BIG)
- [ ] Custom menus from inside chickenmilk.
- [ ] Add `pause` animation type

## Done

- [X] Fix stepping through VM.
