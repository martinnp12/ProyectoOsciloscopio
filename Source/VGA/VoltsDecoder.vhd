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

entity VoltsDecoder is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           Data_I : in STD_LOGIC_VECTOR (3 downto 0);
           Data_O : out STD_LOGIC_VECTOR (15 downto 0));
end VoltsDecoder;

architecture Behavioral of VoltsDecoder is

--RAM memory for decoding parameter
SUBTYPE item_array8_ram IS std_logic_vector (15 downto 0);
TYPE array8_ram IS array (integer range <>) of item_array8_ram;
signal VoltsDecoder : array8_ram(0 to 15) := (x"D106", -- dig1 & dig2 & dig3 & exp
                                              x"D206",
                                              x"D506",
                                              x"1006",
                                              x"2006",
                                              x"5006",
                                              x"DD13",
                                              x"DD23",
                                              x"DD53",
                                              x"D103",
                                              x"D203",
                                              x"D503",
                                              x"1003",
                                              x"2003",
                                              x"5003",
                                              x"DD10"); 
signal Data_aux : STD_LOGIC_VECTOR (15 downto 0);            
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
