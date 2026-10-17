
#pragma once

#include <origin/hardware/hardware_info.hpp>

namespace origin {

[[nodiscard]] HardwareInfo collect_hardware_info();

void print_hardware_info(const HardwareInfo& info);
void print_hardware_info();

} // namespace origin
