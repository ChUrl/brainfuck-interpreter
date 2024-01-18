#ifndef __INTERPRET_H_
#define __INTERPRET_H_

#include <cstdint>
#include <vector>
#include <string>
#include <memory>
#include <map>
#include <functional>

/**
 * @brief Interpreter for a BrainFuck program
 */
class Interpreter {
private:
    const std::map<char, std::function<void(Interpreter *)>> instruction_map = {
        {'>', &Interpreter::_increment_pointer},
        {'<', &Interpreter::_decrement_pointer},
        {'+', &Interpreter::_increment_value},
        {'-', &Interpreter::_decrement_value},
        {'.', &Interpreter::_print_value},
        {',', &Interpreter::_read_value},
        {'[', &Interpreter::_jump_forward_if_zero},
        {']', &Interpreter::_jump_backward_if_nonzero},
    };

    // Runtime VM
    bool running;
    const std::string program;
    uint32_t program_counter;
    uint32_t pointer;
    std::vector<uint8_t> memory;

    // These functions implement the BrainFuck statements
    auto _increment_pointer() -> void;     // >
    auto _decrement_pointer() -> void;     // <
    auto _increment_value() -> void;       // +
    auto _decrement_value() -> void;       // -
    auto _print_value() -> void;           // .
    auto _read_value() -> void;            // ,
    auto _jump_forward_if_zero() -> void;  // [
    auto _jump_backward_if_nonzero() -> void; // ]

public:
    explicit Interpreter(std::string_view program);

    // These functions control the interpreter flow
    auto abort() -> void;
    auto step() -> void;
    auto run() -> void;
};

#endif