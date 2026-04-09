ORG 0x7C00
BITS 16

JMP SHORT main
NOP

; --- BIOS Parameter Block (BPB) ---
bdb_oem:         DB     'MSWIN4.1'
bdb_bytes_per_sector:    DW  512
bdb_sector_per_cluster:  DB 1
bdb_reserved_sectors:    DW 1
bdb_fat_count:           DB 2
bdb_dir_entries_count:   DW 0E0h
bdb_total_sectors:       DW 2880
bdb_media_descriptor_type: DB 0F0h ; FIX: Changed hyphen to underscore
bdb_sectors_per_fat:     DW 9
bdb_sectors_per_track:   DW 18
bdb_heads:               DW 2
bdb_hidden_sectors:      DD 0 ; FIX: Corrected typo 'hiddern' to 'hidden'
bdb_large_sector_count:  DD 0

; --- Extended BIOS Parameter Block (EBR) ---
ebr_drive_number:   DB 0
                    DB 0
ebr_signature:      DB 29h ; FIX: Added colon
ebr_volume_id:      DB 12h, 34h, 56h, 78h
ebr_volume_label:   DB 'PAX OS     '
ebr_system_id:      DB 'FAT12   '

main:
    ; Setup Segments
    MOV ax, 0
    MOV ds, ax
    MOV es, ax
    MOV ss, ax
   
    ; CRITICAL FIX: Set stack to safe area above 0x7C00
    MOV sp, 0x9000

    ; Store drive number passed by BIOS in DL
    MOV [ebr_drive_number], dl 
 
    ; Prepare disk read parameters
    MOV ax, 1 ; LBA index to read (Sector 1, which is the first FAT sector)
    MOV cl, 1 ; Number of sectors to read
    MOV bx, 0x7E00 ; FIX: Changed bc to bx. Load buffer address
    call disk_read

    MOV si, os_boot_msg
    CALL print

    ;4 segments
    ;reserved segments: 1 sector
    ;FAT: 9*2 = 18 sectors
    ;root directory: starting at the 19th sector
    ;Data

    MOV ax, [bdb_sectors_per_track]
    MOV bl, [bdb_fat_count]
    XOR bh,bh
    MUL bx
    ADD ax, [bdb_reserved_sectors] ;LBA of the root directory
    PUSH ax

    MOV ax, [bdb_dir_entries_count]
    SHL ax,5 ;ax *=32
    XOR dx,dx
    DIV word [bdb_bytes_per_sector] ; (32*num of entries)/bytes per sector
    
    TEST dx, dx
    JZ rootDirAfter
    INC ax

rootDirAfter:
    MOV cl, al
    POP ax
    MOV dl, [ebr_drive_number]
    MOV bx, buffer
    CALL disk_read

    XOR bx, bx
    MOV di, buffer

searchKernel:
    MOV si, file_kernel_bin
    MOV cx, 11
    PUSH di
    REPE CMPSB
    POP di
    JE foundKernel
    
    ADD di, 32
    INC bx
    CMP bx, [bdb_dir_entries_count]
    JL searchKernel

    JMP kernelNotFound

kernelNotFound:
    MOV si, msg_kernel_not_found
    CALL print

    HLT
    JMP halt

foundKernel:
    MOV ax, [di+26]
    MOV [kernel_cluster], ax
    MOV ax, [bdb_reserved_sectors]
    MOV bx, buffer
    MOV cl, [bdb_sectors_per_fat]
    MOV dl, [ebr_drive_number]

    CALL disk_read
    MOV bx, kernel_load_segment
    MOV es,bx 
    MOV bx, kernel_load_offset

loadKernelLoop:
    MOV ax, [kernel_cluster]
    ADD ax, 31
    MOV cl, 1
    MOV dl, [ebr_drive_number]

    CALL disk_read

    ADD bx, [bdb_bytes_per_sector]

    MOV ax, [kernel_cluster]; (kernel cluster * 3)/ 2
    MOV cx, 3
    MUL cx,
    MOV cx, 2
    DIV cx, 

    MOV si, buffer
    ADD si, ax
    MOV ax, [ds:si]

    OR dx, dx
    JZ even 

odd:
    SHR ax, 4
    JMP nextClusterAfter

even:
    AND ax, 0x0FFF

nextClusterAfter:
    CMP ax, 0x0FF8
    JAE readFinish

    MOV [kernel_cluster], ax
    JMP loadKernelLoop

readFinish:
    MOV dl, [ebr_drive_number]
    MOV ax, kernel_load_segment
    MOV ds,ax
    MOV es,ax

    JMP kernel_load_segment: kernel_load_offset

halt:
    JMP halt
    

; --- LBA to CHS Conversion ---
; input: LBA index in AX
; output: CX (Sector/Cylinder), DH (Head), DL (Drive number, preserved from ebr_drive_number)
lba_to_chs:
    PUSH ax
    PUSH dx

    XOR dx, dx
    DIV word [bdb_sectors_per_track] ; AX = LBA / SPT, DX = LBA % SPT
    INC dl          ; DL = (LBA % SPT) + 1 = Sector (1-based)
    MOV cx, dx      ; CL = Sector number

    XOR dx, dx
    DIV word [bdb_heads]  ; AX = (LBA/SPT) / Heads, DX = (LBA/SPT) % Heads

    MOV dh, dl ; DH = Head number
    MOV ch, al  ; CH = Cylinder low bits
    SHL ah, 6
    OR CL, AH ; CL: Set cylinder high bits

    POP dx ; Restore DL drive number (partially)
    MOV dl, [ebr_drive_number]  ; Load drive number back into DL
    POP ax

    RET


disk_read:
    PUSH ax
    PUSH bx
    PUSH cx
    PUSH dx
    PUSH di

    call lba_to_chs ; Converts LBA in AX to CHS in CX:DH:DL

    MOV ah, 02h   ; AH = BIOS Read Sector Function
    MOV al, cl    ; AL = Number of sectors to read (from caller CL)

    ; BX already set by caller (ES:BX is the destination buffer)

    MOV di, 3 ; Retry counter

retry:
    INT 13h                  ; Call BIOS Disk I/O
    jc read_error            ; JC means CF is set (Error occurred)
    jnc done_read

read_error:             ; Handle disk error
    call diskReset      ; Reset disk controller

    DEC di
    JNZ retry           ; Retry if counter > 0


failDiskRead:
    MOV si, read_failure
    CALL print
    HLT; Stop here after error message

diskReset:
    Push ax ; Only need to push/pop modified registers
    MOV ah, 0; AH = BIOS Disk Reset Function
    INT 13h
    JC failDiskRead  ; If reset fails, jump to fatal error
    Pop ax
    RET

done_read:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret

; --- Print Subroutine ---
print:          ; FIX: Added colon to label
    PUSH si
    PUSH ax
    PUSH bx

print_loop:     ; FIX: Used valid label name
    LODSB
    OR al, al
    JZ done_print

    MOV ah, 0x0E
    MOV bh, 0
    INT 0x10

    JMP print_loop

done_print:
    POP bx
    POP ax
    POP si
    RET

os_boot_msg: DB 'Our OS has booted!', 0x0D, 0x0A, 0 
read_failure DB 'Failed to read disk!', 0x0D, 0x0A, 0
file_kernel_bin DB 'KERNEL  BIN'
msg_kernel_not_found DB 'KERNEL.BIN not found!'
kernel_cluster DW 0

kernel_load_segment EQU 0x2000
kernel_load_offset EQU 0

TIMES 510 - ($-$$) DB 0
DW 0AA55H

buffer: 