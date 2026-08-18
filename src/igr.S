

#include "defines.h"

.globl igr_reboot
.globl igr_hold
#define MENU_STAGE_PI   0x12000000
#define MENU_STAGE_UNC  0xB2000000
#define DEST_PI         0x10000000
#define SCRATCH_DRAM    0x00300000
#define MENU_COPY_SIZE  0x00100000
#define ROM_MAGIC       0x80371240

.data

.align 4
igr_hold: .word 0

.align 4
igr_imem_stub:
    .word 0x3C0DBFC0, 0x8DA807FC, 0x25AD07C0, 0x31080080
    .word 0x5500FFFC, 0x3C0DBFC0, 0x8DA80024, 0x3C0BB000

.text
.set noreorder
.macro PIW
    lui  t2, 0xA460
    li   t4, 100000
piw\@:
    lw   t3, 0x0010(t2)
    andi t3, t3, 3
    beqz t3, piwd\@
    addi t4, t4, -1
    bnez t4, piw\@
    nop
piwd\@:
.endm
.align 5
igr_ccmd:
    lui  t0, 0xBFFF
    PIW
    sw   zero, 0x0010(t0)
    PIW
    li   t1, 0x5F554E4C
    sw   t1, 0x0010(t0)
    PIW
    li   t1, 0x4F434B5F
    sw   t1, 0x0010(t0)
    PIW
    sw   a0, 0x0004(t0)
    PIW
    sw   a1, 0x0008(t0)
    PIW
    li   t1, 0x43
    sw   t1, 0x0000(t0)
    li   t7, 2000000
ccmd_busy:
    lw   t1, 0x0000(t0)
    srl  t1, t1, 31
    beqz t1, ccmd_done
    addi t7, t7, -1
    bnez t7, ccmd_busy
    nop
ccmd_done:
    jr   ra
    nop

.align 5
igr_reboot:
    lui  t0, 0xA404
    li   t1, 0x00000002
    sw   t1, 0x0010(t0)
    li   t2, 2000000
rsp_halt:
    lw   t1, 0x0010(t0)
    andi t1, t1, 1
    bnez t1, rsp_halted
    addi t2, t2, -1
    bnez t2, rsp_halt
    nop
rsp_halted:
    li   t1, 0x00AAAAAE
    sw   t1, 0x0010(t0)
    sw   zero, 0x001C(t0)
    lui  t1, 0xA408
    sw   zero, 0x0000(t1)
    li   t2, 2000000
rsp_dma:
    lw   t1, 0x0018(t0)
    andi t1, t1, 1
    beqz t1, rsp_done
    addi t2, t2, -1
    bnez t2, rsp_dma
    nop
rsp_done:
    lui  t0, 0xA410
    lw   t1, 0x000C(t0)
    andi t1, t1, 1
    beqz t1, rdp_done
    nop
    li   t2, 2000000
rdp_wait:
    lw   t1, 0x000C(t0)
    andi t1, t1, 0x20
    beqz t1, rdp_done
    addi t2, t2, -1
    bnez t2, rdp_wait
    nop
rdp_done:
    lui  t0, %hi(MENU_STAGE_UNC)
    lw   t0, %lo(MENU_STAGE_UNC)(t0)
    lui  t1, %hi(ROM_MAGIC)
    ori  t1, t1, %lo(ROM_MAGIC)
    bne  t0, t1, do_quiesce
    nop

    li   a0, 1
    jal  igr_ccmd
    li   a1, 1
    li   t7, 0
menu_copy:
    lui  t0, 0xA460
    li   t1, SCRATCH_DRAM
    sw   t1, 0x0000(t0)
    lui  t1, %hi(MENU_STAGE_PI)
    addu t1, t1, t7
    sw   t1, 0x0004(t0)
    li   t1, 0x0000FFFF
    sw   t1, 0x000C(t0)
    li   t2, 2000000
c2r_wait:
    lw   t1, 0x0010(t0)
    andi t1, t1, 3
    beqz t1, c2r_done
    addi t2, t2, -1
    bnez t2, c2r_wait
    nop
c2r_done:
    li   t1, SCRATCH_DRAM
    sw   t1, 0x0000(t0)
    lui  t1, %hi(DEST_PI)
    addu t1, t1, t7
    sw   t1, 0x0004(t0)
    li   t1, 0x0000FFFF
    sw   t1, 0x0008(t0)
    li   t2, 2000000
r2c_wait:
    lw   t1, 0x0010(t0)
    andi t1, t1, 3
    beqz t1, r2c_done
    addi t2, t2, -1
    bnez t2, r2c_wait
    nop
r2c_done:
    lui  t1, 0x0001
    addu t7, t7, t1
    lui  t1, %hi(MENU_COPY_SIZE)
    bne  t7, t1, menu_copy
    nop
    li   a0, 1
    jal  igr_ccmd
    move a1, zero

do_quiesce:
    lui  t0, 0xA410
    li   t1, 0x00000015
    sw   t1, 0x000C(t0)
    lui  t0, 0xA460
    li   t1, 0x00000003
    sw   t1, 0x0010(t0)
    lui  t0, 0xA440
    li   t2, 2000000
vi_line:
    lw   t1, 0x0010(t0)
    andi t1, t1, 0x03FE
    beqz t1, vi_ready
    addi t2, t2, -1
    bnez t2, vi_line
    nop
vi_ready:
    li   t1, 0x000003FF
    sw   t1, 0x000C(t0)
    sw   zero, 0x0024(t0)
    sw   zero, 0x0010(t0)
    lui  t0, 0xA450
    sw   zero, 0x0000(t0)
    sw   zero, 0x0004(t0)
    lui  t0, 0xA480
    li   t2, 2000000
si_idle:
    lw   t1, 0x0018(t0)
    andi t1, t1, 3
    beqz t1, si_done
    addi t2, t2, -1
    bnez t2, si_idle
    nop
si_done:
    lui  t0, 0xA000
    sw   zero, 0x030C(t0)
    lw   t2, 0x0318(t0)
    sw   t2, 0x0318(t0)
    sw   t2, 0x03F0(t0)
    li   t4, 0
dmem_clr:
    lui  t5, 0xA400
    addu t5, t5, t4
    sw   zero, 0(t5)
    addi t4, t4, 4
    slti t6, t4, 0x40
    bnez t6, dmem_clr
    nop
    li   t7, 0x40
ipl3_cpy:
    lui  t5, 0xB000
    addu t5, t5, t7
    lw   t6, 0(t5)
    lui  t5, 0xA400
    addu t5, t5, t7
    sw   t6, 0(t5)
    addi t7, t7, 4
    slti t5, t7, 0x1000
    bnez t5, ipl3_cpy
    nop
    lui  t3, 0xA400
    ori  t3, t3, 0x1000
    la   t7, igr_imem_stub
    li   t4, 0
imem_stub:
    addu t5, t7, t4
    lw   t6, 0(t5)
    addu t5, t3, t4
    sw   t6, 0(t5)
    addi t4, t4, 4
    slti t5, t4, 32
    bnez t5, imem_stub
    nop
imem_zero:
    addu t5, t3, t4
    sw   zero, 0(t5)
    addi t4, t4, 4
    slti t5, t4, 0x1000
    bnez t5, imem_zero
    nop
    lui  t0, 0xBFC0
    ori  t0, t0, 0x07E4
    li   t1, 0x00003F3F
    sw   t1, 0(t0)
    lui  t0, 0x8000
    ori  t1, t0, 0x2000
dflush:
    cache 0x01, 0(t0)
    addiu t0, t0, 16
    bne  t0, t1, dflush
    nop
    lui  t0, 0x8000
    ori  t1, t0, 0x4000
iflush:
    cache 0x00, 0(t0)
    addiu t0, t0, 32
    bne  t0, t1, iflush
    nop
    lui  s4, 0xA000
    lw   s4, 0x0300(s4)
    li   s6, 0x3F
    .set noat
    li   t0, 0x34000000
    mtc0 t0, $12
    move v0, zero
    move v1, zero
    move a0, zero
    move a1, zero
    move a2, zero
    move a3, zero
    move t0, zero
    move t1, zero
    move t2, zero
    li   t3, 0xA4000040
    move t4, zero
    move t5, zero
    move t6, zero
    move t7, zero
    move t8, zero
    move t9, zero
    move s0, zero
    move s1, zero
    move s2, zero
    move s3, zero
    move s5, zero
    move s7, zero
    move s8, zero
    move gp, zero
    move k0, zero
    move k1, zero
    li   sp, 0xA4001FF0
    li   ra, 0xA4001550
    bnez s4, ipl3_go
    nop
    li   ra, 0xA4001554
ipl3_go:
    move $1, zero
    jr   t3
    nop
    .set at
