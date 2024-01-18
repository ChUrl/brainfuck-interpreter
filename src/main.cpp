#include "lex.hpp"
#include "interpret.hpp"

#include <iostream>

int main(int argc, char **argv) {
    if (argc != 2) {
        std::cout << "Usage: bfuck <IN-PATH>" << std::endl;
    }
    std::cout << "Running " << argv[1] << "...\n" << std::endl;

    std::string tokens;
    if (!lex_brainfuck_file(argv[1], tokens)) {
        return 1;
    }

    Interpreter interpreter(tokens);
    interpreter.run();

    return 0;
}