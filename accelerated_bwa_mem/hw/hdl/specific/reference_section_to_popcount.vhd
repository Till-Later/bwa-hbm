----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/03/2021 03:07:02 PM
-- Design Name: 
-- Module Name: reference_section_to_popcount - Behavioral
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
use ieee.numeric_std.all;

                           
Library UNISIM;            
use UNISIM.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reference_section_to_popcount is
port ( 
    bitmask : in unsigned(127 downto 0);
    reference_section : in std_logic_vector(255 downto 0);
    population_bits_a : out std_logic_vector(127 downto 0);
    population_bits_c : out std_logic_vector(127 downto 0);
    population_bits_g : out std_logic_vector(127 downto 0);
    population_bits_t : out std_logic_vector(127 downto 0)
);
end reference_section_to_popcount;

architecture Behavioral of reference_section_to_popcount is

begin

   calculate_population_bits : for I in 0 to 127 generate
   signal decoded : std_logic_vector(3 downto 0);
   begin
    population_bits_a(I) <= decoded(0);
    population_bits_c(I) <= decoded(1);
    population_bits_g(I) <= decoded(2);
    population_bits_t(I) <= decoded(3);

    process(bitmask, reference_section)
    begin
        decoded <= "0000";
        if bitmask(I) = '1' then
            case reference_section(2 * I + 1 downto 2 * I) is
                when "00" => decoded(0) <= '1';
                when "01" => decoded(1) <= '1';
                when "10" => decoded(2) <= '1';
                when others => decoded(3) <= '1';
            end case;            
        end if;
    end process;    
   end generate calculate_population_bits;

end Behavioral;
