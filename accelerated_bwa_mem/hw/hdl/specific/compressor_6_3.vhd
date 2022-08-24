----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/03/2021 11:39:01 AM
-- Design Name: 
-- Module Name: compressor_6_3 - Behavioral
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

                           
Library UNISIM;            
use UNISIM.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity compressor_6_3 is
port(
    pi_population_bits : in std_logic_vector(5 downto 0);
    po_count           : out std_logic_vector(2 downto 0)
);
end compressor_6_3;

architecture Behavioral of compressor_6_3 is
    
begin
    LUT6_0 : LUT6
    generic map (
        INIT => X"6996966996696996"
    )
    port map(
        O => po_count(0),
        I0 => pi_population_bits(0),
        I1 => pi_population_bits(1),
        I2 => pi_population_bits(2),
        I3 => pi_population_bits(3),
        I4 => pi_population_bits(4),
        I5 => pi_population_bits(5)
    );
    
    LUT6_1 : LUT6
    generic map (
        INIT => X"8117177e177e7ee8"
    )
    port map(
        O => po_count(1),
        I0 => pi_population_bits(0),
        I1 => pi_population_bits(1),
        I2 => pi_population_bits(2),
        I3 => pi_population_bits(3),
        I4 => pi_population_bits(4),
        I5 => pi_population_bits(5)
    );
    
    LUT6_2 : LUT6
    generic map (
        INIT => X"fee8e880e8808000"
    )
    port map(
        O => po_count(2),
        I0 => pi_population_bits(0),
        I1 => pi_population_bits(1),
        I2 => pi_population_bits(2),
        I3 => pi_population_bits(3),
        I4 => pi_population_bits(4),
        I5 => pi_population_bits(5)
    );

end Behavioral;
