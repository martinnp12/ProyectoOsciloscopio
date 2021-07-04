----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.04.2021 11:54:17
-- Design Name: 
-- Module Name: DataAcquisition - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

USE work.oscilloscope_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DataAcquisition is
    Port ( Reset_i : in STD_LOGIC;
           CLK100MHz_i : in STD_LOGIC;
           ON_ch1_i : in std_logic;
           ON_ch2_i : in std_logic;
           Vp_I : in STD_LOGIC;
           Vn_I : in STD_LOGIC;
           vauxp2_i : in STD_LOGIC;
           vauxn2_i : in STD_LOGIC;
           vauxp10_i : in STD_LOGIC;
           vauxn10_i : in STD_LOGIC;
           getBusControl_i : in STD_LOGIC;
           ram_addr_i : in STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
           ram_read_i : in STD_LOGIC;
           
           downsample_i : in STD_LOGIC_VECTOR(MAX_DOWNSAMPLE - 1 DOWNTO 0);
           
           triggerLevel_i : in STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
           triggerEdge_i : in STD_LOGIC;
           triggerAuto_i : in STD_LOGIC;
           triggerSingle_i : in STD_LOGIC;
           --Salidas
           triggered_o : out STD_LOGIC;
           trigger_addr_o : out STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
           data_ch1_o : out STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
           data_ch2_o : out STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
           LED_o : out std_logic_vector (15 downto 0));
end DataAcquisition;

architecture Behavioral of DataAcquisition is

--  component Clk_Gen
--    port (
--      resetn     : in  std_logic;
--      clk_in1   : in  std_logic;
--      clk_out1  : out  std_logic;
----      clk_out2  : out  std_logic;
--      locked    : out std_logic); 
--end component;

component ADC_Sampler is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           Vp_I : in STD_LOGIC;
           Vn_I : in STD_LOGIC;
           vauxp2_i : in STD_LOGIC;
           vauxn2_i : in STD_LOGIC;
           vauxp10_i : in STD_LOGIC;
           vauxn10_i : in STD_LOGIC;
           Read_FIFO1_i : in std_logic;
           Read_FIFO2_i : in std_logic;
           FIFO1_empty_o : out std_logic;
           FIFO2_empty_o : out std_logic;
           FIFO1_data_o : out std_logic_vector (11 downto 0);
           FIFO2_data_o : out std_logic_vector (11 downto 0);
           LED_O : out std_logic_vector (15 downto 0));
end component;

component ADC_DataMemory is
    Port ( Reset_I : in STD_LOGIC;
           CLK_i : in STD_LOGIC;
           ON_I : in STD_LOGIC;
           FIFO_empty_i : in STD_LOGIC;
           ram_addr_i : in STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
           data_FIFO_i : in STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
           downsample_i : in STD_LOGIC_VECTOR(MAX_DOWNSAMPLE - 1 downto 0);
           ram_read_i : in STD_LOGIC;
           getBusControl_i  : in STD_LOGIC;
           data_rdy_o : out STD_LOGIC;
           Read_FIFO_o : out STD_LOGIC;
           ram_addr_aux_o : out std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
           ram_data_o : out STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0));
end component;


component Trigger is
    Port ( reset_i : in STD_LOGIC;
           clk_i : in STD_LOGIC;
           data_i : in STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
           ram_address_i : in std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
           trigger_i : in std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);
           adc_drdy_i : in std_logic;
           triggerEdge_i : in std_logic;
           triggerAuto_i : in std_logic;
           triggerSingle_i : in STD_LOGIC;
           triggered_o : out std_logic;
           address_o : out STD_LOGIC_VECTOR (RAM_ADDR_WIDTH - 1 downto 0));
end component;

signal CLK : std_logic;

-- ADC_Sampler signals

signal read_FIFO_ch1, read_FIFO_ch2 : std_logic;
signal data_FIFO_ch1, data_FIFO_ch2: std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
signal FIFO_empty_ch1, FIFO_empty_ch2 : std_logic;
signal data_ch1, data_ch2 : STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
--signal LED : std_logic_vector (15 downto 0);
signal ram_addr_aux : std_logic_vector (RAM_ADDR_WIDTH - 1 downto 0);

signal adc_drdy : std_logic;

begin

--  Clock_generator : Clk_Gen
--    port map (
--      resetn    => reset_I,   
--      clk_in1  => Clk100MHz_I,
--      clk_out1 => CLK,
--      locked   => open);
      
Inst_ADC_Sampler : ADC_Sampler
   port map (   
   Reset_I => Reset_I,                
   CLK_I => CLK100MHz_i,                
   Vp_I => Vp_I,
   Vn_I => Vn_I,
   vauxp2_i => vauxp2_i,
   vauxn2_i => vauxn2_i,
   vauxp10_i => vauxp10_i,
   vauxn10_i => vauxn10_i,
   Read_FIFO1_i => read_FIFO_ch1,
   Read_FIFO2_i => read_FIFO_ch2,
   FIFO1_empty_o => FIFO_empty_ch1,
   FIFO2_empty_o => FIFO_empty_ch2,
   FIFO1_data_o => data_FIFO_ch1,
   FIFO2_data_o => data_FIFO_ch2,
   LED_O => LED_o
 );
 
 Inst_ADC_Memory_ch1 : ADC_DataMemory
   port map (   
   Reset_I => Reset_I,                
   CLK_I => CLK100MHz_i,    
   ON_i => ON_ch1_i,            
   FIFO_empty_i => FIFO_empty_ch1,
   ram_addr_i => ram_addr_i,
   data_FIFO_i => data_FIFO_ch1,
   downsample_i => downsample_i,
   ram_read_i => ram_read_i,
   getBusControl_i  => getBusControl_i ,
   data_rdy_o => adc_drdy,
   Read_FIFO_o => read_FIFO_ch1,
   ram_addr_aux_o => ram_addr_aux,
   ram_data_o => data_ch1_o  
 );
 
  Inst_ADC_Memory_ch2 : ADC_DataMemory
   port map (   
   Reset_I => Reset_I,                
   CLK_I => CLK100MHz_i,   
   ON_i => ON_ch2_i,             
   FIFO_empty_i => FIFO_empty_ch2,
   ram_addr_i => ram_addr_i,
   data_FIFO_i => data_FIFO_ch2,
   downsample_i => downsample_i,
   ram_read_i => ram_read_i,
   getBusControl_i  => getBusControl_i ,
   data_rdy_o => open,
   Read_FIFO_o => read_FIFO_ch2,
   ram_data_o => data_ch2_o  
 );

  Inst_Trigger : Trigger
   port map (   
   Reset_I => Reset_I,                
   CLK_I => CLK100MHz_i,   
   data_i => data_FIFO_ch1,             
   ram_address_i => ram_addr_aux,
   trigger_i => triggerLevel_i,
   adc_drdy_i => adc_drdy,
   triggerEdge_i => triggerEdge_i,
   triggerAuto_i => triggerAuto_i,
   triggerSingle_i => triggerSingle_i,
   triggered_o => triggered_o,
   address_o  => trigger_addr_o  
 );
 
end Behavioral;
