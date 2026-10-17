#include <origin/core/system_info.hpp>

#include <fstream>
#include <iostream>
#include <string>

namespace origin {
void print_system_info() {
    std::cout << "[System]\n";

    std::ifstream os_release("/etc/os-release");
    std::string line;
    bool found = false;

    while (std::getline(os_release, line)) {
        if (line.rfind("PRETTY_NAME=", 0) == 0) {
            std::cout << "Operating system: " << line.substr(12) << '\n';
            found = true;
            break;
        }
    }

    if (!found) {
        std::cout << "Operating system: unable to detect\n";
    }
}
}
