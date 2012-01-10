library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pandadaq.all;

-- Block memory and GPMC logic for streaming data from device
entity gpmc_out is
  generic (
    g_BASE : positive := '0';          -- Base address of block
  )
  port(
    clk         : in std_logic;
    reset       : in std_logic;
    input       : in std_logic_vector(7 downto 0);
    we          : in std_logic;
    
    -- OMAP GPMC
    gpmc_clk    : in std_logic;         -- Clock
    gpmc_cs_    : in std_logic;         -- Chip select
    gpmc_ale    : in std_logic;         -- Address latch enable
    gpmc_we_    : in std_logic;         -- Write enable
    gpmc_oe_    : in std_logic;         -- Output enable
    gpmc_be0_   : in std_logic;         -- Byte enable
    gpmc_wait   : out std_logic_vector(1 downto 0);  -- Wait
    gpmc_ad     : inout std_logic_vector(15 downto 0);  -- Address/data bus
  );
end tdc_channel;

architecture rtl of gpmc_out is
type state_type is (s_idle, s_wait, s_write, s_read);
signal state, next_state : state_type;
signal address : std_logic_vector(15 downto 0);
signal read_en : std_logic;
signal data_out : std_logic_vector(15 downto 0);
begin  -- rtl
  gpmc_cs = not gpmc_cs_;
  gpmc_we = not gpmc_we_;
  gpmc_oe = not gpmc_oe_;
  gpmc_be = not gpmc_be0_;

  cmp_ram: RAM
    generic map(
      DATA_WIDTH_A      => 9,
      DATA_WIDTH_B      => 18,
      RAM_MODE          => SDP
    )
    port map(
      CLKAWRCLK         => clk,
      CLKBRDCLK         => gpmc_clk,
      DIADI             => input,
      ENAWREN           => we,
      ENBRDEN           => read_en
      DOBDO             => data_out;
    );
      
  -- State advance
  process (clk, reset)
  begin  -- process
    if reset='1' then
      state <= s_idle;
      next_state <= s_idle;
      gpmc_wait <= 0;
    elsif rising_edge(gpmc_clk) then
      state <= next_state;
    end if;
  end process;
  
  -- State machine
  process (gpmc_clk)
  begin
    if rising_edge(gpmc_clk) then
      case state is
        when s_idle =>
          if gpmc_cs and gpmc_ale then
            next_state <= s_wait;
            address <= gpmc_ad;
          end if;
          
        when s_wait =>
          if not gpmc_cs then
            next_state <= s_idle;       -- CS fell before we were told what to do
          elsif address(15 downto 8) /= g_BASE and gpmc_ale='0' then
            next_state <= s_idle;       -- This transaction isn't for us
          elsif gpmc_we then
            next_state <= s_write;      -- Write
          elsif gpmc_oe then
            next_state <= s_read;       -- Read
          end if;
          
        when s_read =>
          if not gpmc_cs then
            next_state <= s_idle;
          else
            address <= address + 1;
          end if;
          
        when s_write =>
          if not gpmc_cs then
            next_state <= s_idle;
          else
            address <= address + 1;
          end if;
      end case;
    end if;
  end process;

end rtl;
