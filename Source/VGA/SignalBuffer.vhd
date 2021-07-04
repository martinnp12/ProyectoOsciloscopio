----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2021 01:22:36
-- Design Name: 
-- Module Name: SignalBuffer - Behavioral
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

entity SignalBuffer is
    Port ( reset_i : in STD_LOGIC;
           CLK_i : in STD_LOGIC;
           data_i : in STD_LOGIC_VECTOR (ADC_DATA_WIDTH - 1 downto 0);
           v_sync_i : in STD_LOGIC;
           plot_en_i : in STD_LOGIC;                        --plot enable in the y axis
           VPD_I : in STD_LOGIC_VECTOR (3 DOWNTO 0);
           
           trigger_addr_i : in STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
           triggered_i : in std_logic; 
           
           buffer_addr_i : in STD_LOGIC_VECTOR(PLOT_WIDTH_BIT_LENGTH - 1 downto 0);
           ram_addr_o : out STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
           
           scaleFactor_o : out STD_LOGIC_VECTOR(21 downto 0);
           
           ram_read_en_o : out STD_LOGIC;
           giveBusControl_o : out STD_LOGIC;
           data_o : out STD_LOGIC_VECTOR(PLOT_HEIGHT_BIT_LENGTH - 1 downto 0));
end SignalBuffer;

architecture Behavioral of SignalBuffer is

component VerticalScaleFactor is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           Data_I : in STD_LOGIC_VECTOR (3 downto 0);
           Data_O : out STD_LOGIC_VECTOR (21 downto 0));
end component;

 --FSM signals
   TYPE Estados IS (Idle, Write, Read);
   SIGNAL CurrentState, NextState: Estados;
   
   
   signal copyEnded : std_logic;
   
 -- input regs
 
    signal data_reg : signed(ADC_DATA_WIDTH - 1 downto 0);
    
-- Buffer signals
  
   SIGNAL buffer_data : array_buffer(0 to PLOT_WIDTH); 
   signal write_en, read_en : std_logic;
   signal buffer_addr, buffer_addr_aux : integer range 0 to PLOT_WIDTH - 1;
   --signal buffer_addr_aux: integer range 0 to PLOT_WIDTH; 
   signal data_conv : signed(ADC_DATA_WIDTH + 23 - 1 downto 0);
   signal data_conv_aux : std_logic_vector(PLOT_HEIGHT_BIT_LENGTH - 1 downto 0);
   
   signal GND : natural := (PLOT_HEIGHT - 1)/2;
   signal scaleFactor, scaleFactor_reg: std_logic_vector(21 downto 0);
   
   signal reset_triggered, reg_triggered : std_logic;
   signal reg_address : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
   signal ram_addr : unsigned(RAM_ADDR_WIDTH - 1 downto 0);
   signal cnt_aux : integer;
begin

------------------------------------------------------
-- FSM
------------------------------------------------------

Sync: process(Reset_I, CLK_I)
begin
    if Reset_I = '0' then
        CurrentState <= Idle;
    elsif CLK_I'event AND CLK_I = '1' then
        CurrentState <= NextState;
    end if;
end process;

NextState_proc: process(CurrentState, CLK_I, v_sync_i, plot_en_i, copyEnded, reg_triggered)
begin
    case CurrentState is
        when Idle =>
            if plot_en_i = '1' then
                NextState <= Read;
            elsif v_sync_i = '1' and reg_triggered = '1' then
                NextState <= Write;
            else
                NextState <= Idle;
            end if;
        when Write =>
            if copyEnded = '1' then
                NextState <= Idle;
            else
                NextState <= Write;
            end if;
        when Read =>
            if plot_en_i = '0' then
                NextState <= Idle;
            else
                NextState <= Read;
            end if;    
    end case;    
end process;

--Codificación de las saldas:


giveBusControl_o <= '0' when CurrentState = Write else '1';
write_en <= '1' when CurrentState = Write else '0';
ram_read_en_o <= '1' when CurrentState = Write else '0';
--databus <= data_conv when CurrentState = Write else (Others => 'Z');
read_en <= '1' when CurrentState = Read else '0';
buffer_addr <= buffer_addr_aux when CurrentState = Write else to_integer(unsigned(buffer_addr_i));

ram_addr_o <= std_logic_vector(ram_addr) when CurrentState = Write else (Others => 'Z');
--reset_triggered <= '1' when CurrentState = Read else '0';

--input_reg: process(CLK_i, reset_i, data_i)
--begin
--    if reset_i = '0' then 
--        data_reg <= 0;
--    elsif rising_edge(CLK_i) then
    
--    end if;
--end if;

reg_triggered_proc: process(reset_i, clk_i)
begin
    if reset_i = '0' then
        reg_triggered <= '0';
        reg_address <= (Others =>'0');
    elsif rising_edge(clk_i) then
        if reg_triggered = '0' then
            if triggered_i = '1' then
                reg_triggered <= '1';
                reg_address <= trigger_addr_i;
            end if;
        else 
            if reset_triggered = '1' then
                reg_triggered <= '0';
                reg_address <= (Others => '0');
            end if;
        end if;
    end if;   
end process;

Inst_VerticalScale : VerticalScaleFactor
    port map (Reset_I => Reset_I,
              CLK_I   => CLK_I,
              Data_I  => VPD_I,
              Data_O  => scaleFactor);
              
              
   process(reset_i, clk_i)
   begin
        if reset_i = '0' then
            scaleFactor_reg <= (Others => '0');
        elsif rising_edge(clk_i) then
            scaleFactor_reg <= scaleFactor;
       end if;
   end process;
buffer_addr_proc: process (CLK_i, reset_i)
begin
    if reset_i = '0' then
        buffer_addr_aux <= 0;
        copyEnded <= '0';
        ram_addr <= (Others => '0');
        cnt_aux <= 0;
    elsif rising_edge(CLK_i) then
        if write_en = '1' then
            if buffer_addr_aux = PLOT_WIDTH - 1 then
                buffer_addr_aux <= 0;
                copyEnded <= '1';               
            else
                buffer_addr_aux <= buffer_addr_aux + 1;
                copyEnded <= '0';
            end if;
            if cnt_aux = reg_address + PLOT_WIDTH - 1 then
                reset_triggered <= '1';
                cnt_aux <= 0;
            else
                reset_triggered <= '0';
                ram_addr <= ram_addr + 1;
                cnt_aux <= cnt_aux + 1;
            end if;
        elsif reg_triggered = '1' then
            ram_addr <= unsigned(reg_address);
        end if;
    end if;  
end process;

   

 --Signal to pixel conversion
 mul_prep : process (reset_i, clk_i)
 begin
    if reset_i = '0' then
        data_reg <= (Others => '0');
        --data_conv_aux <= (Others => '0');
    elsif rising_edge(clk_i) then
        if write_en = '1' then
            data_reg <= signed(data_i);
        --data_conv_aux <= data_i(ADC_DATA_WIDTH - 1) & data_i(ADC_DATA_WIDTH - 2 downto 0);           
        end if;        
    end if;
 end process;
    
    scaleFactor_o <= scaleFactor_reg;

    data_conv <= signed(data_reg) * signed('0' & scaleFactor);
    
    data_conv_aux <= std_logic_vector(GND - data_conv (11 + PLOT_HEIGHT_BIT_LENGTH - 1 downto 11));
  --data_conv <= std_logic_vector(unsigned(data_conv_aux) * PLOT_HEIGHT);
    
mem_process : process (CLK_i, reset_i)
begin

    if rising_edge(clk_i) then
        if write_en = '1' then
 
            --buffer_data(buffer_addr)<= std_logic_vector(data_conv (12 + PLOT_HEIGHT_BIT_LENGTH - 1 downto 12) + GND);
            buffer_data(buffer_addr)<= data_conv_aux;
            --buffer_data(buffer_addr)<= data_conv_aux (23 downto 15);

        end if;
        if read_en = '1' then
            data_o <= buffer_data(buffer_addr);
        end if;
    end if;
end process;


end Behavioral;
