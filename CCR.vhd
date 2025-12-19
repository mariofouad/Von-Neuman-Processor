LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

-- Z flag bit 0 
-- N flag bit 1
-- C flag bit 2
ENTITY CCR IS
    PORT (
        clk      : IN  std_logic;
        rst      : IN  std_logic;
        
        write_z : IN  std_logic;
        write_n : IN  std_logic;
        write_c : IN  std_logic;

        z_in    : IN  std_logic;
        n_in    : IN  std_logic;
        c_in    : IN  std_logic;
        
        save_ccr    : IN std_logic;    -- Save current flags to backup
        restore_ccr : IN std_logic;    -- Restore flags from backup

        ccr_out   : OUT std_logic_vector(3 DOWNTO 0)
    );
END CCR;

ARCHITECTURE Behavior OF CCR IS
    SIGNAL ccr_reg    : std_logic_vector(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL backup_ccr : std_logic_vector(3 DOWNTO 0) := (OTHERS => '0');
BEGIN

    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            ccr_reg    <= (OTHERS => '0');
            backup_ccr <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            -- Save logic
            IF save_ccr = '1' THEN
                backup_ccr <= ccr_reg;
            END IF;
            
            -- Normal update or Restore logic
            IF restore_ccr = '1' THEN
                ccr_reg <= backup_ccr;
            ELSE
                IF write_z = '1' THEN
                    ccr_reg(0) <= z_in;
                END IF;
                IF write_n = '1' THEN
                    ccr_reg(1) <= n_in;
                END IF;
                IF write_c = '1' THEN
                    ccr_reg(2) <= c_in;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    ccr_out <= ccr_reg;

END Behavior;
