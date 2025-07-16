#![no_std]

/// Kernel entry point, called by bootloader
#[unsafe(no_mangle)]
pub extern "C" fn kernel_main() -> ! {
    loop {}
}