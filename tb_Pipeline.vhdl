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
        hardware_interrupt : IN std_logic;
        output_port   : OUT std_logic_vector(31 DOWNTO 0);
        out_en        : OUT std_logic
    );
    END COMPONENT;

    SIGNAL clk : std_logic := '0';
    SIGNAL rst : std_logic := '0';
    SIGNAL debug_pc, debug_inst, debug_alu : std_logic_vector(31 DOWNTO 0);
    SIGNAL debug_if_pc, debug_id_pc, debug_ex_pc, debug_mem_pc, debug_wb_pc : std_logic_vector(31 DOWNTO 0);
    SIGNAL debug_reg_w_en, debug_mem_w_en : std_logic;
    SIGNAL input_port_sig : std_logic_vector(31 DOWNTO 0) := x"00000005"; -- Sample input
    SIGNAL hw_int_sig : std_logic := '0';
    SIGNAL output_port_sig : std_logic_vector(31 DOWNTO 0);
    SIGNAL out_en_sig : std_logic;

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
            -- Extract nibble (4 bits)
            nibble := to_integer(unsigned(slv_norm(slv_norm'length - (i-1)*4 - 1 DOWNTO slv_norm'length - i*4)));
            -- Check for unknown logic
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
        hardware_interrupt => hw_int_sig,
        output_port => output_port_sig,
        out_en => out_en_sig
    );

    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

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
        
        -- Run for 40 cycles to see full test case
        FOR i IN 0 TO 40 LOOP
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
            IF i = 9 THEN
                hw_int_sig <= '1';
            ELSIF i = 10 THEN
                hw_int_sig <= '0';
            END IF;
        END LOOP;
        
        REPORT "--- Simulation Finished ---";
        wait;
    end process;

END Behavior;
