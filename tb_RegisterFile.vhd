LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY tb_RegisterFile IS
END tb_RegisterFile;

ARCHITECTURE Behavior OF tb_RegisterFile IS

    COMPONENT RegisterFile
    PORT(
        clk           : IN  std_logic;
        rst           : IN  std_logic;
        reg_write_en1 : IN  std_logic;
        reg_write_en2 : IN  std_logic;
        read_addr1    : IN  std_logic_vector(2 DOWNTO 0);
        read_addr2    : IN  std_logic_vector(2 DOWNTO 0);
        write_addr1   : IN  std_logic_vector(2 DOWNTO 0);
        write_data1   : IN  std_logic_vector(31 DOWNTO 0);
        write_addr2   : IN  std_logic_vector(2 DOWNTO 0);
        write_data2   : IN  std_logic_vector(31 DOWNTO 0);
        read_data1    : OUT std_logic_vector(31 DOWNTO 0);
        read_data2    : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    -- Inputs
    SIGNAL clk           : std_logic := '0';
    SIGNAL rst           : std_logic := '0';
    SIGNAL reg_write_en1 : std_logic := '0';
    SIGNAL reg_write_en2 : std_logic := '0';
    SIGNAL read_addr1    : std_logic_vector(2 DOWNTO 0) := (others => '0');
    SIGNAL read_addr2    : std_logic_vector(2 DOWNTO 0) := (others => '0');
    SIGNAL write_addr1   : std_logic_vector(2 DOWNTO 0) := (others => '0');
    SIGNAL write_data1   : std_logic_vector(31 DOWNTO 0) := (others => '0');
    SIGNAL write_addr2   : std_logic_vector(2 DOWNTO 0) := (others => '0');
    SIGNAL write_data2   : std_logic_vector(31 DOWNTO 0) := (others => '0');

    -- Outputs
    SIGNAL read_data1    : std_logic_vector(31 DOWNTO 0);
    SIGNAL read_data2    : std_logic_vector(31 DOWNTO 0);

    CONSTANT clk_period : time := 10 ns;

BEGIN

    uut: RegisterFile PORT MAP (
        clk           => clk,
        rst           => rst,
        reg_write_en1 => reg_write_en1,
        reg_write_en2 => reg_write_en2,
        read_addr1    => read_addr1,
        read_addr2    => read_addr2,
        write_addr1   => write_addr1,
        write_data1   => write_data1,
        write_addr2   => write_addr2,
        write_data2   => write_data2,
        read_data1    => read_data1,
        read_data2    => read_data2
    );

    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin		
        -- 1. Reset
        rst <= '1';
        wait for 100 ns;	
        rst <= '0';
        wait for clk_period;

        -- 2. Test Write Port 1 alone (Write 0xAA to R1)
        reg_write_en1 <= '1';
        write_addr1   <= "001";
        write_data1   <= x"000000AA";
        wait for clk_period;
        reg_write_en1 <= '0';
        
        -- Verify Read
        read_addr1 <= "001";
        wait for clk_period;
        ASSERT (read_data1 = x"000000AA") REPORT "Write Port 1 Failed" SEVERITY ERROR;

        -- 3. Test Write Port 2 alone (Write 0xBB to R2)
        reg_write_en2 <= '1';
        write_addr2   <= "010";
        write_data2   <= x"000000BB";
        wait for clk_period;
        reg_write_en2 <= '0';
        
        -- Verify Read
        read_addr2 <= "010";
        wait for clk_period;
        ASSERT (read_data2 = x"000000BB") REPORT "Write Port 2 Failed" SEVERITY ERROR;

        -- 4. Test Simultaneous Write to DIFFERENT registers
        -- R3 = 0xCC (Port 1), R4 = 0xDD (Port 2)
        reg_write_en1 <= '1';
        write_addr1   <= "011";
        write_data1   <= x"000000CC";
        
        reg_write_en2 <= '1';
        write_addr2   <= "100";
        write_data2   <= x"000000DD";
        wait for clk_period;
        
        reg_write_en1 <= '0';
        reg_write_en2 <= '0';
        
        read_addr1 <= "011";
        read_addr2 <= "100";
        wait for clk_period;
        ASSERT (read_data1 = x"000000CC") REPORT "Simul Write (Port 1) Failed" SEVERITY ERROR;
        ASSERT (read_data2 = x"000000DD") REPORT "Simul Write (Port 2) Failed" SEVERITY ERROR;

        -- 5. Test Simultaneous Write to SAME register (Priority Check)
        -- Write 0x1111 (Port 1) and 0x2222 (Port 2) to R5
        -- Port 2 should win.
        reg_write_en1 <= '1';
        write_addr1   <= "101";
        write_data1   <= x"11111111";
        
        reg_write_en2 <= '1';
        write_addr2   <= "101";
        write_data2   <= x"22222222";
        wait for clk_period;
        
        reg_write_en1 <= '0';
        reg_write_en2 <= '0';
        
        read_addr1 <= "101";
        wait for clk_period;
        ASSERT (read_data1 = x"22222222") REPORT "Write Priority Failed (Should be Port 2)" SEVERITY ERROR;

        REPORT "Register File Testbench Completed";
        wait;
    end process;

END Behavior;
