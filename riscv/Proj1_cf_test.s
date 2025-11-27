# Proj1_cf_test.s
# Tests all control-flow instructions with nested calls

        .text
        .globl _start
_start:
        li   x1, 0
        li   x2, 5
        jal  x0, main

# --- Functions with nested calls ---
main:
        addi x1, x1, 1
        jal  x0, func1
        wfi

func1:
        addi x1, x1, 1
        beq  x1, x2, done
        jal  x0, func2
        jalr x0, 0(t0)

func2:
        addi x1, x1, 1
        bne  x1, x2, func3
        jalr x0, 0(x0)

func3:
        addi x1, x1, 1
        blt  x1, x2, func4
        bge  x1, x2, done

func4:
        addi x1, x1, 1
        bltu x1, x2, func5
        bgeu x1, x2, done

func5:
        addi x1, x1, 1
done:
        wfi
