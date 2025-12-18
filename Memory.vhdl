LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Memory IS
    GENERIC (
        MEM_SIZE : integer := 4096 -- 4K Words
    );
    PORT (
        clk     : IN  std_logic;
        rst     : IN  std_logic;
        
        -- Ports
        addr    : IN  std_logic_vector(31 DOWNTO 0);
        data_in : IN  std_logic_vector(31 DOWNTO 0); -- Keep 32-bit for instructions
        we      : IN  std_logic;
        
        data_out: OUT std_logic_vector(31 DOWNTO 0)
    );
END Memory;

ARCHITECTURE Behavior OF Memory IS
    -- Memory array: 4K x 32-bit
    TYPE ram_type IS ARRAY (0 TO MEM_SIZE-1) OF std_logic_vector(31 DOWNTO 0);
    
    -- --- PROGRAM LOADER (Hardcoded for Simulation) ---
    -- 1. Assemble your code.
    -- 2. Place it here.
    -- Assembling test_case.asm to VHDL Init Format --
    CONSTANT INIT_RAM : ram_type := (
        0 => x"78000001", -- LDM R0, 1
        1 => x"7804AAAA", -- LDM R1, AAAA
        2 => x"7808FFFF", -- LDM R2, FFFF
        3 => x"7808FFFF", -- LDM R2, FFFF
        4 => x"20000000", -- INC R0
        5 => x"39100000", -- MOV R1, R4
        -- 5 => x"18040000", -- NOT R1
        -- 6 => x"380C0000", -- MOV R0, R3
        -- 7 => x"30000000", -- IN R0	# R0 = FFFF_FFFF
        -- 8 => x"28000000", -- OUT R0
        -- 9 => x"59140000", -- AND R5, R1, R0
        -- 10 => x"38180000", -- MOV R0, R6
        -- 11 => x"18180000", -- NOT R6
        -- 12 => x"20000000", -- INC R0
        OTHERS => (others => '0')
    );


    SIGNAL ram : ram_type := INIT_RAM;
    
    CONSTANT ZEROS : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
BEGIN 

    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- Optional reset
            NULL; 
        ELSIF rising_edge(clk) THEN
            IF we = '1' THEN
                -- Write Operation
                ram(to_integer(unsigned(addr(11 DOWNTO 0)))) <= data_in;
            END IF;
        END IF;
    END PROCESS;

    -- Asynchronous Read
    data_out <= ram(to_integer(unsigned(addr(11 DOWNTO 0))));

END Behavior;
