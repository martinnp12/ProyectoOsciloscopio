----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.06.2021 11:53:23
-- Design Name: 
-- Module Name: VoltageMeasuerments - Behavioral
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

entity VoltageMeasuerments is
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;
        en_i : in std_logic;
        on_i : in std_logic; --when 1, the will come through data_i after 1 cicle
        data_i : in std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
        peak_bcd_o : out std_logic_vector(16 downto 0);
        average_bcd_o : out std_logic_vector(16 downto 0);
        max_bcd_o : out std_logic_vector(16 downto 0);
        min_bcd_o : out std_logic_vector(16 downto 0)
    );
end VoltageMeasuerments;

architecture Behavioral of VoltageMeasuerments is

component bin2bcd is
    Port ( reset_i : in std_logic;
            clk_i : in std_logic;
            bin_i : in  STD_LOGIC_VECTOR (11 downto 0);
           bcd_o : out  STD_LOGIC_VECTOR (15 downto 0));
end component;

     --FSM signals
   TYPE Estados IS (Idle, Reset, Measure);
   SIGNAL CurrentState, NextState: Estados;
   
    signal accumulator : std_logic_vector(ADC_DATA_WIDTH + PLOT_WIDTH_BIT_LENGTH - 1 downto 0);
    signal accumulator_next : std_logic_vector(ADC_DATA_WIDTH + PLOT_WIDTH_BIT_LENGTH - 1 downto 0);
    signal max, min : std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal peak_peak: std_logic_vector(ADC_DATA_WIDTH + 1 - 1 downto 0);
    signal average: std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal peak_peak_magn: std_logic_vector(ADC_DATA_WIDTH + 1 - 1 downto 0);
    signal average_magn, max_magn, min_magn: std_logic_vector(ADC_DATA_WIDTH - 1 downto 0);
    signal peak_peak_sign, average_sign, max_sign, min_sign: std_logic;
    
    signal reset_reg, enable_reg : std_logic;
    signal peak_bcd_aux, average_bcd_aux, max_bcd_aux, min_bcd_aux: std_logic_vector(15 downto 0);
    signal peak_bcd_reg, average_bcd_reg, max_bcd_reg, min_bcd_reg: std_logic_vector(16 downto 0);
    
    signal average_aux : signed(ADC_DATA_WIDTH + PLOT_WIDTH_BIT_LENGTH + OPERATOR_LENGTH - 1 downto 0);
    signal op : std_logic_vector(OPERATOR_LENGTH - 1 downto 0);
    

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

NextState_proc: process(CurrentState, CLK_I, on_i, en_i)
begin
    case CurrentState is
        when Idle =>
            if on_i = '1' and en_i = '1' then
                NextState <= Reset;
            else
                NextState <= Idle;
            end if;
        when Reset =>
            NextState <= Measure;
        when Measure =>
            if on_i = '0' then
                NextState <= Idle;
            else
                NextState <= Measure;
            end if;    
    end case;    
end process;

--Output codification
    reset_reg <= '1' when CurrentState = Reset else '0';
    enable_reg <= '1' when CurrentState = Measure else '0';
    
    
    

    accumulator_next <= std_logic_vector(signed(accumulator) + signed(data_i));

    accumulator_reg : process (clk_i, reset_i)
    begin
        if (reset_i = '0') then
            accumulator <= (others => '0');
        elsif (rising_edge(clk_i)) then
            if (reset_reg = '1') then
                accumulator <= (others => '0');
            elsif (enable_reg = '1') then
                accumulator <= accumulator_next;
            end if;
        end if;
    end process;

    maximum_o_reg : process (clk_i, reset_i)
    begin
        if (reset_i = '0') then
            max <= (others => '0');
        elsif (rising_edge(clk_i)) then
            if (reset_reg = '1') then
                max <= (others => '0');
            elsif enable_reg = '1' then
                if signed(data_i) > signed(max) then
                    max <= data_i;
                end if;
            end if;
        end if;
    end process;

    reg_minimum : process (clk_i, reset_i)
    begin
        if (reset_i = '0') then
            min <= (others => '1');
        elsif (rising_edge(clk_i)) then
            if (reset_reg = '1') then
                min <= (others => '1');
            elsif enable_reg = '1' then
                if signed(data_i) < signed(min) then
                    min <= data_i;
                end if;
            end if;
        end if;
    end process;
    
    
    peak_peak <= std_logic_vector(signed(max(ADC_DATA_WIDTH - 1) & max) - (signed(min(ADC_DATA_WIDTH - 1) & min)));
    --average <= accumulator(ADC_DATA_WIDTH + PLOT_WIDTH_BIT_LENGTH - 1 downto PLOT_WIDTH_BIT_LENGTH);
    op <= std_logic_vector(to_signed(OPERATOR, OPERATOR_LENGTH));
    average_aux <= signed(unsigned(accumulator) * to_unsigned(OPERATOR, OPERATOR_LENGTH));
    average <= std_logic_vector(average_aux(ADC_DATA_WIDTH + PLOT_WIDTH_BIT_LENGTH + OPERATOR_LENGTH - 2 downto QUANTIFICATION));
    
    --Separate the sign and the magnitude
    
    process(reset_i, clk_i)
    begin
        if reset_i = '0' then
            peak_peak_sign <= '0';
            average_sign <= '0';
            max_sign <= '0';
            min_sign <= '0';
            min_sign <= '0';
            peak_peak_magn <= (Others => '0');
            average_magn <= (Others => '0');
            max_magn <= (Others => '0');
            min_magn <= (Others => '0');
        elsif rising_edge(clk_i) then
            if peak_peak(ADC_DATA_WIDTH + 1 - 1) = '0' THEN
                peak_peak_sign <= '0';
                peak_peak_magn <= '0' & peak_peak(ADC_DATA_WIDTH - 1 downto 0);
            else
                peak_peak_sign <= '1';
                peak_peak_magn <=  NOT std_logic_vector(unsigned(peak_peak) - 1);
            end if;  
            
            if average(ADC_DATA_WIDTH - 1) = '0' THEN
                average_sign <= '0';
                average_magn <= '0' & average(ADC_DATA_WIDTH - 2 downto 0);
            else
                average_sign <= '1';
                average_magn <=  NOT std_logic_vector(unsigned(average) - 1);
            end if; 
            
            if max(ADC_DATA_WIDTH - 1) = '0' THEN
                max_sign <= '0';
                max_magn <= '0' & max(ADC_DATA_WIDTH - 2 downto 0);
            else
                max_sign <= '1';
                max_magn <=  NOT std_logic_vector(unsigned(max) - 1);
            end if; 
            
            if min(ADC_DATA_WIDTH - 1) = '0' THEN
                min_sign <= '0';
                min_magn <= '0' & min(ADC_DATA_WIDTH - 2 downto 0);
            else
                min_sign <= '1';
                min_magn <= NOT std_logic_vector(unsigned(min) - 1);
            end if;
        end if;     
    end process;
    
    inst_bin2bcd_peak: bin2bcd
        port map(reset_i => reset_i,
                 clk_i => clk_i,
                 bin_i => peak_peak_magn(ADC_DATA_WIDTH - 1 downto 0),
                 bcd_o => peak_bcd_aux);
                 
    inst_bin2bcd_average: bin2bcd
        port map(reset_i => reset_i,
                 clk_i => clk_i,
                 bin_i => average_magn,
                 bcd_o => average_bcd_aux);
                 
    inst_bin2bcd_max: bin2bcd
        port map(reset_i => reset_i,
                 clk_i => clk_i,
                 bin_i => max_magn,
                 bcd_o => max_bcd_aux);             
    
    inst_bin2bcd_min: bin2bcd
        port map(reset_i => reset_i,
                 clk_i => clk_i,
                 bin_i => min_magn,
                 bcd_o => min_bcd_aux);               
                 
--Output regs

process(reset_i, clk_i)
begin
    if reset_i = '0' then
        peak_bcd_reg <= (Others => '0');
        average_bcd_reg <= (Others => '0');
        max_bcd_reg <= (Others => '0');
        min_bcd_reg <= (Others => '0');
    elsif rising_edge(clk_i) then
        peak_bcd_reg <= peak_peak_sign & peak_bcd_aux;
        average_bcd_reg <= average_sign & average_bcd_aux;
        max_bcd_reg <= max_sign & max_bcd_aux;
        min_bcd_reg <= min_sign & min_bcd_aux;
    end if;
end process;
   
    peak_bcd_o <= peak_bcd_reg;
    average_bcd_o <= average_bcd_reg;
    max_bcd_o <= max_bcd_reg;
    min_bcd_o <= min_bcd_reg;
    
    
    
    
    
 
    
end Behavioral;
