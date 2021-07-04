----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:45:00 04/11/2018 
-- Design Name: 
-- Module Name:    Binario_BCD - Behavioral 
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
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bin2bcd is
    Port ( reset_i : in std_logic;
           clk_i : in std_logic;
           bin_i : in  STD_LOGIC_VECTOR (11 downto 0);
           bcd_o : out  STD_LOGIC_VECTOR (15 downto 0));
end bin2bcd;

architecture Behavioral of bin2bcd is

--component Bin_BCD_Decimal_MaxMin is
--    Port ( Binario : in  STD_LOGIC_VECTOR (5 downto 0);
--           BCD : out  STD_LOGIC_VECTOR (7 downto 0));
--end component;

signal bin_reg : STD_LOGIC_VECTOR (15 downto 0);
signal numero : std_logic_vector(11 downto 0);
signal A,B,C, D, E, F, G, H, I, J, K, L: STD_LOGIC_VECTOR (15 downto 0);
signal BCD : STD_LOGIC_VECTOR (15 downto 0);

begin


--A<=numero&"00";
--B<='0'&numero&'0';
--C<="0000"&numero(3 downto 2);

numero <= bin_i;
A <=x"1388" when bin_i(11) = '1' else (Others => '0');
B <= x"09CA" when bin_i(10) = '1' else (Others => '0');
C <= x"04E2" when bin_i(9) = '1' else (Others => '0');
D <= x"0271" when bin_i(8) = '1' else (Others => '0');
E <= x"0138" when bin_i(7) = '1' else (Others => '0');
F <= x"009C" when bin_i(6) = '1' else (Others => '0');
G <= x"004E" when bin_i(5) = '1' else (Others => '0');
H <= x"0027" when bin_i(4) = '1' else (Others => '0');
I <= x"0013" when bin_i(3) = '1' else (Others => '0');
J <= x"0009" when bin_i(2) = '1' else (Others => '0');
K <= x"0004" when bin_i(1) = '1' else (Others => '0');
L <= x"0002" when bin_i(0) = '1' else (Others => '0');

process(reset_i, clk_i)
begin
    if reset_i = '0' then
        bin_reg <= (Others => '0');
    elsif rising_edge(clk_i) then
        bin_reg<=A+B+C+D+E+F+G+H+I;
    end if;
end process;

process(bin_reg)
 
	variable z : std_logic_vector (35 downto 0);
	
begin

	z:=(others=>'0');		
	
	z(18 downto 3):=bin_reg;  --Los 3 primeros desplazamientos nunca van a dar mas de 5, ni aunque sean todo '1'.
	
	for i in 0 to 12 loop
	
		if z(19 downto 16)>4 then
			z(19 downto 16):=z(19 downto 16)+3;
		end if;
		
		if z(23 downto 20)>4 then
			z(23 downto 20):=z(23 downto 20)+3;
		end if;
		
		if z(27 downto 24)>4 then
			z(27 downto 24):=z(27 downto 24)+3;
		end if;
		
		if z(31 downto 28)>4 then
			z(31 downto 28):=z(31 downto 28)+3;
		end if;
		
		if z(35 downto 32)>4 then
			z(35 downto 32):=z(35 downto 32)+3;
		end if;
		
		z(35 downto 1):=z(34 downto 0);
		
	end loop;
	
	BCD<=z(31 downto 16);
	
end process;

bcd_o <= BCD;



end Behavioral;

