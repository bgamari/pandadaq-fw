library ieee;
use ieee.std_logic_1164.all;

type channels_type is array (0 to 7) of std_logic_vector (23 downto 0);

entity adc is
  port (
    clk         : in std_logic;
    reset       : in std_logic;
    sample_rq   : in std_logic;
    sample_done : out std_logic;
    
    channels    : out channels_type;
    
    adc_sclk    : in std_logic;
    adc_cs_     : out std_logic;
    adc_dout_a  : in std_logic;
    adc_dout_b  : in std_logic;
    adc_os      : out std_logic_vector(3 downto 0);
    adc_range   : out std_logic;
  );
end dac;

architecture rtl of adc is
type state_type is (s_idle, s_busy, s_recv);
signal state, next_state : state_type;
signal current_cmd : std_logic_vector(23 downto 0);
signal bit_n : std_logic_vector(4 downto 0);
signal phase : std_logic_vector(1 downto 0);
signal work_a, word_b : std_logic_vector(23 downto 0);
begin  -- adc

  process (clk, reset)
  begin  -- process
    if reset='1' then
      state <= s_idle;
      next_state <= s_idle;
      adc_cs_ <= '1';
      sample_done <= '0';
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- SPI state machine
  process (adc_sclk)
  begin  -- process
    if rising_edge(sclk) then
      case state is
        when s_idle =>
          sample_done <= '0';
          if sample_rq then
            state <= s_busy;
            adc_cs_ <= '0';
            bit_n <= 0;
            phase <= 0;
            work_a <= 0;
            work_b <= 0;
          end if;

        when s_busy =>
          if not adc_busy then
            next_state <= s_recv;
          end if;

        when s_recv =>
          work_a <= adc_dout_a & (work_a sll 1);
          work_b <= adc_dout_b & (work_b sll 1);
          bit_n <= bit_n + 1;
          if bit_n=23 and phase=3 then
            state <= s_idle;
            sample_done <= 1;
          elsif bit_n=23 then
            bit_n <= 0;
            phase <= phase + 1;
            work_a <= 0;
            work_b <= 0;
            channels(0+phase) <= work_a;
            channels(4+phase) <= work_b;
          end if;
      end case;
    end if ;
  end process;
end dac;
