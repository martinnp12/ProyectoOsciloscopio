----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.05.2021 10:51:34
-- Design Name: 
-- Module Name: TB_Oscilloscope - Behavioral
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

library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_Oscilloscope is
end tb_Oscilloscope;

architecture tb of tb_Oscilloscope is

    component Oscilloscope
        port (Reset_I       : in std_logic;
              CLK100MHz_I   : in std_logic;
              ON_ch1_i      : in std_logic;
              ON_ch2_i      : in std_logic;
              Vp_I          : in std_logic;
              Vn_I          : in std_logic;
              vauxp2_i      : in std_logic;
              vauxn2_i      : in std_logic;
              vauxp10_i     : in std_logic;
              vauxn10_i     : in std_logic;
              selector_i    : in STD_LOGIC;
              triggerEdge_i : in STD_LOGIC;
              triggerAuto_i : in STD_LOGIC;
              triggerSingle_i : in STD_LOGIC;
              measurements_en_i : in STD_LOGIC;
              showAVG_i : in STD_LOGIC;
              showPeak_i : in STD_LOGIC;
              showMax_i : in STD_LOGIC;
              showMin_i : in STD_LOGIC;
              btnu_I        : in std_logic;
              btnr_I        : in std_logic;
              btnd_I        : in std_logic;
              btnl_I        : in std_logic;
              btnc_I        : in std_logic;
              LED_O         : out std_logic_vector (15 downto 0);
              Temp_O        : out std_logic_vector (6 downto 0);
              Display_O     : out std_logic_vector (7 downto 0);
              VGA_HS_O      : out std_logic;
              VGA_VS_O      : out std_logic;
              VGA_RED_O     : out std_logic_vector (3 downto 0);
              VGA_BLUE_O    : out std_logic_vector (3 downto 0);
              VGA_GREEN_O   : out std_logic_vector (3 downto 0));
    end component;

    signal Reset_I       : std_logic := '0';
    signal CLK100MHz_I   : std_logic := '0';
    signal ON_ch1_i      : std_logic := '0';
    signal ON_ch2_i      : std_logic := '0';
    signal Vp_I          : std_logic := '0';
    signal Vn_I          : std_logic := '0';
    signal vauxp2_i      : std_logic := '0';
    signal vauxn2_i      : std_logic := '0';
    signal vauxp10_i     : std_logic := '0';
    signal vauxn10_i     : std_logic := '0';
    signal selector_i    : std_logic := '0';
    signal triggerEdge_i    : std_logic := '1';
    signal triggerAuto_i    : std_logic := '1';
    signal triggerSingle_i    : std_logic := '0';
    signal measurements_en_i : STD_LOGIC := '1';
    signal showAVG_i  : STD_LOGIC := '1';
    signal showPeak_i  : STD_LOGIC := '1';
    signal showMax_i  : STD_LOGIC := '1';
    signal showMin_i  : STD_LOGIC := '1';
    signal btnu_I        : std_logic := '0';
    signal btnr_I        : std_logic := '0';
    signal btnd_I        : std_logic := '0';
    signal btnl_I        : std_logic := '0';
    signal btnc_I        : std_logic := '0';
    signal LED_o         : std_logic_vector (15 downto 0);
    signal Temp_O        : std_logic_vector (6 downto 0);
    signal Display_O     : std_logic_vector (7 downto 0);
    signal VGA_HS_O      : std_logic;
    signal VGA_VS_O      : std_logic;
    signal VGA_RED_O     : std_logic_vector (3 downto 0);
    signal VGA_BLUE_O    : std_logic_vector (3 downto 0);
    signal VGA_GREEN_O   : std_logic_vector (3 downto 0);

    constant CLK_period : time := 10 ns;
    constant CLK2_period : time := 40 ns;
    signal CLK2 : STD_LOGIC;
    
    constant HI  : std_logic := '1';
    constant LOW : std_logic := '0';

    constant space : string := " ";
    constant colon : string := ":";
    
    file vga_log : text is out "./f_out.txt";    -- Better change for the full address

begin

    dut : Oscilloscope
    port map (Reset_I       => Reset_I,
              CLK100MHz_I   => CLK100MHz_I,
              ON_ch1_i      => ON_ch1_i,
              ON_ch2_i      => ON_ch2_i,
              Vp_I          => Vp_I,
              Vn_I          => Vn_I,
              vauxp2_i      => vauxp2_i,
              vauxn2_i      => vauxn2_i,
              vauxp10_i     => vauxp10_i,
              vauxn10_i     => vauxn10_i,
              selector_i    => selector_i,
              triggerEdge_i    => triggerEdge_i,
              triggerAuto_i    => triggerAuto_i,
              triggerSingle_i    => triggerSingle_i,
              measurements_en_i    => measurements_en_i,
              showAVG_i    => showAVG_i,
              showPeak_i    => showPeak_i,
              showMax_i    => showMax_i,
              showMin_i    => showMin_i,
              btnu_I        => btnu_I,
              btnr_I        => btnr_I,
              btnd_I        => btnd_I,
              btnl_I        => btnl_I,
              btnc_I        => btnc_I,
              LED_O         => LED_o,
              Temp_O        => Temp_O,
              Display_O     => Display_O,
              VGA_HS_O      => VGA_HS_O,
              VGA_VS_O      => VGA_VS_O,
              VGA_RED_O     => VGA_RED_O,
              VGA_BLUE_O    => VGA_BLUE_O,
              VGA_GREEN_O   => VGA_GREEN_O);

   -- Clock process definitions
   CLK_process :process
   begin
		CLK100MHz_I <= '1';
		wait for CLK_period/2;
		CLK100MHz_I <= '0';
		wait for CLK_period/2;		
   end process;
    
    CLK2_process :process
   begin
		CLK2 <= '1';
		wait for CLK2_period/2;
		CLK2 <= '0';
		wait for CLK2_period/2;		
   end process;
   
    stimuli : process
    begin
        ON_ch1_i <= '1';
        ON_ch2_i <= '1';
        selector_i <= '1';
        wait for CLK_period*15;
        Reset_I <= '1';
        wait for CLK_period*100;
        triggerAuto_i <= '1';

        wait;
    end process;
    
      
      output_process : process (CLK2)
        variable vga_line : line;
    begin
        if (rising_edge(CLK2)) then
            write(vga_line, now);
            write(vga_line, colon & space);
            write(vga_line, not VGA_HS_O);
            write(vga_line, space);
            write(vga_line, not VGA_VS_O);
            write(vga_line, space);
            write(vga_line, VGA_RED_O(2 downto 0));
            write(vga_line, space);
            write(vga_line, VGA_GREEN_O(2 downto 0));
            write(vga_line, space);
            write(vga_line, VGA_BLUE_O(2 downto 0));
            writeline(vga_log, vga_line);
        end if;
    end process;
 


end tb;