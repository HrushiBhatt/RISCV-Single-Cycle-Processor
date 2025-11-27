# RISC-V Single-Cycle Processor (RV32I) — VHDL

A compact, course-grade CPU that executes a core subset of RV32I in **one cycle per instruction**. The design emphasizes a clean separation between datapath and control, timing-safe interfaces, and a verification flow that compares against RARS reference behavior.  
**Result:** Final course grade for this project: **99.47%**.

---

## Overview
This project implements a single-cycle RISC-V processor in VHDL. Each instruction completes in one clock, trading area and frequency for conceptual clarity. The processor is paired with simple instruction/data memories suitable for simulation, plus self-contained assembly programs used to validate correctness.

**Goals**
- Build a readable, testable RV32I baseline.
- Demonstrate correct control-signal generation and ALU behavior.
- Provide a repeatable simulation flow from assembly → hex → VHDL memory init → waveform/trace checks.

---

## Instruction Set Coverage (RV32I subset)
- **Arithmetic/Logic**: `ADD, SUB, AND, OR, XOR, SLT, SLTU`
- **Shifts**: `SLL, SRL, SRA`
- **Immediate variants**: `ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI`
- **Loads/Stores**: `LW, SW` (others are straightforward to extend)
- **Control-flow**: `BEQ, BNE, BLT, BGE, BLTU, BGEU, JAL, JALR`
- **System**: `LUI, AUIPC` (as needed for tests)

> If a provided program uses instructions outside this set, it can be adapted by RARS or replaced with an equivalent sequence.

---

## Microarchitecture
- **Datapath**: 32-bit regfile (2R/1W), ALU, immediate generation, branch comparator, PC logic, and memory interfaces.
- **Control**: Main control (opcode decode) + ALU control (funct3/funct7 → ALUOp). Signals drive mux selects, mem enables, regfile write, branch/jump decisions.
- **Program Counter**: PC+4 or branch/jump target selected via control; JAL/JALR write return address to `rd`.
- **Memories**: Behavioral instruction/data memories for simulation; initialized from hex files exported by RARS.
- **Timing**: Single-cycle; all effects visible at the end of the clock. No pipeline hazards by construction.

---

## Tooling
- **Assembler/Reference**: **RARS** (RISC-V Assembler and Runtime Simulator)
- **Simulator**: **QuestaSim/ModelSim** (waveform and signal inspection)
- *(Optional)* scripts to convert RARS dumps into hex/mif for memory initialization.

---

## Quick Start — Simulation Workflow
1. **Assemble**  
   Open a test program (e.g., base/control-flow/mergesort) in **RARS**.  
   - Run to confirm behavior on the reference model.  
   - Export instruction and data segments as hex (e.g., `imem.hex`, `dmem.hex`).

2. **Initialize Memories**  
   Point the instruction/data memory VHDL to the exported hex paths (generic map or constant filename).  
   Typical memories support vendor-neutral file reading in an `initialization` process.

3. **Compile & Run (Questa/ModelSim)**
   - Compile VHDL sources and the top-level testbench.
   - `vsim tb_top` and `run -all`, or run for a fixed number of cycles.
   - Observe key signals: `pc`, `instr`, `alu_op/result`, `branch_taken`, `regfile_wen`, `rd`, `rd_data`, memory transactions.

4. **Check Results**  
   - For unit tests, compare register/memory final state to expected values (documented per program).
   - For larger programs (e.g., mergesort), confirm output buffer contents are sorted and termination PC is reached.

---

## Verification Strategy
- **Unit tests**: Focused ALU and branch tests validate opcode → control → ALU mapping and flag behavior.
- **Integration tests**: Base arithmetic, control-flow, and memory tests ensure end-to-end correctness.
- **Program-level tests**: Mergesort or similar validates branches, jumps, loads/stores, and data dependencies at scale.

**Pass Criteria**
- All targeted registers/memory locations match the expected post-execution values.
- No X/undefined values on control lines at active edges.
- PC sequencing matches the architectural definition for taken/not-taken branches and jumps.

---

## Design Notes
- **Control Decoding**: Two-level decode (Main + ALU control) simplifies maintenance as instructions are added.
- **Immediate Generation**: Handles I/S/B/U/J formats with proper sign/zero extension.
- **Branch Decision**: Comparator evaluates signed/unsigned relationships based on `funct3`.
- **Shifts**: Logical and arithmetic variants implemented; immediate and register forms share the same shifter.
- **Memory Model**: Byte-addressed, word-aligned accesses in the baseline; loads/stores constrained to `LW/SW` for simplicity.

---

## Extensibility
- Add remaining RV32I loads/stores (`LB/LH/LBU/LHU`, `SB/SH`), CSR/system ops, and fence as needed.
- Introduce **multi-cycle** or **pipelined** microarchitectures: hazard detection, forwarding, stall/flush control, branch prediction.
- Swap behavioral memories for vendor RAM/IP if targeting synthesis.

---

## Troubleshooting
- **“Added embedded git repository” warning**: a nested `.git/` exists (often inside `src`). Remove it:
  ```bash
  rm -rf src/.git
  git rm -r --cached src
  git add .
  git commit -m "Remove nested git repo"
