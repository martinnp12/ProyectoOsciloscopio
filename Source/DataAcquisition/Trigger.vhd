----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.06.2021 03:42:45
-- Design Name: 
-- Module Name: Trigger - Behavioral
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
--USE IEEE.std_logic_signed.all;
use work.oscilloscope_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Trigger is
    Port ( reset_i : in STD_LOGIC;
           clk_i : in STD_LOGIC;
           data_i : in STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
           ram_address_i : in std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
           trigger_i : in std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);
           adc_drdy_i : in std_logic;
           triggerEdge_i : in std_logic;
           triggerAuto_i : std_logic;
           triggerSingle_i: in STD_LOGIC;
           triggered_o : out std_logic;
           address_o : out STD_LOGIC_VECTOR (RAM_ADDR_WIDTH - 1 downto 0));
end Trigger;

architecture Behavioral of Trigger is
    --FSM signals
   TYPE States IS (Waiting, Triggered, Sampling, Finished, singleShot);
   SIGNAL CurrentState, NextState: States;
   
   signal edge, finish : std_logic;
   signal prev_data : signed(ADC_DATA_WIDTH - 1 downto 0);
   signal save_addres : std_logic;
   signal address, address_aux : std_logic_vector(RAM_ADDR_WIDTH - 1 downto 0);
   signal sampleCount_en, resetSampleCount, enoughData: std_logic;
   signal sampleCount : unsigned(9 downto 0);
   
   signal tickCount_en, resetTickCount, tickCount_prev: std_logic;
   signal tickCount : std_logic_vector (AUTOTRIGGER_COUNT_LENGTH - 1 downto 0);
   signal autoTrigger : std_logic; 
   
--   signal freqCount, signalFreq : std_logic_vector (AUTOTRIGGER_COUNT_LENGTH - 1 downto 0);
--   signal signalFreq_aux : std_logic_vector (AUTOTRIGGER_COUNT_LENGTH - 1 downto 0);
--   signal freqCount_aux : std_logic_vector (AUTOTRIGGER_COUNT_LENGTH - 1 + 15 downto 0);
   
begin


Sync: process(Reset_I, CLK_I)
begin
    if Reset_I = '0' then
        CurrentState <= Waiting;
    elsif CLK_I'event AND CLK_I = '1' then
        CurrentState <= NextState;
    end if;
end process;

NextState_proc: process(CurrentState, CLK_I, edge, finish, enoughData, triggerSingle_i)
begin
    case CurrentState is
        when Waiting =>
            if edge = '1' then
                NextState <= Triggered;
            else
                NextState <= Waiting;
            end if;
        when Triggered =>
            NextState <= Sampling;
        when Sampling =>
            if enoughData = '1' then
                NextState <= Finished;
            else
                NextState <= Sampling;
            end if;  
        when Finished =>
            if triggerSingle_i = '1' then
                NextState <= singleShot;  
            else
                NextState <= Waiting;
            end if;
        when singleShot =>
            if triggerSingle_i = '1' then
                NextState <= singleShot;
            else
                NextState <= Waiting;
            end if;
    end case;    
end process;

-- FSM output codification
resetSampleCount <= '1' when CurrentState = Waiting else '0';
save_addres <= '1' when CurrentState = Triggered else '0';
sampleCount_en <= '1' when CurrentState = Sampling else '0';

resetTickCount <= '1' when CurrentState = Triggered else '0';
tickCount_en <= '0' when CurrentState = Triggered else '1';

triggered_o <= '1' when CurrentState = Finished else '0';

--Sample counter for filling de plot
process(reset_i, clk_i)
begin 
    if reset_i = '0' then
        sampleCount <= (Others => '0');
    elsif rising_edge(CLK_i) then
        if resetSampleCount = '1' then
            sampleCount <= (Others => '0');
        elsif sampleCount_en = '1' then
            if adc_drdy_i = '1' then
                sampleCount <= sampleCount + 1;
            end if;
        end if;
    end if;
end process;

enoughData <= '1' when sampleCount = PLOT_WIDTH/2 else '0';

--Sample delay
process(reset_i, clk_i)
begin
    if reset_i <= '0' then
        prev_data <= (Others => '0');
    elsif rising_edge(clk_i) then
        prev_data <= signed(data_i);
    end if;
end process;

--Frequency divider for the auto triggering in case that no edge is trigger threshold is reached.
process(reset_i, clk_i)
begin
    if reset_i = '0' then
        tickCount <= (Others => '0');
    elsif rising_edge(clk_i) then
        if resetTickCount = '1' then
            tickCount <= (Others => '0');
        elsif tickCount_en = '1' and triggerAuto_i = '1' and triggerSingle_i = '0' then
            tickCount <= std_logic_vector(unsigned(tickCount) + 1);
        end if;
        tickCount_prev <= tickCount(AUTOTRIGGER_COUNT_LENGTH - 1);
    end if;
 end process;

 
 autoTrigger <= tickCount(AUTOTRIGGER_COUNT_LENGTH - 1) and not tickCount_prev; --the autotrigger gets actived when there is a rising edge in the tickCount's MSB.
 

--Mux for the trigger activation signal

--edge <= '1' when (prev_data <= signed(trigger_i) and signed(data_i) > signed(trigger_i) and triggerEdge_i = '1') OR
--        (prev_data >= signed(trigger_i) and signed(data_i) < signed(trigger_i) AND triggerEdge_i = '0') else
--        '0';

edge <= '1' when (prev_data <= signed(trigger_i) and signed(data_i) > signed(trigger_i) and triggerEdge_i = '1') OR
        (prev_data >= signed(trigger_i) and signed(data_i) < signed(trigger_i) AND triggerEdge_i = '0') else
        autoTrigger when triggerAuto_i = '1' else
        '0';
--substracter for obtaining the first address of the window addresss
address_aux <= std_logic_vector(unsigned(ram_address_i) - PLOT_WIDTH/2);
        
--Edge address register       
process(reset_i, clk_i)
begin
    if reset_i = '0' then
        address <= (Others => '0');
    elsif rising_edge(clk_i) then
        if save_addres = '1' then
            address <= address_aux;
        end if;
    end if;
end process;

address_o <= address;
        
end Behavioral;
