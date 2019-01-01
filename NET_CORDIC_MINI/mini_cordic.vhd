---// MINI-CORDIC IP CORE // -----
--- Sine Cosine Wave Generator ---
-- 16 BIT INPUT , 16 BIT OUTPUT , CLOCK IN = 100 MHz , COMPUTATION IN 18 CLOCK CYCLES
--- Developers : Mitu , Roshan ---
--- All Rights Reserved ----------
--- October 2016 ------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity cordic_mini is
  generic(
    XY_WIDTH    : integer := 16;
    ANGLE_WIDTH : integer := 16;
    STAGE       : integer := 14  
        );
    
  port(
    clock   : in  std_logic;
    angle   : in  signed (ANGLE_WIDTH-1 downto 0);
    load    : in std_logic;
    reset   : in std_logic;
    done    : out std_logic;
    Xout    : out signed (XY_WIDTH-1 downto 0);
    Yout    : out signed (XY_WIDTH-1 downto 0)
      );
end cordic_mini;

architecture archi_cordic_mini of cordic_mini is

------------------------------------------------------------------------
--
--                  REGISTER & ARRAY DECLARATIONS
--
------------------------------------------------------------------------
type xyarray is array (natural range <>) of signed (XY_WIDTH-1 downto 0);

type intarray is array (natural range <>) of integer ;

type zarray is array (natural range <>) of signed (ANGLE_WIDTH-1 downto 0);

type atan_lut is array ( natural range <>) of signed (ANGLE_WIDTH-1 downto 0);

  -- TAN INVERSE (ARCTAN) array format 1,16 in DEGREES
    constant TAN_ARRAY : atan_lut (0 to STAGE-1) := (
                          
                          "0001000000000000",   -- 45
                          "0000100100010110",   -- 26.565
                          "0000010011111101",   -- 14.036
                          "0000001010001000",   -- 7.125
                          "0000000101000101",   -- 3.576
                          "0000000010100010",   -- 1.79
                          "0000000001010001",   -- 0.895
                          "0000000000101000",   -- 0.448
                          "0000000000010100",   -- 0.224
                          "0000000000001010",   -- 0.112
                          "0000000000000101",   -- 0.056
                          "0000000000000010",   -- 0.028
                          "0000000000000001",   -- 0.014                         
                          "0000000000000000" );
    constant J_ARRAY : intarray (0 to STAGE-1) := ( 1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192);
	 
signal ok_finished : std_logic := '0' ;           
signal STATE : std_logic_vector(2 downto 0);              
begin
process(clock,reset)
    variable Zsign : std_logic;
    variable Xo : xyarray (0 to STAGE-1);
    variable Yo : xyarray (0 to STAGE-1);
    variable Xo1 : xyarray (0 to STAGE-1);
    variable Yo1 : xyarray (0 to STAGE-1);
    variable Xoo : signed (XY_WIDTH-1 downto 0);
    variable Xo11: signed (XY_WIDTH-1 downto 0);
    variable angle_new: signed (ANGLE_WIDTH-1 downto 0);
    variable copy: signed (ANGLE_WIDTH-1 downto 0 );
    variable Zo : zarray (0 to STAGE-1);
    variable Zo1 : zarray(0 to STAGE-1);
    variable intr : zarray (0 to STAGE-1);
    variable j   : integer := 0;
    variable k   : integer := 0;
    variable sine_sign : std_logic := '0';
    variable cos_sign  : std_logic  := '0';
    variable msbcheck  : std_logic := '0';
    variable flag : std_logic := '0' ;
    variable flag1 : std_logic := '0' ;
    variable ok_load : std_logic :='0' ;
    variable quadrant : signed (1 downto 0 ) ;
    variable CF_cos : signed (XY_WIDTH-1 downto 0);
    variable CF_sin : signed (XY_WIDTH-1 downto 0);
    variable Xo_offset : signed (XY_WIDTH-1 downto 0);
    variable Yo_offset : signed (XY_WIDTH-1 downto 0);
    variable Xo1_offset : signed (XY_WIDTH-1 downto 0);
    variable Yo1_offset : signed (XY_WIDTH-1 downto 0);
    variable zero : unsigned (XY_WIDTH-1 downto 0) ;
begin
if(reset ='1') then
j:= 0;
k:= 0;
flag:='0';
flag1:='0';
zero := "0000000000000000";
STATE <= "000";
done <= '0';
elsif(rising_edge(clock)) then
if(load ='0') then
j:= 0;
k:= 0;
flag:='0';
flag1:='0';
zero := "0000000000000000";
STATE <= "000";
done <= '0';
else
CASE STATE IS
WHEN "000" =>  
         
      if(angle(ANGLE_WIDTH-1) = '1') then 
      msbcheck := '1';
      else
      msbcheck := '0';
      end if;
      
      copy := angle ;
      
      if(angle(ANGLE_WIDTH-1) = '1') then   -- converting -ve angle values from 2's compliment to usual notation
      copy(ANGLE_WIDTH-1) := '0';
      copy := (copy XOR "0111111111111111") + 1 ;
      end if ;
      
      copy(ANGLE_WIDTH-1) := '0';
      angle_new := copy ;
      Zo(0) := angle_new;
      intr(0) := angle_new;

      Xo(0) := "0100110110111001"; --- cordic logic initial values
      Yo(0) := "0000000000000000";
      Xo1(0):= "0100110110111001";
      Yo1(0):= "0000000000000000";

      quadrant := angle_new (ANGLE_WIDTH-2 downto ANGLE_WIDTH-3);

      case quadrant is   --- QUADRANT FINDER AND ANGLE MAPPING TO FIRST QUADRANT
      when "00"  =>   
                    Zo(0) := angle_new;
                    Zo1(0) := "0010000000000000" - angle_new ;
                    sine_sign := '0';
                    cos_sign := '0';
      when "01"  =>    
                    if(Zo(0) /= "0010000000000000")then
                    intr(0)  := "0100000000000000" - angle_new ;
                    Zo(0) := intr(0) ;
                    Zo1(0) := "0010000000000000" - intr(0);
                    sine_sign := '0';
                    cos_sign := '1';
                    end if ;
      when "10"  =>   
                    if(Zo(0) /= "0100000000000000")then
                    intr(0)  := "0110000000000000" - angle_new ;
                    Zo(0)    := "0010000000000000" - intr(0) ;
                    Zo1(0)   := intr(0);
                    sine_sign := '1';
                    cos_sign := '1';
                    end if ;
      when "11"  => 
                    if(Zo(0) /= "0111111111111111")then
                    if(Zo(0) /= "0110000000000000")then
                    intr(0) :=  "0111111111111111" - angle_new ;
                    Zo1(0) :=   "0010000000000000" - intr(0) ;
                    Zo(0) := intr(0);
                    sine_sign := '1';
                    cos_sign := '0';
                    end if ;
                    end if ;
      when others => flag := '0' ;  
      end case ;
      -------finding the correction factor needed --------
      if(Zo(0) >"0001000000000000") then
      CF_cos := "0000000111101011" ;
      CF_sin := "0000000000000000" ;
      elsif(Zo(0) <"0001000000000000") then
      CF_sin := "0000000111101011" ;
      CF_cos := "0000000000000000" ;
      end if ;
      ----------------------------------------------------
      STATE <= "001" ;      
           
WHEN "001" =>    -------- QUICK ANALYSING BLOCK ------------
       if(Zo(0) = "0001000000000000") then --45
       Xo(0) := "0100110110111001";
       Xo1(0) := "0100110110111001";
       sine_sign := '0';
       cos_sign := '0';
       flag := '1';
       flag1 := '1';
       CF_sin := "0000000000000000" ;
       CF_cos := "0000000000000000" ;
       elsif(Zo(0) = "0000000000000000") then -- 0
       Xo(0) := "0111111111111111";
       Xo1(0) := "0000000000000000";
       msbcheck :='0';
       sine_sign := '0';
       cos_sign := '0';
       flag := '1';
       flag1 := '1';
       CF_sin := "0000000000000000" ;
       CF_cos := "0000000000000000" ;
       elsif(Zo(0) = "0010000000000000") then --90
       Xo1(0) := "0011111111111111";
       Xo(0) :=  "0000000000000000";
       sine_sign := '0';
       cos_sign := '0';
       flag := '1';
       flag1 := '1';
       CF_sin := "0000000000000000" ;
       CF_cos := "0000000000000000" ;
       elsif(Zo(0)="0100000000000000") then --180
       Xo(0) := "1111111111111111";
       Xo1(0):= "0000000000000000";
       msbcheck :='0';
       sine_sign := '0';
       cos_sign := '1';
       flag := '1';
       flag1 := '1';
       CF_sin := "0000000000000000" ;
       CF_cos := "0000000000000000" ;
       elsif(Zo(0)="0110000000000000") then --270
       Xo(0) := "0000000000000000";
       Xo1(0):= "1111111111111111";
       sine_sign := '1';
       cos_sign := '0';
       flag := '1';
       flag1 := '1';
       CF_sin := "0000000000000000" ;
       CF_cos := "0000000000000000" ;
       elsif(Zo(0)="0111111111111111") then --360
       Xo(0)  := "0111111111111111";
       Xo1(0) := "0000000000000000";
       msbcheck :='0';
       sine_sign := '0';
       cos_sign := '0';
       flag := '1';
       flag1 := '1';
       CF_sin := "0000000000000000" ;
       CF_cos := "0000000000000000" ;
       end if ;
       STATE <= "011" ;
       
WHEN "011" =>       
      if ( flag /= '1' and j <13) then 
      
      Xo_offset := Yo(j) ; -- /// logic block for division ///
		  Yo_offset := Xo(j) ;
		  
		  if(Xo_offset >=0) then
		  zero := "0000000000000000" + unsigned(Xo_offset(14 downto j)) ;
      Xo_offset := signed(zero) ;
		  else 
		  Xo_offset := (Xo_offset XOR "1111111111111111") + 1;
		  zero := "0000000000000000" + unsigned(Xo_offset(14 downto j)) ;
		  Xo_offset := signed(zero) ;
		  end if;	
		  
		  if(Yo_offset >=0) then
		  zero := "0000000000000000" + unsigned(Yo_offset(14 downto j)) ;
      Yo_offset := signed(zero) ;
		  else 
		  Yo_offset := (Yo_offset XOR "1111111111111111" ) + 1;
		  zero := "0000000000000000" + unsigned(Yo_offset(14 downto j)) ;
		  Yo_offset := signed(zero);
		  end if;	
		  		  
      if (Zo(j)< 0) then -- cordic iteration loop
      Xo(j+1) := Xo(j) + Xo_offset ;--Yo(j)/J_ARRAY(j);--Ysr;
      Yo(j+1) := Yo(j) - Yo_offset ;--Xo(j)/J_ARRAY(j);--Xsr;
      Zo(j+1) := Zo(j) + TAN_ARRAY(j);
      j := j + 1 ;
      elsif (Zo(j) > 0) then
      Xo(j+1) := Xo(j) - Xo_offset ;--Yo(j)/J_ARRAY(j);--Ysr;
      Yo(j+1) := Yo(j) + Yo_offset ;--Xo(j)/J_ARRAY(j);--Xsr;
      Zo(j+1) := Zo(j) - TAN_ARRAY(j); 
			j := j + 1 ;
      elsif (Zo(j) = 0 ) then
      flag := '1';          
      end if;
        
      end if ;

      if ( flag1 /= '1' and k <13) then -- cordic iteration loop 
      Xo1_offset := Yo1(k) ;
		  Yo1_offset := Xo1(k) ;
		  
		  if(Xo1_offset >=0) then
		  zero := "0000000000000000" + unsigned(Xo1_offset(14 downto k)) ;
      Xo1_offset := signed(zero) ;
		  else 
		  Xo1_offset := (Xo1_offset XOR "1111111111111111") + 1;
		  zero := "0000000000000000" + unsigned(Xo1_offset(14 downto k)) ;
		  Xo1_offset := signed(zero) ;
		  end if;	
		  
		  if(Yo1_offset >=0) then
		  zero := "0000000000000000" + unsigned(Yo1_offset(14 downto k)) ;
      Yo1_offset := signed(zero) ;
		  else 
		  Yo1_offset := (Yo1_offset XOR "1111111111111111" ) + 1;
		  zero := "0000000000000000" + unsigned(Yo1_offset(14 downto k)) ;
		  Yo1_offset := signed(zero);
	    end if;	
	  
      if (Zo1(k)< 0) then
      Xo1(k+1) := Xo1(k) + Xo1_offset ;--Yo1(k)/J_ARRAY(k);--Ysr;
      Yo1(k+1) := Yo1(k) - Yo1_offset ;--Xo1(k)/J_ARRAY(k);--Xsr;
      Zo1(k+1) := Zo1(k) + TAN_ARRAY(k);
		  k:= k+1;
      elsif (Zo1(k) > 0) then           
      Xo1(k+1) := Xo1(k) - Xo1_offset ;--Yo1(k)/J_ARRAY(k);--Ysr;
      Yo1(k+1) := Yo1(k) + Yo1_offset ;--Xo1(k)/J_ARRAY(k);--Xsr;
      Zo1(k+1) := Zo1(k) - TAN_ARRAY(k); 
		  k:= k+1;
      elsif (Zo1(k) = 0 ) then
      flag1 := '1';          
      end if;
      
      end if ;
      
      if( (flag = '1' and flag1 ='1') or j =13 )then --- iteration can be stopped or not ?
      STATE <= "010" ;
      else
      STATE <= "011" ;
      end if;
      
WHEN "010" =>  

      Xo(j) := Xo(j) + CF_cos ; --- COMPUTATIONAL ERROR CORRECTION BLOCK ---
      Xo1(k) := Xo1(k) + CF_sin ;
      Xoo := Xo(j) ;
      Xo11:= Xo1(k) ;
      flag := '0' ; 
      flag1 :='0' ; 
      j := 14 ;
      k := 14 ;
------ -VE VALUE ERROR COMPENSATION BLOCK -----------
      if(Xoo < 0) then
      Xoo := (Xoo XOR "0111111111111111" ) + 1 ;
      Xoo(XY_WIDTH-1) := '0' ;
      end if ;

      if(Xo11 <0 ) then
      Xo11 := (Xo11 XOR "0111111111111111" ) + 1 ;
      Xoo(XY_WIDTH-1) := '0' ;
      end if ;
------------------------------------------------------
      if(cos_sign ='1') then                     ---- -VE NO.s CONVERTED TO 2's COMPLIMENT
      Xoo := (Xoo XOR "0111111111111111" ) + 1 ;
      end if ;

      if( (sine_sign XOR msbcheck) = '1') then
      Xo11 := (Xo11 XOR "0111111111111111") + 1 ;
      end if ;

      Xoo(XY_WIDTH-1):= cos_sign ;              --- ASSIGNING SIGNS
      Xo11(XY_WIDTH-1):= (sine_sign XOR msbcheck)  ;
      Xout <= Xoo ;    --- Outputs mapped
      Yout <= Xo11 ;
      
      STATE <= "110";
      
WHEN "110" =>      
      done <= '1';
       
WHEN OTHERS =>
       done <= '0';

end CASE;
end if ;
end if;
end process ;
end archi_cordic_mini ;