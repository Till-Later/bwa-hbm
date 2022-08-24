----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/03/2021 04:17:00 PM
-- Design Name: 
-- Module Name: compressor_128_7 - Behavioral
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

use work.compressor_36_6;

use IEEE.NUMERIC_STD.ALL;

entity compressor_128_8 is
port(   
    pi_population_bits : in std_logic_vector(127 downto 0);
    po_count           : out std_logic_vector(7 downto 0)
);
end compressor_128_8;

architecture Behavioral of compressor_128_8 is
    signal padded_population_bits : std_logic_vector(143 downto 0);
    signal subsum_counts : std_logic_vector(23 downto 0);
begin
    padded_population_bits <= "0000000000000000" & pi_population_bits;
    
    first_layer : for I in 0 to 3 generate
        compressor_36_6: entity work.compressor_36_6
        port map (
            pi_population_bits => padded_population_bits(36 * I + 35 downto 36 * I), 
            po_count => subsum_counts(6 * I + 5 downto 6 * I) 
        );
    end generate first_layer;
   
      
    po_count <= std_logic_vector(
        unsigned("00" & subsum_counts(5 downto 0))
        + unsigned("00" & subsum_counts(11 downto 6)) 
        + unsigned("00" & subsum_counts(17 downto 12))
        + unsigned("00" & subsum_counts(23 downto 18))
    );  

end Behavioral;
