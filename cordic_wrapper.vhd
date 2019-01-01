library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cordic_wrapper is
    generic ( IN_WIDTH  : INTEGER := 8;
              OUT_WIDTH : INTEGER := 8 );
    Port    ( clk         : in STD_LOGIC;
              rst         : in STD_LOGIC;
              sample_rate : in UNSIGNED (IN_WIDTH - 1 downto 0);
              cosine      : out UNSIGNED (OUT_WIDTH - 1 downto 0);
              sine        : out UNSIGNED (OUT_WIDTH - 1 downto 0);
              TDONE       : out STD_LOGIC;
              START       : in STD_LOGIC);
end cordic_wrapper;


architecture Behavioral of cordic_wrapper is

  -- DECLARATIONS *************************************************************
  -- **************************************************************************
	type state is (init, starts, calc, fin);
	signal pr_state, nx_state : state;

	signal counter : UNSIGNED(15 downto 0) := (others => '0');

  -- ***********************&&&&&&&&&&&&&&&&&&&&&&&&&**********&&&&&&&&&&
  signal full_degree : UNSIGNED(15 downto 0) := x"0168";
  signal one_var : UNSIGNED(15 downto 0) := "0000000000000001";
  signal seven_var : UNSIGNED(3 downto 0) := "1000";
  signal div_coef : UNSIGNED(15 downto 0) := (others => '0');
  signal up_bound : UNSIGNED(15 downto 0) := (others => '0');

  signal pr_angle : UNSIGNED(31 downto 0) := (others => '0');
  signal pr_angle_shifted : UNSIGNED(31 downto 0) := (others => '0');
  signal new_angle_t : UNSIGNED(31 downto 0) := (others => '0');
  signal new_angle : UNSIGNED(15 downto 0) := (others => '0');

  -- intermediate signals need for instantiations
  signal angle : signed (15 downto 0);
  signal xout : signed(15 downto 0);
  signal yout : signed(15 downto 0);
  signal load : std_logic;
  signal done : std_logic := '0';

  signal cosine_t : signed(15 downto 0);
  signal sine_t : signed(15 downto 0);
  signal cosine_tt : signed(15 downto 0);
  signal sine_tt : signed(15 downto 0);

  -- INSTANTIATIONS ***********************************************************
  -- **************************************************************************
  component cordic_mini
    generic(
      XY_WIDTH    : integer := 16;
      ANGLE_WIDTH : integer := 16;
      STAGE       : integer := 14
          );
    port (
      clock   : in  std_logic;
      angle   : in  signed (16-1 downto 0);
      load    : in std_logic;
      reset   : in std_logic;
      done    : out std_logic;
      Xout    : out signed (16-1 downto 0);
      Yout    : out signed (16-1 downto 0)
    );
  end component;

begin -- begin of architecture

    -- component isntantiation
    U1 : cordic_mini
    port map( clk,
              angle,
              load,
              rst,
              done,
              xout,
              yout );


  	process(clk)
  	begin
  		if(clk'event and clk = '1') then
  			if(rst = '1') then
  		      pr_state <= init;
  			else
  		      pr_state <= nx_state;
  			end if;
  		end if;
  	end process;


  	process(done, START, sample_rate, pr_state)
  	begin
  		case pr_state is
  		---------------------------------------------------
  			when init =>
          TDONE <= '0';
          load <= '0';
          if (START = '1') then
            nx_state <= starts;
          else
            nx_state <= init;
          end if;
          -- maybe it is need for initializations
  				--nx_state <= starts;

  		---------------------------------------------------
  			when starts =>
          if (counter > up_bound) then -- if counter has reached to its final value

            nx_state <= fin;
          else
            angle <= signed(new_angle);
            load <= '1';

            nx_state <= calc;
          end if;

        	--nx_state <= ;

  		---------------------------------------------------
  			when calc =>
          if (done = '1') then -- calculation finished
            counter <= counter + "0000000000000001";

            nx_state <= init;
          else

            nx_state <= calc;
          end if;

          -- nx_state <= ;

  		---------------------------------------------------
  			when fin =>
          TDONE <= '1';
          counter <= "0000000000000000";

  				nx_state <= init;

  		end case;
  	end process;

    div_coef <= full_degree srl to_integer(sample_rate); -- 360/(2^n)
    up_bound <= one_var sll to_integer(sample_rate); -- 2^n

    cosine_t <= xout srl to_integer(seven_var);
    sine_t <= yout srl to_integer(seven_var);
    cosine_tt <= cosine_t + "0000000010000000";-- cosine_t + 127
    sine_tt <= sine_t + "0000000010000000";-- sine_t + 127
    cosine <= unsigned(cosine_tt(7 downto 0));
    sine <= unsigned(sine_tt(7 downto 0));

    pr_angle <= counter * div_coef;
    pr_angle_shifted <= pr_angle sll 15;
    new_angle_t <= pr_angle_shifted / x"168";
    new_angle <= new_angle_t(15 downto 0);

end Behavioral;
