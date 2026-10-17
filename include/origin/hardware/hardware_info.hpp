
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace origin {

struct CpuInfo {
    std::string model;
};

struct MemoryInfo {
    std::optional<std::uint64_t> total_bytes;
    std::optional<std::uint64_t> available_bytes;
};

struct GpuInfo {
    std::string vendor;
    std::string vendor_id;
    std::string device_id;
};

struct BatteryInfo {
    std::string name;
    std::optional<int> charge_percent;
    std::optional<std::string> status;
    std::optional<std::uint64_t> energy_now_uwh;
    std::optional<std::uint64_t> energy_full_uwh;
};

struct TemperatureInfo {
    std::string sensor;
    std::optional<std::string> label;
    double celsius{};
};

struct HardwareInfo {
    CpuInfo cpu;
    MemoryInfo memory;
    std::vector<GpuInfo> gpus;
    std::vector<BatteryInfo> batteries;
    std::vector<TemperatureInfo> temperatures;
};

} // namespace origin
