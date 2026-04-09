ORG 0x7C00
BITS 16

JMP SHORT main
NOP

bdb_oem:            DB      'MSWIN4.1'
bdb_bytes_per_sector:    DW  512
bdb_sector_per_cluster:  DB 1
bdb_reserved_sectors:    DW 1
bdb_fat_count:           DB 2
bdb_dir_entries_count:   DW 0E0h
bdb_total_sectors:       DW 2880
bdb_media-descriptor_type:   DB 0F0h
bdb_sectors_per_fat:     DW 9
bdb_sectors_per_track:   DW 18
bdb_heads:               DW 2
bdb_hiddern_sectors:     DD 0
bdb_large_sector_count:  DD 0

ebr_drive_number:   DB 0
                    DB 0
ebr_signature       DB 29h
ebr_volume_id:      DB 12h, 34h, 56h, 78h
ebr_volume_label:   DB 'PAX OS     '
ebr_system_id:      DB 'FAT12   '

main:
    MOV ax, 0
    MOV ds, ax
    MOV es, ax
    MOV ss, ax
    MOV sp, 0x7C00

    MOV [ebr_drive_number], dl
    MOV ax, 1
    MOV cl, 1
    MOV bc, 0x7E00
    call disk_read

    MOV si, os_boot_msg
    CALL print
    HLT

halt:
    JMP halt

;input: LBA index in ax
;cx [bits 0-5]: sector number
;cx [bits 6-15]: cyliner
;dx: heads
lba_to_chs:
    PUSH ax
    PUSH dx

    XOR dx, dx
    DIV word [bdb_sectors_per_track] ; (LBA % sectors per track) + 1 <- sector
    INC dx ; sector
    MOV cx, dx

    XOR dx, dx
    DIV word [bdb_heads]

    MOV dh, dl ; head
    MOV ch, al
    SHL ah, 6
    OR CL, AH ; cylinder

    ;head (LBA / sectors per track) % number of heads
    ;cylinder: (LBA / sectors per track) / number of heads

    POP ax
    MOV dl, al
    POP ax

    RET

lba_to_chs:


disk_read:
    PUSH ax
    PUSH bx
    PUSH cx
    PUSH dx
    PUSH di

    call lba_to_chs

    MOV ah, 02h
    MOV di, 3   ;counter

retry:
    STC
    INT 13h
    jnc doneRead

    call diskReset

    DEC di
    TEST di, di
    JNZ retry
    

failDiskRead:
    MOV si, read_failure
    CALL print
    HLT
    JMP halt

diskReset:
    Pusha
    MOV ah, 0
    STC
    INT 13h
    JC failDiskRead
    POPA
    RET

doneRead:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    
    ret

print
    PUSH si
    PUSH ax
    PUSH bx

print loop:
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
TIMES 510 - ($-$$) DB 0
DW 0AA55H