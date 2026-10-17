#include "origin/core/system_info.hpp"
#include "origin/hardware/hardware_detector.hpp"

#include <iostream>
#include <string_view>

int main(int argc, char* argv[]) {
    if (argc > 1 && std::string_view(argv[1]) == "--version") {
        std::cout << "ORIGIN Helper " << origin::version << '\n';
        return 0;
    }

    std::cout << "================================\n"
              << "       ORIGIN Helper\n"
              << "================================\n"
              << "Version: " << origin::version << "\n\n";

    origin::print_system_info();
    origin::print_hardware_info();

    std::cout << "\nHardware controls: not yet implemented.\n"
              << "Run with --version to display the version.\n";
    return 0;
}
