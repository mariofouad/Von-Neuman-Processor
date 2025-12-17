LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY PC IS
    PORT (
        clk      : IN  std_logic;
        rst      : IN  std_logic;
        pc_write : IN  std_logic;
        pc_inc   : IN  std_logic; -- Dedicated Increment Control
        pc_in    : IN  std_logic_vector(31 DOWNTO 0);
        pc_out   : OUT std_logic_vector(31 DOWNTO 0)
    );
END PC;

ARCHITECTURE Behavior OF PC IS
    SIGNAL pc_reg : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
BEGIN

    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            pc_reg <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF pc_write = '1' THEN
                pc_reg <= pc_in;
            ELSIF pc_inc = '1' THEN
                pc_reg <= std_logic_vector(unsigned(pc_reg) + 1);
            END IF;
        END IF;
    END PROCESS;

    pc_out <= pc_reg;

END Behavior;
