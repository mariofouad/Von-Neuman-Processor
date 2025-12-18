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
        0 => x"00000010", -- Reset Vector -> Jump to 16

        -- TEST 1: JMP 20 (Unconditional) - ALREADY WORKING
        16 => x"A8000014", 
        17 => x"79000BAD", -- TRAP (Flushed)
        18 => x"00000000", 19 => x"00000000",
        20 => x"7900CAFE", -- LDM R1, 0xCAFE (Results in FFFFCAFE)

        -- TEST 2: JZ (Taken)
        21 => x"7A000000", -- LDM R2, 0
        
        -- !!! FIXED LINE BELOW !!!
        -- JZ R2, 25 (Was 91..., Changed to 92... to check R2)
        22 => x"92000019", 
        
        23 => x"7A000BAD", -- TRAP: LDM R2, 0xBAD (Should be FLUSHED)
        24 => x"00000000",
        25 => x"7B00FACE", -- LDM R3, 0xFACE (Should execute)

        -- TEST 3: JZ (Not Taken)
        26 => x"7C000001", -- LDM R4, 1
        
        -- JZ R4, 30 (Check R4=100 -> Op 10010 100 -> 94 hex)
        27 => x"9400001E", 
        
        28 => x"7D00BEEF", -- LDM R5, 0xBEEF (Should EXECUTE)
        30 => x"00800000", -- HLT

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
