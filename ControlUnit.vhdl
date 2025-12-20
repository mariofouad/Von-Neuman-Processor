LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.Processor_Pkg.all;

ENTITY ControlUnit IS
    PORT (
        opcode      : IN  std_logic_vector(4 DOWNTO 0);
        
        -- WB Stage
        reg_write   : OUT std_logic;
        reg_write_2 : OUT std_logic;
        wb_sel      : OUT std_logic;
        out_en      : OUT std_logic;

        -- MEM Stage
        mem_write   : OUT std_logic;
        mem_read    : OUT std_logic;
        
        -- EX Stage
        alu_sel     : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b   : OUT std_logic;
        port_sel    : OUT std_logic;
        branch_type : OUT std_logic_vector(2 DOWNTO 0);
        
        -- *** NEW: Flags Enable (Prevents NOPs from messing up Zero Flag) ***
        flags_en    : OUT std_logic;
        
        -- Stack / Special
        sp_write    : OUT std_logic;
        is_stack    : OUT std_logic;
        rti_en      : OUT std_logic;
        hlt_en      : OUT std_logic   -- HLT instruction signal
    );
END ControlUnit;

ARCHITECTURE Behavior OF ControlUnit IS
BEGIN
    PROCESS(opcode)
    BEGIN
        -- Defaults
        reg_write   <= '0'; reg_write_2 <= '0'; wb_sel <= '0';
        mem_write   <= '0'; mem_read <= '0';
        alu_sel     <= "000"; alu_src_b <= '0';
        branch_type <= "000"; sp_write <= '0'; is_stack <= '0';
        out_en      <= '0'; port_sel <= '0'; rti_en <= '0';
        hlt_en      <= '0';  -- Default: not halting
        
        flags_en    <= '0'; -- Default: Don't update flags

        CASE opcode IS
            WHEN OP_NOP => NULL;
            WHEN OP_HLT => hlt_en <= '1'; -- Halt the processor
            
            WHEN OP_SETC =>
                alu_sel <= "111"; flags_en <= '1'; -- Update Flags
            
            WHEN OP_NOT =>
                reg_write <= '1'; alu_sel <= "101"; flags_en <= '1'; -- Update Flags
            
            WHEN OP_INC =>
                reg_write <= '1'; alu_sel <= "110"; flags_en <= '1'; -- Update Flags
                
            WHEN OP_OUT =>
                alu_sel <= "000"; out_en <= '1';
            
            WHEN OP_IN =>
                reg_write <= '1'; alu_src_b <= '1'; alu_sel <= "001"; port_sel <= '1';

            WHEN OP_MOV =>
                reg_write <= '1'; alu_sel <= "000"; 
                -- MOV usually doesn't update flags in this ISA
            
            WHEN OP_SWAP =>
                reg_write <= '1'; reg_write_2 <= '1';
            
            WHEN OP_ADD =>
                reg_write <= '1'; alu_sel <= "010"; flags_en <= '1'; -- Update Flags
            
            WHEN OP_SUB =>
                reg_write <= '1'; alu_sel <= "011"; flags_en <= '1'; -- Update Flags
            
            WHEN OP_AND =>
                reg_write <= '1'; alu_sel <= "100"; flags_en <= '1'; -- Update Flags
            
            WHEN OP_IADD =>
                reg_write <= '1'; alu_src_b <= '1'; alu_sel <= "010"; flags_en <= '1'; -- Update Flags
            
            WHEN OP_PUSH =>
                mem_write <= '1'; sp_write <= '1'; is_stack <= '1';
            
            WHEN OP_POP =>
                reg_write <= '1'; sp_write <= '1'; wb_sel <= '1'; mem_read <= '1'; is_stack <= '1';
            
            WHEN OP_LDM =>
                reg_write <= '1'; alu_src_b <= '1'; alu_sel <= "001";
            
            WHEN OP_LDD =>
                reg_write <= '1'; wb_sel <= '1'; mem_read <= '1'; alu_src_b <= '1'; alu_sel <= "010";
                
            WHEN OP_STD =>
                mem_write <= '1'; alu_src_b <= '1'; alu_sel <= "010";
                
            WHEN OP_JZ => 
                branch_type <= "001";
                alu_src_b   <= '1';   -- Select Immediate (The Jump Target)
                alu_sel     <= "001"; -- ALU Operation: PASS B (Pass the Target)

            WHEN OP_JN => 
                branch_type <= "010";
                alu_src_b   <= '1'; 
                alu_sel     <= "001"; 

            WHEN OP_JC => 
                branch_type <= "011";
                alu_src_b   <= '1'; 
                alu_sel     <= "001";
            WHEN OP_JMP => branch_type <= "100";
            WHEN OP_CALL => 
                branch_type <= "101"; mem_write <= '1'; sp_write <= '1'; is_stack <= '1';
            WHEN OP_RET => 
                branch_type <= "110"; sp_write <= '1'; mem_read <= '1'; is_stack <= '1';
            WHEN OP_INT => 
                branch_type <= "111"; mem_write <= '1'; sp_write <= '1'; is_stack <= '1';
            WHEN OP_RTI => 
                branch_type <= "110"; sp_write <= '1'; mem_read <= '1'; rti_en <= '1'; is_stack <= '1';

            WHEN OTHERS => NULL;
        END CASE;
    END PROCESS;
END Behavior;