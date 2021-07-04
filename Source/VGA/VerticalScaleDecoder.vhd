----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.03.2021 19:28:56
-- Design Name: 
-- Module Name: VoltsDecoder - Behavioral
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
--use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VerticalScaleFactor is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           Data_I : in STD_LOGIC_VECTOR (3 downto 0);
           Data_O : out STD_LOGIC_VECTOR (21 downto 0));
end VerticalScaleFactor;

architecture Behavioral of VerticalScaleFactor is

--RAM memory for decoding parameter
SUBTYPE item_array8_ram IS std_logic_vector (21 downto 0);
TYPE array8_ram IS array (integer range <>) of item_array8_ram;
signal VoltsDecoder : array8_ram(0 to 15) := ("10" & x"191C0", -- dig1 & dig2 & dig3 & exp
                                              "01" & x"0C8E0",
                                              "00" & x"6B6C0",
                                              "00" & x"35B60",
                                              "00" & x"1ADB0",
                                              "00" & x"0ABE0",
                                              "00" & x"055F0",
                                              "00" & x"02AF8",
                                              "00" & x"01130",
                                              "00" & x"00898",
                                              "00" & x"0044C",
                                              "00" & x"001B8",
                                              "00" & x"000DC",
                                              "00" & x"0006E",
                                              "00" & x"0002C",
                                              "00" & x"00016"); 
signal Data_aux : STD_LOGIC_VECTOR (21 downto 0);            
begin

--Data codificator
DecoParam: process (reset_I, CLK_I, Data_I, VoltsDecoder)
begin
--    if reset_I = '0' then
--        Data_aux <= (Others => '0');
    if rising_edge(CLK_I) then
        Data_aux <= VoltsDecoder(to_integer(unsigned(Data_i)));
    end if;
end process;

Data_O <= Data_aux;

end Behavioral;
