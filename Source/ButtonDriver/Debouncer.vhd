----------------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Author:  Mihaita Nagy
--          Copyright 2014 Digilent, Inc.
----------------------------------------------------------------------------
-- 
-- Create Date:    17:11:29 03/06/2013 
-- Design Name: 
-- Module Name:    dbncr - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
-- This module represents a debouncer and is used to synchronize with the system clock
-- and remove glitches from the incoming button signals
--
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Debouncer is
   port(
      CLK       : in std_logic;
      reset     : in std_logic;
      sig_in   : in std_logic;
      sig_out  : out std_logic);
end Debouncer;

architecture Behavioral of Debouncer is

signal count : integer range 0 to DEBOUNCER_CLKS-1;
signal sig_tmp : std_logic;
signal stable, stable_tmp : std_logic;

begin

   DEB: process(CLK, reset)
   begin
      if reset = '0' then
        stable <= '0';
        count <= 0;
        sig_tmp <= '0';
      elsif rising_edge(CLK) then
         if sig_in = '1' then -- Count the number of clock periods if the signal is stable
            if count = DEBOUNCER_CLKS-1 then
               stable <= '1';
            else
               count <= count + 1;
            end if;
         else -- Reset counter and sample the new signal value
            count <= 0;
            sig_tmp <= '0';
            stable <= '0';
         end if;
      end if;
   end process;

   Out_reg: process(CLK)
   begin
      if rising_edge(CLK) then
         stable_tmp <= stable;
      end if;
   end process;
   
   -- generate the one-shot output signal
   sig_out <= '1' when stable_tmp = '0' and stable = '1' else '0';

end Behavioral;

