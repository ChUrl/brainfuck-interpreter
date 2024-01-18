#include "lex.hpp"

#include <iostream>
#include <fstream>
#include <algorithm>
#include <stack>

bool lex_brainfuck_file(const std::string &path, std::string &tokens) {
    if (!tokens.empty()) {
        std::cout << "Result string \"tokens\" has to be empty!" << std::endl;
        return false;
    }

    std::ifstream input_stream;
    input_stream.open(path, std::ios::in);
    if (!input_stream.is_open()) {
        std::cout << "Failed to open file \"" << path << "\"" << std::endl;
        return false;
    }

    std::string line;
    while (std::getline(input_stream, line)) {
        tokens += line;
    }

    if (!input_stream.eof() && input_stream.fail()) {
        std::cout << "Error reading from file \"" << path << "\"" << std::endl;
        input_stream.close();
        return false;
    }
    input_stream.close();

    if (!program_valid(tokens)) {
        std::cout << "Program is invalid!" << std::endl;
        return false;
    }

    std::cout << "Lexed valid BrainFuck program:\n" << tokens << std::endl;
    return true;
}

bool program_valid(const std::string_view tokens) {
    // Check tokens
    std::string valid_tokens = "><+-.,[]";
    bool tokens_valid = std::ranges::all_of(tokens.begin(), tokens.end(), [&valid_tokens](const char c){
        return valid_tokens.find(c) != std::string::npos;
    });

    // Check bracket balance
    std::stack<char> brackets;
    for (const char c : tokens) {
        if (c == '[') {
            brackets.push('[');
        } else if (c == ']') {
            if (brackets.top() == '[') {
                brackets.pop();
            } else {
                return false;
            }
        }
    }

    return tokens_valid && brackets.empty();
}