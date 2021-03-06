----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Nabil Chouba
-- 
-- Create Date:    12:17:53 11/14/2009 
-- Design Name: 
-- Module Name:    vgacontroller - RTL 
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vga_sync is
port(clk_25mhz : in std_logic;     -- vga clock signal 
     rst  : in std_logic;          -- system reset 
	  video_on :out std_logic;      -- Allow the display of rgb  data on the monitor
	  horiz_sync_out: out std_logic;--vga control horiz signal 
	  vert_sync_out: out std_logic; --vga control vert signal 
	  pixel_row    : out std_logic_vector(9 downto 0); --row position of the current display pixel
	  pixel_column : out std_logic_vector(9 downto 0));--column position of the current display pixel
end vga_sync;

architecture rtl of vga_sync is

signal horiz_sync, vert_sync : std_logic;
signal video_on_v, video_on_h : std_logic;
signal h_count_next, v_count_next :std_logic_vector(9 downto 0);
signal h_count_reg, v_count_reg :std_logic_vector(9 downto 0);

begin

-- Register declaration 
-- Use of 2 counters for the generation of pixel row and column
-- Those counters are h_count_reg and v_count_reg 
cloked_process : process( clk_25mhz, rst )
  begin
    if( rst='1' ) then
      h_count_reg  <= (others=>'0') ;
		v_count_reg  <= (others=>'0') ;
    elsif( clk_25mhz'event and clk_25mhz='1' ) then
      h_count_reg <= h_count_next;
		v_count_reg <= v_count_next;
    end if;
 end process ;

--generate horizontal and vertical timing signals for video signal
-- h_count counts pixels (640 + extra time for sync signals)
-- horiz_sync ------------------------------------__________--------
-- h_count    0                        640      659        755     799
 process (h_count_reg)
 begin
   h_count_next <=h_count_reg ;
   if (h_count_reg = 799) then
     h_count_next <= (others=>'0') ;
   else
     h_count_next <= h_count_reg + 1;
   end if;
 end process ;

 --generate horizontal sync signal using h_count
horiz_sync <= '0' when (h_count_reg <= 755) and (h_count_reg >= 659) else 
              '1';

--v_count counts rows of pixels (480 + extra time for sync signals)
-- vert_sync -----------------------------------------------_______------------
-- v_count   0                                 480         493    494        524
 process (v_count_reg,h_count_reg)
 begin
  v_count_next <= v_count_reg;
  if (v_count_reg >= 524) and (h_count_reg >= 699) then
    v_count_next <= (others=>'0') ;
  elsif (h_count_reg = 699) then
    v_count_next <= v_count_reg + 1;
  end if;
 end process;
 
-- generate vertical sync signal using v_count
vert_sync <= '0' when (v_count_reg <= 494) and (v_count_reg >= 493) else 
             '1';
				 
-- generate video on screen signals for pixel data
video_on_h <= '1' when  (h_count_reg <= 639) else 
              '0';

video_on_v <= '1' when (v_count_reg <= 479) else
              '0';

-- video_on is high only when rgb data is displayed
video_on <= video_on_h and video_on_v; 

-- output signal 
horiz_sync_out <= horiz_sync;
vert_sync_out  <= vert_sync;

pixel_row    <= v_count_reg;
pixel_column <= h_count_reg;

end rtl;

