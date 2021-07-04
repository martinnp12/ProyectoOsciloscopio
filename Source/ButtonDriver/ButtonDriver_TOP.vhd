----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.02.2021 20:10:21
-- Design Name: 
-- Module Name: ButtonDriver_TOP - Behavioral
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

use work.oscilloscope_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ButtonDriver_TOP is
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
end ButtonDriver_TOP;


architecture Behavioral of ButtonDriver_TOP is

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
  
component Debouncer is
   port(
      CLK       : in std_logic;
      reset     : in std_logic;
      sig_in   : in std_logic;
      sig_out  : out std_logic);
end component;

component DriverBotones is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;  --20 MHz       
           Increase_I : in STD_LOGIC;
           IncreaseQuick_I : in STD_LOGIC;
           Decrease_I : in STD_LOGIC;
           DecreaseQuick_I : in STD_LOGIC;
           OK_I : in STD_LOGIC;
           --Aux
           paramSelect_O : out std_logic_vector (3 downto 0);   
           --Options memory outputs
           VPD1_O : out STD_LOGIC_VECTOR (3 downto 0);
           VPD2_O : out STD_LOGIC_VECTOR (3 downto 0); 
           TPD_O : out STD_LOGIC_VECTOR (3 downto 0); 
           Trigger_O : out STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0));
end component;

component ControladorDisplay is
    Port ( Reset : in STD_LOGIC;
           CLK : in STD_LOGIC;                              --System clock 20 MHz
           VPD1_I : in STD_LOGIC_VECTOR (3 downto 0);
           VPD2_I : in STD_LOGIC_VECTOR (3 downto 0);
           TPD_I : in STD_LOGIC_VECTOR (3 downto 0);
           Trigger_I : in STD_LOGIC_VECTOR (ADC_DATA_WIDTH - 1 downto 0);
           paramSelect : in STD_LOGIC_VECTOR (3 downto 0);
           Temp : out STD_LOGIC_VECTOR (6 downto 0);
           Display : out STD_LOGIC_VECTOR (7 downto 0));
end component;


------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

--signal CLK : std_logic;

--Debouncer signals
signal btnu_aux, btnr_aux, btnd_aux, btnl_aux, btnc_aux : std_logic;

--DisplayDriver signals
signal VisualizacionParametro_aux: std_logic_vector (3 downto 0);

signal paramSelect_aux: std_logic_vector (3 downto 0);
signal VPD1_aux, VPD2_aux, TPD_aux: std_logic_vector (3 downto 0);
signal Trigger_aux: std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);





begin



--ANTIRREBOTES BOTONES
Inst_Btnu: Debouncer
   port map(
      CLK       => CLK_I,
      reset     => reset_I,
      sig_in    => btnu_I,
      sig_out   => btnu_aux);
      
Inst_Btnr: Debouncer
   port map(
      CLK       => CLK_I,
      reset     => reset_I,
      sig_in    => btnr_I,
      sig_out   => btnr_aux);
      
Inst_Btnd: Debouncer
   port map(
      CLK       => CLK_I,
      reset     => reset_I,
      sig_in    => btnd_I,
      sig_out   => btnd_aux);
      
Inst_Btnl: Debouncer
   port map(
      CLK       => CLK_I,
      reset     => reset_I,
      sig_in    => btnl_I,
      sig_out   => btnl_aux);
      
Inst_Btnc: Debouncer
   port map(
      CLK       => CLK_I,
      reset     => reset_I,
      sig_in    => btnc_I,
      sig_out   => btnc_aux);           
 
  Inst_DriverBotones: DriverBotones
    port map (
        Reset_I  => Reset_I,
        Clk_I    => CLK_I,
        Increase_I    => btnu_aux,
        IncreaseQuick_I    => btnr_aux,
        Decrease_I   => btnd_aux,
        DecreaseQuick_I   => btnl_aux,
        OK_I   => btnc_aux,
        paramSelect_O   => paramSelect_aux,
         VPD1_O   => VPD1_aux,
        VPD2_O   => VPD2_aux,
        TPD_O   => TPD_aux,
        Trigger_O => Trigger_aux);    
        
        
 Inst_ControladorDisplay: ControladorDisplay
    port map (
        Reset  => Reset_I,
        Clk    => CLK_I,
        VPD1_I => VPD1_aux,
        VPD2_I => VPD2_aux,
        TPD_I => TPD_aux,
        Trigger_I => Trigger_aux,
        paramSelect => paramSelect_aux,
        Temp    => Temp_O,
        Display    => Display_O); 
 
 
 paramSelect_O <= paramSelect_aux;
 VPD1_O   <= VPD1_aux;
 VPD2_O   <= VPD2_aux;
 TPD_O   <= TPD_aux;
 Trigger_O <= Trigger_aux;
end Behavioral;
