library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.compressor_128_8;
use work.reference_section_to_popcount;

use IEEE.NUMERIC_STD.ALL;

entity entry_compressor_unit is
port(   
    pi_clk           : in std_logic; 
    pi_inValid       : in std_logic; 
    pi_k             : in std_logic_vector(7 downto 0);
    pi_reference_section : in unsigned(255 downto 0);
    po_reference_section_counter_row       : out std_logic_vector(31 downto 0)
);
end entry_compressor_unit;

architecture Behavioral of entry_compressor_unit is
    signal bitmask : unsigned(127 downto 0);
    signal bitmask16 : unsigned(15 downto 0);
    signal population_bits : std_logic_vector(511 downto 0);

    signal buffered_population_bits : std_logic_vector(511 downto 0);
begin
    process (pi_clk)
    begin
        if pi_clk'event and pi_clk = '1' then            
            if pi_inValid = '1' then
                buffered_population_bits <= population_bits;
            end if;
        end if;
    end process;

    -- bitmask <= ((to_unsigned(1, 129) sll to_integer(unsigned(k)  + 1)) - 1);
    bitmask16 <= (to_unsigned(1, 16) sll to_integer(unsigned(pi_k(3 downto 0)))) - 1;

    with pi_k(6 downto 4) select bitmask(15 downto 0) <= 
      bitmask16   when "000", X"ffff" when others;
    with pi_k(6 downto 4) select bitmask(31 downto 16) <= 
      X"0000" when "000", bitmask16   when "001", X"ffff" when others;
    with pi_k(6 downto 4) select bitmask(47 downto 32) <= 
      X"0000" when "000",
      X"0000" when "001",
      bitmask16   when "010",
      X"ffff" when others;
    with pi_k(6 downto 4) select bitmask(63 downto 48) <= 
      X"0000" when "000",
      X"0000" when "001",
      X"0000" when "010",
      bitmask16   when "011",
      X"ffff" when others;      
    with pi_k(6 downto 4) select bitmask(79 downto 64) <= 
      X"0000" when "000",
      X"0000" when "001",
      X"0000" when "010",
      X"0000" when "011",
      bitmask16   when "100",
      X"ffff" when others;      
    with pi_k(6 downto 4) select bitmask(95 downto 80) <= 
      X"0000" when "000",
      X"0000" when "001",
      X"0000" when "010",
      X"0000" when "011",
      X"0000" when "100",
      bitmask16   when "101",
      X"ffff" when others;
    with pi_k(6 downto 4) select bitmask(111 downto 96) <= 
      X"0000" when "000",
      X"0000" when "001",
      X"0000" when "010",
      X"0000" when "011",
      X"0000" when "100",
      X"0000" when "101",
      bitmask16   when "110",
      X"ffff" when others;    
    with pi_k(6 downto 4) select bitmask(127 downto 112) <= 
      bitmask16   when "111", X"0000" when others;

    calculate_population_bits : entity reference_section_to_popcount
    port map(
      bitmask => bitmask(126 downto 0) & "1",
      reference_section => std_logic_vector(pi_reference_section),
      population_bits_a => population_bits(127 downto 0),
      population_bits_c => population_bits(255 downto 128),
      population_bits_g => population_bits(383 downto 256),
      population_bits_t => population_bits(511 downto 384)
    );
    
    count_bits_a : entity compressor_128_8
    port map (pi_population_bits => buffered_population_bits(127 downto 0), po_count => po_reference_section_counter_row(7 downto 0));
    
    count_bits_c : entity compressor_128_8
    port map (pi_population_bits => buffered_population_bits(255 downto 128), po_count => po_reference_section_counter_row(15 downto 8));
    
    count_bits_g : entity compressor_128_8
    port map (pi_population_bits => buffered_population_bits(383 downto 256), po_count => po_reference_section_counter_row(23 downto 16));
    
    count_bits_t : entity compressor_128_8
    port map (pi_population_bits => buffered_population_bits(511 downto 384), po_count => po_reference_section_counter_row(31 downto 24));

end Behavioral;
