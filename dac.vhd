library ieee;
use ieee.std_logic_1164.all;
use std.numeric_std.all;

entity dac is
  port (
    clk         : in std_logic;
    reset       : in std_logic;
    dest        : in std_logic;
    cmd         : in std_logic_vector(23 downto 0);
    cmd_rdy     : in std_logic;
    done        : out std_logic;
    
    dac_sclk    : in std_logic;
    dac_in      : out std_logic;
    dac_sync_   : out std_logic
  );
end dac;

architecture rtl of dac is
type state_type is (s_idle, s_send);
signal state, next_state : state_type;
signal current_cmd : std_logic_vector(23 downto 0);
signal bit_n : std_logic_vector(4 downto 0);
begin  -- dac

  process (clk, reset)
  begin  -- process
    if reset='1' then
      state <= s_idle;
      next_state <= s_idle;
      dac_sync_ <= '1';
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- purpose: SPI state machine
  process (dac_sclk)
  begin  -- process
    if rising_edge(dac_sclk) then
      case state is
        when s_idle =>
          done <= '0';
          if cmd_rdy then
            next_state <= s_send;
            current_cmd <= cmd;
            bit_n <= 0;
            dac_sync_ <= '0';
          end if;
          
        when s_send =>
          dac_in <= current_cmd(0);
          current_cmd <= current_cmd sll 1
          bit_n <= bit_n + 1;
          if bit_n=23 then
            next_state <= s_idle;
            done <= '1';
            dac_sync_ <= '1'
          end if;
      end case;
    end if;
  end process;

end dac;
