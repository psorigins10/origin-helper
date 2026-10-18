#include "origin/core/system_info.hpp"
#include "origin/hardware/hardware_detector.hpp"

#include <chrono>
#include <iostream>
#include <string_view>
#include <thread>

int main(int argc, char* argv[]) {
    
    if (argc > 1 && std::string_view(argv[1]) == "--version") {
        std::cout << "ORIGIN Helper " << origin::version << '\n';
        return 0;
    }
        
    if (argc > 1 && std::string_view(argv[1]) == "--watch") {
        while (true) {
            std::cout << "\033[2J\033[H";

            origin::print_system_info();
            origin::print_hardware_info();    
            
            // Wait for 2 seconds
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }
    }
    
    std::cout << "================================\n"
    << "================================\n"          
    << "       ORIGIN Helper\n"
    << "================================\n"
    << "================================\n"
    << "Version: " << "\n\n" << origin::version << "\n\n";
    
    origin::print_system_info();
    origin::print_hardware_info();

    std::cout << "\nHardware controls: not yet implemented.\n"
              << "Run with --version to display the version.\n";

    return 0;
}
