#include <algorithm>
#include <filesystem>
#include <fstream>
#include <string>
#include <system_error>
#include <utility>

#include <origin/platform/linux_backend.hpp>

namespace origin::platform {
namespace {

namespace fs = std::filesystem;

std::string trim(std::string value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) return {};

    const auto last = value.find_last_not_of(" \t\r\n");
    return value.substr(first, last - first + 1);
}

std::optional<std::string> read_text(const fs::path& path) {
    std::ifstream file(path);
    std::string value;

    if (!file || !std::getline(file, value)) {
        return std::nullopt;
    }

    return trim(value);
}

std::optional<std::uint64_t> read_uint(const fs::path& path) {
    const auto text = read_text(path);
    if (!text || text->empty()) return std::nullopt;

    try {
        std::size_t parsed = 0;
        const auto value = std::stoull(*text, &parsed);

        if (parsed != text->size()) return std::nullopt;
        return value;
    } catch (...) {
        return std::nullopt;
    }
}

bool is_card_directory(const std::string& name) {
    if (name.size() <= 4 || name.compare(0, 4, "card") != 0) {
        return false;
    }

    return std::all_of(name.begin() + 4, name.end(),
        [](unsigned char c) { return c >= '0' && c <= '9'; });
}

std::string vendor_name(const std::string& id) {
    if (id == "0x8086") return "Intel";
    if (id == "0x10de") return "NVIDIA";
    if (id == "0x1002") return "AMD";
    return "Unknown";
}

} // namespace

HardwareInfo collect_hardware_info() {
    HardwareInfo result;

    // CPU model
    {
        std::ifstream file("/proc/cpuinfo");
        std::string line;

        while (std::getline(file, line)) {
            const auto separator = line.find(':');
            if (separator == std::string::npos) continue;

            const auto key = trim(line.substr(0, separator));
            if (key == "model name" || key == "Hardware") {
                result.cpu.model = trim(line.substr(separator + 1));
                break;
            }
        }
    }

    // Memory: Linux reports these values in KiB.
    {
        std::ifstream file("/proc/meminfo");
        std::string key;
        std::uint64_t value = 0;
        std::string unit;

        std::optional<std::uint64_t> total_kib;
        std::optional<std::uint64_t> available_kib;

        while (file >> key >> value >> unit) {
            if (key == "MemTotal:") total_kib = value;
            if (key == "MemAvailable:") available_kib = value;
        }

        constexpr std::uint64_t kib = 1024;
        if (total_kib) result.memory.total_bytes = *total_kib * kib;
        if (available_kib) result.memory.available_bytes = *available_kib * kib;
    }

    // GPUs: enumerate DRM cards and read PCI vendor/device IDs.
    {
        const fs::path root{"/sys/class/drm"};
        std::error_code ec;

        if (fs::exists(root, ec) && !ec) {
            for (const auto& entry : fs::directory_iterator(root, ec)) {
                if (ec) break;
                if (!is_card_directory(entry.path().filename().string())) {
                    continue;
                }

                const auto vendor = read_text(entry.path() / "device/vendor");
                if (!vendor) continue;

                GpuInfo gpu;
                gpu.vendor_id = *vendor;
                gpu.vendor = vendor_name(*vendor);

                if (const auto device =
                        read_text(entry.path() / "device/device")) {
                    gpu.device_id = *device;
                }

                result.gpus.push_back(std::move(gpu));
            }
        }
    }

    // Batteries: optional fields remain empty when unavailable.
    {
        const fs::path root{"/sys/class/power_supply"};
        std::error_code ec;

        if (fs::exists(root, ec) && !ec) {
            for (const auto& entry : fs::directory_iterator(root, ec)) {
                if (ec) break;

                const auto type = read_text(entry.path() / "type");
                if (!type || *type != "Battery") continue;

                BatteryInfo battery;
                battery.name = entry.path().filename().string();

                if (const auto charge = read_uint(entry.path() / "capacity")) {
                    if (*charge <= 100) {
                        battery.charge_percent = static_cast<int>(*charge);
                    }
                }

                battery.status = read_text(entry.path() / "status");
                battery.energy_now_uwh =
                    read_uint(entry.path() / "energy_now");
                battery.energy_full_uwh =
                    read_uint(entry.path() / "energy_full");

                result.batteries.push_back(std::move(battery));
            }
        }
    }

    // Temperature sensors: hwmon inputs are conventionally in millidegrees C.
    {
        const fs::path root{"/sys/class/hwmon"};
        std::error_code ec;

        if (fs::exists(root, ec) && !ec) {
            for (const auto& chip : fs::directory_iterator(root, ec)) {
                if (ec) break;

                const auto chip_name = read_text(chip.path() / "name");
                const std::string sensor =
                    chip_name.value_or(chip.path().filename().string());

                for (const auto& file :
                     fs::directory_iterator(chip.path(), ec)) {
                    if (ec) break;

                    const auto filename = file.path().filename().string();
                    if (filename.rfind("temp", 0) != 0 ||
                        filename.size() < 11 ||
                        filename.compare(filename.size() - 6, 6, "_input") != 0) {
                        continue;
                    }

                    const auto raw = read_uint(file.path());
                    if (!raw || *raw > 150000) continue;

                    const double celsius =
                        static_cast<double>(*raw) / 1000.0;
                    if (celsius < -20.0) continue;

                    const auto prefix =
                        filename.substr(0, filename.size() - 6);

                    TemperatureInfo temperature;
                    temperature.sensor = sensor;
                    temperature.label =
                        read_text(chip.path() / (prefix + "_label"));
                    temperature.celsius = celsius;

                    result.temperatures.push_back(std::move(temperature));
                }
            }
        }
    }

    return result;
}

} // namespace origin::platform
