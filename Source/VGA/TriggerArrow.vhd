----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 09:23:27
-- Design Name: 
-- Module Name: VPD_Channel1 - Behavioral
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
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all; 

use work.oscilloscope_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TriggerArrow is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_i : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           --H_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           --V_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           ROM_Data : in STD_LOGIC_VECTOR (SYMBOL_ROM_DATA_WIDTH - 1 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (SYMBOL_ROM_ADDR_WIDTH - 1 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end TriggerArrow;

architecture Behavioral of TriggerArrow is


--constant X_START : natural := 40;
--constant Y_START : natural := 5;



--signal en_x_i, en_y_i : std_logic;
signal x_pos : std_logic_vector (2 downto 0);
signal y_pos : std_logic_vector (2 downto 0);
signal digitCount : std_logic_vector (2 downto 0);
signal pxlCount : std_logic_vector (3 downto 0); -- 8 caracters need to be displayed
signal ROM_Addr_aux : std_logic_vector (8 downto 0);
--signal pxlData : std_logic;

--Data decoder signals

signal DataDeco_aux : std_logic_vector (15 downto 0);

signal Dir0, Dir1, Dir2, Dir3, Dir4, Dir5, Dir6, Dir7 : std_logic_vector (4 downto 0);

signal pxlState : std_logic;                                         
begin 

--------------------------------------------------
--Internal counters
--------------------------------------------------
          
--Horizontal counter

process(CLK_I, reset_i)
begin
    if reset_i = '0' then
        x_pos <= (Others => '0'); 
    elsif rising_edge(CLK_I) then
        if clk_pxl_i = '1' then
            if en_x_i = '1' then
                x_pos <= x_pos + 1;
            else
                x_pos <= (Others => '0');             
            end if;
        end if;
    end if;
    
end process;

--Internal V counters
process(CLK_I, reset_i)
begin
    if reset_i = '0' then
        y_pos <= (Others => '0');
    elsif rising_edge(CLK_I) then
        if clk_pxl_i = '1' then
            if en_y_i = '1' then
                if x_pos = SYMBOL_WIDTH - 1 then
                    y_pos <= y_pos + 1;
                end if; 
            else
                  y_pos <= (Others => '0');
            end if;
        end if;
    end if;
    
end process;


-------------------------------------------------
-- ROM control
-------------------------------------------------
--MUX ROM address


    

-- Row digit calc


--ROM_Addr <= (x"3" & "000") + y_pos; --3 * 8 + y_pos
ROM_Addr <= "00010" & y_pos when en_x_i = '1' and en_y_i = '1' else
            (Others => 'Z'); --CharacterNumer * 8 + y_pos

-------------------------------------------------
-- Pixel MUX
-------------------------------------------------

with x_pos select pxlState <=
    ROM_Data(0) when "111",
    ROM_Data(1) when "110",
    ROM_Data(2) when "101",
    ROM_Data(3) when "100",
    ROM_Data(4) when "011",
    ROM_Data(5) when "010",
    ROM_Data(6) when "001",
    ROM_Data(7) when others;


Red_O <= COLOR_GRID(11 downto 8) when pxlState = '1' else (Others => '0');
Green_O <= COLOR_GRID(7 downto 4) when pxlState = '1' else (Others => '0');
Blue_O <= COLOR_GRID(3 downto 0) when pxlState = '1' else (Others => '0');

end Behavioral;
