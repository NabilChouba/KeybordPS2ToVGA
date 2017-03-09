----------------------------------------------------------------------------------
-- Company: FREE
-- Engineer: Nabil Chouba
-- 
-- Create Date:    20:29:30 11/14/2009 
-- Design Name: 
-- Module Name:    mainController - RTL 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity mainController is
port(clk_25mhz : in  std_logic; -- system clock signal 
     rst       : in  std_logic; -- system reset 
	  kbdata    : in  STD_LOGIC; -- input keyboard data 
	  kbclk     : in  STD_LOGIC; -- input keyboard clock 
	  blank_out : out std_logic; -- vga control signal
	  csync_out : out std_logic; -- vga control signal
     red_out   : out std_logic_vector(7 downto 0); -- vga red pixel value
	  green_out : out std_logic_vector(7 downto 0); -- vga green pixel value
	  blue_out  : out std_logic_vector(7 downto 0); -- vga blue pixel value
--	  led  : out std_logic_vector(7 downto 0); -- for debug tu see the position of the cursor on 8 pixel
	  horiz_sync_out: out std_logic; -- vga control signal
	  vert_sync_out : out std_logic);-- vga control signal
	  
end mainController;

architecture RTL of mainController is
 component  vga_sync 
 port(clk_25mhz : in std_logic;
     rst      : in std_logic;
	  video_on :out std_logic;
	  horiz_sync_out: out std_logic;
	  vert_sync_out : out std_logic;
	  pixel_row     : out std_logic_vector(9 downto 0);
	  pixel_column  : out std_logic_vector(9 downto 0));
 end component ;

component font_rom 
   port(
      clk: in std_logic;
      addr: in std_logic_vector(10 downto 0);
      data: out std_logic_vector(7 downto 0)
   );
end component;

component keyPS2controller 
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
			  ack : in  STD_LOGIC;
           kbdata : in  STD_LOGIC;
           kbclk : in  STD_LOGIC;
			  data_ready : out  STD_LOGIC;
			  kbdatarx : out  STD_LOGIC_VECTOR (7 downto 0)
  );
end component;

component ram_dual 
generic( d_width    : integer ; 
         addr_width : integer ; 
         mem_depth  : integer 
        ); 
port (
      o2        : out STD_LOGIC_VECTOR(d_width - 1 downto 0);
      we1       : in STD_LOGIC;
      clk       : in STD_LOGIC; 
      d1        : in STD_LOGIC_VECTOR(d_width - 1 downto 0); 
      addr1     : in unsigned(addr_width - 1 downto 0);
      addr2     : in unsigned(addr_width - 1 downto 0)      
      ); 
end component; 

component counter 
PORT (  clk        : in    std_logic ; -- System Clock
        rst        : in    std_logic ; -- System Reset
		  dec        : in    std_logic ; -- count <= count + 1
		  inc        : in    std_logic ; -- count <= count + 1
		  rst_count  : in    std_logic ; -- Reset the conter count <= 0
        count      : OUT unsigned(11 DOWNTO 0)); 
END component;

component ctr 
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           kb_data_ready : in  STD_LOGIC;
           kb_ack : out  STD_LOGIC;
           counter_inc: out  STD_LOGIC;
			  counter_dec: out  STD_LOGIC;
			  ky_back_space : in STD_LOGIC;
			  ram_we : out  STD_LOGIC);
end component;

 -- pixel signal
 signal video_on : std_logic;
 signal valid_screen : std_logic;
 signal pixel : std_logic;
 
 -- pixel position
 signal pixel_row : std_logic_vector(9 downto 0);
 signal pixel_column : std_logic_vector(9 downto 0);
 
 -- rom signal 
 signal rom_addr:  std_logic_vector(10 downto 0);
 signal rom_data:  std_logic_vector(7 downto 0);
	
 -- keyboard signal
 signal kb_ack : STD_LOGIC;
 signal kb_data_ready : STD_LOGIC;
 signal kb_kbdatarx : STD_LOGIC_VECTOR (7 downto 0);
 signal ky_char : STD_LOGIC_VECTOR (7 downto 0);
 signal ky_back_space : STD_LOGIC;
 
 -- ram signal
 signal ram_we1 : STD_LOGIC;
 signal ram_q2 : STD_LOGIC_VECTOR (7 downto 0);
 signal ram_addr2 : STD_LOGIC_VECTOR (11 downto 0);
 
 -- counter signal
 signal counter_dec : STD_LOGIC;
 signal counter_inc : STD_LOGIC;
 signal counter_rst : STD_LOGIC;
 signal counter_value : unsigned (11 downto 0);		  

begin

  u_vga_sync : vga_sync 
  port map (  
     clk_25mhz => clk_25mhz,
	  rst =>rst,
	  video_on => video_on,
	  horiz_sync_out=> horiz_sync_out,
	  vert_sync_out => vert_sync_out,
	  pixel_row     => pixel_row,
	  pixel_column  => pixel_column
	  );
	  
  u_font_rom : font_rom 
  port map ( 
      clk => clk_25mhz,
      addr => rom_addr,
      data => rom_data
   );

  u_keyPS2controller:  keyPS2controller 
  port map( 
	    clk => clk_25mhz,
       rst => rst,
	    ack => kb_ack,
       kbdata =>kbdata,
       kbclk =>kbclk,
		 data_ready =>kb_data_ready,
		 kbdatarx =>kb_kbdatarx
  );

 U_MonitorRam: ram_dual 
 generic map (d_width   =>  8,
              addr_width => 12,
              mem_depth  => 4096) 
 PORT MAP (
      clk  =>clk_25mhz ,
      --write
      we1  =>ram_we1 ,
      d1   =>ky_char ,
      addr1=>counter_value ,
      --read
      o2   =>ram_q2 ,
      addr2=>unsigned(ram_addr2) );   
			 
  u_counter:  counter 
  port map(   
	    clk => clk_25mhz,
       rst => rst,
		 dec => counter_dec,
		 inc => counter_inc,
		 rst_count =>counter_rst,
       count =>counter_value
     );


u_ctr: ctr 
    Port map(
	   clk => clk_25mhz,
      rst => rst,
		counter_inc =>counter_inc,
		counter_dec => counter_dec,
		kb_data_ready =>kb_data_ready,
		kb_ack =>kb_ack,
		ky_back_space => ky_back_space,
		ram_we  =>ram_we1
	);
-- for debug tu see the position of the cursor on 8 pixel
-- led <= STD_LOGIC_VECTOR(counter_value(7 downto 0));

-- back space detection signal
ky_back_space <= '1' when kb_kbdatarx = x"66" else
              '0';
-- if back space detected clear ths current data
ky_char <= (others=>'0') when ky_back_space = '1' else 
           kb_kbdatarx;
-- allow the display of rgb color pixel			  
red_out   <= (others=>'1') when pixel='1' and  video_on = '1' and valid_screen = '1' else 
             (others=>'0') ;
				 
green_out <= (others=>'1') when pixel='1' and  video_on = '1' and valid_screen = '1' else 
             (others=>'0') ;
				 
blue_out  <= (others=>'1') when pixel='1' and  video_on = '1' and valid_screen = '1' else 
             (others=>'0') ;
	
-- we only siplay 64 x 64 char
valid_screen <= not (pixel_column(9));

-- get char that must be displayed on this region
ram_addr2 <= pixel_row(9  downto 4) & pixel_column(8  downto 3);

-- decode the ram char to displayed it on the screen
rom_addr <=  ram_q2(6 downto 0) & pixel_row(3 downto 0) ; 

-- display the row : data rom data pixel by pixel 
pixel  <= rom_data(0) when pixel_column(2 downto 0) = "000" else
          rom_data(7) when pixel_column(2 downto 0) = "001" else
          rom_data(6) when pixel_column(2 downto 0) = "010" else
          rom_data(5) when pixel_column(2 downto 0) = "011" else
          rom_data(4) when pixel_column(2 downto 0) = "100" else
          rom_data(3) when pixel_column(2 downto 0) = "101" else
          rom_data(2) when pixel_column(2 downto 0) = "110" else
			 rom_data(1) when pixel_column(2 downto 0) = "111" else
			 '0' ;

-- we not use blank_out and csync_out
blank_out <= '1';
csync_out <= '1';
	 
end RTL;

