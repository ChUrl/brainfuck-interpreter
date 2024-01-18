#ifndef __LEX_H_
#define __LEX_H_

#include <string>

/**
 * @brief Lex a brainfuck file to a string from disk. Each element is a token.
 * @param path The path to the file to be lexed
 * @param tokens The string where the tokens will be written to
 * @return True if the file was lexed successfully
 */
bool lex_brainfuck_file(const std::string &path, std::string &tokens);

bool program_valid(const std::string_view tokens);

#endif