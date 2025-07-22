# RustFoundryOS
Developer-first OS built in Rust

# How to build and run this project
If you are interested in building/running this project locally, follow these steps:

**Note:** These instructions were written using Ubuntu on WSL2.
- Run this command in your terminal:
  - `git clone https://github.com/XalorTech/RustFoundryOS.git`
- In terminal, navigate to the root of the project.
  - `cd RustFoundryOS`
- To see available targets and options for `make`, run `make help`.
  - You should see the following or similar:

```
Usage: make [TARGET] [VARIABLE=value]...

Targets:
  help     Show this message
  all      Clean, build, and run (default if no target)
  clean    Remove all build artifacts
  build    Assemble bootsectors for $ARCHS
  run      Launch QEMU for $ARCHS

Variables (override with VAR=value):
  ARCHS    Architectures to process (default: x86_64 aarch64)
  DEBUG    true to enable QEMU debug flags (default: false)

Examples:
  make build ARCHS=x86_64            # build only x86_64
  make run ARCHS=aarch64 DEBUG=true  # run aarch64 in debug mode
```

- The currently supported targets and variables supported will be listed in the command, such as they are above.
  - **Note:** While the default is `x86_64 aarch64`, this will currently FAIL. Only the `x86_64` ARCH has been set up thus far, and that only partially. Currently, it will load in 16-bit Real Mode and then raise the system to 32-bit Protected Mode. I will be adding code to then bring the system up to 64-bit Long Mode prior to handing off control to my 64-bit Rust bootloader, which will handle loading the kernel. Once the x86_64 code can successfully call the Rust bootloader, I will focus on adding support for aarch64.
