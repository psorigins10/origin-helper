#include "origin/power/power_profile.hpp"
#include <algorithm>
#include <sys/types.h>
#include <unistd.h>

#include <array>
#include <cstdio>
#include <memory>
#include <string>
#include <sys/wait.h>
#include <utility>
#include <vector>

namespace origin {
namespace {

struct CommandResult {
    int exit_code = -1;
    std::string output;
};

CommandResult run_command(const std::vector<std::string>& args) {
    CommandResult result;
    if (args.empty()) {
        return result;
    }

    // Use a pipe and fork/exec rather than a shell. Arguments are passed
    // separately, so profile names cannot inject shell commands.
    int pipefd[2];
    if (pipe(pipefd) != 0) {
        return result;
    }

    const pid_t pid = fork();
    if (pid < 0) {
        close(pipefd[0]);
        close(pipefd[1]);
        return result;
    }

    if (pid == 0) {
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        dup2(pipefd[1], STDERR_FILENO);
        close(pipefd[1]);

        std::vector<char*> argv;
        argv.reserve(args.size() + 1);
        for (const auto& arg : args) {
            argv.push_back(const_cast<char*>(arg.c_str()));
        }
        argv.push_back(nullptr);

        execvp(argv[0], argv.data());
        _exit(127);
    }

    close(pipefd[1]);
    std::array<char, 512> buffer{};
    ssize_t count;
    while ((count = read(pipefd[0], buffer.data(), buffer.size())) > 0) {
        result.output.append(buffer.data(), static_cast<std::size_t>(count));
    }
    close(pipefd[0]);

    int status = 0;
    if (waitpid(pid, &status, 0) >= 0 && WIFEXITED(status)) {
        result.exit_code = WEXITSTATUS(status);
    }
    return result;
}

std::string trim(std::string value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) return {};
    const auto last = value.find_last_not_of(" \t\r\n");
    return value.substr(first, last - first + 1);
}

std::string to_daemon_profile(const std::string& profile) {
    if (profile == "low-power" || profile == "power-saver") {
        return "power-saver";
    }
    if (profile == "balanced") {
        return "balanced";
    }
    if (profile == "performance" || profile == "max-power") {
        return "performance";
    }
    return {};
}

std::string from_daemon_profile(const std::string& profile) {
    if (profile == "power-saver") return "low-power";
    return profile;
}

}  // namespace

PowerProfile::PowerProfile(std::string profile_path, std::string choices_path)
    : profile_path_(std::move(profile_path)),
      choices_path_(std::move(choices_path)) {}

PowerProfileInfo PowerProfile::get() const {
    PowerProfileInfo info;

    const auto available = run_command({"powerprofilesctl", "list"});
    if (available.exit_code != 0) {
        info.error = "power-profiles-daemon is unavailable. Install and start power-profiles-daemon.";
        return info;
    }

    // Only advertise profiles actually reported by the daemon.
    if (available.output.find("power-saver:") != std::string::npos) {
        info.available.push_back("low-power");
    }
    if (available.output.find("balanced:") != std::string::npos) {
        info.available.push_back("balanced");
    }
    if (available.output.find("performance:") != std::string::npos) {
        info.available.push_back("performance");
    }

    const auto active = run_command({"powerprofilesctl", "get"});
    if (active.exit_code != 0) {
        info.error = trim(active.output);
        if (info.error.empty()) {
            info.error = "Could not read the active power profile.";
        }
        return info;
    }

    info.active = from_daemon_profile(trim(active.output));
    info.supported = !info.active.empty() && !info.available.empty();
    if (!info.supported) {
        info.error = "The power-profile service did not report a usable profile.";
    }
    return info;
}

bool PowerProfile::set(const std::string& profile, std::string& error) const {
    error.clear();

    const std::string daemon_profile = to_daemon_profile(profile);
    if (daemon_profile.empty()) {
        error = "Unknown power profile requested.";
        return false;
    }

    const auto before = get();
    if (!before.supported) {
        error = before.error.empty()
            ? "Power profiles are not supported."
            : before.error;
        return false;
    }

    if (std::find(before.available.begin(), before.available.end(), profile)
        == before.available.end()) {
        error = "This power profile is not available on this device.";
        return false;
    }

    const auto result = run_command(
        {"powerprofilesctl", "set", daemon_profile});

    if (result.exit_code != 0) {
        error = trim(result.output);
        if (error.empty()) {
            error = "Failed to set the power profile.";
        }
        return false;
    }

    const auto after = get();
    if (!after.supported || after.active != profile) {
        error = after.error.empty()
            ? "The system did not activate the requested power profile."
            : after.error;
        return false;
    }

    return true;
}

}  // namespace origin
