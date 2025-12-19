LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Sequencer IS
    PORT (
        clk                 : IN  std_logic;
        rst                 : IN  std_logic;
        
        -- Inputs from Pipeline
        hardware_interrupt   : IN  std_logic;
        mem_branch_type      : IN  std_logic_vector(2 DOWNTO 0);
        if_inst_raw          : IN  std_logic_vector(31 DOWNTO 0); -- From Memory Out
        
        -- Outputs to Control Stages
        rst_init_pending     : OUT std_logic;
        rst_load_pc          : OUT std_logic;
        hw_int_pending       : OUT std_logic;
        int_phase            : OUT std_logic;
        ex_mem_en            : OUT std_logic
    );
END Sequencer;

ARCHITECTURE Behavior OF Sequencer IS
    SIGNAL rst_init_counter : unsigned(1 DOWNTO 0) := "00";
    SIGNAL hw_int_latch     : std_logic := '0';
    SIGNAL int_phase_reg    : std_logic := '0';
BEGIN

    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            rst_init_counter <= "11";
            hw_int_latch     <= '0';
            int_phase_reg    <= '0';
        ELSIF rising_edge(clk) THEN
            -- Decrement Reset Counter
            IF rst_init_counter /= "00" THEN
                rst_init_counter <= rst_init_counter - 1;
            END IF;
            
            -- Latch Hardware Interrupt
            IF hardware_interrupt = '1' THEN
                hw_int_latch <= '1';
            ELSIF (mem_branch_type = "111" AND int_phase_reg = '1') THEN
                hw_int_latch <= '0';
            END IF;
            
            -- Multi-cycle Instruction Phase Tracking (INT)
            IF mem_branch_type = "111" THEN
                int_phase_reg <= NOT int_phase_reg;
            ELSE
                int_phase_reg <= '0';
            END IF;
        END IF;
    END PROCESS;

    rst_init_pending <= '1' WHEN rst_init_counter /= "00" ELSE '0';
    rst_load_pc      <= '1' WHEN rst_init_counter = "01" ELSE '0';
    hw_int_pending   <= hw_int_latch;
    int_phase        <= int_phase_reg;
    ex_mem_en        <= '0' WHEN (mem_branch_type = "111" AND int_phase_reg = '0') ELSE '1';

END Behavior;
