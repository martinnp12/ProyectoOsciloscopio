----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.01.2021 20:09:39
-- Design Name: 
-- Module Name: VGA - Behavioral
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
--use IEEE.STD_LOGIC_ARITH.ALL;

use work.oscilloscope_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VGA is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           --CLK_aux : out STD_LOGIC;
           VPD1_I : in STD_LOGIC_VECTOR (3 DOWNTO 0);   --V/div channel 1
           VPD2_I : in STD_LOGIC_VECTOR (3 DOWNTO 0); --V/div channel 2
           TPD_I : in STD_LOGIC_VECTOR (3 DOWNTO 0);  --s/div 
           trigger_i : in STD_LOGIC_VECTOR (ADC_DATA_WIDTH - 1 DOWNTO 0);
           triggerEdge_i : in STD_LOGIC;
           trigger_addr_i : in STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
           triggered_i : in std_logic; 
           triggerAuto_i : in std_logic;
           showAVG_i : in STD_LOGIC;
           showPeak_i : in STD_LOGIC;
           showMax_i : in STD_LOGIC;
           showMin_i : in STD_LOGIC;
           ram_data_ch1_i : in STD_LOGIC_VECTOR (ADC_DATA_WIDTH - 1 downto 0);
           ram_data_ch2_i : in STD_LOGIC_VECTOR (ADC_DATA_WIDTH - 1 downto 0);
           peak1_i : in STD_LOGIC_VECTOR(16 downto 0);
           average1_i : in STD_LOGIC_VECTOR(16 downto 0);
           max1_i : in STD_LOGIC_VECTOR(16 downto 0);
           min1_i : in STD_LOGIC_VECTOR(16 downto 0);
           peak2_i : in STD_LOGIC_VECTOR(16 downto 0);
           average2_i : in STD_LOGIC_VECTOR(16 downto 0);
           max2_i : in STD_LOGIC_VECTOR(16 downto 0);
           min2_i : in STD_LOGIC_VECTOR(16 downto 0);
           ram_addr_o : out STD_LOGIC_VECTOR(RAM_ADDR_WIDTH - 1 downto 0);
           ram_read_en_o : out STD_LOGIC;
           giveBusControl_o : out STD_LOGIC;
           VGA_HS_O : out STD_LOGIC;
           VGA_VS_O : out STD_LOGIC;
           VGA_RED_O : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_BLUE_O : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_GREEN_O : out STD_LOGIC_VECTOR (3 downto 0));
    end VGA;

architecture Behavioral of VGA is

--------------------------------------
--Component Declarations
--------------------------------------

--Pixel CLK
--  component pxl_clk
--    port (
--      resetn     : in  std_logic;
--      clk_in1   : in  std_logic;
--      clk_out1  : out  std_logic;
--      locked    : out std_logic
--      );
--  end component;

  component CLK_VGA is
    Port ( CLK_i : in  STD_LOGIC;
           reset_i : in  STD_LOGIC;
           Clk_o : out  STD_LOGIC);
end component;         

--Plot Display
component GridDisplay is
    Port ( Reset_i : in STD_LOGIC;
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
end component;

--Writing ROM  (Tiene un retardo de 2 ciclos de reloj. 
component characterROM
    port( clk_i : in STD_LOGIC;
          reset_i : in STD_LOGIC;
          --ena : in STD_LOGIC;
          addr_i : in STD_LOGIC_VECTOR (CHARACTER_ROM_ADDR_WIDTH - 1 DOWNTO 0);
          data_o : out std_logic_vector(CHARACTER_ROM_DATA_WIDTH - 1 DOWNTO 0));
end component;

component SymbolROM is
    Port ( clk_i : in STD_LOGIC;
           reset_i : in STD_LOGIC;
           addr_i : in STD_LOGIC_VECTOR (SYMBOL_ROM_ADDR_WIDTH - 1 downto 0);
           data_o : out STD_LOGIC_VECTOR (SYMBOL_ROM_DATA_WIDTH - 1 downto 0));
end component;

component VoltsPerDivision
        Generic ( CHANNEL : integer range 0 to N_CHANNELS;
                  COLOR : std_logic_vector(11 downto 0));
        port (Reset_I   : in std_logic;
              CLK_I     : in std_logic;
              clk_pxl_i     : in std_logic;
              en_x_i : in std_logic;
              en_y_i : in std_logic;
              VPD_I     : in std_logic_vector (3 downto 0);
              ROM_Data  : in std_logic_vector (7 downto 0);
              ROM_Addr  : out std_logic_vector (7 downto 0);
              Red_O     : out std_logic_vector (3 downto 0);
              Green_O   : out std_logic_vector (3 downto 0);
              Blue_O    : out std_logic_vector (3 downto 0));
    end component;
    
component TimePerDivision
        port (Reset_I   : in std_logic;
              CLK_I     : in std_logic;
              clk_pxl_i     : in std_logic;
              en_x_i : in std_logic;
              en_y_i : in std_logic;
              TPD_I     : in std_logic_vector (3 downto 0);
              ROM_Data  : in std_logic_vector (7 downto 0);
              ROM_Addr  : out std_logic_vector (7 downto 0);
              Red_O     : out std_logic_vector (3 downto 0);
              Green_O   : out std_logic_vector (3 downto 0);
              Blue_O    : out std_logic_vector (3 downto 0));
end component;

component Vavg_Plot is
    Generic ( CHANNEL : integer range 0 to N_CHANNELS;
              COLOR : std_logic_vector(11 downto 0));
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_i : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           average_i : in STD_LOGIC_VECTOR (16 DOWNTO 0);
           ROM_Data : in STD_LOGIC_VECTOR (7 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (7 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end component;

component Vpp_Plot is
    Generic ( CHANNEL : integer range 0 to N_CHANNELS;
              COLOR : std_logic_vector(11 downto 0));
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_I : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           peak_I : in STD_LOGIC_VECTOR (16 DOWNTO 0);   
           ROM_Data : in STD_LOGIC_VECTOR (7 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (7 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end component;

component Vmax_Plot is
    Generic ( CHANNEL : integer range 0 to N_CHANNELS;
              COLOR : std_logic_vector(11 downto 0));
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_I : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           max_i : in STD_LOGIC_VECTOR (16 DOWNTO 0);   --Average in BCD
           ROM_Data : in STD_LOGIC_VECTOR (7 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (7 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end component;

component Vmin_Plot is
    Generic ( CHANNEL : integer range 0 to N_CHANNELS;
              COLOR : std_logic_vector(11 downto 0));
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_I : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           min_i : in STD_LOGIC_VECTOR (16 DOWNTO 0);   --Average in BCD
           ROM_Data : in STD_LOGIC_VECTOR (7 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (7 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end component;
    
component SignalBuffer is
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
end component;

component TriggerArrow is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_I : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           --H_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           --V_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           ROM_Data : in STD_LOGIC_VECTOR (SYMBOL_ROM_DATA_WIDTH - 1 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (SYMBOL_ROM_ADDR_WIDTH - 1 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end component;

component TriggerEdge is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_I : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           edgeSelector_i : in STD_LOGIC;
           --H_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           --V_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           ROM_Data : in STD_LOGIC_VECTOR (SYMBOL_ROM_DATA_WIDTH - 1 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (SYMBOL_ROM_ADDR_WIDTH - 1 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end component;

component TriggerMode is
    Port ( Reset_I : in STD_LOGIC;
           CLK_I : in STD_LOGIC;
           clk_pxl_I : in STD_LOGIC;
           en_x_i : in STD_LOGIC;
           en_y_i : in STD_LOGIC;
           --H_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           --V_COUNT_I : in STD_LOGIC_VECTOR (11 DOWNTO 0);
           TriggerAuto_i: in STD_LOGIC;
           ROM_Data : in STD_LOGIC_VECTOR (7 DOWNTO 0);
           ROM_Addr : out STD_LOGIC_VECTOR (7 DOWNTO 0);          
           Red_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Green_O : out STD_LOGIC_VECTOR (3 DOWNTO 0);
           Blue_O : out STD_LOGIC_VECTOR (3 DOWNTO 0));
end component;
  
  -------------------------------------------------------------------------
  -- VGA Controller specific signals: Counters, Sync, R, G, B
  -------------------------------------------------------------------------
  -- Pixel clock, in this case 108 MHz
  signal clk_pxl : std_logic;
  -- The active signal is used to signal the active region of the screen (when not blank)
  signal active  : std_logic;
  
  -- Horizontal and Vertical counters
  signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
  
  -- Pipe Horizontal and Vertical Counters
  signal h_cntr_reg_dly   : std_logic_vector(11 downto 0) := (others => '0');
  signal v_cntr_reg_dly   : std_logic_vector(11 downto 0) := (others => '0');
  
  -- Horizontal and Vertical Sync
  signal h_sync_reg : std_logic := not(VGA_H_POL);
  signal v_sync_reg : std_logic := not(VGA_V_POL);
  -- Pipe Horizontal and Vertical Sync
  signal h_sync_reg_dly : std_logic := not(VGA_H_POL);
  signal v_sync_reg_dly : std_logic :=  not(VGA_V_POL);
  
  -- VGA R, G and B signals coming from the main multiplexers
  signal vga_red_cmb   : std_logic_vector(3 downto 0);
  signal vga_green_cmb : std_logic_vector(3 downto 0);
  signal vga_blue_cmb  : std_logic_vector(3 downto 0);
  --The main VGA R, G and B signals, validated by active
  signal vga_red    : std_logic_vector(3 downto 0);
  signal vga_green  : std_logic_vector(3 downto 0);
  signal vga_blue   : std_logic_vector(3 downto 0);
  -- Register VGA R, G and B signals
  signal vga_red_reg   : std_logic_vector(3 downto 0) := (others =>'0');
  signal vga_green_reg : std_logic_vector(3 downto 0) := (others =>'0');
  signal vga_blue_reg  : std_logic_vector(3 downto 0) := (others =>'0');
  
-----------------------------------------------------------
-- Interconnection signals for the displaying components
-----------------------------------------------------------

-- Text signals 

signal vpd1_red, vpd1_green, vpd1_blue : std_logic_vector(3 downto 0);
signal vpd2_red, vpd2_green, vpd2_blue : std_logic_vector(3 downto 0);
signal tpd_red, tpd_green, tpd_blue : std_logic_vector(3 downto 0);
signal avg1_red, avg1_green, avg1_blue : std_logic_vector(3 downto 0);
signal avg2_red, avg2_green, avg2_blue : std_logic_vector(3 downto 0);
signal peak1_red, peak1_green, peak1_blue : std_logic_vector(3 downto 0);
signal peak2_red, peak2_green, peak2_blue : std_logic_vector(3 downto 0);
signal max1_red, max1_green, max1_blue : std_logic_vector(3 downto 0);
signal max2_red, max2_green, max2_blue : std_logic_vector(3 downto 0);
signal min1_red, min1_green, min1_blue : std_logic_vector(3 downto 0);
signal min2_red, min2_green, min2_blue : std_logic_vector(3 downto 0);
signal arrow_red,  arrow_green,  arrow_blue : std_logic_vector(3 downto 0);
signal edge_red,  edge_green,  edge_blue : std_logic_vector(3 downto 0);
signal triggerMode_red,  triggerMode_green,  triggerMode_blue : std_logic_vector(3 downto 0);



-- Plot display signals

signal Plot_red : std_logic_vector(3 downto 0);
signal Plot_green : std_logic_vector(3 downto 0);
signal Plot_blue : std_logic_vector(3 downto 0);



--Writing ROM signals
signal CharacterROM_Address_aux, CharacterROM_Data_aux : std_logic_vector(7 downto 0);
signal SymbolROM_Address_aux : std_logic_vector(SYMBOL_ROM_ADDR_WIDTH - 1 downto 0);
signal SymbolROM_Data_aux : std_logic_vector(SYMBOL_ROM_DATA_WIDTH - 1 downto 0);
--signal CharacterROM_EN : std_logic;
  
  -----------------------------------------------------------
  -- Signals for generating the background
  -----------------------------------------------------------
--  signal cntDyn                : integer range 0 to 2**28-1; -- counter for generating the colorbar
--  signal intHcnt                : integer range 0 to VGA_H_MAX - 1;
--  signal intVcnt                : integer range 0 to VGA_V_MAX - 1;
  -- Colorbar red, greeen and blue signals
  signal bg_red                 : std_logic_vector(3 downto 0);
  signal bg_blue             : std_logic_vector(3 downto 0);
  signal bg_green             : std_logic_vector(3 downto 0);
  -- Pipe the colorbar red, green and blue signals
  signal bg_red_dly            : std_logic_vector(3 downto 0) := (others => '0');
  signal bg_green_dly        : std_logic_vector(3 downto 0) := (others => '0');
  signal bg_blue_dly        : std_logic_vector(3 downto 0) := (others => '0');



--------------------------------------------------------------------
-- Enable signals
--------------------------------------------------------------------

signal vpd1_en_x, vpd1_en_y : std_logic;
signal vpd2_en_x, vpd2_en_y : std_logic;
signal tpd_en_x, tpd_en_y : std_logic;
signal Plot_en_x, Plot_en_y : std_logic;

signal avg1_en_x, avg1_en_y : std_logic;
signal peak1_en_x, peak1_en_y : std_logic;
signal max1_en_x, max1_en_y : std_logic;
signal min1_en_x, min1_en_y : std_logic;


signal avg2_en_x, avg2_en_y : std_logic;
signal peak2_en_x, peak2_en_y : std_logic;
signal max2_en_x, max2_en_y : std_logic;
signal min2_en_x, min2_en_y : std_logic;

signal arrow_en_x, arrow_en_y : std_logic;
signal edge_en_x, edge_en_y : std_logic;
signal triggerMode_en_x, triggerMode_en_y : std_logic;


--signal trigger_arrow_pos : integer range 0 to VGA_FRAME_HEIGHT;
--signal TRIGGER_ARROW_Y_START_START : integer range 0 to VGA_FRAME_HEIGHT;

   signal trigger_pos_aux : signed(ADC_DATA_WIDTH + 23 - 1 downto 0);
   signal  TRIGGER_ARROW_Y_START : std_logic_vector(PLOT_HEIGHT_BIT_LENGTH - 1 downto 0);



----------------------------------------------------------------------
-- Buffer signals
----------------------------------------------------------------------

signal buffer_addr_i_aux : std_logic_vector(PLOT_WIDTH_BIT_LENGTH - 1 downto 0);
signal plot_data_ch1, plot_data_ch2 : std_logic_vector(PLOT_HEIGHT_BIT_LENGTH - 1 downto 0);
signal scaleFactor_aux : std_logic_vector (21 downto 0);


begin
  
  ------------------------------------
  -- Generate the 60 MHz pixel clock 
  ------------------------------------          
--  Clock_generator : pxl_clk
--    port map (
--      resetn    => reset_I,   
--      clk_in1  => Clk_I,
--      clk_out1 => clk_pxl,
--      locked   => open);

  Inst_pxl_clk : CLK_VGA 
      port map(
         CLK_i => CLK_i,
         reset_i => reset_i,
         Clk_o => clk_pxl);

  --clk_pxl <= CLK_I;
        
   ---------------------------------------------------------------
   -- Generate Horizontal, Vertical counters and the Sync signals
   ---------------------------------------------------------------
     -- Horizontal counter
     process (CLK_I)
     begin
       if (rising_edge(CLK_I)) then
         if clk_pxl = '1' then
             if (h_cntr_reg = (VGA_H_MAX - 1)) then
               h_cntr_reg <= (others =>'0');
             else
               h_cntr_reg <= h_cntr_reg + 1;
             end if;
         end if;
       end if;
     end process;
     
     -- Vertical counter
     process (CLK_I)
     begin
       if (rising_edge(CLK_I)) then
            if clk_pxl = '1' then
                 if ((h_cntr_reg = (VGA_H_MAX - 1)) and (v_cntr_reg = (VGA_V_MAX - 1))) then
                   v_cntr_reg <= (others =>'0');
                 elsif (h_cntr_reg = (VGA_H_MAX - 1)) then
                   v_cntr_reg <= v_cntr_reg + 1;
                 end if;
           end if;
       end if;
     end process;
     
     -- Horizontal sync
     process (CLK_I)
     begin
       if (rising_edge(CLK_I)) then
          if clk_pxl = '1' then
             if (h_cntr_reg >= (VGA_H_FP + VGA_FRAME_WIDTH - 1)) and (h_cntr_reg < (VGA_H_FP + VGA_FRAME_WIDTH + VGA_H_PW - 1)) then
               h_sync_reg <= VGA_H_POL;
             else
               h_sync_reg <= not(VGA_H_POL);
             end if;
          end if;
       end if;
     end process;
     
     -- Vertical sync
     process (CLK_I)
     begin
       if (rising_edge(CLK_I)) then
          if clk_pxl = '1' then
             if (v_cntr_reg >= (VGA_V_FP + VGA_FRAME_HEIGHT - 1)) and (v_cntr_reg < (VGA_V_FP + VGA_FRAME_HEIGHT + VGA_V_PW - 1)) then
               v_sync_reg <= VGA_V_POL;
             else
               v_sync_reg <= not(VGA_V_POL);
             end if;
          end if;
       end if;
     end process;
     
   --------------------
   -- The active        
   --------------------  
     -- active signal
     active <= '1' when h_cntr_reg_dly < VGA_FRAME_WIDTH and v_cntr_reg_dly < VGA_FRAME_HEIGHT
               else '0';
       
     ---------------------------------------
     -- Plot Display Instanciation    
     ---------------------------------------

 	Inst_PlotDisplay: GridDisplay 
	PORT MAP(
		Reset_i => Reset_i,
		CLK_i => clk_i,
		clk_pxl_i => clk_pxl,
		en_x_i => Plot_en_x,
		en_y_i => Plot_en_y,
		data_ch1_i => plot_data_ch1,
		data_ch2_i => plot_data_ch2,
		buffer_addr_o => buffer_addr_i_aux,
		RED_O    => Plot_red,
		BLUE_O   => Plot_blue,
		GREEN_O  => Plot_green
	);
	
--	bg_red <= Plot_red;
--    bg_green <= Plot_green;
--    bg_blue <= Plot_blue;
            
  ------------------------------------
  -- Memory for the letters and numbers
  ------------------------------------          
  Ins_Character_ROM : CharacterROM
  port map
   (
    clk_i => clk_i, 
    reset_i => reset_i,
    --ena => CharacterROM_EN,
    addr_i => CharacterROM_Address_aux,
    data_o => CharacterROM_Data_aux);
    
   Ins_Symbol_ROM : SymbolROM
  port map
   (
    clk_i => clk_i,
    reset_i => reset_i,
    --ena => CharacterROM_EN,
    addr_i => SymbolROM_Address_aux,
    data_o => SymbolROM_Data_aux); 
    
--  Ins_VoltsPerDivision : VoltsPerDivision
--  GENERIC MAP(
--		X_START	=> 40,
--		Y_START	=> 5)
--  port map
--   (clk_pxl => clk_pxl,
--    H_COUNT_I => h_cntr_reg,
--    V_COUNT_I => v_cntr_reg,
--    VPD_I => VPD1,
--    CharacterROM_Address => CharacterROM_Address_aux,
--    CharacterROM_Data => CharacterROM_Data_aux,
--    Red_O => ,
--    Green_O => ,
--    Blue_O => );


-----------------------------------------------------
-- Enable signals
-----------------------------------------------------
-- VPD channel 1
vpd1_en_y <= '1' when (v_cntr_reg >= VPD1_Y_START-1 and v_cntr_reg <= VPD1_Y_START + DIGIT_HEIGHT - 2) else '0';
vpd1_en_x <= '1' when ((h_cntr_reg >= VPD1_X_START-1 and h_cntr_reg <= VPD1_X_START + SETTING_WIDTH - 2) and vpd1_en_y = '1') else '0';

-- VPD channel 2
vpd2_en_y <= '1' when (v_cntr_reg >= VPD2_Y_START-1 and v_cntr_reg <= VPD2_Y_START + DIGIT_HEIGHT - 2) else '0';
vpd2_en_x <= '1' when ((h_cntr_reg >= VPD2_X_START-1 and h_cntr_reg <= VPD2_X_START + SETTING_WIDTH - 2) and vpd2_en_y = '1') else '0';

-- TPD
tpd_en_y <= '1' when (v_cntr_reg >= TPD_Y_START-1 and v_cntr_reg <= TPD_Y_START + DIGIT_HEIGHT - 2) else '0';
tpd_en_x <= '1' when ((h_cntr_reg >= TPD_X_START-1 and h_cntr_reg <= TPD_X_START + SETTING_WIDTH - 2) and tpd_en_y = '1') else '0';

-- Plot
plot_en_x <= '1' when ((h_cntr_reg >= PLOT_X_START-1 and h_cntr_reg <= PLOT_X_START + PLOT_WIDTH - 2) and Plot_en_y = '1') else '0';
plot_en_y <= '1' when (v_cntr_reg >= PLOT_Y_START-1 and v_cntr_reg <= PLOT_Y_START + PLOT_HEIGHT - 2) else '0'; 

-- Vavg channel 1
avg1_en_y <= '1' when (v_cntr_reg >= VAVG1_Y_START-1 and v_cntr_reg <= VAVG1_Y_START + DIGIT_HEIGHT - 2) and ShowAVG_i = '1' else '0';
avg1_en_x <= '1' when ((h_cntr_reg >= VAVG1_X_START-1 and h_cntr_reg <= VAVG1_X_START + MEASUREMENT_WIDTH - 2) and avg1_en_y = '1') else '0';

-- Vpp channel 1
peak1_en_y <= '1' when (v_cntr_reg >= VPP1_Y_START-1 and v_cntr_reg <= VPP1_Y_START + DIGIT_HEIGHT - 2) and ShowPeak_i = '1' else '0';
peak1_en_x <= '1' when ((h_cntr_reg >= VPP1_X_START-1 and h_cntr_reg <= VPP1_X_START + MEASUREMENT_WIDTH - 2) and peak1_en_y = '1') else '0';

-- Vmax channel 1
max1_en_y <= '1' when (v_cntr_reg >= VMAX1_Y_START-1 and v_cntr_reg <= VMAX1_Y_START + DIGIT_HEIGHT - 2) and ShowMax_i = '1' else '0';
max1_en_x <= '1' when ((h_cntr_reg >= VMAX1_X_START-1 and h_cntr_reg <= VMAX1_X_START + MEASUREMENT_WIDTH - 2) and max1_en_y = '1') else '0';

-- Vmin channel 1
min1_en_y <= '1' when (v_cntr_reg >= VMIN1_Y_START-1 and v_cntr_reg <= VMIN1_Y_START + DIGIT_HEIGHT - 2) and ShowMin_i = '1' else '0';
min1_en_x <= '1' when ((h_cntr_reg >= VMIN1_X_START-1 and h_cntr_reg <= VMIN1_X_START + MEASUREMENT_WIDTH - 2) and min1_en_y = '1') else '0';

-- Vavg channel 2
avg2_en_y <= '1' when (v_cntr_reg >= VAVG2_Y_START-1 and v_cntr_reg <= VAVG2_Y_START + DIGIT_HEIGHT - 2) and ShowAVG_i = '1' else '0';
avg2_en_x <= '1' when ((h_cntr_reg >= VAVG2_X_START-1 and h_cntr_reg <= VAVG2_X_START + MEASUREMENT_WIDTH - 2) and avg2_en_y = '1') else '0';

--Vpp channel 2
peak2_en_y <= '1' when (v_cntr_reg >= VPP2_Y_START-1 and v_cntr_reg <= VPP2_Y_START + DIGIT_HEIGHT - 2) and ShowPeak_i = '1' else '0';
peak2_en_x <= '1' when ((h_cntr_reg >= VPP2_X_START-1 and h_cntr_reg <= VPP2_X_START + MEASUREMENT_WIDTH - 2) and peak2_en_y = '1') else '0';

-- Vmax channel 2
max2_en_y <= '1' when (v_cntr_reg >= VMAX2_Y_START-1 and v_cntr_reg <= VMAX2_Y_START + DIGIT_HEIGHT - 2) and ShowMax_i = '1' else '0';
max2_en_x <= '1' when ((h_cntr_reg >= VMAX2_X_START-1 and h_cntr_reg <= VMAX2_X_START + MEASUREMENT_WIDTH - 2) and max2_en_y = '1') else '0';

-- Vmin channel 2
min2_en_y <= '1' when (v_cntr_reg >= VMIN2_Y_START-1 and v_cntr_reg <= VMIN2_Y_START + DIGIT_HEIGHT - 2) and ShowMin_i = '1' else '0';
min2_en_x <= '1' when ((h_cntr_reg >= VMIN2_X_START-1 and h_cntr_reg <= VMIN2_X_START + MEASUREMENT_WIDTH - 2) and min2_en_y = '1') else '0';

-- Trigger arrow
arrow_en_y <= '1' when (v_cntr_reg >= TRIGGER_ARROW_Y_START - 1 and v_cntr_reg <= TRIGGER_ARROW_Y_START + SYMBOL_HEIGHT - 2) else '0';
arrow_en_x <= '1' when ((h_cntr_reg >= TRIGGER_ARROW_X_START-1 and h_cntr_reg <= TRIGGER_ARROW_X_START + SYMBOL_WIDTH - 2) and arrow_en_y = '1') else '0';

-- Trigger edge
edge_en_y <= '1' when (v_cntr_reg >= TRIGGER_EDGE_Y_START - 1 and v_cntr_reg <= TRIGGER_EDGE_Y_START + SYMBOL_HEIGHT - 2) else '0';
edge_en_x <= '1' when ((h_cntr_reg >= TRIGGER_EDGE_X_START-1 and h_cntr_reg <= TRIGGER_EDGE_X_START + SYMBOL_WIDTH - 2) and edge_en_y = '1') else '0';

-- Trigger mode
triggerMode_en_y <= '1' when (v_cntr_reg >= TRIGGER_MODE_Y_START - 1 and v_cntr_reg <= TRIGGER_MODE_Y_START + DIGIT_HEIGHT - 2) else '0';
triggerMode_en_x <= '1' when ((h_cntr_reg >= TRIGGER_MODE_X_START - 1 and h_cntr_reg <= TRIGGER_MODE_X_START + TRIGGER_WIDTH - 2) and triggerMode_en_y = '1') else '0';

--triggerMode_en_y <= '0';
--triggerMode_en_x <= '0';

Ins_VoltsPerDivision1 : VoltsPerDivision
    GENERIC MAP(CHANNEL	=> 1,
                COLOR => COLOR_CH1)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i => clk_pxl,
              en_x_i => vpd1_en_x,
              en_y_i => vpd1_en_y,
              VPD_I     => VPD1_I,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => vpd1_red,
              Green_O   => vpd1_green,
              Blue_O    => vpd1_blue);
              
Ins_VoltsPerDivision2 : VoltsPerDivision
    GENERIC MAP(CHANNEL	=> 2,
                COLOR => COLOR_CH2)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i => clk_pxl,
              en_x_i => vpd2_en_x,
              en_y_i => vpd2_en_y,
              VPD_I     => VPD2_I,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => vpd2_red,
              Green_O   => vpd2_green,
              Blue_O    => vpd2_blue);
              
Ins_TimePerDivision : TimePerDivision
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => tpd_en_x,
              en_y_i => tpd_en_y,
              TPD_I     => TPD_I,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => tpd_red,
              Green_O   => tpd_green,
              Blue_O    => tpd_blue);

 Ins_Vavg_Plot_ch1 : Vavg_Plot
    GENERIC MAP(CHANNEL	=> 1,
                COLOR => COLOR_CH1)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => avg1_en_x,
              en_y_i => avg1_en_y,
              average_I     => average1_i,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => avg1_red,
              Green_O   => avg1_green,
              Blue_O    => avg1_blue);                     

 Ins_Vavg_Plot_ch2 : Vavg_Plot
    GENERIC MAP(CHANNEL	=> 2,
                COLOR => COLOR_CH2)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => avg2_en_x,
              en_y_i => avg2_en_y,
              average_i => average2_i,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => avg2_red,
              Green_O   => avg2_green,
              Blue_O    => avg2_blue);  
  
  Ins_Vpp_Plot_ch1 : Vpp_Plot
    GENERIC MAP(CHANNEL	=> 1,
                COLOR => COLOR_CH1)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => peak1_en_x,
              en_y_i => peak1_en_y,
              peak_i => peak1_i,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => peak1_red,
              Green_O   => peak1_green,
              Blue_O    => peak1_blue);             
              
  Ins_Vpp_Plot_ch2 : Vpp_Plot
    GENERIC MAP(CHANNEL	=> 2,
                COLOR => COLOR_CH2)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => peak2_en_x,
              en_y_i => peak2_en_y,
              peak_i => peak2_i,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => peak2_red,
              Green_O   => peak2_green,
              Blue_O    => peak2_blue); 
              
    Ins_Vmax_Plot_ch1 : Vmax_Plot
    GENERIC MAP(CHANNEL	=> 1,
                COLOR => COLOR_CH1)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => max1_en_x,
              en_y_i => max1_en_y,
              max_i => max1_i,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => max1_red,
              Green_O   => max1_green,
              Blue_O    => max1_blue); 
              
     Ins_Vmax_Plot_ch2 : Vmax_Plot
    GENERIC MAP(CHANNEL	=> 2,
                COLOR => COLOR_CH2)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => max2_en_x,
              en_y_i => max2_en_y,
              max_i => max2_i,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => max2_red,
              Green_O   => max2_green,
              Blue_O    => max2_blue); 
      
     Ins_Vmin_Plot_ch1 : Vmin_Plot
    GENERIC MAP(CHANNEL	=> 1,
                COLOR => COLOR_CH1)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => min1_en_x,
              en_y_i => min1_en_y,
              min_i => min1_i,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => min1_red,
              Green_O   => min1_green,
              Blue_O    => min1_blue); 
      
     Ins_Vmin_Plot_ch2 : Vmin_Plot
    GENERIC MAP(CHANNEL	=> 2,
                COLOR => COLOR_CH2)
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => min2_en_x,
              en_y_i => min2_en_y,
              min_i => min2_i,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => min2_red,
              Green_O   => min2_green,
              Blue_O    => min2_blue);         
                           
Ins_SignalBuffer_ch1 : SignalBuffer
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              data_i => ram_data_ch1_i,
              v_sync_i => v_sync_reg,
              plot_en_i     => plot_en_y,
              VPD_i     => VPD1_i,
              trigger_addr_i => trigger_addr_i,
              triggered_i => triggered_i,
              buffer_addr_i  => buffer_addr_i_aux,
              ram_addr_o  => ram_addr_o,
              
              scaleFactor_o => scaleFactor_aux,
              
              ram_read_en_o  => ram_read_en_o,
              giveBusControl_o     => giveBusControl_o,
              data_o   => plot_data_ch1);         
              
Ins_SignalBuffer_ch2 : SignalBuffer
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              data_i => ram_data_ch2_i,
              v_sync_i => v_sync_reg,
              plot_en_i     => plot_en_y,
              VPD_i     => VPD2_i,
              trigger_addr_i => trigger_addr_i,
              triggered_i => triggered_i,
              buffer_addr_i  => buffer_addr_i_aux,
              ram_addr_o  => open,
              
              scaleFactor_o => open,
              
              ram_read_en_o  => open,
              giveBusControl_o     => open,
              data_o   => plot_data_ch2); 

   
   process(reset_i, clk_i)
   begin
        if reset_i ='0' then
            trigger_pos_aux <= (Others => '0');
        elsif rising_edge(clk_i) then
            trigger_pos_aux <= signed(trigger_i) * signed('0' & scaleFactor_aux); --trigger * 88
        end if;
   end process;
   
   TRIGGER_ARROW_Y_START <= std_logic_vector(TRIGGER_ARROW_Y_INIT - trigger_pos_aux (11 + PLOT_HEIGHT_BIT_LENGTH - 1 downto 11));
   
   Ins_TriggerArrow : TriggerArrow
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => arrow_en_x,
              en_y_i => arrow_en_y,
              ROM_Data  => SymbolROM_Data_aux,
              ROM_Addr  => SymbolROM_Address_aux,
              Red_O     => arrow_red,
              Green_O   => arrow_green,
              Blue_O    => arrow_blue);  
    
      
      
   Ins_TriggerEdge : TriggerEdge
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => edge_en_x,
              en_y_i => edge_en_y,
              edgeSelector_i => triggerEdge_i,
              ROM_Data  => SymbolROM_Data_aux,
              ROM_Addr  => SymbolROM_Address_aux,
              Red_O     => edge_red,
              Green_O   => edge_green,
              Blue_O    => edge_blue);  
                                 
    Inst_TriggerMode : TriggerMode
    port map (Reset_I   => Reset_I,
              CLK_i     => clk_i,
              clk_pxl_i     => clk_pxl,
              en_x_i => triggerMode_en_x,
              en_y_i => triggerMode_en_y,
              triggerAuto_i => triggerAuto_i,
              ROM_Data  => CharacterROM_Data_aux,
              ROM_Addr  => CharacterROM_Address_aux,
              Red_O     => triggerMode_red,
              Green_O   => triggerMode_green,
              Blue_O    => triggerMode_blue);  
                        
	bg_red <= vpd1_red when vpd1_en_x = '1' and vpd1_en_y = '1' else
	          vpd2_red when vpd2_en_x = '1' and vpd2_en_y = '1' else
	          tpd_red when tpd_en_x = '1' and tpd_en_y = '1' else
	          Plot_red when Plot_en_x = '1' and Plot_en_y = '1' else
	          avg1_red when avg1_en_x = '1' and avg1_en_y = '1' else
	          avg2_red when avg2_en_x = '1' and avg2_en_y = '1' else
	          peak1_red when peak1_en_x = '1' and peak1_en_y = '1' else
	          peak2_red when peak2_en_x = '1' and peak2_en_y = '1' else
	          max1_red when max1_en_x = '1' and max1_en_y = '1' else
	          max2_red when max2_en_x = '1' and max2_en_y = '1' else
	          min1_red when min1_en_x = '1' and min1_en_y = '1' else
	          min2_red when min2_en_x = '1' and min2_en_y = '1' else
	          arrow_red when arrow_en_x = '1' and arrow_en_y = '1' else
	          edge_red when edge_en_x = '1' and edge_en_y = '1' else
	          triggerMode_red when triggerMode_en_x = '1' and triggerMode_en_y = '1' else
	          "0000";
	          
    bg_green <= vpd1_green when vpd1_en_x = '1' and vpd1_en_y = '1' else
	            vpd2_green when vpd2_en_x = '1' and vpd2_en_y = '1' else
	            tpd_green when tpd_en_x = '1' and tpd_en_y = '1' else
	            Plot_green when Plot_en_x = '1' and Plot_en_y = '1' else
	            avg1_green when avg1_en_x = '1' and avg1_en_y = '1' else
	            avg2_green when avg2_en_x = '1' and avg2_en_y = '1' else
	            peak1_green when peak1_en_x = '1' and peak1_en_y = '1' else
	            peak2_green when peak2_en_x = '1' and peak2_en_y = '1' else
	            max1_green when max1_en_x = '1' and max1_en_y = '1' else
	            max2_green when max2_en_x = '1' and max2_en_y = '1' else
	            min1_green when min1_en_x = '1' and min1_en_y = '1' else
	            min2_green when min2_en_x = '1' and min2_en_y = '1' else
	            arrow_green when arrow_en_x = '1' and arrow_en_y = '1' else
	            edge_green when edge_en_x = '1' and edge_en_y = '1' else
	            triggerMode_green when triggerMode_en_x = '1' and triggerMode_en_y = '1' else
	            "0000";
	            
    bg_blue <= vpd1_blue when vpd1_en_x = '1' and vpd1_en_y = '1' else
	           vpd2_blue when vpd2_en_x = '1' and vpd2_en_y = '1' else
	           tpd_blue when tpd_en_x = '1' and tpd_en_y = '1' else
	           Plot_blue when Plot_en_x = '1' and Plot_en_y = '1' else
	           avg1_blue when avg1_en_x = '1' and avg1_en_y = '1' else
	           avg2_blue when avg2_en_x = '1' and avg2_en_y = '1' else
	           peak1_blue when peak1_en_x = '1' and peak1_en_y = '1' else
	           peak2_blue when peak2_en_x = '1' and peak2_en_y = '1' else
	           max1_blue when max1_en_x = '1' and max1_en_y = '1' else
	           max2_blue when max2_en_x = '1' and max2_en_y = '1' else
	           min1_blue when min1_en_x = '1' and min1_en_y = '1' else
	           min2_blue when min2_en_x = '1' and min2_en_y = '1' else
	           arrow_blue when arrow_en_x = '1' and arrow_en_y = '1' else
	           edge_blue when edge_en_x = '1' and edge_en_y = '1' else
	           triggerMode_blue when triggerMode_en_x = '1' and triggerMode_en_y = '1' else
	           "0000"; 
	              
    ---------------------------------------------------------------------------------------------------   
    -- Register Outputs coming from the displaying components and the horizontal and vertical counters   
    ---------------------------------------------------------------------------------------------------
      process (clk_i)
      begin   
        if (rising_edge(clk_i)) then
            if clk_pxl = '1' then
                bg_red_dly            <= bg_red;
                bg_green_dly        <= bg_green;
                bg_blue_dly            <= bg_blue;
               
                h_cntr_reg_dly <= h_cntr_reg;
                v_cntr_reg_dly <= v_cntr_reg;
            end if;

        end if;
      end process;

    ----------------------------------
    -- VGA Output
    ----------------------------------

    vga_red <= bg_red_dly;
    vga_green <= bg_green_dly;
    vga_blue <= bg_blue_dly;
           
    ------------------------------------------------------------
    -- Turn Off VGA RBG Signals if outside of the active screen
    -- Make a 4-bit AND logic with the R, G and B signals
    ------------------------------------------------------------
    vga_red_cmb <= (active & active & active & active) and vga_red;
    vga_green_cmb <= (active & active & active & active) and vga_green;
    vga_blue_cmb <= (active & active & active & active) and vga_blue;
    
    
    -- Register Outputs
     process (clk_i)
     begin
       if (rising_edge(clk_i)) then
         if clk_pxl = '1' then
             v_sync_reg_dly <= v_sync_reg;
             h_sync_reg_dly <= h_sync_reg;
             vga_red_reg    <= vga_red_cmb;
             vga_green_reg  <= vga_green_cmb;
             vga_blue_reg   <= vga_blue_cmb; 
         end if;     
       end if;
     end process;
    
     -- Assign outputs
     VGA_HS_O     <= h_sync_reg_dly;
     VGA_VS_O     <= v_sync_reg_dly;
     VGA_RED_O    <= vga_red_reg;
     VGA_GREEN_O  <= vga_green_reg;
     VGA_BLUE_O   <= vga_blue_reg;

end Behavioral;
