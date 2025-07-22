; Global Descriptor Table (GDT) definition
gdt_start:
	; Null descriptor (required, not used)
	dq 0x0000000000000000

	; Code segment: base=0, limit=4 GiB, 32-bit, present, DPL=0
	dq 0x00CF9A000000FFFF

	; Data segment: base=0, limit=4 GiB, 32-bit, present, DPL=0
	dq 0x00CF92000000FFFF

gdt_end:

gdt_descriptor:
	dw gdt_end - gdt_start - 1		; Set GDT size (limit = size - 1)
	dd gdt_start					; Set GDT base address

; Protected mode entry point
[SECTION .text]

pm_entry:
	cli								; Disable interrupts
	lgdt [gdt_descriptor]			; Load GDT pointer into GDTR
	mov eax, cr0					; Get current CR0 value
	or eax, 1						; Set PE bit (Protection Enable)
	mov cr0, eax					; Write back to CR0 to enable protected mode
	jmp 0x08:protected_mode			; Far jump to code segment (selector 0x08 in GDT)

; 32-bit code
[BITS 32]
protected_mode:
	mov ax, 0x10					; Set ax to 0x10 (Data Segment selector for GDT)
	mov ds, ax						; Set Data Segment (ds) to 0x10
	mov es, ax						; Set Extra Segment (es) to 0x10
	mov fs, ax						; Set General Purpose F Segment (fs) to 0x10
	mov gs, ax						; Set General Purpose G Segment (gs) to 0x10
	mov ss, ax						; Set Stack Segment (ss) to 0x10
	mov esp, 0x9F000				; Set Extended Stack Pointer (esp) to 0x9F000 (Memory Address for Stack Pointer)

	; TODO: Load next stage or kernel here
	hlt								; Halt CPU (for now)
	jmp $							; Infinite loop to prevent execution past code
