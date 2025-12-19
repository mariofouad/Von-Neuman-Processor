LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE std.textio.all;
USE ieee.std_logic_textio.all;

ENTITY Memory IS
    GENERIC (
        MEM_SIZE : integer := 4096 -- 4K Words
    );
    PORT (
        clk     : IN  std_logic;
        addr    : IN  std_logic_vector(31 DOWNTO 0);
        data_in : IN  std_logic_vector(31 DOWNTO 0);
        we      : IN  std_logic;
        data_out: OUT std_logic_vector(31 DOWNTO 0)
    );
END Memory;

ARCHITECTURE Behavior OF Memory IS
    TYPE ram_type IS ARRAY (0 TO MEM_SIZE-1) OF std_logic_vector(31 DOWNTO 0);

    -- Function to load memory from a text file
    impure function InitRamFromFile (RamFileName : in string) return ram_type is
        FILE ramfile : text is in RamFileName;
        variable ramfile_line : line;
        variable temp_word : std_logic_vector(31 downto 0);
        variable temp_ram : ram_type := (others => (others => '0'));
    begin
        for i in 0 to MEM_SIZE-1 loop
            if not endfile(ramfile) then
                readline(ramfile, ramfile_line);
                hread(ramfile_line, temp_word); -- Reads Hexadecimal
                temp_ram(i) := temp_word;
            end if;
        end loop;
        return temp_ram;
    end function;

    -- The RAM signal initialized from file
    SIGNAL ram : ram_type := InitRamFromFile("program.mem");

BEGIN 

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF we = '1' THEN
                -- Physical addressing: use lower 12 bits
                ram(to_integer(unsigned(addr(11 DOWNTO 0)))) <= data_in;
            END IF;
        END IF;
    END PROCESS;

    -- Asynchronous Read (Crucial for Fetch stage speed)
    data_out <= ram(to_integer(unsigned(addr(11 DOWNTO 0))));

END Behavior;