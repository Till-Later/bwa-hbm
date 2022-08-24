----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/03/2021 11:46:15 AM
-- Design Name: 
-- Module Name: bitmask_generator - Behavioral
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
use ieee.numeric_std.all;               -- Needed for shifts

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bitmask_generator is
port (
    j : in unsigned(6 downto 0);
    bitmask : out unsigned(63 downto 0)
);
end bitmask_generator;

architecture Behavioral of bitmask_generator is

begin
    bitmask <= to_unsigned(1, 64) sll to_integer(j) - 1;

end Behavioral;
