----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.04.2021 16:29:58
-- Design Name: 
-- Module Name: DataAcquisition - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ADC_Sampler is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           Vp_I : in STD_LOGIC;
           Vn_I : in STD_LOGIC;
           vauxp2_i : in STD_LOGIC;
           vauxn2_i : in STD_LOGIC;
           vauxp10_i : in STD_LOGIC;
           vauxn10_i : in STD_LOGIC;
           Read_FIFO1_i : in std_logic;
           Read_FIFO2_i : in std_logic;
           FIFO1_empty_o : out std_logic;
           FIFO2_empty_o : out std_logic;
           FIFO1_data_o : out std_logic_vector (11 downto 0);
           FIFO2_data_o : out std_logic_vector (11 downto 0);
           LED_o : out std_logic_vector (15 downto 0));
end ADC_Sampler;

architecture Behavioral of ADC_Sampler is

--component CLK_Gen
--port
-- (-- Clock in ports
--  -- Clock out ports
--  clk_out1          : out    std_logic;
--  -- Status and control signals
--  resetn             : in     std_logic;
--  locked            : out    std_logic;
--  clk_in1           : in     std_logic
-- );
--end component;

COMPONENT ADC
  PORT (
  --CLK and reset
    dclk_in : IN STD_LOGIC;
    reset_in : IN STD_LOGIC;
  --DRP interface
    di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);       --input data for DRP
    daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    den_in : IN STD_LOGIC;                          --enable signal for DRP
    dwe_in : IN STD_LOGIC;                          --write enable for DRP
    drdy_out : OUT STD_LOGIC;
    do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
  --Dedicated input channel (not used)
    vp_in : IN STD_LOGIC;
    vn_in : IN STD_LOGIC;
  --Auxiliary imput channels
    vauxp2 : IN STD_LOGIC;
    vauxn2 : IN STD_LOGIC;
    vauxp10 : IN STD_LOGIC;
    vauxn10 : IN STD_LOGIC;
  --Alarms
    user_temp_alarm_out : OUT STD_LOGIC;
    vccint_alarm_out : OUT STD_LOGIC;
    vccaux_alarm_out : OUT STD_LOGIC;
    alarm_out : OUT STD_LOGIC;
  --Signal status
    ot_out : OUT STD_LOGIC;
    channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    eoc_out : OUT STD_LOGIC;
    eos_out : OUT STD_LOGIC;
    busy_out : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT FIFO
  PORT (   reset_i : in STD_LOGIC;
           clk_i : in STD_LOGIC;
           data_i : in STD_LOGIC_VECTOR (11 downto 0);
           wr_en_i : in STD_LOGIC;
           rd_en_i : in STD_LOGIC;
           data_o : out STD_LOGIC_VECTOR (11 downto 0);
           full_o : out STD_LOGIC;
           empty_o : out STD_LOGIC);
END COMPONENT;

   --FSM signals
   TYPE Estados IS (Idle, RQ1, Waiting1, Save1, RQ2, Waiting2, Save2);
   SIGNAL CurrentState, NextState: Estados;

   
   --ADC signals
   signal ResetN : std_logic;
   signal EndConversion, EndSequence, Busy : std_logic;
   signal Channel : std_logic_vector (4 downto 0);
   SIGNAL ADC_Data : std_logic_vector (15 downto 0);
   SIGNAL daddr : std_logic_vector (6 downto 0) := (Others => '0');
   SIGNAL di_in : std_logic_vector (15 downto 0) := (Others => '0');
   SIGNAL den, dwe, drdy : std_logic := '0';
   
   --SIGNAL CLK : std_logic;
   
   --FIFO signals
   signal Write_FIFO1, Write_FIFO2 : std_logic;
   
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

NextState_proc: process(CurrentState, CLK_I, drdy, EndConversion)
begin
    case CurrentState is
        when Idle =>
            if EndConversion = '1' then
                NextState <= RQ1;
            else
                NextState <= Idle;
            end if;
        when RQ1 =>
            NextState <= Waiting1;
        when Waiting1 =>
            if drdy = '1' then
                NextState <= Save1;
            else
                NextState <= Waiting1;
            end if;    
        when Save1 =>
            NextState <= RQ2;
        when RQ2 =>
            NextState <= Waiting2;
        when Waiting2 =>
            if drdy = '1' then
                NextState <= Save2;
            else
                NextState <= Waiting2;
            end if;    
        when Save2 =>
            NextState <= Idle;
    end case;    
end process;

--Codificación de las saldas:
daddr <= "0010010" when CurrentState = RQ1 else
         "0011010" when CurrentState = RQ2 else
         (others=>'0');
den <= '1' when CurrentState = RQ1 or CurrentState = RQ2  else '0';
Write_FIFO1 <= '1' when CurrentState = Save1 else '0';
Write_FIFO2 <= '1' when CurrentState = Save2 else '0';


--den <= '1';


ResetN <= not Reset_I;


 
--process (CLK_I, Reset_I)
--begin
--  if rising_edge(CLK_I) then
--      if (RESET_i = '0') then
--       --daddr_in <= "0000000"; --{2'b00, CHANNEL_TB};
--       di_in <= x"0000";
--       --dwe_in <= '0';
--       --den <= '0'; --EOC_TB;
--      else 
--       --daddr_in <= "00" & channel;
--       --daddr_in <= "0011010";
--       di_in <= x"0000";
--       --dwe_in <= '0';
--       --den <= EndConversion;
--      end if;
--  end if;
--end process;

--Inst_CLK_Gen : CLK_Gen
--   port map ( 
--  -- Clock out ports  
--   clk_out1 => CLK,
--  -- Status and control signals                
--   resetn => Reset_I,
--   locked => open,
--   -- Clock in ports
--   clk_in1 => CLK_I
-- );
 
Inst_ADC : ADC
  PORT MAP (
    di_in => di_in,
    daddr_in => daddr,
    den_in => den,
    dwe_in => dwe,
    drdy_out => drdy,
    do_out => ADC_Data,
  
    dclk_in => CLK_i,
    reset_in => ResetN,
    vp_in => vp_i,
    vn_in => vn_i,
    vauxp2 => vauxp2_i,
    vauxn2 => vauxn2_i,
    vauxp10 => vauxp10_i,
    vauxn10 => vauxn10_i,
    user_temp_alarm_out => open,
    vccint_alarm_out => open,
    vccaux_alarm_out => open,
    ot_out => open,

    channel_out => channel,
    eoc_out => EndConversion,
    alarm_out => open,
    eos_out => EndSequence,
    busy_out => busy
  );
  

  
  process (CLK_i, ADC_Data)
  
  begin
  case ADC_Data(15 downto 12) is
    when x"1" => LED_o <= "0000000000000001";
    when x"2" => LED_o <= "0000000000000011";
    when x"3" => LED_o <= "0000000000000111";
    when x"4" => LED_o <= "0000000000001111";
    when x"5" => LED_o <= "0000000000011111";
    when x"6" => LED_o <= "0000000000111111";
    when x"7" => LED_o <= "0000000001111111";
    when x"8" => LED_o <= "0000000011111111";
    when x"9" => LED_o <= "0000000111111111";
    when x"A" => LED_o <= "0000001111111111";
    when x"B" => LED_o <= "0000011111111111";
    when x"C" => LED_o <= "0000111111111111";
    when x"D" => LED_o <= "0001111111111111";
    when x"E" => LED_o <= "0011111111111111";
    when x"F" => LED_o <= "0111111111111111";
    when others => LED_o <= (Others => '0');
  end case;
  end process;

FIFO_ch2 : FIFO
  PORT MAP (
    clk_i => clk_i,
    reset_i => Reset_i,
    data_i => ADC_Data(15 downto 4),
    wr_en_i => Write_FIFO1,
    rd_en_i => Read_FIFO1_i,
    data_o => FIFO1_data_o,
    full_o => open,
    empty_o => FIFO1_empty_o
  );
  
  FIFO_ch10 : FIFO
  PORT MAP (
    
    clk_i => clk_i,
    reset_i => Reset_i,
    data_i => ADC_Data(15 downto 4),
    wr_en_i => Write_FIFO2,
    rd_en_i => Read_FIFO2_i,
    data_o => FIFO2_data_o,
    full_o => open,
    empty_o => FIFO2_empty_o
  );
  
end Behavioral;
