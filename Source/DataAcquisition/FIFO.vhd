----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.02.2021 16:08:49
-- Design Name: 
-- Module Name: FIFO - Behavioral
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
use work.oscilloscope_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FIFO is
    Port ( reset_i : in STD_LOGIC;
           clk_i : in STD_LOGIC;
           data_i : in STD_LOGIC_VECTOR (11 downto 0);
           wr_en_i : in STD_LOGIC;
           rd_en_i : in STD_LOGIC;
           data_o : out STD_LOGIC_VECTOR (11 downto 0);
           full_o : out STD_LOGIC;
           empty_o : out STD_LOGIC);
end FIFO;

architecture Behavioral of FIFO is

SIGNAL ContentFIFO : array_fifo(0 to FIFO_LENGTH - 1);  
signal dataCount : natural range 0 to FIFO_LENGTH - 1;
--signal dataCount : std_logic_vector(3 downto 0);
signal comp : std_logic;
begin
comp <= '1' when std_logic_vector(to_unsigned(dataCount, 4)) < FIFO_LENGTH - 1 else '0';
process(reset_i, clk_i)
begin
    if reset_i = '0' then
        for i in 0 to FIFO_LENGTH - 1 loop
            ContentFIFO(i) <= (Others => '0');
        end loop;
        dataCount <= 0;
        data_o <= (Others => '0');
    elsif rising_edge(clk_i) then
        if wr_en_i = '1' then
            
            if dataCount < FIFO_LENGTH - 1 then
                dataCount <= dataCount + 1;

            end if;
            contentFIFO(dataCount) <= data_i;
        elsif rd_en_i = '1' then
            if dataCount > 0 then
                dataCount <= dataCount - 1;
            end if;
            
            data_o <= ContentFIFO(0);
            for i in 0 to FIFO_LENGTH - 2 loop
                ContentFIFO(i) <= contentFIFO(i + 1);
            end loop;
        end if;
        
     end if;
end process;

empty_o <= '1' when dataCount = 0 else '0';
full_o <= '1' when dataCount = FIFO_LENGTH - 1 else '0';

end Behavioral;
