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

    MOV sp, 0x07C00
    MOV si, os_boot_msg
    CALL print
    HLT

halt:
    JMP halt

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

TIMES 510 - ($-$$) DB 0
DW 0AA55H