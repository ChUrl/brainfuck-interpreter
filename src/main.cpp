#include "lex.hpp"

#include <iostream>

int main(int argc, char **argv) {
    if (argc != 2) {
        std::cout << "Usage: bfuck <IN-PATH>" << std::endl;
    }
    std::cout << "Running " << argv[1] << "...\n" << std::endl;

    std::string tokens;
    lex_brainfuck_file(argv[1], tokens);

    return 0;
}