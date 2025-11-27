

library ieee;
use ieee.std_logic_1164.all;

entity onescomp is
    port (
        a : in  std_logic_vector(31 downto 0);
        y : out std_logic_vector(31 downto 0)
    );
end onescomp;

architecture rtl of onescomp is
begin
    y <= not a;
end rtl;
