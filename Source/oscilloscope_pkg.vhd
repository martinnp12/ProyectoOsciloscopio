
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

PACKAGE oscilloscope_pkg IS

-------------------------------------------------------------------------------
--Data acquisition configuration
-------------------------------------------------------------------------------
--CLK
  constant CLK_FREQ : integer := 100000000;    -- Hz
--ADC
  constant ADC_DATA_WIDTH : integer := 12;
--FIFO
  constant FIFO_LENGTH : integer := 16;     --1024 directions
  SUBTYPE item_array_fifo IS std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);
  TYPE array_fifo IS array (integer range <>) of item_array_fifo;

--RAM
  constant RAM_ADDR_WIDTH : integer := 10;     --1024 directions
  SUBTYPE item_array_ram IS std_logic_vector (ADC_DATA_WIDTH - 1 downto 0);
  TYPE array_ram IS array (integer range <>) of item_array_ram;
  constant RAM_ADDR_LENGTH : natural := 2**RAM_ADDR_WIDTH;
  
  constant MAX_UPSAMPLING : natural := 10;
  constant MAX_DOWNSAMPLE : NATURAL := 13;    --max number of bits

-------------------------------------------------------------------------------
--VGA configuration
-------------------------------------------------------------------------------
  --Frame dimensions
  constant VGA_FRAME_WIDTH : natural := 640;
  constant VGA_FRAME_HEIGHT : natural := 480;
  
  --VGA TIMMING (640 x 480 @ 60Hz)
  
  constant PXL_FREQ : natural := 25000000;   --freq in MHz
  constant CLK_COUNT : natural := CLK_FREQ/PXL_FREQ;
  --constant CLK_COUNT_BITS : natural :=  natural(ceil(log2(real(CLK_COUNT))));
  
  
  constant FRAME_WIDTH : natural := 640;
  constant FRAME_HEIGHT : natural := 480;
  constant FRAME_HEIGHT_BIT_LENGTH : natural := natural(ceil(log2(real(FRAME_HEIGHT))));
  constant FRAME_WIDTH_BIT_LENGTH : natural := natural(ceil(log2(real(FRAME_WIDTH))));

  
  constant VGA_H_FP : natural := 16; --H front porch width (pixels)
  constant VGA_H_PW : natural := 96; --H sync pulse width (pixels)
  constant VGA_H_MAX : natural := 800; --H total period (pixels)
  
  constant VGA_V_FP : natural := 10; --V front porch width (lines)
  constant VGA_V_PW : natural := 2; --V sync pulse width (lines)
  constant VGA_V_MAX : natural := 525; --V total period (lines)
  constant VGA_H_POL : std_logic := '1';
  constant VGA_V_POL : std_logic := '1';
  
  -- Character ROM
  constant CHARACTER_ROM_ADDR_WIDTH : natural := 8;
  constant CHARACTER_ROM_DATA_WIDTH : natural := 8;
  constant CHARACTER_ROM_ADDR_LENGTH : natural := 2**CHARACTER_ROM_ADDR_WIDTH;
  type character_rom_t is array(0 to CHARACTER_ROM_ADDR_LENGTH - 1) of std_logic_vector(CHARACTER_ROM_DATA_WIDTH - 1 downto 0);
 
    -- Character ROM
  constant SYMBOL_ROM_ADDR_WIDTH : natural := 8;
  constant SYMBOL_ROM_DATA_WIDTH : natural := 8;
  constant SYMBOL_ROM_ADDR_LENGTH : natural := 2**SYMBOL_ROM_ADDR_WIDTH;
    type symbol_rom_t is array(0 to 23) of std_logic_vector(SYMBOL_ROM_DATA_WIDTH - 1 downto 0);
  --DIGITS
  
  constant DIGIT_WIDTH : natural := 10;  --antes estaba puesto 10. Para que haya mas espacio entre numeros
  constant DIGIT_HEIGHT : natural := 8;
  
  constant SETTING_DIGITS : natural := 8;
  constant SETTING_WIDTH : natural := SETTING_DIGITS * DIGIT_WIDTH;
  
  constant MEASUREMENT_DIGITS : natural := 13;
  constant MEASUREMENT_WIDTH : natural := MEASUREMENT_DIGITS * DIGIT_WIDTH;
  
 -- constant TOTAL_HEIGHT : natural := 8;
  
  
  constant N_CHANNELS : natural := 2;
  
  constant COLOR_CH1 : std_logic_vector (11 downto 0) := "1111" & "1111" & "0000"; --red & green & blue
  constant COLOR_CH2 : std_logic_vector (11 downto 0) := "0000" & "1111" & "0000"; --red & green & blue
  constant COLOR_GRID : std_logic_vector (11 downto 0) := "1111" & "1111" & "1111"; --red & green & blue
  constant COLOR_BACKGROUND : std_logic_vector (11 downto 0) := "0000" & "0000" & "0000"; --red & green & blue
  
  
  
  
  --VPD channel 1
  constant VPD1_X_START : integer range 0 to VGA_FRAME_WIDTH := 40;
  constant VPD1_Y_START : integer range 0 to VGA_FRAME_HEIGHT := 10;
  
  
  
  --VPD channel 2
  constant VPD2_X_START : integer range 0 to VGA_FRAME_WIDTH := 140;
  constant VPD2_Y_START : integer range 0 to VGA_FRAME_HEIGHT := 10;
  
  --TPD 
  constant TPD_X_START : integer range 0 to VGA_FRAME_WIDTH := 240;
  constant TPD_Y_START : integer range 0 to VGA_FRAME_HEIGHT := 10;
  
  --Plot window
  constant PLOT_X_START : natural := 34;
  constant PLOT_Y_START : natural := 34;
  constant PLOT_WIDTH : natural := 440;
  constant PLOT_HEIGHT : natural := 352;
  constant PLOT_HEIGHT_BIT_LENGTH : natural := natural(ceil(log2(real(PLOT_HEIGHT))));
  constant PLOT_WIDTH_BIT_LENGTH : natural := natural(ceil(log2(real(PLOT_WIDTH))));
  
  -- Grid
  constant GRID_WIDTH : natural := PLOT_WIDTH/10;
  constant GRID_HEIGHT : natural := PLOT_HEIGHT/8;
  constant GRID_HEIGHT_BIT_LENGTH : natural := natural(ceil(log2(real(GRID_HEIGHT))));
  constant GRID_WIDTH_BIT_LENGTH : natural := natural(ceil(log2(real(GRID_WIDTH))));
  
  --Signal values channel 1
  constant VPP1_X_START : natural := 490;
  constant VPP1_Y_START : natural := 50;
  constant VMAX1_X_START : natural := 490;
  constant VMAX1_Y_START : natural := 80;
  constant VMIN1_X_START : natural := 490;
  constant VMIN1_Y_START : natural := 110;
  constant VAVG1_X_START : natural := 490;
  constant VAVG1_Y_START : natural := 140;
  
  --Signal values channel 2
  constant VPP2_X_START : natural := 490;
  constant VPP2_Y_START : natural := 170;
  constant VMAX2_X_START : natural := 490;
  constant VMAX2_Y_START : natural := 200;
  constant VMIN2_X_START : natural := 490;
  constant VMIN2_Y_START : natural := 230;
  constant VAVG2_X_START : natural := 490;
  constant VAVG2_Y_START : natural := 270;
  
  constant QUANTIFICATION: natural := 24;
  constant OPERATOR : natural := natural(floor(real((2**QUANTIFICATION)/PLOT_WIDTH)));
  constant OPERATOR_LENGTH : natural := natural(ceil(log2(real(OPERATOR))));
  constant ROUND : integer := 2**(QUANTIFICATION - 1);
  
  --Symbols
  
  constant SYMBOL_WIDTH : natural := 8; 
  constant SYMBOL_HEIGHT : natural := 8;
  
  --Trigger arrow 
  constant TRIGGER_ARROW_X_START : integer range 0 to VGA_FRAME_WIDTH := 20;
  --constant TRIGGER_ARROW_Y_START : integer range 0 to VGA_FRAME_HEIGHT := 230;
  constant TRIGGER_ARROW_Y_INIT : integer range 0 to VGA_FRAME_HEIGHT := 205;
  
  --TRIGGER EDGE
  constant TRIGGER_EDGE_X_START : integer range 0 to VGA_FRAME_WIDTH := 400;
  constant TRIGGER_EDGE_Y_START : integer range 0 to VGA_FRAME_HEIGHT := 10;
  
  --TRIGGER MODE
  constant AUTOTRIGGER_FREQ : natural := 30; --Hz
  constant AUTOTRIGGER_COUNT : natural := CLK_FREQ / AUTOTRIGGER_FREQ; 
  constant AUTOTRIGGER_COUNT_LENGTH : natural := natural(ceil(log2(real(AUTOTRIGGER_COUNT))));
  constant TRIGGER_DIGITS : natural := 4;
  constant TRIGGER_WIDTH : natural := TRIGGER_DIGITS * DIGIT_WIDTH;
  constant TRIGGER_MODE_X_START : integer range 0 to VGA_FRAME_WIDTH := 355;
  constant TRIGGER_MODE_Y_START : integer range 0 to VGA_FRAME_HEIGHT := 10;
  
  --MAGNITUDES' DIGITS  
  
  
  
 --Buffer
 SUBTYPE item_array_buffer IS std_logic_vector (PLOT_HEIGHT_BIT_LENGTH - 1 downto 0);
 TYPE array_buffer IS array (integer range <>) of item_array_buffer;
 
 constant DATA_CONV :natural := (2**ADC_DATA_WIDTH) / 3;
 
  
  --Voltage measurements
  constant POP_SIZE_WIDTH : integer := 45;
  -------------------------------------------------------------------------
  --Button driver
  -------------------------------------------------------------------------
  
  --DEBOUNCER
  constant DEBOUNCER_CLKS : natural := 7500;
  


END oscilloscope_pkg;

PACKAGE BODY oscilloscope_pkg IS
END oscilloscope_pkg;

