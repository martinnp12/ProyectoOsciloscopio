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

entity VoltsPerDivision is
    Generic ( CHANNEL : integer range 0 to N_CHANNELS;
              COLOR : std_logic_vector(11 downto 0));
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_i : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           --H_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           --V_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           VPD_I : in STD_LOGIC_VECTOR (3 DOWNTO 0);
           ROM_Data : in STD_LOGIC_VECTOR (7 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (7 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end VoltsPerDivision;

architecture Behavioral of VoltsPerDivision is

component VoltsDecoder is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           Data_I : in STD_LOGIC_VECTOR (3 downto 0);
           Data_O : out STD_LOGIC_VECTOR (15 downto 0));
end component;

--constant X_START : natural := 40;
--constant Y_START : natural := 5;



--signal en_x_i, en_y_i : std_logic;
signal x_pos : std_logic_vector (6 downto 0);
signal y_pos : std_logic_vector (2 downto 0);
signal digitCount : std_logic_vector (2 downto 0);
signal pxlCount : std_logic_vector (3 downto 0); -- 8 caracters need to be displayed
signal ROM_Addr_aux : std_logic_vector (4 downto 0);
--signal pxlData : std_logic;

--Data decoder signals

signal DataDeco_aux : std_logic_vector (15 downto 0);

signal Dir0, Dir1, Dir2, Dir3, Dir4, Dir5, Dir6, Dir7 : std_logic_vector (4 downto 0);

signal pxlState : std_logic;  
signal red_aux, green_aux, blue_aux : std_logic_vector(3 downto 0);
                                       
begin

--en <= '1' when (H_COUNT_I >= X_START-1 and H_COUNT_I <= X_START + TOTAL_WIDTH - 1)  
--                  and (V_COUNT_I >= Y_START-1 and V_COUNT_I <= Y_START + TOTAL_HEIGHT - 1) 
--                  else '0';

--en_y_i <= '1' when (V_COUNT_I >= Y_START-1 and V_COUNT_I <= Y_START + TOTAL_HEIGHT - 2) else '0';
--en_x_i <= '1' when ((H_COUNT_I >= X_START-1 and H_COUNT_I <= X_START + TOTAL_WIDTH - 2) and en_y_i = '1') else '0';
 

Inst_DataDecoder : VoltsDecoder
    port map (Reset_I => Reset_I,
              CLK_I   => CLK_I,
              Data_I  => VPD_I,
              Data_O  => DataDeco_aux);
          
--Text generator

Dir0 <= std_logic_vector(to_unsigned(CHANNEL, 5));
Dir1 <= "01011";

with DataDeco_aux(15 downto 12) select Dir2 <= 
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
    
with DataDeco_aux(11 downto 8) select Dir3 <= 
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
       
with DataDeco_aux(7 downto 4) select Dir4 <= 
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

--Dir5 <= "10110";

with DataDeco_aux(3 downto 0) select Dir5 <= 
    "01101" when x"6",
    "01110" when x"3",
    "10110" when others;

Dir6 <= "01111";
Dir7 <= "10001";

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
                if x_pos = SETTING_WIDTH - 1 then
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
    Dir0 when "000",
    Dir1 when "001",
    Dir2 when "010",
    Dir3 when "011",
    Dir4 when "100",
    Dir5 when "101",
    Dir6 when "110",
    Dir7 when others;
    

-- Row digit calc

--ROM_Addr <= (ROM_Addr_aux & "000") + y_pos; --CharacterNumer * 8 + y_pos
ROM_Addr <= ROM_Addr_aux & y_pos when en_x_i = '1' and en_y_i = '1' else
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

---------------------------------------------------
-- Colour MUX
---------------------------------------------------
red_aux <= COLOR(11 downto 8) WHEN digitCount = "000" or digitCount = "001" else
           COLOR_GRID(11 downto 8);
green_aux <= COLOR(7 downto 4) WHEN digitCount = "000" or digitCount = "001" else
           COLOR_GRID(7 downto 4);
blue_aux <= COLOR(3 downto 0) WHEN digitCount = "000" or digitCount = "001" else
           COLOR_GRID(3 downto 0);
           
Red_O <= red_aux when pxlState = '1' else (Others => '0');
Green_O <= green_aux when pxlState = '1' else (Others => '0');
Blue_O <= blue_aux when pxlState = '1' else (Others => '0');

end Behavioral;
