library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Pipelined_Processor_tb is
-- Testbench has no ports
end Pipelined_Processor_tb;

architecture Behavior of Pipelined_Processor_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component Pipelined_Processor
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC
    );
    end component;

    -- Inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    -- Clock period definitions
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: Pipelined_Processor PORT MAP (
        clk => clk,
        rst => rst
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
        -- 1. Hold Reset for 20 ns to initialize everything
        rst <= '1';
        wait for 20 ns;
        
        -- 2. Release Reset - Processor starts Fetching from Address 16
        rst <= '0';

        -- 3. Let the simulation run
        -- We have instructions + NOPs. 
        -- It takes 5 cycles to fill the pipeline.
        -- We want to see the ADD result (R3 = R1 + R2) land in the Register File.
        
        wait for 200 ns;

        -- 4. Stop the simulation (Optional, or just let it run)
        assert false report "Simulation Finished Successfully" severity failure;
        wait;
    end process;

end Behavior;