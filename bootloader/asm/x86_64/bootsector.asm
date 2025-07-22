; Minimal 16-bit Real Mode entry for x86_64
BITS 16
ORG 0x7C00				; Address where BIOS loads the boot sector

start:
	cli					; Disable interrupts
	xor ax, ax			; Set ax to 0
	mov ds, ax			; Set Data Segment (ds) to 0
	mov es, ax			; Set Extra Segment (es) to 0
	mov ss, ax			; Set Stack Segment (ss) to 0
	mov sp, 0x7C00		; Set Stack Pointer (sp) to 0x7C00, so stack grows down from boot sector's Address

	call pm_entry		; Call the protected mode entry (defined in protected_mode.asm)
	hlt					; If we return, just hang

; Include code to switch over to 32-bit Protected Mode
%include "protected_mode.asm"

times 510-($-$$) db 0	; Pad to 510 bytes
dw 0xAA55
