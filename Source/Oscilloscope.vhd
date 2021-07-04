----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2021 01:49:07
-- Design Name: 
-- Module Name: VGA_Opciones - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Oscilloscope is
    Port ( Reset_I : in STD_LOGIC;
           CLK100MHz_I : in STD_LOGIC;    
           --Data Acquisition
           ON_ch1_i : in std_logic;
           ON_ch2_i : in std_logic;
           Vp_I : in STD_LOGIC;
           Vn_I : in STD_LOGIC;
           vauxp2_i : in STD_LOGIC;
           vauxn2_i : in STD_LOGIC;
           vauxp10_i : in STD_LOGIC;
           vauxn10_i : in STD_LOGIC;
           selector_i : in STD_LOGIC;
           triggerEdge_i : in STD_LOGIC;
           triggerAuto_i : in STD_LOGIC;
           triggerSingle_i: in STD_LOGIC;
           
           showAVG_i : in STD_LOGIC;
           showPeak_i : in STD_LOGIC;
           showMax_i : in STD_LOGIC;
           showMin_i : in STD_LOGIC;
           
           --Measurements
           measurements_en_i : in STD_LOGIC;
           
           --Options
           btnu_I : in STD_LOGIC;           --upper button
           btnr_I : in STD_LOGIC;           --right button
           btnd_I : in STD_LOGIC;           --bottom button
           btnl_I : in STD_LOGIC;           --left button
           btnc_I : in STD_LOGIC;
           LED_O : out std_logic_vector (15 downto 0);
           Temp_O : out STD_LOGIC_vector (6 downto 0);
           Display_O : out STD_LOGIC_vector (7 downto 0);
           --CLK_aux: out STD_LOGIC;
           VGA_HS_O : out STD_LOGIC;
           VGA_VS_O : out STD_LOGIC;
           VGA_RED_O : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_BLUE_O : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_GREEN_O : out STD_LOGIC_VECTOR (3 downto 0));
end Oscilloscope;

architecture Behavioral of Oscilloscope is

--  component Clk_Gen
--    port (
--      resetn     : in  std_logic;
--      clk_in1   : in  std_logic;
--      clk_out1  : out  std_logic;
----      clk_out2  : out  std_logic;
--      locked    : out std_logic); 
--end component;

component DataAcquisition is
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
           triggerSingle_i: in STD_LOGIC;
           
           --Salidas
           triggered_o : out STD_LOGIC;
           trigger_addr_o : out STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
           data_ch1_o : out STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
           data_ch2_o : out STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
           LED_O : out std_logic_vector (15 downto 0));
end component;

component VGA
        port (Reset_I     : in std_logic;
              CLK_I       : in std_logic;
             -- CLK_aux       : out std_logic;
              VPD1_I      : in std_logic_vector (3 downto 0);
              VPD2_I      : in std_logic_vector (3 downto 0);
              TPD_I      : in std_logic_vector (3 downto 0);
              trigger_i : in std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);
              triggerEdge_i : in STD_LOGIC;
              trigger_addr_i : in STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
              triggered_i : in std_logic; 
              triggerAuto_i : in std_logic;
              showAVG_i : in STD_LOGIC;
              showPeak_i : in STD_LOGIC;
              showMax_i : in STD_LOGIC;
              showMin_i : in STD_LOGIC;
              ram_data_ch1_i : in STD_LOGIC_VECTOR (ADC_DATA_WIDTH - 1 downto 0);
              ram_data_ch2_i : in STD_LOGIC_VECTOR (ADC_DATA_WIDTH - 1 downto 0);
              peak1_i : in STD_LOGIC_VECTOR(16 downto 0);
              average1_i : in STD_LOGIC_VECTOR(16 downto 0);
              max1_i : in STD_LOGIC_VECTOR(16 downto 0);
              min1_i : in STD_LOGIC_VECTOR(16 downto 0);
              peak2_i : in STD_LOGIC_VECTOR(16 downto 0);
              average2_i : in STD_LOGIC_VECTOR(16 downto 0);
              max2_i : in STD_LOGIC_VECTOR(16 downto 0);
              min2_i : in STD_LOGIC_VECTOR(16 downto 0);
              ram_addr_o : out STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
              ram_read_en_o : out STD_LOGIC;
              giveBusControl_o : out STD_LOGIC;
              VGA_HS_O    : out std_logic;
              VGA_VS_O    : out std_logic;
              VGA_RED_O   : out std_logic_vector (3 downto 0);
              VGA_BLUE_O  : out std_logic_vector (3 downto 0);
              VGA_GREEN_O : out std_logic_vector (3 downto 0));
    end component;

component ButtonDriver_TOP is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;      --CLK 25 MHz
           btnu_I : in STD_LOGIC;           --upper button
           btnr_I : in STD_LOGIC;           --right button
           btnd_I : in STD_LOGIC;           --bottom button
           btnl_I : in STD_LOGIC;           --left button
           btnc_I : in STD_LOGIC;
           paramSelect_O : out std_logic_vector (3 downto 0);
           Temp_O : out STD_LOGIC_vector (6 downto 0);
           Display_O : out STD_LOGIC_vector (7 downto 0);
           VPD1_O : out STD_LOGIC_VECTOR (3 downto 0);
           VPD2_O : out STD_LOGIC_VECTOR (3 downto 0); 
           TPD_O : out STD_LOGIC_VECTOR (3 downto 0); 
           Trigger_O : out STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0)
           );
end component;

component VoltageMeasuerments is
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;
        en_i : in std_logic;
        on_i : in std_logic;
        data_i : in std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
        peak_bcd_o : out std_logic_vector(16 downto 0);
        average_bcd_o : out std_logic_vector(16 downto 0);
        max_bcd_o : out std_logic_vector(16 downto 0);
        min_bcd_o : out std_logic_vector(16 downto 0)
    );
end component;

signal CLK, CLK_VGA : std_logic;
signal VPD1_aux, VPD2_aux, TPD_aux: std_logic_vector (3 downto 0);
signal VPD1_reg, VPD2_reg, TPD_reg: std_logic_vector (3 downto 0);
signal trigger_aux : std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);
signal trigger_reg : std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);
--signal ShowFreq_aux : std_logic;
signal dataBusControl, dataBusControl_neg : std_logic;
signal data_ram_addr : std_logic_vector (RAM_ADDR_WIDTH - 1 downto 0);
signal data_ram_read : std_logic;
signal downsample : std_logic_vector (MAX_DOWNSAMPLE - 1 DOWNTO 0);
signal data_ch1, data_ch2: std_logic_vector (ADC_DATA_WIDTH -1 DOWNTO 0);
signal LED : std_logic_vector (15 downto 0);
signal paramSelect : std_logic_vector (3 downto 0);
signal triggered_aux : std_logic;
signal trigger_addr_aux : std_logic_vector (RAM_ADDR_WIDTH - 1 downto 0);

signal peak1_aux, avg1_aux, max1_aux, min1_aux: std_logic_vector(16 downto 0);
signal peak2_aux, avg2_aux, max2_aux, min2_aux: std_logic_vector(16 downto 0);

begin

process(reset_i, CLK100MHz_I)
begin
    if reset_i = '0' then
        VPD1_reg <= (Others => '0');
        VPD2_reg <= (Others => '0');
        TPD_reg <= (Others => '0');
        Trigger_reg <= (Others => '0');
    elsif rising_edge (CLK100MHz_I) then
        VPD1_reg <= VPD1_aux;
        VPD2_reg <= VPD2_aux;
        TPD_reg <= TPD_aux;
        Trigger_reg <= Trigger_aux;
    end if;
end process;
    
 downsample <= '1' & x"1C1" when TPD_aux = x"F" else
               '0' & x"8E3" when TPD_aux = x"E" else
               '0' & x"470" when TPD_aux = x"D" else
               '0' & x"1C6" when TPD_aux = x"C" else
               '0' & x"0E3" when TPD_aux = x"B" else
               '0' & x"071" when TPD_aux = x"A" else
               '0' & x"02D" when TPD_aux = x"9" else
               '0' & x"016" when TPD_aux = x"8" else
               '0' & x"00B" when TPD_aux = x"7" else
               '0' & x"004" when TPD_aux = x"6" else
               '0' & x"002" when TPD_aux = x"5" else
               '0' & x"001";
               
 LED_O <= "000000000000" & paramSelect when selector_i = '1' else
                  LED;           
--  Clock_generator : Clk_Gen
--    port map (
--      resetn    => reset_I,   
--      clk_in1  => Clk100MHz_I,
--      clk_out1 => CLK,
--      locked   => open);
    
    --CLK <= CLK100MHz_I;

Inst_DataAcquisition : DataAcquisition
    port map (Reset_I     => Reset_I,
              CLK100MHz_i       => Clk100MHz_I,
              ON_ch1_i  => ON_ch1_i,
              ON_ch2_i      => ON_ch2_i,
              Vp_I      => Vp_I,
              Vn_I    => Vn_I,
              vauxp2_i    => vauxp2_i,
              vauxn2_i   => vauxn2_i,
              vauxp10_i  => vauxp10_i,
              vauxn10_i  => vauxn10_i,
              getBusControl_i  => dataBusControl,
              ram_addr_i  => data_ram_addr,
              ram_read_i  => data_ram_read,
              downsample_i  =>downsample ,
              triggerLevel_i => trigger_aux,
              triggerEdge_i => triggerEdge_i,
              triggerAuto_i => triggerAuto_i,
              triggerSingle_i => triggerSingle_i,
              triggered_o => triggered_aux,
              trigger_addr_o => trigger_addr_aux,
              data_ch1_o  => data_ch1,
              data_ch2_o => data_ch2,
              LED_o => LED);
                
Inst_VGA : VGA
    port map (Reset_I     => Reset_I,
              CLK_I       => Clk100MHz_I,
              --CLK_aux       => CLK_aux,
              VPD1_I      => VPD1_reg,
              VPD2_I      => VPD2_reg,
              TPD_I      => TPD_reg,
              trigger_i  => trigger_reg,
              triggerEdge_i  => triggerEdge_i,
              trigger_addr_i =>trigger_addr_aux,
              triggered_i => triggered_aux, 
              triggerAuto_i => triggerAuto_i,
              ShowAVG_I => ShowAVG_I,
              ShowPeak_I => ShowPeak_I,
              ShowMax_I => ShowMax_I,
              ShowMin_I => ShowMin_I,
              ram_data_ch1_i      => data_ch1,
              ram_data_ch2_i      => data_ch2,
              peak1_i => peak1_aux,
              average1_i => avg1_aux,
              max1_i => max1_aux,
              min1_i => min1_aux,
              peak2_i => peak2_aux,
              average2_i => avg2_aux,
              max2_i => max2_aux,
              min2_i => min2_aux,
              giveBusControl_o      => dataBusControl,
              ram_addr_o      => data_ram_addr,
              ram_read_en_o      => data_ram_read,
              VGA_HS_O    => VGA_HS_O,
              VGA_VS_O    => VGA_VS_O,
              VGA_RED_O   => VGA_RED_O,
              VGA_BLUE_O  => VGA_BLUE_O,
              VGA_GREEN_O => VGA_GREEN_O);

Inst_ButtonDriver : ButtonDriver_TOP
    port map (Reset_I       => Reset_I,
              CLK_I         => Clk100MHz_I,
              btnu_I        => btnu_I,
              btnr_I        => btnr_I,
              btnd_I        => btnd_I,
              btnl_I        => btnl_I,
              btnc_I        => btnc_I,
              paramSelect_O => paramSelect,
              Temp_O        => Temp_O,
              Display_O     => Display_O,
              VPD1_O        => VPD1_aux,
              VPD2_O        => VPD2_aux,
              TPD_O         => TPD_aux,
              Trigger_O    => Trigger_aux
--              ShowVRMS_O    => ShowVRMS_O,
--              ShowVpp_O     => ShowVpp_O,
--              ShowVavg_O    => ShowVavg_O
              );
              
         

dataBusControl_neg <= not dataBusControl;
 
Inst_Measurements_CH1 : VoltageMeasuerments
    port map (clk_i     => CLK100MHz_I,
              reset_i   => reset_i,
              en_i      => measurements_en_i,
              on_i   => dataBusControl_neg,
              data_i    => data_ch1,
              peak_bcd_o  => peak1_aux,
              average_bcd_o => avg1_aux,
              max_bcd_o => max1_aux,
              min_bcd_o => min1_aux 
              );

Inst_Measurements_CH2 : VoltageMeasuerments
    port map (clk_i     => CLK100MHz_I,
              reset_i   => reset_i,
              en_i      => measurements_en_i,
              on_i   => dataBusControl_neg,
              data_i    => data_ch2,
              peak_bcd_o  => peak2_aux,
              average_bcd_o => avg2_aux,
              max_bcd_o => max2_aux,
              min_bcd_o => min2_aux 
              );
              


end Behavioral;
