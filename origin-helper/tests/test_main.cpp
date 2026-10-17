
#include <origin/core/system_info.hpp>
#include <origin/hardware/hardware_detector.hpp>

#include <cstdlib>
#include <iostream>

namespace {

void check(bool condition, const char* message) {
    if (!condition) {
        std::cerr << "FAIL: " << message << '\n';
        std::exit(EXIT_FAILURE);
    }
}

} // namespace

int main() {
    check(!origin::version.empty(), "version must not be empty");
    check(origin::version == "0.1.0", "unexpected initial version");

    const auto hardware = origin::collect_hardware_info();

    // Linux exposes memory statistics through /proc/meminfo.
    check(hardware.memory.total_bytes.has_value(),
          "total memory should be available on Linux");
    check(*hardware.memory.total_bytes > 0,
          "total memory must be greater than zero");

    if (hardware.memory.available_bytes) {
        check(*hardware.memory.available_bytes <=
                  *hardware.memory.total_bytes,
              "available memory must not exceed total memory");
    }

    for (const auto& gpu : hardware.gpus) {
        check(!gpu.vendor_id.empty(),
              "detected GPUs should have a vendor ID");
    }

    for (const auto& battery : hardware.batteries) {
        if (battery.charge_percent) {
            check(*battery.charge_percent >= 0 &&
                      *battery.charge_percent <= 100,
                  "battery charge must be between 0 and 100");
        }
    }

    for (const auto& temperature : hardware.temperatures) {
        check(temperature.celsius >= -20.0 &&
                  temperature.celsius <= 150.0,
              "temperature must be within the accepted sensor range");
    }

    std::cout << "ORIGIN Helper tests passed\n";
    return EXIT_SUCCESS;
}
