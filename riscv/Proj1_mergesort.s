# ============================================================
# Proj1_mergesort.s
# Iterative bottom-up Merge Sort (RV32I compatible)
# ============================================================

.data
array:  .word 5, 3, 8, 1         # initial array
temp:   .space 16                # temporary buffer (same size)
n:      .word 4                  # array length

.text
.globl _start
_start:
    # --------------------------------------------------------
    # Initialization
    # --------------------------------------------------------
    la   s0, array               # s0 = base address of array (A)
    la   s1, temp                # s1 = base address of temp (B)
    lw   s2, n                   # s2 = n (length)
    addi s3, x0, 1               # s3 = width = 1

# ============================================================
# Outer pass: for width = 1, 2, 4, 8, ...
# ============================================================
outer_pass:
    blt  s3, s2, merge_pass      # if width < n, do merge pass
    j    done                    # else finished

# ============================================================
# Merge pass: merge runs of size 'width'
# ============================================================
merge_pass:
    addi s4, x0, 0               # s4 = i = 0  (offset in bytes)

merge_loop:
    # If i >= n*4, exit this merge pass
    slli t0, s2, 2               # n * 4
    bge  s4, t0, copy_back

    # left = A + i
    add  t1, s0, s4

    # mid = left + width*4
    slli t2, s3, 2
    add  t2, t1, t2

    # right = mid + width*4
    slli t3, s3, 3               # (2*width)*4
    add  t3, t1, t3

    # Clamp right = min(right, A + n*4)
    add  t4, s0, t0
    blt  t4, t3, skip_clamp
    mv   t3, t4
skip_clamp:

    # Call merge(A, mid, right, B)
    mv   a0, t1                  # left pointer (src1)
    mv   a1, t2                  # mid pointer (src2)
    mv   a2, t3                  # right pointer (end)
    mv   a3, s1                  # dest pointer (temp)
    jal  ra, merge

    # Advance i += 2*width*4
    slli t5, s3, 3
    add  s4, s4, t5
    j    merge_loop

# ============================================================
# Copy back: temp -> array
# ============================================================
copy_back:
    addi t0, x0, 0
copy_loop:
    bge  t0, s2, next_width
    slli t1, t0, 2
    add  t2, s1, t1
    add  t3, s0, t1
    lw   t4, 0(t2)
    sw   t4, 0(t3)
    addi t0, t0, 1
    j    copy_loop

# ============================================================
# width *= 2 and repeat
# ============================================================
next_width:
    slli s3, s3, 1
    j    outer_pass

# ============================================================
# Merge subroutine
#   merge(A[left..mid), A[mid..right), temp)
# ============================================================
merge:
    mv   t0, a0          # left ptr
    mv   t1, a1          # mid ptr
    mv   t2, a2          # right ptr
    mv   t3, a3          # dest ptr

merge_loop_body:
    # If left >= mid or right >= end, break
    bge  t0, t1, right_remaining
    bge  t1, t2, left_remaining

    lw   t4, 0(t0)       # val_left
    lw   t5, 0(t1)       # val_right
    ble  t4, t5, take_left

take_right:
    sw   t5, 0(t3)
    addi t1, t1, 4
    addi t3, t3, 4
    j    merge_loop_body

take_left:
    sw   t4, 0(t3)
    addi t0, t0, 4
    addi t3, t3, 4
    j    merge_loop_body

# Left run remaining
left_remaining:
    bge  t0, t1, right_remaining
left_copy:
    bge  t0, t1, right_remaining
    lw   t4, 0(t0)
    sw   t4, 0(t3)
    addi t0, t0, 4
    addi t3, t3, 4
    j    left_copy

# Right run remaining
right_remaining:
    bge  t1, t2, merge_done
right_copy:
    bge  t1, t2, merge_done
    lw   t5, 0(t1)
    sw   t5, 0(t3)
    addi t1, t1, 4
    addi t3, t3, 4
    j    right_copy

merge_done:
    jr   ra

# ============================================================
# Done
# ============================================================
done:
    wfi
