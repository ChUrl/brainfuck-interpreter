cmake_minimum_required(VERSION 3.25)
project(BrainfuckInterpreter)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# find_package(Boost 1.81 COMPONENTS program_options REQUIRED)

include_directories(include)

add_executable(bfuck
    src/main.cpp
    src/lex.cpp
    src/interpret.cpp
)

# target_link_libraries(lasm Boost::program_options)
