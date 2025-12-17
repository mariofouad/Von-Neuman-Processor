library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CCR is
    Port (
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        enable    : in  STD_LOGIC; -- Only update flags on Arithmetic/Logic ops
        
        -- Inputs from ALU
        Z_in, N_in, C_in : in  STD_LOGIC;
        
        -- Outputs to Branch Control
        Z_out, N_out, C_out : out STD_LOGIC
    );
end CCR;

architecture Behavioral of CCR is
    signal flags : STD_LOGIC_VECTOR(2 downto 0) := "000"; -- Z, N, C
begin
    process(clk, rst)
    begin
        if rst = '1' then
            flags <= "000";
        elsif rising_edge(clk) then
            if enable = '1' then
                flags(0) <= Z_in;
                flags(1) <= N_in;
                flags(2) <= C_in;
            end if;
        end if;
    end process;

    Z_out <= flags(0);
    N_out <= flags(1);
    C_out <= flags(2);
end Behavioral;