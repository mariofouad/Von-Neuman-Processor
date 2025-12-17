LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Memory_tb IS
END Memory_tb;

ARCHITECTURE Behavior OF Memory_tb IS
    COMPONENT Memory
    PORT(
        clk : IN std_logic;
        rst : IN std_logic;
        addr : IN std_logic_vector(31 downto 0);
        data_in : IN std_logic_vector(31 downto 0);
        we : IN std_logic;
        data_out : OUT std_logic_vector(31 downto 0)
    );
    END COMPONENT;

    -- Inputs
    SIGNAL clk : std_logic := '0';
    SIGNAL rst : std_logic := '0';
    SIGNAL addr : std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL data_in : std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL we : std_logic := '0';

    -- Outputs
    SIGNAL data_out : std_logic_vector(31 downto 0);

    -- Clock period definitions
    CONSTANT clk_period : time := 10 ns;

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    uut: Memory PORT MAP (
        clk => clk,
        rst => rst,
        addr => addr,
        data_in => data_in,
        we => we,
        data_out => data_out
    );

    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin		
        -- hold reset state for 100 ns.
        rst <= '1';
        wait for 100 ns;	
        rst <= '0';
        wait for clk_period*10;

        -- Test Case 1: Write to Address 0x0
        we <= '1';
        addr <= x"00000000";
        data_in <= x"DEADBEEF";
        wait for clk_period;
        
        -- Test Case 2: Write to Address 0x4 (Word 4)
        addr <= x"00000004";
        data_in <= x"CAFEBABE";
        wait for clk_period;

        -- Disable Write
        we <= '0';
        wait for clk_period;

        -- Test Case 3: Read from Address 0x0
        addr <= x"00000000";
        wait for clk_period;
        ASSERT (data_out = x"DEADBEEF") REPORT "Read Error at 0x0" SEVERITY ERROR;

        -- Test Case 4: Read from Address 0x4
        addr <= x"00000004";
        wait for clk_period;
        ASSERT (data_out = x"CAFEBABE") REPORT "Read Error at 0x4" SEVERITY ERROR;

        -- Test Case 5: Read Empty Address
        addr <= x"00000008";
        wait for clk_period;
        -- Should be undefined or 0 depending on init. 
        
        ASSERT false REPORT "Simulation Completed Successfully" SEVERITY NOTE;
        wait;
    end process;

END Behavior;
