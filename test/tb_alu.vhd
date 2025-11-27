library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu is
end tb_alu;

architecture Behavioral of tb_alu is
    -- Component under test
    component alu
        port (
            A        : in  std_logic_vector(31 downto 0);
            B        : in  std_logic_vector(31 downto 0);
            ALU_Sel  : in  std_logic_vector(3 downto 0);
            Result   : out std_logic_vector(31 downto 0);
            Zero     : out std_logic
        );
    end component;

    -- Signals
    signal A, B, Result : std_logic_vector(31 downto 0) := (others => '0');
    signal ALU_Sel      : std_logic_vector(3 downto 0) := (others => '0');
    signal Zero         : std_logic;
    signal CLK          : std_logic := '0';
    signal done         : std_logic := '0';
begin
    ----------------------------------------------------------------
    -- Clock generation (10 ns period)
    ----------------------------------------------------------------
    CLK <= not CLK after 5 ns;

    ----------------------------------------------------------------
    -- Instantiate ALU
    ----------------------------------------------------------------
    uut : alu
        port map (
            A        => A,
            B        => B,
            ALU_Sel  => ALU_Sel,
            Result   => Result,
            Zero     => Zero
        );

    ----------------------------------------------------------------
    -- Stimulus
    ----------------------------------------------------------------
    process
    begin
        -- ADD
        A <= x"00000003"; B <= x"00000004"; ALU_Sel <= "0000"; wait for 20 ns;
        -- SUB
        A <= x"00000009"; B <= x"00000003"; ALU_Sel <= "0001"; wait for 20 ns;
        -- AND
        A <= x"F0F0F0F0"; B <= x"0FF00FF0"; ALU_Sel <= "0010"; wait for 20 ns;
        -- OR
        A <= x"F0F0F0F0"; B <= x"0FF00FF0"; ALU_Sel <= "0011"; wait for 20 ns;
        -- XOR
        A <= x"F0F0F0F0"; B <= x"0FF00FF0"; ALU_Sel <= "0100"; wait for 20 ns;
        -- SLT (signed)
        A <= x"FFFFFFFE"; B <= x"00000002"; ALU_Sel <= "0110"; wait for 20 ns;
        -- SLTU (unsigned)
        A <= x"FFFFFFFE"; B <= x"00000002"; ALU_Sel <= "1010"; wait for 20 ns;
        -- SLL
        A <= x"0000000F"; B <= x"00000002"; ALU_Sel <= "0111"; wait for 20 ns;
        -- SRL
        A <= x"000000F0"; B <= x"00000004"; ALU_Sel <= "1000"; wait for 20 ns;
        -- SRA
        A <= x"F0000000"; B <= x"00000004"; ALU_Sel <= "1001"; wait for 20 ns;

        -- Finish test
        done <= '1';
        wait;
    end process;

end Behavioral;
