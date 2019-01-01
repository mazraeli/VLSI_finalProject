library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity testbench_1 is
end testbench_1;

Architecture archi of testbench_1 is

component cordic_mini
generic(
    XY_WIDTH    : integer := 16;
    ANGLE_WIDTH : integer := 16;
    STAGE       : integer := 14 --(no. of STAGE = XY_WIDTH) 
        );
    
  port(
    clock   : in  std_logic;
    load    : in  std_logic;
    reset   : in  std_logic;
    angle   : in  signed (ANGLE_WIDTH-1 downto 0);
    done    : out std_logic;
    Xout    : out signed (XY_WIDTH-1 downto 0);
    Yout    : out signed (XY_WIDTH-1 downto 0)
      );
end component;

signal checker : integer ;
signal reset : std_logic ;
signal clock : std_logic :='0' ;
signal load : std_logic := '0';
signal angle  : signed (15 downto 0) ; -- <= "0001000000000000";
signal done   : std_logic := '0' ;
signal Cos    : signed (15 downto 0);
signal Sin   : signed (15 downto 0);

begin

uut: cordic_mini PORT MAP (
          clock => clock,
          load => load,
          angle => angle ,
          done => done ,
          reset => reset ,
          Xout => Cos,
          Yout => Sin
          --Xin => Xin,
          --Yin => Yin ,
          --aout => aout
        );
--resetn <= '0';
clock <= not clock after 100 ns ;
--resetn <= not resetn after 200 ns ;
process(clock)
variable anglex : signed (15 downto 0) := "0000000000000000";
variable check :  integer := 0  ;
begin
if(rising_edge(clock)) then
if( load = '0' ) then
angle <= anglex ;
checker <= check ;
load <= '1' ;
else
if(done = '1') then
anglex := anglex + "0000000001011011";
check := check + 1 ;
load <= '0';
end if;
if(check = 360 ) then 
check := 0 ;
anglex := "0000000000000000";
end if ;
end if ;
end if ; --clock

end process ;
end archi ;