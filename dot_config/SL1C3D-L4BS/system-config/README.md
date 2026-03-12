# SL1C3D-L4BS system config

Branded, speed-tuned configs for Arch. Apply with the install scripts (sudo).

## TTY autologin (tty1)

- **the_architect** logs in automatically on VT1.
- Run: `./install-getty-autologin.sh` then reboot.

## pacman (speed + branding)

- **Color**, **ILoveCandy**, **ParallelDownloads = 10**, **VerbosePkgLists**.
- Backs up existing `/etc/pacman.conf` before overwrite.
- Run: `./install-pacman-conf.sh`

## Mirror speed (reflector)

Install reflector, then rank mirrors by speed:

```bash
sudo pacman -S reflector
# one-shot: fastest 10 US mirrors, save to mirrorlist
sudo reflector --country US --age 12 --protocol https --sort rate -n 10 --save /etc/pacman.d/mirrorlist
```

Optional: enable `reflector.timer` for weekly updates:

```bash
sudo systemctl enable --now reflector.timer
```

## Kernel/sysctl tuning

- TCP buffers, TCP Fast Open, lower swappiness, more inotify watches.
- Run: `./install-sysctl.sh`

## makepkg (optional)

For faster AUR builds, set parallel jobs in `/etc/makepkg.conf`:

```bash
# uncomment and set, e.g.:
MAKEFLAGS="-j$(nproc)"
```

Optional: enable **ccache** in `BUILDENV` in the same file (change `!ccache` to `ccache`) for repeated builds.

## Dev stack (2026 elite: JS/TS, Python, Go, Rust, C/C++, Java, .NET, containers, AI)

One-shot install of npm, pip/pipx/uv, deno, Docker, kubectl, Terraform, dotnet-sdk, OpenJDK 17, PHP, Ruby, Zig, C/C++ (gcc, clang, cmake, base-devel), plus AUR: ollama-bin. (bun is in extra and installs with pacman if needed.)

```bash
chmod +x install-dev-stack.sh
./install-dev-stack.sh
```

After install, add your user to the `docker` group to run containers without sudo: `sudo usermod -aG docker $USER` (then log out and back in).

## Install all (except pacman.conf backup)

From this directory:

```bash
chmod +x install-*.sh
./install-getty-autologin.sh
./install-pacman-conf.sh
./install-sysctl.sh
```
