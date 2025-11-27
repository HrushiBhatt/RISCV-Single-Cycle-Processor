# Proj1_base_test.s
# Tests every arithmetic and logical instruction at least once

        .text
        .globl _start
_start:
        li   x1, 10
        li   x2, 5

# --- Arithmetic ---
        add  x3, x1, x2        # 15
        sub  x4, x1, x2        # 5
        addi x5, x1, -3        # 7

# --- Logic / bitwise ---
        and  x6, x1, x2        # 0b0101 & 0b1010
        andi x7, x1, 3
        or   x8, x1, x2
        ori  x9, x2, 8
        xor  x10, x1, x2
        xori x11, x1, 12

# --- Shifts ---
        sll  x12, x1, x2       # shift left logical
        slli x13, x1, 2
        srl  x14, x1, x2       # shift right logical
        srli x15, x1, 1
        sra  x16, x1, x2       # shift right arithmetic
        srai x17, x1, 1

# --- Compare / set ---
        slt  x18, x2, x1
        slti x19, x1, 20
        sltiu x20, x1, 20
        lui  x21, 0x10010
        auipc x22, 0x10000

# --- Memory ---
        la   x23, array
        sw   x1, 0(x23)
        lw   x24, 0(x23)
        lb   x25, 0(x23)
        lh   x26, 0(x23)
        lbu  x27, 0(x23)
        lhu  x28, 0(x23)
        slli x29, x1, 0         # nop filler
        wfi                    # halt

.data
array:  .word 0
