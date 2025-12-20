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

        -- Hardware Interrupt Line
        irq_line      : IN  std_logic;

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
        hlt_en      : OUT std_logic
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

    COMPONENT ForwardingUnit
    PORT (
        id_ex_rs1        : IN  std_logic_vector(2 DOWNTO 0);
        id_ex_rs2        : IN  std_logic_vector(2 DOWNTO 0);
        ex_mem_rd        : IN  std_logic_vector(2 DOWNTO 0);
        ex_mem_reg_write : IN  std_logic;
        mem_wb_rd        : IN  std_logic_vector(2 DOWNTO 0);
        mem_wb_reg_write : IN  std_logic;
        forward_a        : OUT std_logic_vector(1 DOWNTO 0);
        forward_b        : OUT std_logic_vector(1 DOWNTO 0)
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
        is_std_in    : IN std_logic;
        sp_write_in  : IN std_logic;
        is_stack_in  : IN std_logic;
        out_en_in    : IN std_logic;
        rti_en_in    : IN std_logic;
        branch_type_in : IN std_logic_vector(2 DOWNTO 0);
        flags_en_in  : IN std_logic; -- NEW
        port_sel_in  : IN std_logic;
        
        pc_in, r_data1_in, r_data2_in, imm_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in    : IN std_logic_vector(31 DOWNTO 0);
        r_addr1_in, r_addr2_in, rdst_addr_in : IN std_logic_vector(2 DOWNTO 0);
        
        reg_write_out, reg_write_2_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        alu_sel_out   : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b_out : OUT std_logic;
        is_std_out    : OUT std_logic;
        sp_write_out  : OUT std_logic;
        is_stack_out  : OUT std_logic;
        out_en_out    : OUT std_logic;
        rti_en_out    : OUT std_logic;
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0);
        flags_en_out  : OUT std_logic; -- NEW
        
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
        alu_res_in, r_data2_in : IN std_logic_vector(31 DOWNTO 0);
        sp_new_val_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in     : IN std_logic_vector(31 DOWNTO 0);
        rdst_addr_in: IN std_logic_vector(2 DOWNTO 0);
        rsrc_addr_in : IN std_logic_vector(2 DOWNTO 0);
        
        reg_write_out, reg_write_2_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        sp_write_out  : OUT std_logic;
        is_stack_out  : OUT std_logic;
        out_en_out    : OUT std_logic;
        rti_en_out    : OUT std_logic;
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0);
        
        pc_out        : OUT std_logic_vector(31 DOWNTO 0);
        alu_res_out, r_data2_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_new_val_out: OUT std_logic_vector(31 DOWNTO 0);
        sp_val_out    : OUT std_logic_vector(31 DOWNTO 0);
        rdst_addr_out: OUT std_logic_vector(2 DOWNTO 0);
        rsrc_addr_out : OUT std_logic_vector(2 DOWNTO 0)
    );
    END COMPONENT;
    
    COMPONENT MEM_WB_Reg
    PORT (
        clk, rst, en : IN std_logic;
        reg_write_in, reg_write_2_in, wb_sel_in : IN std_logic;
        out_en_in    : IN std_logic;
        
        pc_in          : IN std_logic_vector(31 DOWNTO 0);
        mem_data_in    : IN std_logic_vector(31 DOWNTO 0);
        alu_res_in  : IN std_logic_vector(31 DOWNTO 0);
        rdst_addr_in : IN std_logic_vector(2 DOWNTO 0);
        rsrc_addr_in : IN std_logic_vector(2 DOWNTO 0);
        r_data2_in   : IN std_logic_vector(31 DOWNTO 0);
        
        reg_write_out, reg_write_2_out, wb_sel_out : OUT std_logic;
        out_en_out   : OUT std_logic;
        
        pc_out         : OUT std_logic_vector(31 DOWNTO 0);
        mem_data_out   : OUT std_logic_vector(31 DOWNTO 0);
        alu_res_out : OUT std_logic_vector(31 DOWNTO 0);
        rdst_addr_out: OUT std_logic_vector(2 DOWNTO 0);
        rsrc_addr_out : OUT std_logic_vector(2 DOWNTO 0);
        r_data2_out   : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    -- Interrupt Controller: Handles HW interrupt line
    COMPONENT InterruptController
    PORT (
        clk            : IN  std_logic;
        rst            : IN  std_logic;
        irq_line       : IN  std_logic;
        cpu_ack        : IN  std_logic;
        pipeline_clear : IN  std_logic;
        irq_req        : OUT std_logic;
        irq_inst       : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    -- Stack Packer: Packs/unpacks PC and CCR for CALL/RET/INT/RTI
    COMPONENT StackPacker
    PORT (
        is_call       : IN std_logic;
        is_int        : IN std_logic;
        pc_current    : IN std_logic_vector(31 DOWNTO 0);
        pc_plus_1     : IN std_logic_vector(31 DOWNTO 0);
        ccr_flags     : IN std_logic_vector(2 DOWNTO 0);
        normal_data   : IN std_logic_vector(31 DOWNTO 0);
        mem_write_data: OUT std_logic_vector(31 DOWNTO 0);
        mem_read_data : IN  std_logic_vector(31 DOWNTO 0);
        restored_pc   : OUT std_logic_vector(31 DOWNTO 0);
        restored_ccr  : OUT std_logic_vector(2 DOWNTO 0)
    );
    END COMPONENT;

    -- Interrupt Vector Unit: Computes vector address
    COMPONENT InterruptVectorUnit
    PORT (
        int_index     : IN std_logic_vector(14 DOWNTO 0);
        vector_addr   : OUT std_logic_vector(31 DOWNTO 0)
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
    
    SIGNAL c_reg_write, c_reg_write_2, c_wb_sel, c_mem_write, c_mem_read, c_alu_src_b : std_logic;
    SIGNAL c_out_en, c_port_sel, c_rti_en, c_flags_en, c_hlt_en : std_logic;
    SIGNAL c_alu_sel : std_logic_vector(2 DOWNTO 0);
    SIGNAL c_branch_type : std_logic_vector(2 DOWNTO 0);
    SIGNAL c_is_std, c_sp_write, c_is_stack : std_logic;
    SIGNAL id_out_en_mux : std_logic;
    
    -- Halt signal latch
    SIGNAL halted : std_logic := '0';

    -- For Hazard detection unit
    SIGNAL stall : std_logic;
    -- Intermediate signals to handle the "Bubble" (Control Mux)
    SIGNAL id_reg_write_mux, id_reg_write_2_mux, id_mem_write_mux, id_mem_read_mux : std_logic;
    SIGNAL id_alu_src_b_mux, id_sp_write_mux, id_is_stack_mux, id_flags_en_mux : std_logic;
    SIGNAL id_branch_type_mux : std_logic_vector(2 DOWNTO 0);
    
    -- STAGE: EX
    SIGNAL ex_reg_write, ex_reg_write_2, ex_wb_sel, ex_mem_write, ex_mem_read, ex_alu_src_b : std_logic;
    SIGNAL ex_out_en, ex_rti_en, ex_flags_en : std_logic;
    SIGNAL ex_alu_sel : std_logic_vector(2 DOWNTO 0);
    SIGNAL ex_is_std, ex_sp_write, ex_is_stack : std_logic;
    SIGNAL ex_branch_type : std_logic_vector(2 DOWNTO 0);
    
    SIGNAL ex_pc, ex_r_data1, ex_r_data2, ex_imm_ext : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_pc_plus_1 : std_logic_vector(31 DOWNTO 0);  -- PC+1 for CALL return address
    SIGNAL ex_r_addr1, ex_r_addr2, ex_w_addr_dest : std_logic_vector(2 DOWNTO 0);
    SIGNAL ex_write_data : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_src_a, ex_src_b, ex_alu_result : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_alu_result_muxed : std_logic_vector(31 DOWNTO 0);  -- ALU result or vector addr for INT
    SIGNAL ex_zero, ex_neg, ex_carry : std_logic;
    SIGNAL ex_sp_val, ex_sp_side_result : std_logic_vector(31 DOWNTO 0);
    SIGNAL forward_a_sel, forward_b_sel : std_logic_vector(1 DOWNTO 0);
    SIGNAL ex_r2_forwarded : std_logic_vector(31 DOWNTO 0);
    
    -- CCR Signals
    SIGNAL ccr : std_logic_vector(2 DOWNTO 0) := (others => '0');

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
    SIGNAL wb_out_en : std_logic;
    SIGNAL wb_pc, wb_mem_data, wb_alu_result : std_logic_vector(31 DOWNTO 0);
    SIGNAL wb_w_addr_dest, wb_w_addr_swap : std_logic_vector(2 DOWNTO 0);
    SIGNAL wb_write_data, wb_swap_data : std_logic_vector(31 DOWNTO 0);
    
    -- Memory Arbiter
    SIGNAL memory_addr : std_logic_vector(31 DOWNTO 0);
    SIGNAL memory_we, mem_busy : std_logic;
    SIGNAL memory_data_in, memory_data_out : std_logic_vector(31 DOWNTO 0);
    
    SIGNAL sp_current : std_logic_vector(31 DOWNTO 0);
    SIGNAL sp_forwarded : std_logic_vector(31 DOWNTO 0);  -- SP with forwarding
    SIGNAL pc_write_sig, if_id_en_sig : std_logic;

    -- Intermediate Reset Signals
    SIGNAL rst_if_id  : std_logic;
    SIGNAL rst_id_ex  : std_logic;
    SIGNAL rst_ex_mem : std_logic;

    -- Reset Vector State Machine
    SIGNAL reset_state : std_logic := '1';  -- '1' = reading reset vector, '0' = normal operation

    -- =========================================================================
    -- INTERRUPT AND CONTROL FLOW SIGNALS
    -- =========================================================================
    -- Fast bits from instruction at each stage (bits 16:15)
    SIGNAL id_fast_bits  : std_logic_vector(1 DOWNTO 0);
    SIGNAL ex_fast_bits  : std_logic_vector(1 DOWNTO 0);
    SIGNAL mem_fast_bits : std_logic_vector(1 DOWNTO 0);
    
    -- Interrupt Controller signals
    SIGNAL irq_req           : std_logic;
    SIGNAL irq_inst          : std_logic_vector(31 DOWNTO 0);
    SIGNAL irq_cpu_ack       : std_logic;
    SIGNAL irq_pipeline_clear : std_logic;
    
    -- Hazard Unit outputs for control flow
    SIGNAL ctrl_flow_stall : std_logic;
    SIGNAL ctrl_flow_flush : std_logic;
    
    -- Stack Packer signals
    SIGNAL is_call_sig   : std_logic;
    SIGNAL is_int_sig    : std_logic;
    SIGNAL packed_stack_data : std_logic_vector(31 DOWNTO 0);
    SIGNAL restored_pc   : std_logic_vector(31 DOWNTO 0);
    SIGNAL restored_ccr  : std_logic_vector(2 DOWNTO 0);
    
    -- Interrupt vector
    SIGNAL int_vector_addr : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_int_index    : std_logic_vector(14 DOWNTO 0);
    
    -- INT branch taken in MEM stage
    SIGNAL mem_int_branch  : std_logic;
    SIGNAL int_state       : std_logic := '0';  -- '0' = idle/push, '1' = read vector
    SIGNAL int_vector_addr_latched : std_logic_vector(31 DOWNTO 0);
    
    -- Instruction mux for HW interrupt injection
    SIGNAL if_inst_muxed   : std_logic_vector(31 DOWNTO 0);

BEGIN

    ----------------------------------------------------------------------------
    -- 1. FETCH STAGE
    ----------------------------------------------------------------------------
    -- Memory Access Logic (Arbiter)
    -- INT requires: 1) Push PC+CCR to stack, 2) Read vector from memory
    -- With single-port memory, these happen in sequence using int_state.
    -- 
    -- INT sequence:
    -- Cycle N:   INT in MEM stage, mem_write=1, push PC+CCR to stack
    --            int_state goes to '1', latch vector address
    -- Cycle N+1: int_state='1', read from latched vector address
    --            mem_int_branch='1', PC jumps to memory_data_out
    
    mem_busy <= '1' WHEN (mem_mem_write = '1' OR mem_mem_read = '1' OR int_state = '1') ELSE '0';
    
    -- Memory address selection:
    memory_addr <= mem_sp_val            WHEN (mem_is_stack = '1' AND mem_mem_write = '1') ELSE -- PUSH/CALL/INT stack push
                   int_vector_addr_latched WHEN (int_state = '1')                           ELSE -- INT vector read (2nd cycle)
                   mem_sp_new_val        WHEN (mem_is_stack = '1' AND mem_mem_read = '1')  ELSE -- POP/RET/RTI stack pop
                   mem_alu_result        WHEN (mem_mem_write = '1' OR mem_mem_read = '1')  ELSE -- LDD/STD
                   pc_current;                                                                  -- Instruction fetch
                   
    memory_data_in <= mem_write_data;
    memory_we      <= mem_mem_write;
    
    -- INT state machine: handles 2-cycle INT operation
    -- INT sequence:
    -- When INT is in MEM stage: Push PC+CCR to stack, latch vector address, set int_state='1'
    -- Next cycle: int_state='1', read vector from latched address, branch
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            int_state <= '0';
            int_vector_addr_latched <= (others => '0');
        ELSIF rising_edge(clk) THEN
            -- State machine for INT read cycle
            IF mem_branch_type = "111" AND mem_mem_write = '1' AND int_state = '0' THEN
                -- INT is in MEM stage doing push, latch vector address NOW
                -- (int_vector_addr is computed from ex_int_index which is stable at this point
                --  since INT has already passed through EX and is now in MEM)
                -- Actually we need to use mem stage signals - pass through alu_result
                int_vector_addr_latched <= mem_alu_result;
                int_state <= '1';
            ELSIF int_state = '1' THEN
                -- Vector read cycle complete, clear state
                int_state <= '0';
            END IF;
        END IF;
    END PROCESS;
    
    -- Stall IF if Memory is used by MEM stage
    if_stall <= mem_busy;
    
    -- Next PC Logic
    pc_plus_1 <= std_logic_vector(unsigned(pc_current) + 1);
    
    -- =========================================================================
    -- INTERRUPT CONTROLLER INSTANTIATION
    -- =========================================================================
    -- CPU acknowledges when INT opcode is being processed in ID stage
    irq_cpu_ack <= '1' WHEN (id_opcode = OP_INT) ELSE '0';
    
    -- Pipeline is clear when no control flow ops in ID, EX, or MEM stages
    -- This is the inverse of ctrl_flow_stall (which is based on fast bits)
    irq_pipeline_clear <= '1' WHEN (id_fast_bits = "00" AND ex_fast_bits = "00" AND mem_fast_bits = "00") ELSE '0';
    
    U_InterruptController: InterruptController PORT MAP (
        clk            => clk,
        rst            => rst,
        irq_line       => irq_line,
        cpu_ack        => irq_cpu_ack,
        pipeline_clear => irq_pipeline_clear,
        irq_req        => irq_req,
        irq_inst       => irq_inst
    );
    
    -- Instruction Mux: Inject HW interrupt instruction when requested
    if_inst_muxed <= irq_inst WHEN irq_req = '1' ELSE memory_data_out;
    
    -- FETCH STAGE OPTIMIZATION
    if_inst <= if_inst_muxed; 
    if_opcode <= if_inst(31 DOWNTO 27);
    if_imm <= std_logic_vector(resize(unsigned(if_inst(14 DOWNTO 0)), 32)); -- Now 15 bits
    
    if_is_uncond_jmp <= '1' WHEN (if_opcode = OP_JMP OR if_opcode = OP_CALL) ELSE '0';
    if_jmp_target <= if_imm; 
    
    -- =========================================================================
    -- FAST BITS EXTRACTION (bits 16:15 of instruction)
    -- =========================================================================
    id_fast_bits  <= id_inst(16 DOWNTO 15);

    -- Calculate Reset Signals (Flush)
    flush_ex  <= ex_branch_taken;
    flush_mem <= mem_branch_taken OR int_state;  -- Flush on RET/RTI or INT vector jump
    flush_pipeline <= flush_ex OR flush_mem;

    -- 1. IF/ID: Must be flushed for ANY branch (EX or MEM) OR control flow flush
    --    EXCEPT: Don't flush when irq_req is active (we're injecting INT instruction)
    rst_if_id  <= rst OR flush_ex OR flush_mem OR (ctrl_flow_flush AND NOT irq_req); 

    -- 2. ID/EX: Only flush if the branch is in MEM stage. 
    --    DO NOT flush if the branch is in EX stage (don't kill the JZ!)
    rst_id_ex  <= rst OR flush_mem;  -- CHANGED (Removed flush_ex)

    -- 3. EX/MEM: Only flush if global reset (or potentially MEM branch depending on ISA)
    rst_ex_mem <= rst OR flush_mem;
    
    -- =========================================================================
    -- INTERRUPT VECTOR UNIT
    -- =========================================================================
    ex_int_index <= ex_imm_ext(14 DOWNTO 0);  -- INT index from immediate field
    
    U_InterruptVectorUnit: InterruptVectorUnit PORT MAP (
        int_index   => ex_int_index,
        vector_addr => int_vector_addr
    );
    
    -- MASTER PC MUX - Now includes reset vector and INT vector handling
    PROCESS(pc_plus_1, if_is_uncond_jmp, if_jmp_target, ex_branch_taken, ex_alu_result, 
            mem_branch_taken, mem_int_branch, mem_read_data, reset_state, memory_data_out,
            restored_pc, ctrl_flow_stall, int_state)
    BEGIN
        IF reset_state = '1' THEN
            -- After reset, PC=0, memory_data_out contains the reset vector address
            pc_next <= memory_data_out;  -- Jump to reset vector address
        ELSIF int_state = '1' THEN
            -- INT: Jump to handler address (vector read from memory)
            pc_next <= memory_data_out;
        ELSIF mem_branch_taken = '1' THEN
            -- RET/RTI: Jump to restored PC from stack
            pc_next <= restored_pc; 
        ELSIF ex_branch_taken = '1' THEN
            pc_next <= ex_alu_result; 
        ELSIF if_is_uncond_jmp = '1' AND ctrl_flow_stall = '0' THEN
            pc_next <= if_jmp_target;
        ELSE
            pc_next <= pc_plus_1;
        END IF;
    END PROCESS;

    -- Reset state machine - clears after first cycle
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reset_state <= '1';  -- Enter reset vector fetch state
        ELSIF rising_edge(clk) THEN
            IF reset_state = '1' THEN
                reset_state <= '0';  -- Clear after one cycle (vector has been read)
            END IF;
        END IF;
    END PROCESS;

    -- PC and IF/ID enable signals are defined later with halted logic

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

    ----------------------------------------------------------------------------
    -- 2. DECODE STAGE
    ----------------------------------------------------------------------------
    id_opcode <= id_inst(31 DOWNTO 27);
    id_r1     <= id_inst(26 DOWNTO 24); 
    id_r2     <= id_inst(23 DOWNTO 21); 
    id_w <= id_inst(20 DOWNTO 18);

    -- Data Hazard Detection Logic (Load-Use)
    stall <= '1' WHEN (ex_mem_read = '1' AND 
                    (id_r1 = ex_w_addr_dest OR id_r2 = ex_w_addr_dest)) 
            ELSE '0';
    
    -- Combined stall signal (data hazard OR control flow stall)
    -- Note: ctrl_flow_stall already handled in pc_write_sig and if_id_en_sig
    
    id_reg_write_mux   <= c_reg_write   WHEN stall = '0' ELSE '0';
    id_reg_write_2_mux <= c_reg_write_2 WHEN stall = '0' ELSE '0';
    id_mem_write_mux   <= c_mem_write   WHEN stall = '0' ELSE '0';
    id_mem_read_mux    <= c_mem_read    WHEN stall = '0' ELSE '0';
    id_alu_src_b_mux   <= c_alu_src_b   WHEN stall = '0' ELSE '0';
    id_sp_write_mux    <= c_sp_write    WHEN stall = '0' ELSE '0';
    id_is_stack_mux    <= c_is_stack    WHEN stall = '0' ELSE '0';
    id_flags_en_mux    <= c_flags_en    WHEN stall = '0' ELSE '0';
    id_branch_type_mux <= c_branch_type WHEN stall = '0' ELSE "000";
    id_out_en_mux      <= c_out_en      WHEN stall = '0' ELSE '0';

    -- Master PC and IF/ID Enable Logic
    -- Freeze if we have a Hazard (stall), but allow branches to override
    -- Also reset_state keeps PC updating and IF/ID frozen during reset vector fetch
    -- Freeze completely when halted
    -- Also consider control flow stall and int_state
    -- IMPORTANT: When irq_req='1', we need to HOLD PC but ALLOW IF/ID to capture the INT
    pc_write_sig <= '0' WHEN halted = '1' ELSE
                    '0' WHEN irq_req = '1' ELSE  -- Hold PC when injecting interrupt
                    ((NOT if_stall AND NOT stall AND NOT ctrl_flow_stall) OR ex_branch_taken OR mem_branch_taken OR int_state OR reset_state);
    if_id_en_sig <= '0' WHEN halted = '1' ELSE
                    '1' WHEN irq_req = '1' ELSE  -- Allow IF/ID to capture INT instruction when irq_req
                    (NOT if_stall AND NOT stall AND NOT reset_state AND NOT ctrl_flow_stall AND NOT int_state);

    id_r1_mux <= id_w WHEN (id_opcode = OP_PUSH OR id_opcode = OP_NOT OR id_opcode = OP_INC OR id_opcode = OP_OUT) 
                 ELSE id_r1;

    id_imm_ext <= std_logic_vector(resize(unsigned(id_inst(15 DOWNTO 0)), 32));
    
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
        hlt_en => c_hlt_en
    );
    
    -- Halt latch - once HLT is decoded, freeze the processor until reset
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            halted <= '0';
        ELSIF rising_edge(clk) THEN
            IF c_hlt_en = '1' THEN
                halted <= '1';
            END IF;
        END IF;
    END PROCESS;
    
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

    -- SP Forwarding: Use newest SP value from pipeline if stack op is in flight
    sp_forwarded <= ex_sp_side_result WHEN (ex_sp_write = '1') ELSE  -- Forward from EX stage
                    mem_sp_new_val    WHEN (mem_sp_write = '1') ELSE -- Forward from MEM stage
                    sp_current;                                       -- No forwarding needed

    U_ID_EX: ID_EX_Reg PORT MAP (
        clk => clk, 
        rst => rst_id_ex,
        en => '1',
        reg_write_in => id_reg_write_mux,
        reg_write_2_in => id_reg_write_2_mux,
        wb_sel_in => c_wb_sel, mem_write_in => c_mem_write, mem_read_in => c_mem_read,
        out_en_in => id_out_en_mux, rti_en_in => c_rti_en,
        alu_sel_in => c_alu_sel, alu_src_b_in => id_alu_src_b_mux,
        is_std_in => c_is_std, sp_write_in => id_sp_write_mux,
        is_stack_in => id_is_stack_mux,
        branch_type_in => id_branch_type_mux,
        flags_en_in => id_flags_en_mux,
        port_sel_in => c_port_sel,
        pc_in => id_pc, r_data1_in => id_r_data1, r_data2_in => id_r_data2,
        imm_in => id_imm_or_port, sp_val_in => sp_forwarded,  -- Use forwarded SP
        r_addr1_in => id_r1_mux, r_addr2_in => id_r2, rdst_addr_in => id_w,
        
        reg_write_out => ex_reg_write, reg_write_2_out => ex_reg_write_2,
        wb_sel_out => ex_wb_sel, mem_write_out => ex_mem_write, mem_read_out => ex_mem_read,
        out_en_out => ex_out_en, rti_en_out => ex_rti_en,
        alu_sel_out => ex_alu_sel, alu_src_b_out => ex_alu_src_b,
        is_std_out => ex_is_std, sp_write_out => ex_sp_write, is_stack_out => ex_is_stack,
        branch_type_out => ex_branch_type,
        flags_en_out => ex_flags_en,
        
        pc_out => ex_pc, r_data1_out => ex_r_data1, r_data2_out => ex_r_data2,
        imm_out => ex_imm_ext, sp_val_out => ex_sp_val,
        r_addr1_out => ex_r_addr1, r_addr2_out => ex_r_addr2, rdst_addr_out => ex_w_addr_dest
    );

    ----------------------------------------------------------------------------
    -- 3. EXECUTE STAGE
    ----------------------------------------------------------------------------
    -- CCR Update Process
    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            ccr <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            -- PRIORITY 1: Handle the Branch Clear SYNCHRONOUSLY
            IF ex_branch_taken = '1' THEN
            ccr <= (OTHERS => '0'); -- Clear flags for the NEXT cycle
            
        -- PRIORITY 2: Normal Flag Update from ALU
        ELSIF ex_flags_en = '1' THEN
            ccr <= ex_zero & ex_neg & ex_carry;
        END IF;
    END IF;
    END PROCESS;

    -- Branch Resolution
    PROCESS(ex_branch_type, ccr)
    BEGIN
        ex_branch_taken <= '0';
        CASE ex_branch_type IS
            WHEN "001" => ex_branch_taken <= ccr(2); -- JZ (Check Saved Z flag)
            WHEN "010" => ex_branch_taken <= ccr(1); -- JN (Check Saved N flag)
            WHEN "011" => ex_branch_taken <= ccr(0); -- JC (Check Saved C flag)
            WHEN OTHERS => ex_branch_taken <= '0';
        END CASE;
    END PROCESS;

    -- Forwarding Unit Instantiation
    U_ForwardingUnit: ForwardingUnit PORT MAP (
        id_ex_rs1 => ex_r_addr1,
        id_ex_rs2 => ex_r_addr2,
        ex_mem_rd => mem_w_addr_dest,
        ex_mem_reg_write => mem_reg_write,
        mem_wb_rd => wb_w_addr_dest,
        mem_wb_reg_write => wb_reg_write,
        forward_a => forward_a_sel,
        forward_b => forward_b_sel
    );

    -- MUX for ALU Operand A
    ex_src_a <= mem_alu_result WHEN forward_a_sel = "10" ELSE -- From EX/MEM stage
                wb_write_data  WHEN forward_a_sel = "01" ELSE -- From MEM/WB stage
                ex_r_data1;                                   -- From Register File 

    -- 1. First, find the "Correct" value of the register (considering hazards)
    ex_r2_forwarded <= mem_alu_result WHEN forward_b_sel = "10" ELSE 
                       wb_write_data   WHEN forward_b_sel = "01" ELSE 
                       ex_r_data2;

    -- 2. Second, choose between THAT "Correct" register value OR the Immediate
    ex_src_b <= ex_imm_ext WHEN ex_alu_src_b = '1' ELSE 
                ex_r2_forwarded;   -- Default: Use Register

    U_ALU: ALU PORT MAP (
        SrcA => ex_src_a, SrcB => ex_src_b, ALU_Sel => ex_alu_sel,
        ALU_Result => ex_alu_result, Zero => ex_zero, Negative => ex_neg, Carry => ex_carry
    );
    
    -- For INT, route vector address through ALU result path to MEM stage
    -- This way mem_alu_result will contain the vector address when INT is in MEM stage
    ex_alu_result_muxed <= int_vector_addr WHEN (ex_branch_type = "111") ELSE  -- INT: use vector addr
                           ex_alu_result;                                       -- Normal: use ALU result
    
    ex_sp_side_result <= std_logic_vector(unsigned(ex_sp_val) + 1) WHEN (ex_mem_read = '1' AND ex_is_stack = '1') ELSE -- POP
                         std_logic_vector(unsigned(ex_sp_val) - 1) WHEN (ex_mem_write = '1' AND ex_is_stack = '1') ELSE -- PUSH
                         ex_sp_val;

    -- =========================================================================
    -- STACK PACKER FOR CALL/INT
    -- =========================================================================
    -- Detect CALL and INT opcodes in EX stage
    is_call_sig <= '1' WHEN (ex_branch_type = "101") ELSE '0';  -- CALL branch type
    is_int_sig  <= '1' WHEN (ex_branch_type = "111") ELSE '0';  -- INT branch type
    
    -- Compute PC+1 for CALL return address
    ex_pc_plus_1 <= std_logic_vector(unsigned(ex_pc) + 1);
    
    U_StackPacker: StackPacker PORT MAP (
        is_call       => is_call_sig,
        is_int        => is_int_sig,
        pc_current    => ex_pc,
        pc_plus_1     => ex_pc_plus_1,
        ccr_flags     => ccr,
        normal_data   => ex_src_a,  -- Normal push data (with forwarding)
        mem_write_data => packed_stack_data,
        mem_read_data => mem_read_data,
        restored_pc   => restored_pc,
        restored_ccr  => restored_ccr
    );

    
    -- For PUSH: Use packed stack data for CALL/INT, otherwise use forwarded register
    ex_write_data <= packed_stack_data WHEN (ex_is_stack = '1' AND ex_mem_write = '1' AND (is_call_sig = '1' OR is_int_sig = '1')) ELSE
                     ex_src_a          WHEN (ex_is_stack = '1' AND ex_mem_write = '1') ELSE 
                     ex_r2_forwarded;
    
    -- Fast bits tracking through pipeline (extract from branch_type encoding)
    -- Since we're using branch_type, we can derive fast bits:
    -- branch_type 101 = CALL -> fast 11
    -- branch_type 110 = RET/RTI -> fast 10  
    -- branch_type 111 = INT -> fast 01
    ex_fast_bits  <= "11" WHEN ex_branch_type = "101" ELSE  -- CALL
                     "10" WHEN ex_branch_type = "110" ELSE  -- RET/RTI
                     "01" WHEN ex_branch_type = "111" ELSE  -- INT
                     "00";
    mem_fast_bits <= "11" WHEN mem_branch_type = "101" ELSE -- CALL
                     "10" WHEN mem_branch_type = "110" ELSE -- RET/RTI
                     "01" WHEN mem_branch_type = "111" ELSE -- INT
                     "00";

    U_EX_MEM: EX_MEM_Reg PORT MAP (
        clk => clk, 
        rst => rst_ex_mem,
        en => '1',
        reg_write_in => ex_reg_write, reg_write_2_in => ex_reg_write_2,
        wb_sel_in => ex_wb_sel, mem_write_in => ex_mem_write, mem_read_in => ex_mem_read,
        out_en_in => ex_out_en, rti_en_in => ex_rti_en,
        sp_write_in => ex_sp_write, is_stack_in => ex_is_stack,
        branch_type_in => ex_branch_type, 
        
        pc_in => ex_pc, alu_res_in => ex_alu_result_muxed, r_data2_in => ex_write_data,
        sp_new_val_in => ex_sp_side_result, sp_val_in => ex_sp_val,
        rdst_addr_in => ex_w_addr_dest,
        rsrc_addr_in => ex_r_addr1,
        
        reg_write_out => mem_reg_write, reg_write_2_out => mem_reg_write_2,
        wb_sel_out => mem_wb_sel, mem_write_out => mem_mem_write, mem_read_out => mem_mem_read,
        out_en_out => mem_out_en, rti_en_out => mem_rti_en,
        sp_write_out => mem_sp_write, is_stack_out => mem_is_stack,
        branch_type_out => mem_branch_type, 
        
        pc_out => mem_pc, alu_res_out => mem_alu_result, r_data2_out => mem_write_data,
        sp_new_val_out => mem_sp_new_val, sp_val_out => mem_sp_val,
        rdst_addr_out => mem_w_addr_dest,
        rsrc_addr_out => mem_w_addr_swap
    );

    ----------------------------------------------------------------------------
    -- 4. MEMORY STAGE
    ----------------------------------------------------------------------------
    
    -- Memory address for INT: need to read from vector address
    -- For INT in MEM stage: after pushing PC+CCR, we need to read the vector
    -- This requires a 2-cycle operation: first push, then read vector
    -- For simplicity, we'll handle INT branch in EX stage using the vector unit
    
    U_Memory: Memory PORT MAP (
        clk => clk,
        addr => memory_addr, data_in => memory_data_in, we => memory_we,
        data_out => memory_data_out
    );
    mem_read_data <= memory_data_out;
    -- For swap operations, use the r_data2_out from EX_MEM (which is mem_write_data)
    mem_swap_data <= mem_write_data;

    -- Check for RET/RTI (branch_type = 110)
    mem_branch_taken <= '1' WHEN (mem_branch_type = "110") ELSE '0';
    
    -- Check for INT - branch happens on the 2nd cycle when vector is read
    -- int_state = '1' means we're reading the vector this cycle
    mem_int_branch <= int_state;
    
    -- =========================================================================
    -- CCR RESTORATION FOR RTI
    -- =========================================================================
    -- When RTI is in MEM stage, restore CCR from the popped stack value
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- ccr handled in EX stage process
        ELSIF rising_edge(clk) THEN
            IF mem_rti_en = '1' THEN
                -- Restore CCR from stack (bits 14:12 of mem_read_data)
                ccr <= restored_ccr;
            END IF;
        END IF;
    END PROCESS;

    U_MEM_WB: MEM_WB_Reg PORT MAP (
        clk => clk, rst => rst, en => '1',
        reg_write_in => mem_reg_write, reg_write_2_in => mem_reg_write_2,
        wb_sel_in => mem_wb_sel,
        out_en_in => mem_out_en,
        pc_in => mem_pc, mem_data_in => mem_read_data, alu_res_in => mem_alu_result,
        rdst_addr_in => mem_w_addr_dest, rsrc_addr_in => mem_w_addr_swap, r_data2_in => mem_swap_data,
        
        reg_write_out => wb_reg_write, reg_write_2_out => wb_reg_write_2,
        wb_sel_out => wb_wb_sel,
        out_en_out => wb_out_en,
        pc_out => wb_pc, mem_data_out => wb_mem_data, alu_res_out => wb_alu_result,
        rdst_addr_out => wb_w_addr_dest, rsrc_addr_out => wb_w_addr_swap, r_data2_out => wb_swap_data
    );

    ----------------------------------------------------------------------------
    -- 5. WRITE BACK
    ---------------------------------------------------------------------------- 
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF wb_out_en = '1' THEN 
                output_port <= wb_alu_result; 
            END IF;
        END IF;
    END PROCESS;
    
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
    out_en <= wb_out_en;

END Structure;