library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;  -- word = std_logic_vector(31 downto 0)

entity RISCV_Processor is
  generic ( N : integer := 32 );
  port (
    iCLK      : in  std_logic;
    iRST      : in  std_logic;

    -- instruction loader (testbench)
    iInstLd   : in  std_logic;
    iInstAddr : in  std_logic_vector(N-1 downto 0);
    iInstExt  : in  std_logic_vector(N-1 downto 0);

    -- debug
    oALUOut   : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture rtl of RISCV_Processor is
  -- Trace pins for toolflow
  signal s_DMemWr    : std_logic := '0';
  signal s_DMemAddr  : word := (others=>'0');
  signal s_DMemData  : word := (others=>'0');
  signal s_RegWr     : std_logic := '0';
  signal s_RegWrAddr : std_logic_vector(4 downto 0) := (others=>'0');
  signal s_RegWrData : word := (others=>'0');
  signal s_Halt      : std_logic := '0';
  signal s_Ovfl      : std_logic := '0';

  -- ALU / control
  signal ALU_Result : std_logic_vector(31 downto 0);
  signal Zero       : std_logic := '0';
  signal SLTflag    : std_logic := '0';
  signal ALUOp      : std_logic_vector(3 downto 0);

  -- PC / fetch
  signal pc_r, next_pc : word := (others=>'0');
  signal instr_f        : word := (others=>'0');
  signal imem_addr_mux  : word;
  signal imem_data_mux  : std_logic_vector(N-1 downto 0);

  -- decode fields
  signal opcode   : std_logic_vector(6 downto 0);
  signal rd       : std_logic_vector(4 downto 0);
  signal rs1      : std_logic_vector(4 downto 0);
  signal rs2      : std_logic_vector(4 downto 0);
  signal funct3   : std_logic_vector(2 downto 0);
  signal funct7   : std_logic_vector(6 downto 0);

  -- control / immediates
  signal imm      : word := (others=>'0');
  signal ALU_Sel  : std_logic_vector(3 downto 0) := (others=>'0');
  signal RegWrite : std_logic := '0';
  signal MemRead  : std_logic := '0';
  signal MemWrite : std_logic := '0';

  -- regfile values
  signal rs1_val, rs2_val : word := (others=>'0');

  -- ALU B operand mux (VHDL-93 safe)
  signal alu_B_in : word := (others=>'0');

  -- Data memory / writeback
  signal dmem_q   : word := (others=>'0');
  signal wb_data  : word := (others=>'0');
  signal wb_rd    : std_logic_vector(4 downto 0) := (others=>'0');
  signal wb_we    : std_logic := '0';
begin
  ----------------------------------------------------------------
  -- Program Counter
  ----------------------------------------------------------------
  process(iCLK, iRST)
  begin
    if iRST = '1' then
      pc_r <= x"00400000";
    elsif rising_edge(iCLK) then
      if s_Halt = '0' then
        pc_r <= next_pc;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Instruction memory (loader mux)
  ----------------------------------------------------------------
  imem_addr_mux <= iInstAddr when iInstLd='1' else pc_r;
  imem_data_mux <= iInstExt  when iInstLd='1' else (others => '0');

  IMem : entity work.mem
    generic map (DATA_WIDTH => N, ADDR_WIDTH => 10)
    port map (
      clk  => iCLK,
      addr => imem_addr_mux,  -- mem slices [ADDR_WIDTH+1:2] internally
      data => imem_data_mux,
      we   => iInstLd,
      q    => instr_f
    );

  ----------------------------------------------------------------
  -- Decode
  ----------------------------------------------------------------
  opcode <= instr_f(6  downto 0);
  rd     <= instr_f(11 downto 7);
  funct3 <= instr_f(14 downto 12);
  rs1    <= instr_f(19 downto 15);
  rs2    <= instr_f(24 downto 20);
  funct7 <= instr_f(31 downto 25);

  u_imm : entity work.imm_gen
    port map (instr => instr_f, imm => imm);

  ----------------------------------------------------------------
  -- Control Unit
  ----------------------------------------------------------------
  u_ctl : entity work.control
    port map (
      opcode   => opcode,
      funct3   => funct3,
      funct7   => funct7,
      ALU_Sel  => ALU_Sel,
      RegWrite => RegWrite,
      MemRead  => MemRead,
      MemWrite => MemWrite,
      Branch   => open,
      ALUOp    => ALUOp
    );

  ----------------------------------------------------------------
  -- Register file
  ----------------------------------------------------------------
  u_rf : entity work.regfile
    port map (
      i_CLK => iCLK,
      i_RST => iRST,
      i_WE  => wb_we,            -- (gated below)
      i_RD  => wb_rd,
      i_D   => wb_data,
      i_RS1 => rs1,
      i_RS2 => rs2,
      o_RS1 => rs1_val,
      o_RS2 => rs2_val
    );

  ----------------------------------------------------------------
  -- ALU operand select (VHDL-93 compatible)
  ----------------------------------------------------------------
  process(opcode, imm, rs2_val)
  begin
    if (opcode = "0010011" or  -- I-type arithmetic
        opcode = "0000011" or  -- LOAD
        opcode = "0100011" or  -- STORE
        opcode = "1100111") then  -- JALR
      alu_B_in <= imm;
    else
      alu_B_in <= rs2_val;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Execute (ALU)
  ----------------------------------------------------------------
  U_ALU : entity work.alu
    port map (
      A        => rs1_val,
      B        => alu_B_in,
      ALUOp    => ALUOp,
      F        => ALU_Result,
      Zero     => Zero,
      SLTflag  => SLTflag
    );

  oALUOut <= ALU_Result;

  ----------------------------------------------------------------
  -- Data memory  (gate WE so no store on the halt cycle)
  ----------------------------------------------------------------
  DMem : entity work.mem
    generic map (DATA_WIDTH => N, ADDR_WIDTH => 10)
    port map (
      clk  => iCLK,
      addr => ALU_Result,
      data => rs2_val,
      we   => (MemWrite and (not s_Halt)),
      q    => dmem_q
    );

  ----------------------------------------------------------------
  -- Next PC
  ----------------------------------------------------------------
  process(pc_r, rs1_val, rs2_val, imm, opcode, funct3, Zero)
    variable pc_plus4  : unsigned(31 downto 0);
    variable pc_branch : unsigned(31 downto 0);
    variable pc_jalr   : unsigned(31 downto 0);
  begin
    pc_plus4  := unsigned(pc_r) + 4;
    pc_branch := unsigned(pc_r) + unsigned(imm);
    pc_jalr   := (unsigned(rs1_val) + unsigned(imm)) and (not to_unsigned(1, 32));

    next_pc   <= std_logic_vector(pc_plus4);  -- default

    if opcode = "1100011" then  -- BRANCH
      case funct3 is
        when "000" => if Zero = '1' then next_pc <= std_logic_vector(pc_branch); end if; -- BEQ
        when "001" => if Zero = '0' then next_pc <= std_logic_vector(pc_branch); end if; -- BNE
        when "100" => if signed(rs1_val) <  signed(rs2_val) then next_pc <= std_logic_vector(pc_branch); end if; -- BLT
        when "101" => if signed(rs1_val) >= signed(rs2_val) then next_pc <= std_logic_vector(pc_branch); end if; -- BGE
        when "110" => if unsigned(rs1_val) <  unsigned(rs2_val) then next_pc <= std_logic_vector(pc_branch); end if; -- BLTU
        when "111" => if unsigned(rs1_val) >= unsigned(rs2_val) then next_pc <= std_logic_vector(pc_branch); end if; -- BGEU
        when others => null;
      end case;
    elsif opcode = "1101111" then       -- JAL
      next_pc <= std_logic_vector(pc_branch);
    elsif opcode = "1100111" then       -- JALR
      next_pc <= std_logic_vector(pc_jalr);
    end if;
  end process;

  ----------------------------------------------------------------
  -- Writeback (gate WE so no RF write on the halt cycle)
  ----------------------------------------------------------------
  wb_rd <= rd;
  wb_we <= RegWrite and (not s_Halt);

  process(opcode, pc_r, imm, dmem_q, ALU_Result)
    variable pc_plus4_v  : unsigned(31 downto 0);
    variable pc_plusimm  : unsigned(31 downto 0);
  begin
    pc_plus4_v := unsigned(pc_r) + 4;
    pc_plusimm := unsigned(pc_r) + unsigned(imm);

    if (opcode = "1101111" or opcode = "1100111") then      -- JAL/JALR
      wb_data <= std_logic_vector(pc_plus4_v);
    elsif (opcode = "0110111") then                          -- LUI
      wb_data <= imm;
    elsif (opcode = "0010111") then                          -- AUIPC
      wb_data <= std_logic_vector(pc_plusimm);
    elsif (opcode = "0000011") then                          -- LOAD
      wb_data <= dmem_q;
    else                                                     -- ALU ops / STORE / BRANCH
      wb_data <= ALU_Result;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Trace pins + HALT detection (ECALL or WFI), masked during reset
  ----------------------------------------------------------------
  s_RegWr     <= wb_we;
  s_RegWrAddr <= wb_rd;
  s_RegWrData <= wb_data;

  s_DMemWr    <= MemWrite and (not s_Halt);
  s_DMemAddr  <= ALU_Result;
  s_DMemData  <= rs2_val;

  s_Ovfl      <= '0';

  -- SYSTEM opcode (1110011), funct3=000; halt on ECALL (funct12=0x000) or WFI (funct12=0x105)
  s_Halt <= '1' when (
              iRST = '0' and
              instr_f(6 downto 0)  = "1110011" and
              instr_f(14 downto 12) = "000" and
              ( instr_f(31 downto 20) = x"000" or    -- ECALL
                instr_f(31 downto 20) = x"105" )     -- WFI
            )
            else '0';
end architecture;