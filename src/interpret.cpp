#include "interpret.hpp"

#include <iostream>
#include <limits>

//
// Private functions
//

static const constexpr uint8_t MIN_VALUE = static_cast<uint8_t>(0);
static const constexpr uint8_t MAX_VALUE = static_cast<uint8_t>(-1);

auto Interpreter::_increment_pointer() -> void {
    if (pointer == std::numeric_limits<uint32_t>::max()) {
        std::cout << "Can't increment pointer: Max size reached!" << std::endl;
        abort();
        return;
    }

    pointer++;

    // If our currently allocated memory is exceeded, double it
    if (pointer == memory.size()) {
        memory.resize(memory.size() * 2, MIN_VALUE);
    }
}

auto Interpreter::_decrement_pointer() -> void {
    if (pointer == 0) {
        std::cout << "Can't decrement pointer: Min size reached!" << std::endl;
        abort();
        return;
    }

    pointer--;
}

auto Interpreter::_increment_value() -> void {
    if (memory[pointer] == MAX_VALUE) {
        std::cout << "Can't increment value: Max value reached!" << std::endl;
        abort();
        return;
    }

    memory[pointer]++;
}

auto Interpreter::_decrement_value() -> void {
    if (memory[pointer] == MIN_VALUE) {
        std::cout << "Can't decrement value: Min value reached!" << std::endl;
        abort();
        return;
    }

    memory[pointer]--;
}

auto Interpreter::_print_value() -> void {
    std::cout << static_cast<uint8_t>(memory[pointer]) << std::endl;
}

auto Interpreter::_read_value() -> void {
    char input;
    std::cin.get(input);

    if (static_cast<uint8_t>(input) < MIN_VALUE || static_cast<uint8_t>(input) > MAX_VALUE) {
        std::cout << "Invalid input! Must be element of ["
                  << MIN_VALUE << ", " << MAX_VALUE
                  << "]!" << std::endl;
        abort();
        return;
    }

    memory[pointer] = static_cast<uint8_t>(input);
}

auto Interpreter::_jump_forward_if_zero() -> void {
    if (memory[pointer] != MIN_VALUE) {
        return;
    }

    // Find the corresponding ']'
    int32_t jump_counter = 0;
    for (uint32_t index = program_counter; index < program.size(); ++index) {
        if (program[index] == '[') {
            ++jump_counter;
        } else if (program[index] == ']') {
            --jump_counter;
        }

        if (jump_counter == 0) {
            program_counter = index; // PC gets incremented later
            return;
        }
    }
}

auto Interpreter::_jump_backward_if_nonzero() -> void {
    if (memory[pointer] == MIN_VALUE) {
        return;
    }

    // Find the corresponding '['
    int32_t jump_counter = 0;
    for (uint32_t index = program_counter; index > 0; --index) {
        if (program[index] == '[') {
            ++jump_counter;
        } else if (program[index] == ']') {
            --jump_counter;
        }

        if (jump_counter == 0) {
            program_counter = index; // PC gets incremented later
            return;
        }
    }
}

//
// Public functions
//

Interpreter::Interpreter(const std::string_view program)
    : running(false), program(program), program_counter(0), pointer(0), memory(1024, MIN_VALUE) {
    std::cout << "Initialized interpreter with program size " << program.size() << "!\n" << std::endl;
}

auto Interpreter::abort() -> void {
    running = false;
    std::cout << "Program aborted!" << std::endl;
}

auto Interpreter::step() -> void {
    if (program_counter == program.size()) {
        std::cout << "Program finished!" << std::endl;
        running = false;
        return;
    }

    const char instruction = program[program_counter];

    // Execute the correct action in the VM
    instruction_map.at(instruction)(this);

    ++program_counter;
}

auto Interpreter::run() -> void {
    running = true;
    while (running) {
        step();
    }
}