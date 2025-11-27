library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity barrel_shifter is
  port(
    A        : in  std_logic_vector(31 downto 0);
    shamt    : in  std_logic_vector(4 downto 0);
    dir_left : in  std_logic;   -- '1' = left, '0' = right
    arith    : in  std_logic;   -- for right shifts; '1' = arithmetic
    Y        : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of barrel_shifter is
begin
  process(A, shamt, dir_left, arith)
    variable res  : std_logic_vector(31 downto 0);
    variable k    : integer range 0 to 31;
    variable fill : std_logic;
  begin
    k := to_integer(unsigned(shamt));
    if dir_left = '1' then            -- SLL
      for i in 31 downto 0 loop
        if (i - k) >= 0 then res(i) := A(i - k); else res(i) := '0'; end if;
      end loop;
    else                               -- SRL/SRA
      if arith = '1' then
          fill := A(31);
      else
          fill := '0';
      end if;
      for i in 0 to 31 loop
        if (i + k) <= 31 then res(i) := A(i + k); else res(i) := fill; end if;
      end loop;
    end if;
    Y <= res;
  end process;
end architecture;