----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.05.2021 12:58:53
-- Design Name: 
-- Module Name: SymbolROM - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SymbolROM is
    Port ( clk_i : in STD_LOGIC;
           reset_i : in STD_LOGIC;
           addr_i : in STD_LOGIC_VECTOR (SYMBOL_ROM_ADDR_WIDTH - 1 downto 0);
           data_o : out STD_LOGIC_VECTOR (SYMBOL_ROM_DATA_WIDTH - 1 downto 0));
end SymbolROM;

architecture Behavioral of SymbolROM is
  signal rom : symbol_rom_t := (
        -- Trigger rising edge symbol
        "00001111",
        "00001000",
        "00001000",
        "00011100",
        "00111110",
        "01111111",
        "00001000",
        "01111000",
        -- Trigger falling edge symbol
        "01111000",
        "00001000",
        "01111111",
        "00111110",
        "00011100",
        "00001000",
        "00001000",
        "00000111",
        --Trigger arrow
        "10000000",
        "11100000",
        "11111000",
        "11111110",
        "11111110",
        "11111000",
        "11100000",
        "10000000");

signal data_aux : std_logic_vector (SYMBOL_ROM_DATA_WIDTH - 1 downto 0);
  
begin

reg : process(clk_i, reset_i)
begin
    if reset_i = '0' then
        data_aux <= (Others => '0');
    elsif rising_edge(clk_i) then
        data_aux <= rom(to_integer(unsigned(addr_i)));
    end if;
end process;

data_o <= data_aux;

end Behavioral;

