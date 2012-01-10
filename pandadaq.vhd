library ieee;
use ieee.std_logic_1164.all;
use std.numeric_std.all;

entity pandadaq is
  port (
    clk         : in std_logic;
    reset       : in std_logic;
    cmd         : in std_logic_vector(23 downto 0);
    cmd_rdy     : in std_logic;
    done        : out std_logic;
    
    adc_reset   : out std_logic;
    adc_sclk    : out std_logic;
    adc_convst_a : out std_logic;
    adc_convst_b : out std_logic;
    adc_dout_a  : in std_logic;
    adc_dout_b  : in std_logic;
    
    adc1_cs_    : out std_logic;
    adc1_os      : out std_logic_vector(3 downto 0);
    adc1_range   : out std_logic;
    adc2_cs_    : out std_logic;
    adc2_os      : out std_logic_vector(3 downto 0);
    adc2_range   : out std_logic;
    
    dac_sclk    : in std_logic;
    dac_in      : out std_logic;
    dac_sync_   : out std_logic
  );
end pandadaq;

architecture rtl of pandadaq is
begin  -- dac
  
  adc1_cmp: adc
    port map (
      clk       => clk,
      reset     => reset,
      sample_rq => adc1_samp_rq,
      sample_done => adc1_done,
      sample_channels => adc1_channels,

      adc_sclk  => adc_sclk,
      adc_cs_   => adc1_cs_,
      adc_dout_a => adc_dout_a,
      adc_dout_b => adc_dout_b,
      adc_os    => "000",
      adc_range => '0' 
    );
  
  adc2_cmp: adc
    port map (
      clk       => clk,
      reset     => reset,
      sample_rq => adc2_samp_rq,
      sample_done => adc2_done,
      sample_channels => adc2_channels,

      adc_sclk  => adc_sclk,
      adc_cs_   => adc2_cs_,
      adc_dout_a => adc_dout_a,
      adc_dout_b => adc_dout_b,
      adc_os    => "000",
      adc_range => '0' 
    );

  dac1_cmp: dac
    port map (
      clk       => clk,
      reset     => reset,
      cmd       => dac1_cmd,
      cmd_rdy   => dac1_rdy,
      done      => dac1_done,
      dac_sclk  => dac_sclk,
      dac_in    => dac_in,
      dac_sync_ => dac_sync_
    )

  process (clk)
  begin  -- process
    adc_reset <= reset;
  end process;
end dac
  
