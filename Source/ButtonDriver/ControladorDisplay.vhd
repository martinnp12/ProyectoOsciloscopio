----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.01.2021 15:31:34
-- Design Name: 
-- Module Name: ControladorDisplay - Behavioral
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

use work.oscilloscope_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ControladorDisplay is
    Port ( Reset : in STD_LOGIC;
           CLK : in STD_LOGIC;                              --System clock 20 MHz
           VPD1_I : in STD_LOGIC_VECTOR (3 downto 0);
           VPD2_I : in STD_LOGIC_VECTOR (3 downto 0);
           TPD_I : in STD_LOGIC_VECTOR (3 downto 0);
           Trigger_I : in STD_LOGIC_VECTOR (ADC_DATA_WIDTH - 1 downto 0);
           
           paramSelect : in STD_LOGIC_VECTOR (3 downto 0);
           Temp : out STD_LOGIC_VECTOR (6 downto 0);
           Display : out STD_LOGIC_VECTOR (7 downto 0));
end ControladorDisplay;

architecture Behavioral of ControladorDisplay is

signal cuenta : std_logic_vector(15 downto 0);
signal Q_actual, Q_anterior, Clk244Hz : std_logic;
signal S : STD_LOGIC_vector (2 downto 0);
signal anode : STD_LOGIC_VECTOR (7 downto 0);
--signal numeroBCD : std_logic_vector(9 downto 0);
signal digit : std_logic_vector (3 downto 0);
signal data : std_logic_vector (15 downto 0);
signal exponente : std_logic_vector (3 downto 0); --Exponente del numero en notación cientifica
signal sign : std_logic_vector (3 downto 0) := "1010";

signal paramDecoded : std_logic_vector(15 downto 0);
signal triggerBCD :std_logic_vector(15 downto 0);

--RAM memory for decoding parameter
SUBTYPE item_array8_ram IS std_logic_vector (15 downto 0);
TYPE array8_ram IS array (integer range <>) of item_array8_ram;
signal VPD_Decoder : array8_ram(0 to 15) := (x"D106", -- dig1 & dig2 & dig3 & exp
                                              x"D206",
                                              x"D506",
                                              x"1006",
                                              x"2006",
                                              x"5006",
                                              x"DD13",
                                              x"DD23",
                                              x"DD53",
                                              x"D103",
                                              x"D203",
                                              x"D503",
                                              x"1003",
                                              x"2003",
                                              x"5003",
                                              x"DD10");
                                              
signal TPD_Decoder : array8_ram(0 to 15) := ( x"DD26",
                                              x"DD56",                                              
                                              x"D106", -- dig1 & dig2 & dig3 & exp
                                              x"D206",
                                              x"D506",
                                              x"1006",
                                              x"2006",
                                              x"5006",
                                              x"DD13",
                                              x"DD23",
                                              x"DD53",
                                              x"D103",
                                              x"D203",
                                              x"D503",
                                              x"1003",
                                              x"2003");  


begin


process(Trigger_i)
 
	variable z : std_logic_vector (30 downto 0);
	
begin

	z:=(others=>'0');		
	
	z(16 downto 3):="00" & Trigger_i;  --Los 3 primeros desplazamientos nunca van a dar mas de 5, ni aunque sean todo '1'.
	
	for i in 0 to 10 loop
	
		if z(17 downto 14)>4 then
			z(17 downto 14):=z(17 downto 14)+3;
		end if;
		
		if z(21 downto 18)>4 then
			z(21 downto 18):=z(21 downto 18)+3;
		end if;
		
		if z(25 downto 22)>4 then
			z(25 downto 22):=z(25 downto 22)+3;
		end if;
		
		if z(29 downto 26)>4 then
			z(29 downto 26):=z(29 downto 26)+3;
		end if;
		
		z(30 downto 1):=z(29 downto 0);
	end loop;
	
	triggerBCD<=z(29 downto 14);
end process;

--Decodificador VisualizacionParametro

paramDecoded <= VPD_Decoder(to_integer(unsigned(VPD1_I))) when paramSelect(0) = '1' else
                VPD_Decoder(to_integer(unsigned(VPD2_I))) when paramSelect(1) = '1' else
                TPD_Decoder(to_integer(unsigned(TPD_I))) when paramSelect(2) = '1' else
                triggerBCD;
                
DecoParam: process (reset, CLK)
begin
    if reset = '0' then
        data <= (Others => '0');
    elsif rising_edge(CLK) then
        data <= paramDecoded;
    end if;
end process;
           
--Divisor 244 Hz aproximado--

Contador_divisor: process(Reset,CLK)

begin
	if Reset = '0' then
		cuenta<=(others=>'0');
	elsif rising_edge(CLK) then
		cuenta<=cuenta+1;
	end if;	
end process;

Detector_flanco: process(CLK)

begin

	if rising_edge(CLK) then
		Q_actual<=cuenta(15);
		--Q_actual<=cuenta(7);
		Q_anterior<=Q_actual;
	end if;
	
end process Detector_flanco;

Clk244Hz<=Q_actual and (not Q_anterior);

-- Selector display --

process (Reset, CLK, Clk244Hz)  
begin
   if Reset = '0' then 
      S <= (Others => '0');
   elsif rising_edge (CLK) then
    if Clk244Hz = '1' then
        if S = "110" then
            S <= "000";
        else
            S <= S + 1;
        end if;
    end if;
   end if;
end process;

-- Control anodes -- 

process(S)
begin
    case S is
        when "000" => anode <= "11111110";
        when "001" => anode <= "11111101";
        when "010" => anode <= "11111011";
        when "011" => anode <= "11110111";
        when "100" => anode <= "11101111";
        when "101" => anode <= "11011111";
        when "110" => anode <= "10111111";
        when others => anode <= "11111110";
    end case;
end process;

Display <= anode;

-- Mux dígito --
process(S, data, sign, paramSelect)
begin
    if paramSelect(3) = '1' then
        case S is
            when "000" => digit <= data(3 downto 0);
            when "001" => digit <= data(7 downto 4);
            when "010" => digit <= data(11 downto 8);
            when "011" => digit <= data(15 downto 12);
            when "100" => digit <= "0000";
            when "101" => digit <= "0000";
            when others => digit <= "0000";
        end case;
    else
        case S is
            when "000" => digit <= data(3 downto 0);
            when "001" => digit <= sign;
            when "010" => digit <= "0000";
            when "011" => digit <= "0001";
            when "100" => digit <= data(7 downto 4);
            when "101" => digit <= data(11 downto 8);
            when others => digit <= data(15 downto 12);
        end case;
    end if;
end process;

--Display decoder
process(digit, paramSelect, digit)
 begin
--         if paramSelect(3) = '1' then
--               case digit is
--                   when X"0" => Temp <= "1000000"; --0 
--                   when X"1" => Temp <= "1111001"; --1 
--                   when X"2" => Temp <= "0100100"; --2 
--                   when X"3" => Temp <= "0110000"; --3 
--                   when X"4" => Temp <= "0011001"; --4 
--                   when X"5" => Temp <= "0010010"; --5 
--                   when X"6" => Temp <= "0000010"; --6 
--                   when X"7" => Temp <= "1111000"; --7 
--                   when X"8" => Temp <= "0000000"; --8 
--                   when X"9" => Temp <= "0010000"; --9 
--                   when X"A" => Temp <= "1110111"; --A 
--                   when X"B" => Temp <= "1111100"; --b 
--                   when X"C" => Temp <= "0111001"; --C 
--                   when X"D" => Temp <= "1011110"; --d 
--                   when X"E" => Temp <= "1111001"; --E 
--                   when others => Temp <= "1110001"; --F 
--              end case;
--        else
            case digit is
                   when X"0" => Temp <= "1000000"; --0
                   when X"1" => Temp <= "1111001"; --1
                   when X"2" => Temp <= "0100100"; --2
                   when X"3" => Temp <= "0110000"; --3
                   when X"4" => Temp <= "0011001"; --4
                   when X"5" => Temp <= "0010010"; --5
                   when X"6" => Temp <= "0000010"; --6
                   when X"7" => Temp <= "1111000"; --7
                   when X"8" => Temp <= "0000000"; --8
                   when X"9" => Temp <= "0010000"; --9
                   when X"A" => Temp <= "0111111"; -- -
                   when X"B" => Temp <= "1000001"; --U
                   when X"C" => Temp <= "0010010"; --S
                   when X"D" => Temp <= "1111111"; --All segments off
                   when X"E" => Temp <= "0000110"; --E
                   when others => Temp <= "0001110"; --F
              end case;
--         END IF;
	end process;

--with digit select
--Temp <=
--    "1111001" when "0001",  -- 1
--    "0100100" when "0010",  -- 2
--    "0110000" when "0011",  -- 3
--    "0011001" when "0100",  -- 4
--    "0010010" when "0101",  -- 5
--    "0000010" when "0110",  -- 6
--    "1111000" when "0111",  -- 7
--    "0000000" when "1000",  -- 8
--    "0010000" when "1001",  -- 9
--    "0111111" when "1010",  -- -
--    "1000001" when "1011",  -- U
--    "0010010" when "1100",  -- S
--    "1111111" when "1101",  -- All segments off
--    "0000110" when "1110",  -- E
--    "0001110" when "1111",  -- F
--    "1000000" when others;  -- 0
    
--with digit select
--Temp <=
--    "1111001" when "001",  -- 1
--    "0100100" when "010",  -- 2
    
--    "0010010" when "011",  -- 5
--    "0111111" when "100",  -- -
--    "1000001" when "101",  -- U
--    "0010010" when "110",  -- S
--    "1111111" when "111",  -- Todo apgado
--    "1000000" when others; -- 0


end Behavioral;
