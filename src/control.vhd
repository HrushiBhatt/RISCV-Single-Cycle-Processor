library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control is
  port (
    opcode   : in  std_logic_vector(6 downto 0);
    funct3   : in  std_logic_vector(2 downto 0);
    funct7   : in  std_logic_vector(6 downto 0);
    ALU_Sel  : out std_logic_vector(3 downto 0); -- kept for your sheet; not used downstream
    RegWrite : out std_logic;
    MemRead  : out std_logic;
    MemWrite : out std_logic;
    Branch   : out std_logic;
    ALUOp    : out std_logic_vector(3 downto 0)
  );
end entity;
architecture rtl of control is
begin
  process(opcode, funct3, funct7)
  begin
    ALU_Sel  <= "0000";
    RegWrite <= '0'; MemRead <= '0'; MemWrite <= '0'; Branch <= '0';
    ALUOp    <= "0000"; -- default ADD

    case opcode is
      when "0110011" =>  -- R
        RegWrite <= '1';
        case funct3 is
          when "000" =>
            if funct7 = "0100000" then
              ALUOp <= "0001"; -- SUB
            else
              ALUOp <= "0000"; -- ADD
            end if;
          when "111" => ALUOp <= "0010"; -- AND
          when "110" => ALUOp <= "0011"; -- OR
          when "100" => ALUOp <= "0100"; -- XOR
          when "001" => ALUOp <= "0110"; -- SLL
          when "101" =>
            if funct7 = "0100000" then
              ALUOp <= "1000"; -- SRA
            else
              ALUOp <= "0111"; -- SRL
            end if;
          when "010" => ALUOp <= "1010"; -- SLT
          when "011" => ALUOp <= "1011"; -- SLTU
          when others => null;
        end case;

      when "0010011" =>  -- I-ALU
        RegWrite <= '1';
        case funct3 is
          when "000" => ALUOp <= "0000"; -- ADDI
          when "111" => ALUOp <= "0010"; -- ANDI
          when "110" => ALUOp <= "0011"; -- ORI
          when "100" => ALUOp <= "0100"; -- XORI
          when "001" => ALUOp <= "0110"; -- SLLI
          when "101" =>
            if funct7 = "0100000" then
              ALUOp <= "1000"; -- SRAI
            else
              ALUOp <= "0111"; -- SRLI
            end if;
          when "010" => ALUOp <= "1010"; -- SLTI
          when "011" => ALUOp <= "1011"; -- SLTIU
          when others => null;
        end case;

      when "0000011" => RegWrite <= '1'; MemRead  <= '1'; ALUOp <= "0000"; -- LOAD
      when "0100011" => MemWrite <= '1'; ALUOp <= "0000"; -- STORE
      when "1100011" => Branch <= '1'; ALUOp <= "0001"; -- BRANCH uses SUB
      when "0110111" => RegWrite <= '1'; ALUOp <= "0000"; -- LUI
      when "0010111" => RegWrite <= '1'; ALUOp <= "0000"; -- AUIPC
      when "1101111" => RegWrite <= '1'; ALUOp <= "0000"; -- JAL
      when "1100111" => RegWrite <= '1'; ALUOp <= "0000"; -- JALR
      when others => null;
    end case;
  end process;
end architecture;
