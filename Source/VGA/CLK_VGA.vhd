----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:33:38 02/14/2018 
-- Design Name: 
-- Module Name:    Divisor_1_exacto - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use ieee.std_logic_unsigned.all;
use work.oscilloscope_pkg.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CLK_VGA is
    Port ( CLK_i : in  STD_LOGIC;
           reset_i : in  STD_LOGIC;
           Clk_o : out  STD_LOGIC);
end CLK_VGA;

architecture Behavioral of CLK_VGA is

	--signal count: integer range 0 to CLK_COUNT;
	signal count: integer range 0 TO CLK_COUNT - 1;

begin

process(CLK_i,reset_i)

begin

if reset_i = '0' then
	count <= 0 ;
elsif rising_edge(CLK_i) then
	if count = CLK_COUNT - 1 then 
		count <= 0;
	else
		count <= count + 1;
	end if;
end if;
end process;

Clk_o<= '1' when count = CLK_COUNT - 1 else '0';

end Behavioral;

