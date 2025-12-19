LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.Processor_Pkg.all;

ENTITY Processor IS
    PORT (
        clk           : IN  std_logic;
        rst           : IN  std_logic;
        
        -- Debug Outputs
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
        
        -- I/O Ports
        input_port    : IN  std_logic_vector(31 DOWNTO 0);
        hardware_interrupt : IN std_logic;

        -- Output Port
        output_port   : OUT std_logic_vector(31 DOWNTO 0);
        out_en        : OUT std_logic
    );
END Processor;

ARCHITECTURE Structure OF Processor IS

    COMPONENT ControlUnit
    PORT (
        opcode      : IN  std_logic_vector(4 DOWNTO 0);
        reg_write   : OUT std_logic;
        reg_write_2 : OUT std_logic;
        wb_sel      : OUT std_logic;
        out_en      : OUT std_logic;
        mem_write   : OUT std_logic;
        mem_read    : OUT std_logic;
        alu_sel     : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b   : OUT std_logic;
        port_sel    : OUT std_logic; 
        branch_type : OUT std_logic_vector(2 DOWNTO 0);
        flags_en    : OUT std_logic;
        sp_write    : OUT std_logic;
        is_stack    : OUT std_logic;
        rti_en      : OUT std_logic;
        ccr_z_en    : OUT std_logic;
        ccr_n_en    : OUT std_logic;
        ccr_c_en    : OUT std_logic
    );
    END COMPONENT;

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

    COMPONENT ALU
    PORT(
        SrcA        : IN  std_logic_vector(31 downto 0);
        SrcB        : IN  std_logic_vector(31 downto 0);
        ALU_Sel     : IN  std_logic_vector(2 downto 0);
        ALU_Result  : OUT std_logic_vector(31 downto 0);
        Zero        : OUT std_logic;
        Negative    : OUT std_logic;
        Carry       : OUT std_logic
    );
    END COMPONENT;

    COMPONENT Memory
    PORT(
        clk     : IN  std_logic;
        addr    : IN  std_logic_vector(31 DOWNTO 0);
        data_in : IN  std_logic_vector(31 DOWNTO 0);
        we      : IN  std_logic;
        data_out: OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;
    
    COMPONENT PC
    PORT (
        clk      : IN  std_logic;
        rst      : IN  std_logic;
        pc_write : IN  std_logic;
        pc_inc   : IN  std_logic;
        pc_in    : IN  std_logic_vector(31 DOWNTO 0);
        pc_out   : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT SP
    PORT (
        clk      : IN  std_logic;
        rst      : IN  std_logic;
        sp_write : IN  std_logic;
        sp_in    : IN  std_logic_vector(31 DOWNTO 0);
        sp_out   : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT Sequencer
    PORT (
        clk                 : IN  std_logic;
        rst                 : IN  std_logic;
        hardware_interrupt  : IN  std_logic;
        mem_branch_type     : IN  std_logic_vector(2 DOWNTO 0);
        if_inst_raw         : IN  std_logic_vector(31 DOWNTO 0);
        rst_init_pending    : OUT std_logic;
        rst_load_pc         : OUT std_logic;
        hw_int_pending      : OUT std_logic;
        int_phase           : OUT std_logic;
        ex_mem_en           : OUT std_logic
    );
    END COMPONENT;

    COMPONENT CCR
    PORT (
        clk, rst : IN std_logic;
        write_z, write_n, write_c : IN std_logic;
        z_in, n_in, c_in : IN std_logic;
        save_ccr, restore_ccr : IN std_logic;
        ccr_out : OUT std_logic_vector(3 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT IF_ID_Reg
    PORT (
        clk, rst, en : IN std_logic;
        pc_in, inst_in : IN std_logic_vector(31 DOWNTO 0);
        pc_out, inst_out : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT ID_EX_Reg
    PORT (
        clk, rst, en : IN std_logic;
        reg_write_in, reg_write_2_in, wb_sel_in, mem_write_in, mem_read_in : IN std_logic;
        alu_sel_in   : IN std_logic_vector(2 DOWNTO 0);
        alu_src_b_in : IN std_logic;
        port_sel_in  : IN std_logic; -- ADDED
        is_std_in    : IN std_logic;
        sp_write_in  : IN std_logic;
        is_stack_in  : IN std_logic;
        out_en_in    : IN std_logic;
        rti_en_in    : IN std_logic;
        branch_type_in : IN std_logic_vector(2 DOWNTO 0);
        flags_en_in  : IN std_logic;
        ccr_z_en_in, ccr_n_en_in, ccr_c_en_in : IN std_logic;
        
        pc_in, r_data1_in, r_data2_in, imm_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in    : IN std_logic_vector(31 DOWNTO 0);
        r_addr1_in, r_addr2_in, rdst_addr_in : IN std_logic_vector(2 DOWNTO 0);
        
        reg_write_out, reg_write_2_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        alu_sel_out   : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b_out : OUT std_logic;
        port_sel_out  : OUT std_logic; -- ADDED
        is_std_out    : OUT std_logic;
        sp_write_out  : OUT std_logic;
        is_stack_out  : OUT std_logic;
        out_en_out    : OUT std_logic;
        rti_en_out    : OUT std_logic;
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0);
        flags_en_out  : OUT std_logic;
        ccr_z_en_out, ccr_n_en_out, ccr_c_en_out : OUT std_logic;
        
        pc_out, r_data1_out, r_data2_out, imm_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_val_out    : OUT std_logic_vector(31 DOWNTO 0);
        r_addr1_out, r_addr2_out, rdst_addr_out : OUT std_logic_vector(2 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT EX_MEM_Reg
    PORT (
        clk, rst, en : IN std_logic;
        
        reg_write_in, reg_write_2_in, wb_sel_in, mem_write_in, mem_read_in : IN std_logic;
        sp_write_in  : IN std_logic;
        is_stack_in  : IN std_logic;
        out_en_in    : IN std_logic;
        rti_en_in    : IN std_logic;
        branch_type_in : IN std_logic_vector(2 DOWNTO 0);

        pc_in         : IN std_logic_vector(31 DOWNTO 0);
        alu_res_in, write_data_in : IN std_logic_vector(31 DOWNTO 0);
        sp_new_val_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in     : IN std_logic_vector(31 DOWNTO 0);
        rdst_addr_in: IN std_logic_vector(2 DOWNTO 0);
        rsrc_addr_in : IN std_logic_vector(2 DOWNTO 0);
        r_data2_in   : IN std_logic_vector(31 DOWNTO 0);
        
        reg_write_out, reg_write_2_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        sp_write_out  : OUT std_logic;
        is_stack_out  : OUT std_logic;
        out_en_out    : OUT std_logic;
        rti_en_out    : OUT std_logic;
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0);
        
        pc_out        : OUT std_logic_vector(31 DOWNTO 0);
        alu_res_out, write_data_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_new_val_out: OUT std_logic_vector(31 DOWNTO 0);
        sp_val_out    : OUT std_logic_vector(31 DOWNTO 0);
        rdst_addr_out: OUT std_logic_vector(2 DOWNTO 0);
        rsrc_addr_out : OUT std_logic_vector(2 DOWNTO 0);
        r_data2_out   : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;
    
    COMPONENT MEM_WB_Reg
    PORT (
        clk, rst, en : IN std_logic;
        reg_write_in, reg_write_2_in, wb_sel_in : IN std_logic;
        
        pc_in          : IN std_logic_vector(31 DOWNTO 0);
        mem_data_in    : IN std_logic_vector(31 DOWNTO 0);
        alu_res_in     : IN std_logic_vector(31 DOWNTO 0);
        rdst_addr_in   : IN std_logic_vector(2 DOWNTO 0);
        rsrc_addr_in   : IN std_logic_vector(2 DOWNTO 0);
        swap_data_in   : IN std_logic_vector(31 DOWNTO 0);
        
        reg_write_out, reg_write_2_out, wb_sel_out : OUT std_logic;
        
        pc_out         : OUT std_logic_vector(31 DOWNTO 0);
        mem_data_out   : OUT std_logic_vector(31 DOWNTO 0);
        alu_res_out    : OUT std_logic_vector(31 DOWNTO 0);
        rdst_addr_out  : OUT std_logic_vector(2 DOWNTO 0);
        rsrc_addr_out  : OUT std_logic_vector(2 DOWNTO 0);
        r_data2_out    : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    ----------------------------------------------------------------------------
    -- SIGNALS
    ----------------------------------------------------------------------------
    
    -- STAGE: IF
    SIGNAL pc_current, pc_next, pc_plus_1 : std_logic_vector(31 DOWNTO 0);
    SIGNAL if_inst : std_logic_vector(31 DOWNTO 0);
    SIGNAL if_stall : std_logic := '0';
    
    -- IF Branch Optimization
    SIGNAL if_opcode : std_logic_vector(4 DOWNTO 0);
    SIGNAL if_is_uncond_jmp : std_logic;
    SIGNAL if_jmp_target : std_logic_vector(31 DOWNTO 0);
    SIGNAL if_imm : std_logic_vector(31 DOWNTO 0);
    
    -- STAGE: ID
    SIGNAL id_pc, id_inst : std_logic_vector(31 DOWNTO 0);
    SIGNAL id_opcode : std_logic_vector(4 DOWNTO 0);
    SIGNAL id_r1, id_r2, id_w : std_logic_vector(2 DOWNTO 0);
    SIGNAL id_imm_ext : std_logic_vector(31 DOWNTO 0);
    SIGNAL id_r_data1, id_r_data2 : std_logic_vector(31 DOWNTO 0);
    SIGNAL id_r1_mux : std_logic_vector(2 DOWNTO 0);
    SIGNAL id_imm_or_port : std_logic_vector(31 DOWNTO 0); 
    SIGNAL id_inst_mux : std_logic_vector(31 DOWNTO 0);
    
    SIGNAL c_reg_write, c_reg_write_2, c_wb_sel, c_mem_write, c_mem_read, c_alu_src_b : std_logic;
    SIGNAL c_out_en, c_port_sel, c_rti_en, c_flags_en : std_logic;
    SIGNAL c_alu_sel : std_logic_vector(2 DOWNTO 0);
    SIGNAL c_branch_type : std_logic_vector(2 DOWNTO 0);
    SIGNAL c_is_std, c_sp_write, c_is_stack : std_logic;
    SIGNAL c_ccr_z_en, c_ccr_n_en, c_ccr_c_en : std_logic;
    
    -- STAGE: EX
    SIGNAL ex_reg_write, ex_reg_write_2, ex_wb_sel, ex_mem_write, ex_mem_read, ex_alu_src_b : std_logic;
    SIGNAL ex_out_en, ex_rti_en, ex_flags_en, ex_port_sel : std_logic; -- Added ex_port_sel
    SIGNAL ex_alu_sel : std_logic_vector(2 DOWNTO 0);
    SIGNAL ex_is_std, ex_sp_write, ex_is_stack : std_logic;
    SIGNAL ex_branch_type : std_logic_vector(2 DOWNTO 0);
    SIGNAL ex_ccr_z_en, ex_ccr_n_en, ex_ccr_c_en : std_logic;
    
    SIGNAL ex_pc, ex_r_data1, ex_r_data2, ex_imm_ext : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_r_addr1, ex_r_addr2, ex_w_addr_dest : std_logic_vector(2 DOWNTO 0);
    SIGNAL ex_write_data : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_src_a, ex_src_b, ex_alu_result : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_zero, ex_neg, ex_carry : std_logic;
    SIGNAL ex_sp_val, ex_sp_side_result : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_pc_plus_1, ex_int_addr, ex_alu_result_final : std_logic_vector(31 DOWNTO 0);
    
    -- CCR Signals
    SIGNAL ccr_write_z, ccr_write_n, ccr_write_c : std_logic;
    SIGNAL ccr_z_in, ccr_n_in, ccr_c_in : std_logic;
    SIGNAL ccr_save, ccr_restore : std_logic;
    SIGNAL ccr_out : std_logic_vector(3 DOWNTO 0);

    -- BRANCH LOGIC SIGNALS
    SIGNAL ex_branch_taken : std_logic;
    SIGNAL mem_branch_taken : std_logic;
    SIGNAL flush_ex, flush_mem, flush_pipeline : std_logic;

    -- STAGE: MEM
    SIGNAL mem_reg_write, mem_reg_write_2, mem_wb_sel, mem_mem_write, mem_mem_read : std_logic;
    SIGNAL mem_out_en, mem_rti_en : std_logic;
    SIGNAL mem_is_stack, mem_sp_write : std_logic;
    SIGNAL mem_branch_type : std_logic_vector(2 DOWNTO 0);
    SIGNAL mem_pc, mem_alu_result, mem_write_data : std_logic_vector(31 DOWNTO 0);
    SIGNAL mem_sp_new_val, mem_sp_val : std_logic_vector(31 DOWNTO 0);
    SIGNAL mem_w_addr_dest, mem_w_addr_swap : std_logic_vector(2 DOWNTO 0);
    SIGNAL mem_read_data, mem_swap_data : std_logic_vector(31 DOWNTO 0);
    
    -- STAGE: WB
    SIGNAL wb_reg_write, wb_reg_write_2, wb_wb_sel : std_logic;
    SIGNAL wb_pc, wb_mem_data, wb_alu_result : std_logic_vector(31 DOWNTO 0);
    SIGNAL wb_w_addr_dest, wb_w_addr_swap : std_logic_vector(2 DOWNTO 0);
    SIGNAL wb_write_data, wb_swap_data : std_logic_vector(31 DOWNTO 0);
    
    -- Memory Arbiter
    SIGNAL memory_addr : std_logic_vector(31 DOWNTO 0);
    SIGNAL memory_we, mem_busy : std_logic;
    SIGNAL memory_data_in, memory_data_out : std_logic_vector(31 DOWNTO 0);
    
    SIGNAL sp_current : std_logic_vector(31 DOWNTO 0);
    SIGNAL pc_write_sig, if_id_en_sig : std_logic;

    -- Reset / Logic Signals
    SIGNAL rst_init_pending, rst_load_pc : std_logic;
    SIGNAL hw_int_pending   : std_logic;
    SIGNAL int_phase        : std_logic;
    SIGNAL force_nop_sig    : std_logic;
    SIGNAL ex_mem_en_sig    : std_logic;
    SIGNAL mem_restored_pc : std_logic_vector(31 DOWNTO 0);

    -- Intermediate Reset Signals
    SIGNAL rst_if_id  : std_logic;
    SIGNAL rst_id_ex  : std_logic;
    SIGNAL rst_ex_mem : std_logic;

BEGIN

    ----------------------------------------------------------------------------
    -- 0. SEQUENCER
    ----------------------------------------------------------------------------
    U_Sequencer: Sequencer PORT MAP (
        clk => clk, rst => rst,
        hardware_interrupt => hardware_interrupt,
        mem_branch_type => mem_branch_type,
        if_inst_raw => memory_data_out,
        rst_init_pending => rst_init_pending,
        rst_load_pc => rst_load_pc,
        hw_int_pending => hw_int_pending,
        int_phase => int_phase,
        ex_mem_en => ex_mem_en_sig
    );

    ----------------------------------------------------------------------------
    -- 1. FETCH STAGE
    ----------------------------------------------------------------------------
    -- Memory Access Logic (Arbiter)
    mem_busy <= '1' WHEN (mem_mem_write = '1' OR mem_mem_read = '1') ELSE '0';
    
    memory_addr <= (OTHERS => '0')    WHEN rst_init_pending = '1' ELSE
                   mem_sp_val         WHEN (mem_is_stack = '1' AND mem_mem_write = '1' AND int_phase = '0') ELSE
                   mem_alu_result     WHEN (mem_branch_type = "111" AND int_phase = '1')                 ELSE
                   mem_sp_new_val     WHEN (mem_is_stack = '1' AND mem_mem_read = '1')                      ELSE
                   pc_current;
                   
    memory_data_in <= mem_write_data;
    memory_we      <= '1' WHEN (mem_mem_write = '1' AND (mem_branch_type /= "111" OR int_phase = '0')) ELSE '0';
    
    -- Stall IF if Memory is used by MEM stage or during Reset/Interrupt
    if_stall <= '1' WHEN (rst_init_pending = '1' OR mem_busy = '1' OR (mem_branch_type = "111" AND int_phase = '0')) ELSE '0'; 
    
    -- Next PC Logic
    pc_plus_1 <= std_logic_vector(unsigned(pc_current) + 1);
    
    -- FETCH STAGE OPTIMIZATION
    mem_restored_pc <= memory_data_out; -- For Reset/Interrupt vector fetch
    if_inst <= x"00000000" WHEN (force_nop_sig = '1' OR ex_branch_taken = '1' OR mem_branch_taken = '1') ELSE memory_data_out;
    
    if_opcode <= if_inst(31 DOWNTO 27);
    if_imm <= std_logic_vector(resize(unsigned(if_inst(15 DOWNTO 0)), 32));
    
    if_is_uncond_jmp <= '1' WHEN (if_opcode = "10101" OR if_opcode = "10110") ELSE '0';
    if_jmp_target <= if_imm; 

    -- Calculate Reset Signals (Flush)
    flush_ex  <= ex_branch_taken;
    flush_mem <= mem_branch_taken;
    flush_pipeline <= flush_ex OR flush_mem;

    -- 1. IF/ID: Must be flushed for ANY branch (EX or MEM).
    rst_if_id  <= rst OR flush_ex OR flush_mem; 

    -- 2. ID/EX: Only flush if the branch is in MEM stage. 
    --    DO NOT flush if the branch is in EX stage (don't kill the JZ!)
    rst_id_ex  <= rst OR flush_mem;  -- CHANGED (Removed flush_ex)

    -- 3. EX/MEM: Only flush if global reset (or potentially MEM branch depending on ISA)
    rst_ex_mem <= rst OR flush_mem;
    -- MASTER PC MUX
    PROCESS(pc_plus_1, if_is_uncond_jmp, if_jmp_target, ex_branch_taken, ex_alu_result_final, mem_branch_taken, mem_restored_pc, rst_load_pc)
    BEGIN
        IF rst_load_pc = '1' THEN
            pc_next <= mem_restored_pc; 
        ELSIF mem_branch_taken = '1' THEN
            pc_next <= mem_restored_pc; 
        ELSIF ex_branch_taken = '1' THEN
            pc_next <= ex_alu_result_final; 
        ELSIF if_is_uncond_jmp = '1' THEN
            pc_next <= if_jmp_target;
        ELSE
            pc_next <= pc_plus_1;
        END IF;
    END PROCESS;

    -- Allow PC update if not stalled, OR if we are branching (Branch overrides Stall)
    pc_write_sig <= (NOT if_stall) OR ex_branch_taken OR mem_branch_taken OR rst_load_pc;
    if_id_en_sig <= NOT if_stall;

    U_PC: PC PORT MAP (
        clk => clk, rst => rst,
        pc_write => pc_write_sig, pc_inc => '0', 
        pc_in => pc_next, pc_out => pc_current
    );

    U_IF_ID: IF_ID_Reg PORT MAP (
        clk => clk, 
        rst => rst_if_id,
        en => if_id_en_sig,
        pc_in => pc_current, inst_in => if_inst,
        pc_out => id_pc, inst_out => id_inst
    );

    -- RTI/INT Pre-decode for NOP injection
    force_nop_sig <= '1' WHEN (id_inst(17 DOWNTO 16) = "10" OR id_inst(17 DOWNTO 16) = "01") ELSE '0';

    ----------------------------------------------------------------------------
    -- 2. DECODE STAGE
    ----------------------------------------------------------------------------
    id_opcode <= id_inst(31 DOWNTO 27);
    id_r1     <= id_inst(26 DOWNTO 24); 
    id_r2     <= id_inst(23 DOWNTO 21); 
    
    -- *** FIXED Rdst Logic ***
    -- If R-Type (ADD, SUB, etc), Destination is 20-18.
    -- If I-Type (LDM, LDD), Destination is 23-21 (per your Test Case Hex).
    PROCESS(id_opcode, id_inst)
    BEGIN
        CASE id_opcode IS
            -- List R-Type Opcodes that write to bits 20-18
            -- Removed OP_DEC to fix the error
            WHEN OP_ADD | OP_SUB | OP_AND | OP_NOT | OP_INC | OP_SETC | OP_OUT | OP_IN =>
                id_w <= id_inst(20 DOWNTO 18);
            
            -- Default (LDM, IN, MOV, etc) uses bits 23-21
            WHEN OTHERS =>
                id_w <= id_inst(23 DOWNTO 21);
        END CASE;
    END PROCESS;
    id_r1_mux <= id_w WHEN (id_opcode = OP_PUSH OR id_opcode = OP_NOT OR id_opcode = OP_INC OR id_opcode = OP_OUT) 
                     ELSE id_r1;

    -- HW Interrupt Opcode Injection
    id_inst_mux <= x"C0040000" WHEN (hw_int_pending = '1' AND if_stall = '0') ELSE id_inst;
    
    id_imm_ext <= x"80000001" WHEN (hw_int_pending = '1' AND if_stall = '0') ELSE
                  input_port  WHEN id_opcode = OP_IN ELSE
                  std_logic_vector(resize(unsigned(id_inst_mux(15 DOWNTO 0)), 32)) WHEN (id_opcode = OP_LDM OR id_opcode = OP_INT) ELSE
                  std_logic_vector(resize(signed(id_inst_mux(15 DOWNTO 0)), 32));
    
    U_Control: ControlUnit PORT MAP (
        opcode => id_opcode,
        reg_write => c_reg_write, reg_write_2 => c_reg_write_2,
        wb_sel => c_wb_sel, out_en => c_out_en,
        mem_write => c_mem_write, mem_read => c_mem_read,
        alu_sel => c_alu_sel, alu_src_b => c_alu_src_b,
        port_sel => c_port_sel, branch_type => c_branch_type,
        flags_en => c_flags_en, 
        sp_write => c_sp_write, is_stack => c_is_stack,
        rti_en => c_rti_en,
        ccr_z_en => c_ccr_z_en,
        ccr_n_en => c_ccr_n_en,
        ccr_c_en => c_ccr_c_en
    );
    
    id_imm_or_port <= input_port WHEN c_port_sel = '1' ELSE id_imm_ext;
    c_is_std <= '1' WHEN id_opcode = OP_STD ELSE '0';

    U_RegFile: RegisterFile PORT MAP (
        clk => clk, rst => rst,
        reg_write_en1 => wb_reg_write,
        reg_write_en2 => wb_reg_write_2,
        read_addr1 => id_r1_mux, read_addr2 => id_r2,
        write_addr1 => wb_w_addr_dest, write_data1 => wb_write_data,
        write_addr2 => wb_w_addr_swap, write_data2 => wb_swap_data,
        read_data1 => id_r_data1, read_data2 => id_r_data2
    );
    
    U_SP: SP PORT MAP (
        clk => clk, rst => rst,
        sp_write => mem_sp_write, sp_in => mem_sp_new_val, sp_out => sp_current
    );

    U_ID_EX: ID_EX_Reg PORT MAP (
        clk => clk, 
        rst => rst_id_ex,
        en => '1',
        reg_write_in => c_reg_write, reg_write_2_in => c_reg_write_2,
        wb_sel_in => c_wb_sel, mem_write_in => c_mem_write, mem_read_in => c_mem_read,
        out_en_in => c_out_en, rti_en_in => c_rti_en,
        alu_sel_in => c_alu_sel, alu_src_b_in => c_alu_src_b,
        port_sel_in => c_port_sel, -- CONNECTED
        is_std_in => c_is_std, sp_write_in => c_sp_write, is_stack_in => c_is_stack,
        branch_type_in => c_branch_type,
        flags_en_in => c_flags_en,
        ccr_z_en_in => c_ccr_z_en,
        ccr_n_en_in => c_ccr_n_en,
        ccr_c_en_in => c_ccr_c_en,
        
        pc_in => id_pc, r_data1_in => id_r_data1, r_data2_in => id_r_data2,
        imm_in => id_imm_or_port, sp_val_in => sp_current,
        r_addr1_in => id_r1, r_addr2_in => id_r2, rdst_addr_in => id_w,
        
        reg_write_out => ex_reg_write, reg_write_2_out => ex_reg_write_2,
        wb_sel_out => ex_wb_sel, mem_write_out => ex_mem_write, mem_read_out => ex_mem_read,
        out_en_out => ex_out_en, rti_en_out => ex_rti_en,
        alu_sel_out => ex_alu_sel, alu_src_b_out => ex_alu_src_b,
        port_sel_out => ex_port_sel, -- CONNECTED
        is_std_out => ex_is_std, sp_write_out => ex_sp_write, is_stack_out => ex_is_stack,
        branch_type_out => ex_branch_type,
        flags_en_out => ex_flags_en,
        ccr_z_en_out => ex_ccr_z_en,
        ccr_n_en_out => ex_ccr_n_en,
        ccr_c_en_out => ex_ccr_c_en,
        
        pc_out => ex_pc, r_data1_out => ex_r_data1, r_data2_out => ex_r_data2,
        imm_out => ex_imm_ext, sp_val_out => ex_sp_val,
        r_addr1_out => ex_r_addr1, r_addr2_out => ex_r_addr2, rdst_addr_out => ex_w_addr_dest
    );

    ----------------------------------------------------------------------------
    -- 3. EXECUTE STAGE
    ----------------------------------------------------------------------------
    U_CCR: CCR PORT MAP (
        clk => clk, rst => rst,
        write_z => ccr_write_z, write_n => ccr_write_n, write_c => ccr_write_c,
        z_in => ccr_z_in, n_in => ccr_n_in, c_in => ccr_c_in,
        save_ccr => ccr_save, restore_ccr => ccr_restore,
        ccr_out => ccr_out
    );

    ccr_write_z <= ex_ccr_z_en AND ex_flags_en;
    ccr_write_n <= ex_ccr_n_en AND ex_flags_en;
    ccr_write_c <= ex_ccr_c_en AND ex_flags_en;
    ccr_z_in <= ex_zero;
    ccr_n_in <= ex_neg;
    ccr_c_in <= ex_carry;
    ccr_save <= '1' WHEN ex_branch_type = "111" ELSE '0';
    ccr_restore <= ex_rti_en;

    -- Branch Resolution
    PROCESS(ex_branch_type, ccr_out)
    BEGIN
        ex_branch_taken <= '0';
        CASE ex_branch_type IS
            WHEN "001" => IF ccr_out(0) = '1' THEN ex_branch_taken <= '1'; END IF; -- JZ
            WHEN "010" => IF ccr_out(1) = '1' THEN ex_branch_taken <= '1'; END IF; -- JN
            WHEN "011" => IF ccr_out(2) = '1' THEN ex_branch_taken <= '1'; END IF; -- JC
            WHEN "100" => ex_branch_taken <= '1'; -- JMP
            WHEN "101" => ex_branch_taken <= '1'; -- CALL
            WHEN OTHERS => ex_branch_taken <= '0';
        END CASE;
    END PROCESS;

    ex_src_a <= ex_r_data1; 
    ex_src_b <= ex_imm_ext WHEN ex_alu_src_b = '1' ELSE ex_r_data2;

    U_ALU: ALU PORT MAP (
        SrcA => ex_src_a, SrcB => ex_src_b, ALU_Sel => ex_alu_sel,
        ALU_Result => ex_alu_result, Zero => ex_zero, Negative => ex_neg, Carry => ex_carry
    );
    
    -- INT Vector Addr Calculation
    ex_int_addr <= x"00000001" WHEN ex_imm_ext(31) = '1' ELSE 
                   std_logic_vector(unsigned(ex_imm_ext(31 DOWNTO 0)) + 2);
    
    ex_alu_result_final <= ex_int_addr WHEN ex_branch_type = "111" ELSE ex_alu_result;

    ex_pc_plus_1 <= std_logic_vector(unsigned(ex_pc) + 1);

    -- Memory Write Data
    ex_write_data <= ex_pc        WHEN (ex_mem_write = '1' AND ex_is_stack = '1' AND ex_branch_type = "111") ELSE
                     ex_pc_plus_1 WHEN (ex_mem_write = '1' AND ex_is_stack = '1' AND ex_branch_type = "101") ELSE
                     ex_r_data1   WHEN (ex_is_std = '1' OR (ex_mem_write = '1' AND ex_is_stack = '1')) ELSE
                     ex_r_data2;

    -- Output Port Latch
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF ex_out_en = '1' THEN output_port <= ex_alu_result; END IF;
            out_en <= ex_out_en;
        END IF;
    END PROCESS;

    U_EX_MEM: EX_MEM_Reg PORT MAP (
        clk => clk, 
        rst => rst_ex_mem,
        en => ex_mem_en_sig,
        reg_write_in => ex_reg_write, reg_write_2_in => ex_reg_write_2,
        wb_sel_in => ex_wb_sel, mem_write_in => ex_mem_write, mem_read_in => ex_mem_read,
        out_en_in => ex_out_en, rti_en_in => ex_rti_en,
        sp_write_in => ex_sp_write, is_stack_in => ex_is_stack,
        branch_type_in => ex_branch_type, 
        
        pc_in => ex_pc, alu_res_in => ex_alu_result_final, write_data_in => ex_write_data,
        sp_new_val_in => ex_sp_side_result, sp_val_in => ex_sp_val,
        rdst_addr_in => ex_w_addr_dest,
        rsrc_addr_in => ex_r_addr1, r_data2_in => ex_r_data2,
        
        reg_write_out => mem_reg_write, reg_write_2_out => mem_reg_write_2,
        wb_sel_out => mem_wb_sel, mem_write_out => mem_mem_write, mem_read_out => mem_mem_read,
        out_en_out => mem_out_en, rti_en_out => mem_rti_en,
        sp_write_out => mem_sp_write, is_stack_out => mem_is_stack,
        branch_type_out => mem_branch_type, 
        
        pc_out => mem_pc, alu_res_out => mem_alu_result, write_data_out => mem_write_data,
        sp_new_val_out => mem_sp_new_val, sp_val_out => mem_sp_val,
        rdst_addr_out => mem_w_addr_dest,
        rsrc_addr_out => mem_w_addr_swap, r_data2_out => mem_swap_data
    );

    ----------------------------------------------------------------------------
    -- 4. MEMORY STAGE
    ----------------------------------------------------------------------------
    U_Memory: Memory PORT MAP (
        clk => clk,
        addr => memory_addr, data_in => memory_data_in, we => memory_we,
        data_out => memory_data_out
    );
    mem_read_data <= memory_data_out;

    -- Check for RET/RTI
    mem_branch_taken <= '1' WHEN (mem_branch_type = "110") ELSE '0';

    U_MEM_WB: MEM_WB_Reg PORT MAP (
        clk => clk, rst => rst, en => '1',
        reg_write_in => mem_reg_write, reg_write_2_in => mem_reg_write_2,
        wb_sel_in => mem_wb_sel,
        pc_in => mem_pc, mem_data_in => mem_read_data, alu_res_in => mem_alu_result,
        rdst_addr_in => mem_w_addr_dest, rsrc_addr_in => mem_w_addr_swap, swap_data_in => mem_swap_data,
        
        reg_write_out => wb_reg_write, reg_write_2_out => wb_reg_write_2,
        wb_sel_out => wb_wb_sel,
        pc_out => wb_pc, mem_data_out => wb_mem_data, alu_res_out => wb_alu_result,
        rdst_addr_out => wb_w_addr_dest, rsrc_addr_out => wb_w_addr_swap, r_data2_out => wb_swap_data
    );

    ----------------------------------------------------------------------------
    -- 5. WRITE BACK
    ----------------------------------------------------------------------------
    wb_write_data <= wb_mem_data WHEN wb_wb_sel = '1' ELSE wb_alu_result;
    
    -- Debugs
    debug_pc <= pc_current;
    debug_if_pc <= pc_current;
    debug_id_pc <= id_pc;
    debug_ex_pc <= ex_pc;
    debug_mem_pc <= mem_pc;
    debug_wb_pc <= wb_pc;
    debug_inst <= id_inst;
    debug_reg_w_en <= wb_reg_write;
    debug_mem_w_en <= mem_mem_write;
    debug_alu <= mem_alu_result;

END Structure;