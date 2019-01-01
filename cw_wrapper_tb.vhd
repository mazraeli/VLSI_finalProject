library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity cw_wrapper_tst is
end cw_wrapper_tst;

Architecture archi of cw_wrapper_tst is

component cordic_wrapper
generic ( IN_WIDTH  : INTEGER := 8;
          OUT_WIDTH : INTEGER := 8 );
Port    ( clk         : in STD_LOGIC;
          rst         : in STD_LOGIC;
          sample_rate : in UNSIGNED (IN_WIDTH - 1 downto 0);
          cosine      : out UNSIGNED (OUT_WIDTH - 1 downto 0);
          sine        : out UNSIGNED (OUT_WIDTH - 1 downto 0);
          TDONE       : out STD_LOGIC;
          START       : in STD_LOGIC);
end component;

signal reset : std_logic ;
signal clock : std_logic :='0' ;
signal load : std_logic := '0';
signal start : std_logic := '0';
signal smp  : unsigned (7 downto 0) ; -- sample_rate
signal done   : std_logic := '0' ;
signal Cos    : unsigned (7 downto 0);
signal Sin   : unsigned (7 downto 0);

begin

uut: cordic_wrapper PORT MAP (
          clock,
          reset,
          smp,
          Cos,
          Sin,
          done,
          start
        );
--resetn <= '0';
clock <= not clock after 10 ns ;
--resetn <= not resetn after 200 ns ;

pp : process
begin
  reset <= '1';
  smp <= "00000110";
  start <= '0';
  wait for 10 ns;
  reset <= '0';
  wait for 10 ns;
  start <= '1';

  wait;

end process;

end  archi;
