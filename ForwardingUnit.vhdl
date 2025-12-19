LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ForwardingUnit IS
    PORT (
        -- Inputs from ID/EX (Current Instruction in Execute)
        id_ex_rs1        : IN  std_logic_vector(2 DOWNTO 0);
        id_ex_rs2        : IN  std_logic_vector(2 DOWNTO 0);

        -- Inputs from EX/MEM (Instruction ahead in Memory Stage)
        ex_mem_rd        : IN  std_logic_vector(2 DOWNTO 0);
        ex_mem_reg_write : IN  std_logic;

        -- Inputs from MEM/WB (Instruction ahead in Write-Back Stage)
        mem_wb_rd        : IN  std_logic_vector(2 DOWNTO 0);
        mem_wb_reg_write : IN  std_logic;

        -- Outputs: Selectors for ALU Muxes
        -- 00: Register File, 10: EX/MEM Forward, 01: MEM/WB Forward
        forward_a        : OUT std_logic_vector(1 DOWNTO 0);
        forward_b        : OUT std_logic_vector(1 DOWNTO 0)
    );
END ForwardingUnit;

ARCHITECTURE Behavior OF ForwardingUnit IS
BEGIN
    PROCESS(id_ex_rs1, id_ex_rs2, ex_mem_rd, ex_mem_reg_write, mem_wb_rd, mem_wb_reg_write)
    BEGIN
        -- --- FORWARD A (Operand 1) ---
        
        -- EX Hazard: Priority goes to the most recent instruction (EX/MEM)
        IF (ex_mem_reg_write = '1' AND (ex_mem_rd /= "000") AND (ex_mem_rd = id_ex_rs1)) THEN
            forward_a <= "10";
            
        -- MEM Hazard: Only if EX hazard is not present
        ELSIF (mem_wb_reg_write = '1' AND (mem_wb_rd /= "000") AND (mem_wb_rd = id_ex_rs1)) THEN
            forward_a <= "01";
            
        ELSE
            forward_a <= "00"; -- No hazard, use data from Register File
        END IF;


        -- --- FORWARD B (Operand 2) ---
        
        -- EX Hazard
        IF (ex_mem_reg_write = '1' AND (ex_mem_rd /= "000") AND (ex_mem_rd = id_ex_rs2)) THEN
            forward_b <= "10";
            
        -- MEM Hazard
        ELSIF (mem_wb_reg_write = '1' AND (mem_wb_rd /= "000") AND (mem_wb_rd = id_ex_rs2)) THEN
            forward_b <= "01";
            
        ELSE
            forward_b <= "00"; -- No hazard
        END IF;

    END PROCESS;
END Behavior;