LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY SP IS
    PORT (
        clk      : IN  std_logic;
        rst      : IN  std_logic;
        sp_write : IN  std_logic;
        sp_in    : IN  std_logic_vector(31 DOWNTO 0);
        sp_out   : OUT std_logic_vector(31 DOWNTO 0)
    );
END SP;

ARCHITECTURE Behavior OF SP IS
    -- Initialize SP to Top of Memory? Or 0 depends on conventions.
    -- Usually Highest Address (e.g. 4095) for descending stack.
    -- Let's stick to 0 or User spec. 
    -- Requirement says: "sp+=1; PC ← X[SP]" (Pop) and "X[Sp]←PC; sp-=1" (Push)?
    -- Actually user text: "RTI sp+=1; PC ← X[SP]" -> Ascending?
    -- "Interrupt X[Sp]←PC; sp-=1;" -> Descending?
    -- Wait. If Push is sp-=1, then stack grows down.
    -- Let's init to High Value (e.g. 0xFFF = 4095).
    SIGNAL sp_reg : std_logic_vector(31 DOWNTO 0) := x"00000FFF"; 
BEGIN

    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            sp_reg <= x"00000FFF"; -- Reset to 4095 (Top of 4K)
        ELSIF rising_edge(clk) THEN
            IF sp_write = '1' THEN
                sp_reg <= sp_in;
            END IF;
        END IF;
    END PROCESS;

    sp_out <= sp_reg;

END Behavior;
