#include "instance_guard.h"

#include <dirent.h>
#include <errno.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <chrono>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

namespace {

constexpr int kTerminateTimeoutMs = 5000;
constexpr int kTerminatePollMs = 100;

struct FileIdentity {
  dev_t device = 0;
  ino_t inode = 0;
  std::string path;
  bool valid = false;
};

std::string read_link(const std::string &path) {
  std::vector<char> buffer(4096);
  while (true) {
    const ssize_t length = readlink(path.c_str(), buffer.data(), buffer.size());
    if (length < 0) {
      return std::string();
    }
    if (static_cast<size_t>(length) < buffer.size()) {
      return std::string(buffer.data(), static_cast<size_t>(length));
    }
    buffer.resize(buffer.size() * 2);
  }
}

bool stat_identity(const std::string &path, FileIdentity *identity) {
  struct stat st{};
  if (path.empty() || stat(path.c_str(), &st) != 0) {
    return false;
  }
  identity->device = st.st_dev;
  identity->inode = st.st_ino;
  identity->path = path;
  identity->valid = true;
  return true;
}

std::string basename_of(const std::string &path) {
  const size_t slash = path.find_last_of('/');
  if (slash == std::string::npos) {
    return path;
  }
  return path.substr(slash + 1);
}

std::string read_file(const std::string &path) {
  std::ifstream file(path, std::ios::in | std::ios::binary);
  if (!file) {
    return std::string();
  }
  return std::string(std::istreambuf_iterator<char>(file),
                     std::istreambuf_iterator<char>());
}

std::string environ_value(const std::string &environ, const std::string &key) {
  size_t start = 0;
  const std::string prefix = key + "=";
  while (start < environ.size()) {
    const size_t end = environ.find('\0', start);
    const size_t length =
        (end == std::string::npos) ? environ.size() - start : end - start;
    if (length >= prefix.size() &&
        environ.compare(start, prefix.size(), prefix) == 0) {
      return environ.substr(start + prefix.size(), length - prefix.size());
    }
    if (end == std::string::npos) {
      break;
    }
    start = end + 1;
  }
  return std::string();
}

std::string current_appimage_path() {
  const char *appimage = std::getenv("APPIMAGE");
  if (appimage == nullptr) {
    return std::string();
  }
  return std::string(appimage);
}

FileIdentity launch_identity_for_pid(pid_t pid) {
  FileIdentity identity;
  const std::string proc = "/proc/" + std::to_string(pid);
  const std::string environ = read_file(proc + "/environ");
  const std::string appimage = environ_value(environ, "APPIMAGE");
  if (stat_identity(appimage, &identity)) {
    return identity;
  }
  stat_identity(proc + "/exe", &identity);
  return identity;
}

FileIdentity current_launch_identity() {
  FileIdentity identity;
  if (stat_identity(current_appimage_path(), &identity)) {
    return identity;
  }
  stat_identity("/proc/self/exe", &identity);
  return identity;
}

bool same_identity(const FileIdentity &a, const FileIdentity &b) {
  return a.valid && b.valid && a.device == b.device && a.inode == b.inode;
}

bool process_exists(pid_t pid) {
  if (kill(pid, 0) == 0) {
    return true;
  }
  return errno == EPERM;
}

bool is_zombie(pid_t pid) {
  const std::string status =
      read_file("/proc/" + std::to_string(pid) + "/stat");
  const size_t close = status.rfind(')');
  if (close == std::string::npos || close + 2 >= status.size()) {
    return false;
  }
  return status[close + 2] == 'Z';
}

bool wait_for_exit(pid_t pid, int timeout_ms) {
  const auto deadline =
      std::chrono::steady_clock::now() + std::chrono::milliseconds(timeout_ms);
  while (std::chrono::steady_clock::now() < deadline) {
    if (!process_exists(pid) || is_zombie(pid)) {
      return true;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(kTerminatePollMs));
  }
  return !process_exists(pid) || is_zombie(pid);
}

bool terminate_process(pid_t pid, std::string *error) {
  if (kill(pid, SIGTERM) != 0 && errno != ESRCH) {
    *error = "failed to terminate pid " + std::to_string(pid) + ": " +
             std::strerror(errno);
    return false;
  }
  if (wait_for_exit(pid, kTerminateTimeoutMs)) {
    return true;
  }
  if (kill(pid, SIGKILL) != 0 && errno != ESRCH) {
    *error = "failed to kill pid " + std::to_string(pid) + ": " +
             std::strerror(errno);
    return false;
  }
  if (!wait_for_exit(pid, kTerminateTimeoutMs)) {
    *error = "pid " + std::to_string(pid) + " did not exit after SIGKILL";
    return false;
  }
  return true;
}

bool is_digits(const char *text) {
  if (text == nullptr || *text == '\0') {
    return false;
  }
  for (const char *cursor = text; *cursor != '\0'; ++cursor) {
    if (*cursor < '0' || *cursor > '9') {
      return false;
    }
  }
  return true;
}

bool process_owned_by_uid(pid_t pid, uid_t uid) {
  struct stat st {};
  const std::string proc = "/proc/" + std::to_string(pid);
  if (stat(proc.c_str(), &st) != 0) {
    return false;
  }
  return st.st_uid == uid;
}

bool is_candidate_process(pid_t pid, const std::string &current_exe_name,
                          const std::string &current_appimage_name) {
  const std::string proc = "/proc/" + std::to_string(pid);
  const std::string exe = read_link(proc + "/exe");
  if (!exe.empty() && basename_of(exe) == current_exe_name) {
    return true;
  }

  const std::string environ = read_file(proc + "/environ");
  const std::string appimage = environ_value(environ, "APPIMAGE");
  if (!current_appimage_name.empty() &&
      basename_of(appimage) == current_appimage_name) {
    return true;
  }

  return false;
}

} // namespace

bool fluent_lyrics_prepare_instance(std::string *error) {
  const pid_t self = getpid();
  const uid_t current_uid = getuid();
  const std::string current_exe = read_link("/proc/self/exe");
  const std::string current_exe_name = basename_of(current_exe);
  const std::string current_appimage_name =
      basename_of(current_appimage_path());
  const FileIdentity current_identity = current_launch_identity();

  if (!current_identity.valid) {
    *error = "failed to resolve current executable identity";
    return false;
  }

  DIR *proc_dir = opendir("/proc");
  if (proc_dir == nullptr) {
    *error = std::string("failed to open /proc: ") + std::strerror(errno);
    return false;
  }

  while (dirent *entry = readdir(proc_dir)) {
    if (!is_digits(entry->d_name)) {
      continue;
    }
    const pid_t pid =
        static_cast<pid_t>(std::strtol(entry->d_name, nullptr, 10));
    if (pid <= 0 || pid == self) {
      continue;
    }
    if (!process_owned_by_uid(pid, current_uid)) {
      continue;
    }
    if (!is_candidate_process(pid, current_exe_name, current_appimage_name)) {
      continue;
    }

    const FileIdentity existing_identity = launch_identity_for_pid(pid);
    if (!existing_identity.valid ||
        same_identity(current_identity, existing_identity)) {
      continue;
    }

    if (!terminate_process(pid, error)) {
      closedir(proc_dir);
      return false;
    }
  }

  closedir(proc_dir);
  return true;
}
