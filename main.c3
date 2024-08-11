import common;
import compiler;
import vm;


fn void main() {
    compiler::compile_file("test.balls")!!;
    compiler::print_syntax_tree();
}
