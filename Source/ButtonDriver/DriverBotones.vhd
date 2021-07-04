----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.02.2021 17:49:40
-- Design Name: 
-- Module Name: DriverBotones - Behavioral
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
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;

use work.oscilloscope_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DriverBotones is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;  --20 MHz       
           Increase_I : in STD_LOGIC;
           IncreaseQuick_I : in STD_LOGIC;
           Decrease_I : in STD_LOGIC;
           DecreaseQuick_I : in STD_LOGIC;
           OK_I : in STD_LOGIC;
           --Aux
           paramSelect_O : out std_logic_vector (3 downto 0);   --OJO. Hay solo 6 parametros, pero se pone 7 por una posible ampliación
           --Options memory outputs
           VPD1_O : out STD_LOGIC_VECTOR (3 downto 0);
           VPD2_O : out STD_LOGIC_VECTOR (3 downto 0); 
           TPD_O : out STD_LOGIC_VECTOR (3 downto 0); 
           Trigger_O : out STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0));
--           ShowVRMS_O : out STD_LOGIC; 
--           ShowVpp_O : out STD_LOGIC; 
--           ShowVavg_O : out STD_LOGIC);
end DriverBotones;

architecture Behavioral of DriverBotones is



--Señales de la máquina de estados
TYPE Estados IS (Idle, Read, Modify);
SIGNAL CurrentState, NextState: Estados;

signal ShiftRegisterEN : std_logic;
signal parameterSelection : std_logic_vector (3 downto 0);

--Options memory signals
signal OptionRegEN : STD_LOGIC_VECTOR (3 DOWNTO 0);
signal WriteEN : std_logic;
signal VPD1 : STD_LOGIC_VECTOR (3 downto 0);
signal VPD2 : STD_LOGIC_VECTOR (3 downto 0); 
signal TPD : STD_LOGIC_VECTOR (3 downto 0); 
signal Trigger : STD_LOGIC_VECTOR(ADC_DATA_WIDTH - 1 downto 0);
--signal ShowVrms : STD_LOGIC; 
--signal ShowVpp : STD_LOGIC; 
--signal ShowVavg : STD_LOGIC;
           
           
--Counter signals
signal ResetCounter, LoadCounter, countEN : std_logic;
signal Parameter, DataReg : std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);



begin
------------------------------------------------------
--Máquina de estados
------------------------------------------------------
Sync: process(Reset_I, CLK_I)
begin
    if Reset_I = '0' then
        CurrentState <= Idle;
    elsif CLK_I'event AND CLK_I = '1' then
        CurrentState <= NextState;
    end if;
end process;

Next_State: process(CLK_I, CurrentState, OK_I, Increase_I, IncreaseQuick_I, Decrease_I, DecreaseQuick_I)
begin
    case CurrentState is
        when Idle => 
           if OK_I = '1' then
               NextState <= Read;
           else
               NextState <= Idle;
           end if;            
        when Read =>
            NextState <= Modify;
        when Modify =>
            if OK_I = '1' then
               NextState <= Idle;
           else
               NextState <= Modify;
           end if; 
     end case;
end process;

--Codificación de las salidas
ShiftRegisterEN <= '1' when CurrentState = Idle else '0';
WriteEN <= '1' when CurrentState = Modify else '0';
LoadCounter <= '1' when CurrentState = Read else '0';
ResetCounter <= '1' when CurrentState = Idle else '0';
countEN <= '1' when CurrentState = Modify else '0';

--------------------------------------------------------
--Datapath
--------------------------------------------------------
      
--REGISTRO DE DESPLAZAMIENTO

RegDesp: process(Reset_I, CLK_I, Increase_I, IncreaseQuick_I, Decrease_I, DecreaseQuick_I)
begin
    if Reset_I = '0' then
        parameterSelection <= "0001";
    elsif rising_edge(CLK_I) then
        if ShiftRegisterEN = '1' then
            if Increase_I = '1' or IncreaseQuick_I = '1' then
                parameterSelection(3 downto 1) <= parameterSelection(2 downto 0);
                parameterSelection(0) <= parameterSelection(3);
            elsif Decrease_I = '1' or DecreaseQuick_I = '1' then
                parameterSelection(2 downto 0) <= parameterSelection(3 downto 1);
                parameterSelection(3) <= parameterSelection(0);
            end if;
        end if;
    end if;
end process;

--Output for LED visualization
paramSelect_O <= parameterSelection;

--Options register enable
OptionRegEN <= parameterSelection when WriteEN = '1' else (Others => '0');              


--REGISTERS

Regs: process(Reset_I, CLK_I, OptionRegEN, Parameter)
begin
    if Reset_I = '0' then
        VPD1 <= (Others => '0');
        VPD2 <= (Others => '0');
        TPD <= (Others => '0');
        Trigger <= (Others => '0');
    elsif rising_edge(CLK_I) then
        if OptionRegEN(0) = '1' then
            VPD1 <= Parameter(3 downto 0);
        elsif OptionRegEN(1) = '1' then
            VPD2 <= Parameter(3 downto 0);
        elsif OptionRegEN(2) = '1' then
            TPD <= Parameter(3 downto 0);
        elsif OptionRegEN(3) = '1' then
            Trigger <= Parameter(6 downto 0) & "00000";
        end if;
    end if;
end process;

--MUX REGISTERS
                          
DataReg <= x"00" & VPD1 when parameterSelection(0) = '1' else
           x"00" & VPD2 when parameterSelection(1) = '1' else
           x"00" & TPD when parameterSelection(2) = '1' else
           Trigger;


-- CONTADOR

Counter: process(Reset_I, CLK_I, Parameter)
begin
    if Reset_I = '0' then
        Parameter <= (Others => '0');
    elsif rising_edge(CLK_I) then
        if ResetCounter = '1' then
            Parameter <= (Others => '0');
        elsif LoadCounter = '1' then
            if parameterSelection(3) = '1' then
                Parameter <= "00000" & DataReg(ADC_DATA_WIDTH - 1 downto ADC_DATA_WIDTH - 1 - 6);
            else
                Parameter <= DataReg;
            end if;
        elsif countEN = '1' then
            if Increase_I = '1' then
                Parameter <= Parameter + 1;
            elsif IncreaseQuick_I = '1' then
                Parameter <= Parameter + 3;         --Cambio de magnitud
            elsif Decrease_I = '1' then
                Parameter <= Parameter - 1;
            elsif DecreaseQuick_I = '1' then
                Parameter <= Parameter - 3;       --Cambio de magnitud
            end if;
        end if;
    end if;
 end process; 
 


 --OPTIONS OUTPUTS
  VPD1_O <= "1110";
 VPD2_O <= "1110";
 TPD_O <= "0011";
 
-- VPD1_O <= VPD1;
-- VPD2_O <= VPD2;
-- TPD_O <= TPD;
 Trigger_O <= Trigger;
       
        
end Behavioral;
