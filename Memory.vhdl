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
    CONSTANT INIT_RAM : ram_type := (
    16 => x"78040014", -- LDM R1, 20      # R1 = 20 (0x14)
    17 => x"7808000A", -- LDM R2, 10      # R2 = 10 (0x0A)
    18 => x"780C0005", -- LDM R3, 5       # R3 = 5  (0x05)
    19 => x"00000000", -- NOP
    20 => x"00000000", -- NOP
    21 => x"00000000", -- NOP
    22 => x"51500000", -- SUB R4, R1, R2
    23 => x"00000000", -- NOP
    24 => x"00000000", -- NOP
    25 => x"00000000", -- NOP
    26 => x"5A740000", -- AND R5, R2, R3
    27 => x"00000000", -- NOP
    28 => x"00000000", -- NOP
    29 => x"00000000", -- NOP
    30 => x"61180005", -- IADD R6, R1, 5
    31 => x"00000000", -- NOP
    32 => x"00000000", -- NOP
    33 => x"00000000", -- NOP
    34 => x"495C0000", -- ADD R7, R1, R2
    35 => x"08000000", -- HLT
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
