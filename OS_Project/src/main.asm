ORG 0x7C00
BITS 16

main:
    ; Set up segments (CS is already 0x0000 by BIOS/bootloader)
    ; Set DS and ES to 0 for addressing
    XOR ax, ax
    MOV ds, ax
    MOV es, ax
    
    ; Set the Stack Segment (SS) to 0 and SP to 0x7C00
    ; A better practice is to use a high memory area for the stack. 
    ; E.g., SS=0x0000, SP=0x7C00 is DANGEROUS, so we use a safe area: 0x9000
    MOV ss, ax
    MOV sp, 0x9000   ; **FIXED: Stack set to a safe address above 0x7C00**
    
    ; Print the message
    MOV si, os_boot_msg
    CALL print
    
halt:
    JMP halt         ; Infinite loop to stop execution

; Subroutine to print a null-terminated string to the screen using BIOS INT 0x10
print:
    PUSH si          ; Save caller's SI
    PUSH ax          ; Save caller's AX
    PUSH bx          ; Save caller's BX

print_loop:
    LODSB            ; Load Byte from [DS:SI] into AL, increment SI
    OR al, al        ; Check if AL is 0 (the null terminator)
    JZ done_print    ; If ZF is set (AL was 0), finished printing

    ; BIOS INT 0x10, Function 0x0E: Teletype Output
    MOV ah, 0x0E     ; AH = function number
    MOV bh, 0x00     ; BH = page number (usually 0)
    INT 0x10         ; Print the character in AL

    JMP print_loop

done_print:
    POP bx
    POP ax
    POP si
    RET              ; Return to caller (main)

os_boot_msg: DB 'Our OS has booted!', 0x0D, 0x0A, 0 ; 0x0D=CR, 0x0A=LF, 0=Null terminator

; Boot signature required by BIOS
TIMES 510 - ($-$$) DB 0
DW 0AA55H