----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.03.2021 11:12:32
-- Design Name: 
-- Module Name: GridDisplay - Behavioral
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

entity GridDisplay is
    Port ( Reset_I : in STD_LOGIC; --Low level reset
           CLK_I : in STD_LOGIC;
           clk_pxl_i : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           data_ch1_i : in STD_LOGIC_VECTOR(PLOT_HEIGHT_BIT_LENGTH - 1 downto 0);
           data_ch2_i : in STD_LOGIC_VECTOR(PLOT_HEIGHT_BIT_LENGTH - 1 downto 0);  
           buffer_addr_o : out STD_LOGIC_VECTOR(PLOT_WIDTH_BIT_LENGTH - 1 downto 0);
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end GridDisplay;

architecture Behavioral of GridDisplay is




signal x_plot : std_logic_vector (PLOT_WIDTH_BIT_LENGTH - 1 downto 0);
signal y_plot : std_logic_vector (PLOT_HEIGHT_BIT_LENGTH - 1 downto 0);
signal x_grid : std_logic_vector (GRID_WIDTH_BIT_LENGTH - 1 downto 0);
signal y_grid : std_logic_vector (GRID_WIDTH_BIT_LENGTH - 1 downto 0);
--signal pxlState : std_logic;

signal red_aux, green_aux, blue_aux : std_logic_vector(3 downto 0);

begin


          

--Internal H counters
process(CLK_I, reset_i)
begin
    if reset_i = '0' then
        x_plot <= (Others => '0');  
        x_grid <= (Others => '0'); 
    elsif rising_edge(CLK_I) then
        if clk_pxl_i = '1' then
            if en_x_i = '1' then
                x_plot <= x_plot + 1;
                if x_grid = GRID_WIDTH - 1 then
                    x_grid <= (others => '0');
                else
                    x_grid <= x_grid + 1;
                end if;
            else
                x_plot <= (Others => '0');  
                x_grid <= (Others => '0');            
            end if;
        end if;
    end if;
    
end process;

buffer_addr_o <= x_plot;

--Internal V counters
process(CLK_I, reset_i)
begin
    if reset_i = '0' then
        y_plot <= (Others => '0');
        y_grid <= (Others => '0'); 
    elsif rising_edge(CLK_I) then
        if clk_pxl_i = '1' then
            if en_y_i = '1' then
                if x_plot = PLOT_WIDTH - 1 then
                    y_PLOT <= y_PLOT + 1; 
                    if y_grid = GRID_HEIGHT - 1 then
                        y_grid <= (others => '0');
                    else
                        y_grid <= y_grid + 1;
                    end if;   
                end if;  
            else
                  y_plot <= (Others => '0');
                  y_grid <= (Others => '0');  
            end if;
        end if;
    end if;
    
end process;

--Creacion del marco y regilla
process(en_y_i, x_PLOT, y_PLOT, x_grid, y_grid, en_x_i, en_y_i, data_ch1_i, data_ch2_i)
     begin
        red_aux <= (Others => '0');
        green_aux <= (Others => '0');  
        blue_aux <= (Others => '0');
         --Recuadro
         if en_x_i = '1' and en_y_i = '1' then
         --PLOT
             if ((x_plot >= 0) and (x_plot <= 2))  or ((x_plot >= (PLOT_WIDTH-2)) and (x_plot <= (PLOT_WIDTH))) then
                red_aux <= COLOR_GRID(11 downto 8);
                green_aux <= COLOR_GRID(7 downto 4);  
                blue_aux <= COLOR_GRID(3 downto 0);
             end if;
             
             if ((y_plot >= 0) and (y_plot <= 2))  or ((y_plot >= (PLOT_HEIGHT-2)) and (y_plot <= (PLOT_HEIGHT))) then
               red_aux <= COLOR_GRID(11 downto 8);
               green_aux <= COLOR_GRID(7 downto 4);  
               blue_aux <= COLOR_GRID(3 downto 0);
             end if;       

            if (x_plot = 0)  or (x_plot = PLOT_WIDTH+1) then
               red_aux <= COLOR_GRID(11 downto 8);
               green_aux <= COLOR_GRID(7 downto 4);  
               blue_aux <= COLOR_GRID(3 downto 0);
             end if;
             
             if (y_plot = 0)  or (y_plot = PLOT_HEIGHT+1) then
               red_aux <= COLOR_GRID(11 downto 8);
               green_aux <= COLOR_GRID(7 downto 4);  
               blue_aux <= COLOR_GRID(3 downto 0);
             end if;  
             
----             -- Regilla
             if data_ch1_i = y_plot then
                red_aux <= COLOR_CH1(11 downto 8);
                green_aux <= COLOR_CH1(7 downto 4);  
                blue_aux <= COLOR_CH1(3 downto 0);
             elsif data_ch2_i = y_plot then
             --if data_ch2_i = y_plot then
                red_aux <= COLOR_CH2(11 downto 8);
                green_aux <= COLOR_CH2(7 downto 4);  
                blue_aux <= COLOR_CH2(3 downto 0);
             elsif x_grid = GRID_WIDTH - 1 or y_grid = GRID_HEIGHT - 1 then
                red_aux <= COLOR_GRID(11 downto 8);
                green_aux <= COLOR_GRID(7 downto 4);  
                blue_aux <= COLOR_GRID(3 downto 0);
             end if;
         end if;
     end process;
     
-- Z RGB
Red_O <= red_aux;
Green_O <= green_aux;
Blue_O <= blue_aux;

end Behavioral;

