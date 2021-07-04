----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.05.2021 19:56:22
-- Design Name: 
-- Module Name: ADC_DataMemory - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;


use IEEE.NUMERIC_STD.ALL;
use work.oscilloscope_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ADC_DataMemory is
    Port ( Reset_I : in STD_LOGIC;
           CLK_i : in STD_LOGIC;
           ON_i : in std_logic;
           FIFO_empty_i : in STD_LOGIC;
           ram_addr_i : in STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
           data_FIFO_i : in STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
           downsample_i : in STD_LOGIC_VECTOR(MAX_DOWNSAMPLE - 1 downto 0);
           ram_read_i : in STD_LOGIC;
           getBusControl_i : in STD_LOGIC;
           data_rdy_o : out STD_LOGIC;
           Read_FIFO_o : out STD_LOGIC;
           ram_addr_aux_o : out std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
           ram_data_o : out STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0));
end ADC_DataMemory;

architecture Behavioral of ADC_DataMemory is

COMPONENT RAM IS
PORT (
   clk_i      : in    std_logic;
   address_i  : in    std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
   databus_io : inout std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
   write_en_i : in    std_logic;
   read_en_i : in    std_logic);
END COMPONENT;

--FSM signals

TYPE States IS (Idle, Waiting, Ask, Downsample_comp, Discard, Save);
SIGNAL CurrentState, NextState: States;


signal data_FIFO : std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);
--RAM signals

signal ram_addr, ram_addr_reg, addr_count : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
signal databus : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
signal ram_data_aux : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
signal ram_write_en : std_logic;
signal ram_read_reg : std_logic;
signal getBusControl_reg : std_logic;



--downsampling signal
signal data_asked : std_logic;
signal downsample_cnt : std_logic_vector (MAX_DOWNSAMPLE - 1 downto 0);
signal downsample_reg : std_logic_vector (MAX_DOWNSAMPLE - 1 downto 0);

--signal downsample_count : integer range 0 to 2**MAX_DOWNSAMPLE;
signal sample_en : std_logic;


   signal drdy : std_logic; --the adc_drdy is 1 when any channel outputs a signal.
                            --So as we are using two channels, we get 2 consecutive signals.
                            --We just want one of them.
                            --Also, we have downsample, so we need to make sure that we are counting a real sample

begin

--This block interacts with the VGA block, which has a diferent frequency.
--So it is necessary to register the inputs.

input_reg : process(reset_i, CLK_i)
begin
    if reset_i = '0' then
        ram_addr_reg <= (Others => '0');
        ram_read_reg <= '0';
        getBusControl_reg <= '0';
        downsample_reg <= (Others => '0');
    elsif rising_edge(CLK_i) then
        ram_addr_reg <= ram_addr_i;
        ram_read_reg <= ram_read_i;
        getBusControl_reg <= getBusControl_i;
        downsample_reg <= downsample_i;
        if ON_i = '1' then
            data_FIFO <= data_FIFO_i;
        else 
            data_FIFO <= (Others => '0');
        end if;
    end if;

end process;

------------------------------------------------
--FSM ram writing control
------------------------------------------------
Sync: process(Reset_I, CLK_i)
begin
    if Reset_I = '0' then
        CurrentState <= Idle;
    elsif CLK_i'event AND CLK_i = '1' then
        CurrentState <= NextState;
    end if;
end process;

Next_State: process(CLK_i, CurrentState, FIFO_empty_i, getBusControl_reg, ON_i, sample_en)
begin
    case CurrentState is
        when Idle => 
           if FIFO_empty_i = '0' then
               NextState <= Waiting;
           else
               NextState <= Idle;
           end if;            
        when Waiting =>
            if getBusControl_reg = '1' then
                NextState <= Ask;
            else
                NextState <= Waiting;
            end if;
        when Ask =>
            NextState <= Downsample_comp;       
        when Downsample_comp =>
            if sample_en = '1' then
                NextState <= Save;
            else
                NextState <= Discard;
            end if;
        when Discard =>
            if getBusControl_reg = '1' and FIFO_empty_i = '0' then
                NextState <= Ask;
            else
                NextState <= Idle;
            end if;
        when Save =>
            if getBusControl_reg = '1' and FIFO_empty_i = '0' then
                NextState <= Ask;
            else
                NextState <= Idle;
            end if;
     end case;
end process;

--Output codification

read_FIFO_o <= '1' when CurrentState = Ask else '0';
data_asked <= '1' when CurrentState = Ask else '0';
ram_addr <= addr_count when CurrentState = Save else ram_addr_reg;
ram_write_en <= '1' when CurrentState = Save else '0';
databus <= data_FIFO when CurrentState = Save else (Others => 'Z');
ram_data_aux <= databus when CurrentState = Idle or CurrentState = Waiting else (Others => 'Z');

drdy <= '1' when CurrentState = Save else '0';

--downsample : process(CLK_i, reset_i)
--begin 
--    if reset_i = '0' then
--        downsample_count <= 0;
--    elsif rising_edge(CLK_i) then
--        if sample_en <= '1' then
--            downsample_count <= downsample_count + 1;
--        end if;
--    end if;
--end process; 

Downsample_Counter: process (CLK_i, reset_i, data_asked)
begin
    if reset_i = '0' then
        downsample_cnt <= (Others => '0');
    elsif rising_edge(CLK_i) then
        if data_asked = '1' then
            if downsample_cnt >= downsample_reg - 1 then
                downsample_cnt <= (Others => '0'); 
                sample_en <= '1';
            else
                downsample_cnt <= downsample_cnt + 1;
                sample_en <= '0';
            end if;
        end if; 
    end if;  
end process;

addr_Counter: process (CLK_i, reset_i, ram_write_en)
begin
    if reset_i = '0' then
        addr_count <= (Others => '0');
    elsif rising_edge(CLK_i) then
        if ram_write_en = '1' then
            addr_count <= addr_count + 1;
        end if; 
    end if;  
end process;

ram_addr_aux_o <= addr_count;

Inst_RAM : RAM
   port map (   
   clk_i => CLK_i,                
   address_i => ram_addr,
   databus_io => databus,
   write_en_i => ram_write_en,
   read_en_i => ram_read_reg
 );
 
--It is necessary to register the outputs too, to avoid metastability.

output_reg : process(reset_i, CLK_i)
begin
    if reset_i = '0' then
        ram_data_o <= (Others => '0');
    elsif rising_edge(CLK_i) then
        ram_data_o <= ram_data_aux;
    end if;

end process;

data_rdy_o <= drdy;

end Behavioral;
