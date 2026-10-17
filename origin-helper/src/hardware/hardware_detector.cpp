
#include <origin/hardware/hardware_detector.hpp>
#include <origin/platform/linux_backend.hpp>

#include <iomanip>
#include <iostream>

namespace origin {
namespace {

constexpr double bytes_per_gib = 1024.0 * 1024.0 * 1024.0;

void print_memory(const MemoryInfo& memory) {
    std::cout << "Memory: ";

    if (memory.total_bytes) {
        std::cout << std::fixed << std::setprecision(1);

        if (memory.available_bytes &&
            *memory.available_bytes <= *memory.total_bytes) {
            const auto used =
                *memory.total_bytes - *memory.available_bytes;

            std::cout << static_cast<double>(used) / bytes_per_gib
                      << " GiB used / ";
        }

        std::cout << static_cast<double>(*memory.total_bytes) / bytes_per_gib
                  << " GiB total\n";
    } else {
        std::cout << "unavailable\n";
    }
}

} // namespace

HardwareInfo collect_hardware_info() {
    return platform::collect_hardware_info();
}

void print_hardware_info(const HardwareInfo& info) {
    std::cout << "\n[Hardware]\n";

    std::cout << "CPU: "
              << (info.cpu.model.empty() ? "unavailable" : info.cpu.model)
              << '\n';

    print_memory(info.memory);

    for (const auto& gpu : info.gpus) {
        std::cout << "GPU: " << gpu.vendor;

        if (!gpu.vendor_id.empty()) {
            std::cout << " (vendor " << gpu.vendor_id;
            if (!gpu.device_id.empty()) {
                std::cout << ", device " << gpu.device_id;
            }
            std::cout << ')';
        }

        std::cout << '\n';
    }

    if (info.gpus.empty()) {
        std::cout << "GPU: no supported graphics devices detected\n";
    }

    for (const auto& battery : info.batteries) {
        std::cout << "Battery: " << battery.name;

        if (battery.charge_percent) {
            std::cout << ", charge " << *battery.charge_percent << '%';
        }

        if (battery.status) {
            std::cout << ", status " << *battery.status;
        }

        std::cout << '\n';
    }

    if (info.batteries.empty()) {
        std::cout << "Battery: no battery detected\n";
    }

    for (const auto& temperature : info.temperatures) {
        std::cout << "Temperature: " << temperature.sensor;

        if (temperature.label && !temperature.label->empty()) {
            std::cout << " (" << *temperature.label << ')';
        }

        std::cout << ": " << std::fixed << std::setprecision(1)
                  << temperature.celsius << " C\n";
    }

    if (info.temperatures.empty()) {
        std::cout << "Temperatures: no readable sensors\n";
    }
}

void print_hardware_info() {
    print_hardware_info(collect_hardware_info());
}

} // namespace origin
