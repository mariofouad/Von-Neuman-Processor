LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.Processor_Pkg.all;

ENTITY ControlUnit IS
    PORT (
        opcode      : IN  std_logic_vector(4 DOWNTO 0);
        
        -- WB Stage
        reg_write   : OUT std_logic;
        reg_write_2 : OUT std_logic; -- For SWAP
        wb_sel      : OUT std_logic; -- 0: ALU, 1: MEM
        out_en      : OUT std_logic; -- Output Enable

        -- M Stage
        mem_write   : OUT std_logic;
        mem_read    : OUT std_logic; -- Useful for Hazard Detection
        
        -- EX Stage
        alu_sel     : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b   : OUT std_logic; -- 0: Reg, 1: Imm
        port_sel    : OUT std_logic; -- 0: Immediate, 1: IN.PORT

        -- Branching (Handled in EX/MEM usually, but decoding happens here)
        branch_type : OUT std_logic_vector(2 DOWNTO 0); -- 0: None, 1: JZ, 2: JN, 3: JC, 4: JMP, 5: CALL, 6: RET
        
        -- Stack / Special
        sp_write    : OUT std_logic;
        is_stack    : OUT std_logic;
        
        rti_en      : OUT std_logic;  -- New: To restore flags from stack   

        ccr_z_en    : OUT std_logic;
        ccr_n_en    : OUT std_logic;
        ccr_c_en    : OUT std_logic
    );
END ControlUnit;

ARCHITECTURE Behavior OF ControlUnit IS
BEGIN
    PROCESS(opcode)
    BEGIN
        -- Defaults
        reg_write   <= '0';
        reg_write_2 <= '0';
        wb_sel      <= '0';
        mem_write   <= '0';
        mem_read    <= '0';
        alu_sel     <= "000";       -- NOP/MOV by default
        alu_src_b   <= '0';         -- Reg by default
        branch_type <= "000";       -- No Branch
        sp_write    <= '0';
        is_stack    <= '0';
        
        out_en      <= '0';
        port_sel    <= '0';
        rti_en      <= '0';
        
        ccr_z_en    <= '0';
        ccr_n_en    <= '0';
        ccr_c_en    <= '0';

        CASE opcode IS
            WHEN OP_NOP =>
                NULL;
            
            WHEN OP_HLT =>
                -- For now, maybe just loop or disable PC write? 
                -- Assuming external handling or infinite loop
                branch_type <= "100"; -- Treat as JMP to self? Not implemented in datapath yet.

            WHEN OP_SETC =>
                alu_sel <= "111"; -- ALU SETC
                ccr_c_en <= '1';
            
            WHEN OP_NOT =>
                reg_write <= '1';
                alu_sel   <= "101"; -- ALU NOT
                ccr_z_en <= '1';
                ccr_n_en <= '1';
            
            WHEN OP_INC =>
                reg_write <= '1';
                alu_sel   <= "110"; -- ALU INC
                ccr_z_en <= '1';
                ccr_n_en <= '1';
                ccr_c_en <= '1';
                
            WHEN OP_OUT =>
                alu_sel   <= "000"; -- MOV (Pass A to output port?) - TODO: Add Output Port
                out_en    <= '1';
            
            WHEN OP_IN =>
                reg_write <= '1';
                alu_src_b <= '1'; -- Use Input (Routed via Imm path)
                alu_sel   <= "001"; -- Pass B
                port_sel  <= '1';

            WHEN OP_MOV =>
                reg_write <= '1';
                alu_sel   <= "000"; -- Pass A
            
            WHEN OP_SWAP =>
                reg_write   <= '1'; -- Write to Rsrc (from R2)
                reg_write_2 <= '1'; -- Write to Rdst (from R1)
                -- Complex: Needs implementation in Processor
                -- For now, just mark writes. Processor needs to handle swapping data.
            
            WHEN OP_ADD =>
                reg_write <= '1';
                alu_sel   <= "010"; -- ADD
                ccr_z_en <= '1';
                ccr_n_en <= '1';
                ccr_c_en <= '1';
            WHEN OP_SUB =>
                reg_write <= '1';
                alu_sel   <= "011"; -- SUB
                ccr_z_en <= '1';
                ccr_n_en <= '1';
                ccr_c_en <= '1';
            
            WHEN OP_AND =>
                reg_write <= '1';
                alu_sel   <= "100"; -- AND
                ccr_z_en <= '1';
                ccr_n_en <= '1';
            
            WHEN OP_IADD =>
                reg_write <= '1';
                alu_src_b <= '1'; -- Imm
                alu_sel   <= "010"; -- ADD
                ccr_z_en <= '1';
                ccr_n_en <= '1';
                ccr_c_en <= '1';
            
            WHEN OP_PUSH =>
                mem_write <= '1';
                sp_write  <= '1'; -- Dec SP
                is_stack  <= '1';
                -- Needs Processor logic: Addr = SP, Data = Rsrc
            
            WHEN OP_POP =>
                reg_write <= '1';
                sp_write  <= '1'; -- Inc SP
                wb_sel    <= '1'; -- From Mem
                mem_read  <= '1';
                is_stack  <= '1';
                -- Needs Processor logic: Addr = SP
            
            WHEN OP_LDM =>
                reg_write <= '1';
                alu_src_b <= '1'; -- Imm
                alu_sel   <= "001"; -- Pass B (Pass Imm)
                port_sel  <= '0'; -- Use Immediate
            
            WHEN OP_LDD =>
                reg_write <= '1';
                wb_sel    <= '1'; -- From Mem
                mem_read  <= '1';
                alu_src_b <= '1'; -- Imm (Offset)
                alu_sel   <= "010"; -- Add Base + Offset
                
            WHEN OP_STD =>
                mem_write <= '1';
                alu_src_b <= '1'; -- Imm (Offset)
                alu_sel   <= "010"; -- Add Base + Offset
                
            WHEN OP_JZ =>
                branch_type <= "001";
                
            WHEN OP_JN =>
                branch_type <= "010";
            
            WHEN OP_JC =>
                branch_type <= "011";
                
            WHEN OP_JMP =>
                branch_type <= "100";
            
            WHEN OP_CALL =>
                branch_type <= "101";
                mem_write   <= '1'; -- Push PC
                sp_write    <= '1'; -- Dec SP
                is_stack    <= '1';
                
            WHEN OP_RET =>
                branch_type <= "110"; -- RET type
                sp_write    <= '1';   -- Inc SP
                mem_read    <= '1';   -- Pop PC
                is_stack    <= '1';
            
            WHEN OP_INT =>
                branch_type <= "111"; -- INT type
                mem_write   <= '1';   -- Push PC/Flags
                sp_write    <= '1';
                is_stack    <= '1';
                
            WHEN OP_RTI =>
                branch_type <= "110"; -- Same as RET effectively for control flow, popping logic differs
                sp_write    <= '1';
                mem_read    <= '1';
                is_stack    <= '1';
                rti_en      <= '1';

            WHEN OTHERS =>
                NULL;
        END CASE;
    END PROCESS;
END Behavior;
