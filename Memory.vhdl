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
    0 => x"00000000",
    1 => x"00000030", -- Vector 0 -> PC 20 (0x14)
    2 => x"00000014", -- Vector 1 -> PC 32 (0x20)
    3 => x"00000020", -- Vector 0 -> PC 20 (0x14)
    4 => x"C0020000", -- INT 0 -> Jump to PC 20
    20 => x"78040010", -- LDM R1, 0x0010
    21 => x"00000000", -- NOP
    22 => x"00000000", -- NOP
    23 => x"00000000", -- NOP
    24 => x"78080010", -- LDM R2, 10
    25 => x"39100000", -- MOV R1, R4

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
