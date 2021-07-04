----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.04.2021 11:38:57
-- Design Name: 
-- Module Name: RAM - Behavioral
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
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;

USE work.oscilloscope_pkg.all;

ENTITY RAM IS
PORT (
   clk_i      : in    std_logic;
   address_i  : in    std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
   databus_io : inout std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
   write_en_i : in    std_logic;
   read_en_i : in    std_logic);
END RAM;

ARCHITECTURE behavior OF RAM IS

  
  SIGNAL ContentRAM : array_ram(0 to RAM_ADDR_LENGTH);  
                
BEGIN

-------------------------------------------------------------------------
-- Memoria de propósito general
-------------------------------------------------------------------------
GeneralRAM : process (clk_i, address_i, databus_io, write_en_i)  -- no reset (Hacer 2 process?)
begin 
  if clk_i'event and clk_i = '1' then
        if write_en_i = '1' then
            ContentRAM(TO_INTEGER(unsigned(address_i))) <= databus_io;
        end if;
--        if read_en_i = '1' then
--            databus_io <= ContentRAM(to_integer(unsigned(address_i)));
--        else
--            databus_io <= (Others => 'Z');
--        end if;
     end if;
end process;

databus_io <= ContentRAM(to_integer(unsigned(address_i))) when read_en_i = '1' else (others => 'Z');

END behavior;

