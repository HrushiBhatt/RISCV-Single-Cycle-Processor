library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  port (
    A, B     : in  std_logic_vector(31 downto 0);
    ALUOp    : in  std_logic_vector(3 downto 0);
    F        : out std_logic_vector(31 downto 0);
    Zero     : out std_logic;
    SLTflag  : out std_logic
  );
end entity;

architecture rtl of alu is
  component barrel_shifter
    port(
      A        : in  std_logic_vector(31 downto 0);
      shamt    : in  std_logic_vector(4 downto 0);
      dir_left : in  std_logic;
      arith    : in  std_logic;
      Y        : out std_logic_vector(31 downto 0)
    );
  end component;

  signal shamt     : std_logic_vector(4 downto 0);
  signal dir_left  : std_logic;
  signal arith     : std_logic;
  signal shift_out : std_logic_vector(31 downto 0);

  signal aS, bS : signed(31 downto 0);
  signal addsub : signed(31 downto 0);

  signal and_res, or_res, xor_res, nor_res : std_logic_vector(31 downto 0);
  signal slt_s, slt_u : std_logic;
  signal msbA, msbB, msbS, ovf : std_logic;

begin
  aS <= signed(A); bS <= signed(B);
  and_res <= A and B;
  or_res  <= A or  B;
  xor_res <= A xor B;
  nor_res <= not (A or B);

  -- single adder for ADD/SUB
  addsub <= aS - bS when (ALUOp = "0001" or ALUOp = "1010" or ALUOp = "1011")
            else aS + bS;

  -- barrel shifter
  shamt    <= B(4 downto 0);
  dir_left <= '1' when (ALUOp = "0110") else '0'; -- SLL
  arith    <= '1' when (ALUOp = "1000") else '0'; -- SRA

  U_SH: barrel_shifter
    port map (A => A, shamt => shamt, dir_left => dir_left, arith => arith, Y => shift_out);

  -- SLT via corrected subtraction sign
  msbA <= A(31); msbB <= B(31); msbS <= std_logic(addsub(31));
  ovf  <= (msbA xor msbB) and (msbS xor msbA);
  slt_s <= (msbS xor ovf);
  slt_u <= '1' when unsigned(A) < unsigned(B) else '0';

  -- result mux
  with ALUOp select
    F <= std_logic_vector(addsub) when "0000",     -- ADD
         std_logic_vector(addsub) when "0001",     -- SUB
         and_res                when "0010",       -- AND
         or_res                 when "0011",       -- OR
         xor_res                when "0100",       -- XOR
         nor_res                when "0101",       -- NOR (optional)
         shift_out              when "0110",       -- SLL
         shift_out              when "0111",       -- SRL
         shift_out              when "1000",       -- SRA
         (31 downto 1 => '0') & slt_s when "1010",-- SLT
         (31 downto 1 => '0') & slt_u when "1011",-- SLTU
         (others => '0')        when others;

  Zero    <= '1' when F = x"00000000" else '0';
  SLTflag <= slt_s when ALUOp = "1010" else slt_u when ALUOp = "1011" else '0';
end architecture;