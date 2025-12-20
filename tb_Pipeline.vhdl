LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY tb_Pipeline IS
END tb_Pipeline;

ARCHITECTURE Behavior OF tb_Pipeline IS

    COMPONENT Processor
    PORT(
        clk           : IN  std_logic;
        rst           : IN  std_logic;
        interrupt     : IN  std_logic;  -- Hardware interrupt input
        debug_pc      : OUT std_logic_vector(31 DOWNTO 0);
        debug_if_pc   : OUT std_logic_vector(31 DOWNTO 0);
        debug_id_pc   : OUT std_logic_vector(31 DOWNTO 0);
        debug_ex_pc   : OUT std_logic_vector(31 DOWNTO 0);
        debug_mem_pc  : OUT std_logic_vector(31 DOWNTO 0);
        debug_wb_pc   : OUT std_logic_vector(31 DOWNTO 0);
        debug_inst    : OUT std_logic_vector(31 DOWNTO 0);
        debug_reg_w_en: OUT std_logic;
        debug_mem_w_en: OUT std_logic;
        debug_alu     : OUT std_logic_vector(31 DOWNTO 0);
        input_port    : IN  std_logic_vector(31 DOWNTO 0);
        output_port   : OUT std_logic_vector(31 DOWNTO 0);
        out_en        : OUT std_logic
    );
    END COMPONENT;

    SIGNAL clk : std_logic := '0';
    SIGNAL rst : std_logic := '0';
    SIGNAL interrupt_sig : std_logic := '0';  -- Hardware interrupt signal
    SIGNAL debug_pc, debug_inst, debug_alu : std_logic_vector(31 DOWNTO 0);
    SIGNAL debug_if_pc, debug_id_pc, debug_ex_pc, debug_mem_pc, debug_wb_pc : std_logic_vector(31 DOWNTO 0);
    SIGNAL debug_reg_w_en, debug_mem_w_en : std_logic;
    SIGNAL output_port_sig : std_logic_vector(31 DOWNTO 0);
    SIGNAL out_en_sig : std_logic;
    
    -- Input Port Signal driven by Process
    SIGNAL input_port_sig : std_logic_vector(31 DOWNTO 0) := x"00000000";

    CONSTANT clk_period : time := 10 ns;

    -- Custom Hex Function for compatibility
    FUNCTION to_hex_string(sv: std_logic_vector) RETURN string IS
        CONSTANT chars : string := "0123456789ABCDEF";
        VARIABLE result : string(1 TO sv'length/4);
        VARIABLE nibble : integer;
        VARIABLE slv_norm : std_logic_vector(sv'length-1 DOWNTO 0);
    BEGIN
        slv_norm := sv; -- Normalize
        FOR i IN 1 TO result'length LOOP
            nibble := to_integer(unsigned(slv_norm(slv_norm'length - (i-1)*4 - 1 DOWNTO slv_norm'length - i*4)));
            IF nibble >= 0 AND nibble <= 15 THEN
                result(i) := chars(nibble + 1);
            ELSE
                result(i) := 'X';
            END IF;
        END LOOP;
        RETURN result;
    END FUNCTION;

BEGIN

    uut: Processor PORT MAP (
        clk => clk,
        rst => rst,
        interrupt => interrupt_sig,  -- Hardware interrupt (active high)
        debug_pc => debug_pc,
        debug_if_pc => debug_if_pc,
        debug_id_pc => debug_id_pc,
        debug_ex_pc => debug_ex_pc,
        debug_mem_pc => debug_mem_pc,
        debug_wb_pc => debug_wb_pc,
        debug_inst => debug_inst,
        debug_reg_w_en => debug_reg_w_en,
        debug_mem_w_en => debug_mem_w_en,
        debug_alu => debug_alu,
        input_port => input_port_sig,
        output_port => output_port_sig,
        out_en => out_en_sig
    );

    -- Clock Process
    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- SMART INPUT DRIVER:
    -- Changes the input_port value based on which instruction is currently in the Decode (ID) stage.
    -- This matches the addresses provided in your Assembly Test Case.
    PROCESS(debug_id_pc)
    BEGIN
        CASE to_integer(unsigned(debug_id_pc)) IS
            -- Initial IN instructions
            WHEN 10 => input_port_sig <= x"0000001E"; -- IN R1 (Expect 30)
            WHEN 11 => input_port_sig <= x"00000032"; -- IN R2 (Expect 50)
            WHEN 12 => input_port_sig <= x"00000064"; -- IN R3 (Expect 100)
            WHEN 13 => input_port_sig <= x"0000012C"; -- IN R4 (Expect 300)
            
            -- IN instructions after Jumps
            WHEN 53 => input_port_sig <= x"0000003C"; -- IN R1 (Expect 60)
            WHEN 60 => input_port_sig <= x"00000046"; -- IN R1 (Expect 70)
            WHEN 80 => input_port_sig <= x"000002BC"; -- IN R6 (Expect 700)
            
            -- Default value (Safety)
            WHEN OTHERS => input_port_sig <= x"FFFFFFFF"; 
        END CASE;
    END PROCESS;

    -- Hardware Interrupt Trigger Process
    -- Triggers interrupt at specific cycle (adjust HW_INT_TRIGGER_CYCLE to test)
    -- Set to 0 to disable hardware interrupt testing
    hw_int_proc: process
        CONSTANT HW_INT_TRIGGER_CYCLE : integer := 15;  -- Set to cycle number to trigger, 0 to disable
        CONSTANT HW_INT_DURATION : integer := 2;       -- How many cycles to hold interrupt high
    begin
        interrupt_sig <= '0';
        IF HW_INT_TRIGGER_CYCLE > 0 THEN
            -- Wait for trigger cycle
            wait for (HW_INT_TRIGGER_CYCLE + 2) * clk_period;  -- +2 for reset cycles
            REPORT ">>> HARDWARE INTERRUPT TRIGGERED at cycle " & integer'image(HW_INT_TRIGGER_CYCLE);
            interrupt_sig <= '1';
            wait for HW_INT_DURATION * clk_period;
            interrupt_sig <= '0';
            REPORT ">>> HARDWARE INTERRUPT RELEASED";
        END IF;
        wait;
    end process;

    -- Stimulus Process
    stim_proc: process
    begin
        -- Hold Reset
        rst <= '1';
        wait for 10 ns;
        rst <= '0';
        wait for 10 ns;

        REPORT "--- Starting Pipeline Simulation ---";
        REPORT "Cycle |  IF  |  ID  |  EX  | MEM |  WB  | Inst(Hex) | ALU Res | RegW | MemW";
        REPORT "-----------------------------------------------------------------------------";
        
        -- Increased Loop Count to 100 cycles to allow the full program (Jumps/Branches) to execute
        FOR i IN 0 TO 100 LOOP
            wait for clk_period;
            
            REPORT "C" & integer'image(i) & " | " & 
                   integer'image(to_integer(unsigned(debug_if_pc))) & " | " & 
                   integer'image(to_integer(unsigned(debug_id_pc))) & " | " & 
                   integer'image(to_integer(unsigned(debug_ex_pc))) & " | " & 
                   integer'image(to_integer(unsigned(debug_mem_pc))) & " | " & 
                   integer'image(to_integer(unsigned(debug_wb_pc))) & " | " & 
                   to_hex_string(debug_inst) & " | " & 
                   to_hex_string(debug_alu) & " | " & 
                   std_logic'image(debug_reg_w_en) & " | " & 
                   std_logic'image(debug_mem_w_en);
        END LOOP;
        
        REPORT "--- Simulation Finished ---";
        wait;
    end process;

END Behavior;