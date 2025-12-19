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
        -- .ORG 0: Reset Vector -> JMP 10
        0 => x"A800000A",

        -- .ORG 10: IN R1 
        10 => x"30040000",
        -- 11: IN R2 
        11 => x"30080000",
        -- 12: IN R3 
        12 => x"300C0000",
        -- 13: IN R4 
        13 => x"30100000",
        -- 14: PUSH R4
        14 => x"68100000",
        -- 15: JMP 30
        15 => x"A800001E",
        -- 16: INC R1 (Skipped/Flushed by Hardware)
        16 => x"20040000",

        -- .ORG 30: AND R5, R1, R5
        30 => x"59B40000",
        -- 31: JZ 50
        31 => x"90000032",
        -- 32: SETC (Skipped)
        32 => x"10000000",

        -- .ORG 50: JZ 30 (Assuming Flag Z=1 from AND, this loops or falls through)
        50 => x"9000001E",
        -- 51: NOT R5 (Writes to R5)
        51 => x"18140000",
        
        -- *** HAZARD RESOLUTION: 3 NOPs inserted ***
        52 => x"00000000",
        53 => x"00000000",
        54 => x"00000000",

        -- 55: SUB R7, R5, R5 (Moved from 52) - Reads R5
        55 => x"55BC0000",
        -- 56: IN R1 (Moved from 53)
        56 => x"30040000",
        -- 57: JZ 60 (Moved from 54)
        57 => x"9000003C",
        -- 58: ADD (Moved from 55 - Skipped)
        58 => x"4A640000",

        -- .ORG 60: IN R1
        60 => x"30040000",
        -- 61: JZ 70
        61 => x"90000046",
        -- 62: JMP 70
        62 => x"A8000046",
        -- 63: INC R1 (Skipped)
        63 => x"20040000",

        -- .ORG 70: IADD R1, R1, 10 (Writes R1)
        70 => x"6120000A",
        
        -- *** HAZARD RESOLUTION: 3 NOPs inserted ***
        71 => x"00000000",
        72 => x"00000000",
        73 => x"00000000",

        -- 74: SUB R7, R1, R1 (Moved from 71) - Reads R1
        74 => x"513C0000",
        -- 75: PUSH R1 (Moved from 72)
        75 => x"68040000",
        -- 76: POP R1 (Moved from 73)
        76 => x"70040000",
        -- 77: JZ 80 (Moved from 74)
        77 => x"90000050",
        -- 78: INC R1 (Moved from 75 - Skipped)
        78 => x"20040000",

        -- .ORG 80: IN R6
        80 => x"30180000",
        -- 81: JMP 700
        81 => x"A80002BC",

        -- .ORG 700: ADD R7, R0, R1
        700 => x"483C0000",
        -- 701: POP R6
        701 => x"70180000",
        -- 702: NOP (Was Call)
        702 => x"00000000",
        -- 703: INC R6
        703 => x"20180000",
        -- 704-705: NOP
        704 => x"00000000",
        705 => x"00000000",
        -- 706: HLT
        706 => x"08000000",

        OTHERS => (OTHERS => '0')
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
