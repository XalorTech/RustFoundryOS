#![no_std]
#![no_main]

extern crate kernel;

use core::panic::PanicInfo;

/// Bootloader entry point
#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    // Bootloader logic will go here...
    
    // Load Kernel to start OS
    kernel::kernel_main()
}

/// Panic handler: gets invoked on `panic!()`
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    // Example: you could write the panic message over serial or VGA.
    // For now, we just spin forever.
    //
    // If you had a `serial_println!()`, you might do:
    // serial_println!("PANIC: {}", info);

    loop {}
}
