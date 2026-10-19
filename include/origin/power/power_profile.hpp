#pragma once
#include <string>
#include <vector>

namespace origin {
struct PowerProfileInfo {
    std::string active;
    std::vector<std::string> available;
    bool supported = false;
    std::string error;
};

class PowerProfile {
public:
    explicit PowerProfile(
        std::string profile_path = "/sys/firmware/acpi/platform_profile",
        std::string choices_path = "/sys/firmware/acpi/platform_profile_choices");
    [[nodiscard]] PowerProfileInfo get() const;
    [[nodiscard]] bool set(const std::string& profile, std::string& error) const;
private:
    std::string profile_path_;
    std::string choices_path_;
};
}  // namespace origin
