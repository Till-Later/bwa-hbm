----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/03/2021 04:02:44 PM
-- Design Name: 
-- Module Name: compressor36_6 - Behavioral
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

use work.compressor_6_3;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity compressor_36_6 is
port(
    pi_population_bits : in std_logic_vector(35 downto 0);
    po_count           : out std_logic_vector(5 downto 0)
);
end compressor_36_6;

architecture Behavioral of compressor_36_6 is
    signal first_layer_counts : std_logic_vector(17 downto 0);
    signal second_layer_counts : std_logic_vector(8 downto 0);
begin
    first_layer : for I in 0 to 5 generate
        compressor_6_3_fist_layer: entity work.compressor_6_3
        port map (
            pi_population_bits => pi_population_bits(6 * I + 5 downto 6 * I), 
            po_count => first_layer_counts(3 * I + 2 downto 3 * I) 
        );
    end generate first_layer;
    
    second_layer : for I in 0 to 2 generate
        signal first_layer_combined_positional_bits : std_logic_vector(5 downto 0); 
    begin
        first_layer_combined_positional_bits <= 
            first_layer_counts(0 + I) 
            & first_layer_counts(3 + I)
            & first_layer_counts(6 + I)
            & first_layer_counts(9 + I)
            & first_layer_counts(12 + I)
            & first_layer_counts(15 + I);
            
        compressor_6_3_second_layer : entity work.compressor_6_3
        port map (
            pi_population_bits => first_layer_combined_positional_bits, 
            po_count => second_layer_counts(3 * I + 2 downto 3 * I) 
        );
    end generate second_layer;
    
    po_count <= 
        ("000" & second_layer_counts(2 downto 0)) 
        + ("00" & second_layer_counts(5 downto 3) & "0") 
        + ("0" & second_layer_counts(8 downto 6) & "00");  

end Behavioral;
