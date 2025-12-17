library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SignExtend is
    Port ( 
        Input  : in  STD_LOGIC_VECTOR (15 downto 0);
        Output : out STD_LOGIC_VECTOR (31 downto 0)
    );
end SignExtend;

architecture Behavioral of SignExtend is
begin
    -- Resizes and preserves the sign bit (2's complement)
    Output <= std_logic_vector(resize(signed(Input), 32));
end Behavioral;