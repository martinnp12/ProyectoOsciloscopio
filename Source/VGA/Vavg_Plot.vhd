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
use ieee.numeric_std.all; 

use work.oscilloscope_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Vavg_Plot is
    Generic ( CHANNEL : integer range 0 to N_CHANNELS;
              COLOR : std_logic_vector(11 downto 0));
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_I : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           average_I : in STD_LOGIC_VECTOR (16 DOWNTO 0);   --Average in BCD
           ROM_Data : in STD_LOGIC_VECTOR (7 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (7 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end Vavg_Plot;

architecture Behavioral of Vavg_Plot is

--signal en_x_i, en_y_i : std_logic;
signal x_pos : unsigned (7 downto 0);
signal y_pos : unsigned (2 downto 0);
signal digitCount : unsigned (3 downto 0);
signal pxlCount : unsigned (3 downto 0); -- 12 caracters need to be displayed
signal ROM_Addr_aux : std_logic_vector (4 downto 0);
--signal pxlData : std_logic;


signal Dir0, Dir1, Dir2, Dir3, Dir4, Dir5, Dir6, Dir7, Dir8, Dir9, Dir10, Dir11, Dir12 : std_logic_vector (4 downto 0);

signal pxlState : std_logic;                                         
begin


Dir0 <= "01111"; --15 (V)"01100"; --12  (=)
Dir1 <= "11100"; --28  (a)
Dir2 <= "11101"; --29  (v)
Dir3 <= "11110"; --30  (g)
Dir4 <= "01100"; --12  (=)

Dir5 <= "11010" when average_i(16) = '1' else "10110";

with average_i(15 downto 12) select Dir6 <= 
    "00000" when x"0",
    "00001" when x"1",
    "00010" when x"2",
    "00011" when x"3",
    "00100" when x"4",
    "00101" when x"5",
    "00110" when x"6",
    "00111" when x"7",
    "01000" when x"8",
    "01001" when x"9",
    "10110" when others;
    
with average_i(11 downto 8) select Dir7 <= 
    "00000" when x"0",
    "00001" when x"1",
    "00010" when x"2",
    "00011" when x"3",
    "00100" when x"4",
    "00101" when x"5",
    "00110" when x"6",
    "00111" when x"7",
    "01000" when x"8",
    "01001" when x"9",
    "10110" when others;
       
with average_i(7 downto 4) select Dir8 <= 
    "00000" when x"0",
    "00001" when x"1",
    "00010" when x"2",
    "00011" when x"3",
    "00100" when x"4",
    "00101" when x"5",
    "00110" when x"6",
    "00111" when x"7",
    "01000" when x"8",
    "01001" when x"9",
    "10110" when others;

Dir9 <= "01010";    --10  (.)

with average_i(3 downto 0) select Dir10 <= 
    "00000" when x"0",
    "00001" when x"1",
    "00010" when x"2",
    "00011" when x"3",
    "00100" when x"4",
    "00101" when x"5",
    "00110" when x"6",
    "00111" when x"7",
    "01000" when x"8",
    "01001" when x"9",
    "10110" when others;
       

Dir11 <= "01110"; --14 (m)
Dir12 <= "01111"; --15 (V)


--------------------------------------------------
--Internal counters
--------------------------------------------------
          
--Horizontal counter

process(CLK_I, reset_i)
begin
    if reset_i = '0' then
        x_pos <= (Others => '0');
        pxlCount <= (Others => '0');              
        digitCount <= (Others => '0'); 
    elsif rising_edge(CLK_I) then
        if clk_pxl_i = '1' then
            if en_x_i = '1' then
                x_pos <= x_pos + 1;
                pxlCount <= pxlCount + 1;
                if pxlCount = DIGIT_WIDTH - 1 then
                    digitCount <= digitCount + 1;
                    pxlCount <= (Others => '0');
                end if;
            else
                x_pos <= (Others => '0');
                pxlCount <= (Others => '0');              
                digitCount <= (Others => '0');              
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
                if x_pos = MEASUREMENT_WIDTH - 1 then
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

with digitCount select ROM_Addr_aux <=
    Dir0 when "0000",
    Dir1 when "0001",
    Dir2 when "0010",
    Dir3 when "0011",
    Dir4 when "0100",
    Dir5 when "0101",
    Dir6 when "0110",
    Dir7 when "0111",
    Dir8 when "1000",
    Dir9 when "1001",
    Dir10 when "1010",
    Dir11 when "1011",
    Dir12 when "1100",
    "10110" when others;
    

-- Row digit calc

--ROM_Addr <= (ROM_Addr_aux & "000") + y_pos; --CharacterNumer * 8 + y_pos
ROM_Addr <= ROM_Addr_aux & std_logic_vector(y_pos) when en_x_i = '1' and en_y_i = '1' else
            (Others => 'Z'); --CharacterNumer * 8 + y_pos

-------------------------------------------------
-- Pixel MUX
-------------------------------------------------

with pxlCount select pxlState <=
    ROM_Data(7) when "0010",
    ROM_Data(6) when "0011",
    ROM_Data(5) when "0100",
    ROM_Data(4) when "0101",
    ROM_Data(3) when "0110",
    ROM_Data(2) when "0111",
    ROM_Data(1) when "1000",
    ROM_Data(0) when "1001",
    '0' when others;
           

Red_O <= COLOR(11 downto 8) when pxlState = '1' else (Others => '0');
Green_O <= COLOR(7 downto 4) when pxlState = '1' else (Others => '0');
Blue_O <= COLOR(3 downto 0) when pxlState = '1' else (Others => '0');

end Behavioral;
