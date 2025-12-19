LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.Processor_Pkg.all;

ENTITY Processor IS
    PORT (
        clk           : IN  std_logic;
        rst           : IN  std_logic;
        
        -- Debug Outputs (Detailed Pipeline Trace)
        debug_pc      : OUT std_logic_vector(31 DOWNTO 0); -- Same as debug_if_pc
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
        -- Hardware interrupt
        hardware_interrupt : IN std_logic;
        -- Output Port
        output_port   : OUT std_logic_vector(31 DOWNTO 0);
        out_en        : OUT std_logic
    );
END Processor;

ARCHITECTURE Structure OF Processor IS

    ----------------------------------------------------------------------------
    -- COMPONENTS
    ----------------------------------------------------------------------------
    COMPONENT ControlUnit
    PORT (
        opcode      : IN  std_logic_vector(4 DOWNTO 0);
        reg_write   : OUT std_logic;
        wb_sel      : OUT std_logic; 
        mem_write   : OUT std_logic;
        mem_read    : OUT std_logic;
        alu_sel     : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b   : OUT std_logic;
        branch_type : OUT std_logic_vector(2 DOWNTO 0);
        sp_write    : OUT std_logic;
        is_stack    : OUT std_logic;
        rti_en      : OUT std_logic;  
        ccr_z_en    : OUT std_logic;
        ccr_n_en    : OUT std_logic;
        ccr_c_en    : OUT std_logic;
        reg_write_2 : OUT std_logic;
        out_en      : OUT std_logic;
        port_sel    : OUT std_logic
    );
    END COMPONENT;

    COMPONENT RegisterFile
    PORT(
        clk           : IN  std_logic;
        rst           : IN  std_logic;
        reg_write_en1 : IN  std_logic;
        reg_write_en2 : IN  std_logic; -- Not used in simple pipeline
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
    -- SP component
    COMPONENT SP
    PORT (
        clk      : IN  std_logic;
        rst      : IN  std_logic;
        sp_write : IN  std_logic;
        sp_in    : IN  std_logic_vector(31 DOWNTO 0);
        sp_out   : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;
    -- PIPELINE REGISTERS
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
        reg_write_in, wb_sel_in, mem_write_in, mem_read_in : IN std_logic;
        alu_sel_in : IN std_logic_vector(2 DOWNTO 0);
        alu_src_b_in : IN std_logic;
        is_std_in  : IN std_logic;
        sp_write_in  : IN std_logic; -- NEW
        is_stack_in  : IN std_logic; -- NEW
        branch_type_in : IN std_logic_vector(2 DOWNTO 0); -- NEW
        ccr_z_en_in, ccr_n_en_in, ccr_c_en_in : IN std_logic;
        rti_en_in : IN std_logic;
        
        pc_in, r_data1_in, r_data2_in, imm_extended_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in    : IN std_logic_vector(31 DOWNTO 0); -- NEW
        r_addr1_in, r_addr2_in, w_addr_dest_in : IN std_logic_vector(2 DOWNTO 0);
        
        reg_write_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        alu_sel_out : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b_out : OUT std_logic;
        is_std_out  : OUT std_logic;
        sp_write_out  : OUT std_logic; -- NEW
        is_stack_out  : OUT std_logic; -- NEW
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0); -- NEW
        ccr_z_en_out, ccr_n_en_out, ccr_c_en_out : OUT std_logic;
        rti_en_out  : OUT std_logic;
        
        pc_out, r_data1_out, r_data2_out, imm_extended_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_val_out    : OUT std_logic_vector(31 DOWNTO 0); -- NEW
        r_addr1_out, r_addr2_out, w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT EX_MEM_Reg
    PORT (
        clk, rst, en : IN std_logic;
        reg_write_in, wb_sel_in, mem_write_in, mem_read_in : IN std_logic;
        sp_write_in  : IN std_logic; -- NEW
        is_stack_in  : IN std_logic; -- NEW
        branch_type_in : IN std_logic_vector(2 DOWNTO 0); -- NEW
        pc_in         : IN  std_logic_vector(31 DOWNTO 0); -- NEW
        alu_result_in, write_data_in : IN std_logic_vector(31 DOWNTO 0);
        sp_new_val_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in     : IN std_logic_vector(31 DOWNTO 0); -- NEW
        w_addr_dest_in : IN std_logic_vector(2 DOWNTO 0);
        rti_en_in      : IN std_logic;
        
        reg_write_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        sp_write_out  : OUT std_logic; -- NEW
        is_stack_out  : OUT std_logic; -- NEW
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0); -- NEW
        pc_out          : OUT std_logic_vector(31 DOWNTO 0); -- NEW
        alu_result_out, write_data_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_new_val_out : OUT std_logic_vector(31 DOWNTO 0); -- NEW
        sp_val_out     : OUT std_logic_vector(31 DOWNTO 0); -- NEW
        w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0);
        rti_en_out      : OUT std_logic
    );
    END COMPONENT;
    
    COMPONENT MEM_WB_Reg
    PORT (
        clk, rst, en : IN std_logic;
        reg_write_in, wb_sel_in : IN std_logic;
        pc_in          : IN  std_logic_vector(31 DOWNTO 0); -- NEW
        mem_data_in, alu_result_in : IN std_logic_vector(31 DOWNTO 0);
        w_addr_dest_in : IN std_logic_vector(2 DOWNTO 0);
        
        reg_write_out, wb_sel_out : OUT std_logic;
        pc_out          : OUT std_logic_vector(31 DOWNTO 0); -- NEW
        mem_data_out, alu_result_out : OUT std_logic_vector(31 DOWNTO 0);
        w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT Sequencer
    PORT (
        clk                 : IN  std_logic;
        rst                 : IN  std_logic;
        hardware_interrupt   : IN  std_logic;
        mem_branch_type      : IN  std_logic_vector(2 DOWNTO 0);
        if_inst_raw          : IN  std_logic_vector(31 DOWNTO 0);
        rst_init_pending     : OUT std_logic;
        rst_load_pc          : OUT std_logic;
        hw_int_pending       : OUT std_logic;
        int_phase            : OUT std_logic;
        ex_mem_en            : OUT std_logic
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
    ----------------------------------------------------------------------------
    -- SIGNALS
    ----------------------------------------------------------------------------
    
    -- STAGE: IF
    SIGNAL pc_current, pc_next, pc_plus_1 : std_logic_vector(31 DOWNTO 0);
    SIGNAL if_inst : std_logic_vector(31 DOWNTO 0);
    SIGNAL if_stall : std_logic;
    
    -- STAGE: ID
    SIGNAL id_pc, id_inst : std_logic_vector(31 DOWNTO 0);
    SIGNAL id_opcode : std_logic_vector(4 DOWNTO 0);
    SIGNAL id_r1, id_r2, id_w : std_logic_vector(2 DOWNTO 0);
    SIGNAL id_imm_ext : std_logic_vector(31 DOWNTO 0);
    SIGNAL id_r_data1, id_r_data2 : std_logic_vector(31 DOWNTO 0);
    SIGNAL id_r1_mux : std_logic_vector(2 DOWNTO 0); -- NEW Mux signal
    
    -- Control Signals in ID
    SIGNAL c_reg_write, c_wb_sel, c_mem_write, c_mem_read, c_alu_src_b : std_logic;
    SIGNAL c_alu_sel : std_logic_vector(2 DOWNTO 0);
    SIGNAL c_branch_type : std_logic_vector(2 DOWNTO 0);
    SIGNAL c_is_std : std_logic; -- NEW
    SIGNAL c_is_stack, c_rti_en : std_logic; -- NEW
    SIGNAL c_ccr_z_en, c_ccr_n_en, c_ccr_c_en : std_logic;

    
    -- STAGE: EX
    SIGNAL ex_reg_write, ex_wb_sel, ex_mem_write, ex_mem_read, ex_alu_src_b : std_logic;
    SIGNAL ex_alu_sel : std_logic_vector(2 DOWNTO 0);
    SIGNAL ex_is_std  : std_logic; -- NEW
    SIGNAL ex_is_stack : std_logic; -- NEW
    SIGNAL ex_branch_type : std_logic_vector(2 DOWNTO 0); -- NEW
    SIGNAL ex_pc, ex_r_data1, ex_r_data2, ex_imm_ext : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_r_addr1, ex_r_addr2, ex_w_addr_dest : std_logic_vector(2 DOWNTO 0);
    SIGNAL ex_write_data : std_logic_vector(31 DOWNTO 0); -- NEW for STD swap
    SIGNAL ex_pc_plus_1 : std_logic_vector(31 DOWNTO 0); -- NEW
    SIGNAL ex_ccr_z_en, ex_ccr_n_en, ex_ccr_c_en, ex_rti_en : std_logic;
    
    SIGNAL ex_src_a, ex_src_b : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_alu_result : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_int_addr   : std_logic_vector(31 DOWNTO 0); -- NEW
    SIGNAL ex_alu_result_final : std_logic_vector(31 DOWNTO 0); -- NEW
    SIGNAL ex_zero, ex_neg, ex_carry : std_logic;
    
    -- STAGE: MEM
    SIGNAL mem_reg_write, mem_wb_sel, mem_mem_write, mem_mem_read, mem_rti_en : std_logic;
    SIGNAL mem_is_stack : std_logic; -- NEW
    SIGNAL mem_branch_type : std_logic_vector(2 DOWNTO 0); -- NEW
    SIGNAL mem_pc : std_logic_vector(31 DOWNTO 0); -- NEW
    SIGNAL mem_alu_result, mem_write_data : std_logic_vector(31 DOWNTO 0);
    SIGNAL mem_sp_new_val : std_logic_vector(31 DOWNTO 0); -- NEW
    SIGNAL mem_w_addr_dest : std_logic_vector(2 DOWNTO 0);
    SIGNAL mem_read_data : std_logic_vector(31 DOWNTO 0);
    
    -- STAGE: WB
    SIGNAL wb_reg_write, wb_wb_sel : std_logic;
    SIGNAL wb_pc : std_logic_vector(31 DOWNTO 0); -- NEW
    SIGNAL wb_mem_data, wb_alu_result : std_logic_vector(31 DOWNTO 0);
    SIGNAL wb_w_addr_dest : std_logic_vector(2 DOWNTO 0);
    SIGNAL wb_write_data : std_logic_vector(31 DOWNTO 0);
    
    -- MEMORY ARBITER
    SIGNAL memory_addr : std_logic_vector(31 DOWNTO 0);
    SIGNAL memory_we : std_logic;
    SIGNAL memory_data_in : std_logic_vector(31 DOWNTO 0);
    SIGNAL memory_data_out : std_logic_vector(31 DOWNTO 0);
    SIGNAL mem_busy : std_logic;
    SIGNAL ex_mem_en_sig : std_logic; -- Control EX/MEM Stall

    -- Signals for Static Port Mapping
    SIGNAL pc_write_sig : std_logic;
    SIGNAL if_id_en_sig : std_logic;
    SIGNAL id_inst_mux  : std_logic_vector(31 DOWNTO 0); -- Optimization
    -- Branch Taken Logic
    SIGNAL ex_branch_taken : std_logic;
    
    -- Reset Initialization
    SIGNAL rst_init_pending, rst_load_pc : std_logic;
    SIGNAL hw_int_pending   : std_logic;

    -- SP section
    SIGNAL sp_current : std_logic_vector(31 DOWNTO 0);
    SIGNAL id_sp_val, ex_sp_val, mem_sp_val : std_logic_vector(31 DOWNTO 0);
    SIGNAL c_sp_write, ex_sp_write, mem_sp_write : std_logic;
    -- Logic for SP math
    SIGNAL ex_sp_side_result : std_logic_vector(31 DOWNTO 0);
    
    -- Stall Mux Signals
    SIGNAL pipe_reg_write, pipe_mem_write, pipe_mem_read, pipe_sp_write, pipe_is_stack : std_logic;
    SIGNAL pipe_ccr_z_en, pipe_ccr_n_en, pipe_ccr_c_en, pipe_rti_en : std_logic;
    
    -- INT Multi-cycle tracking
    SIGNAL int_phase : std_logic := '0';

    -- Restored PC
    SIGNAL mem_restored_pc : std_logic_vector(31 DOWNTO 0);
    SIGNAL force_nop_sig   : std_logic;
    SIGNAL ccr_save, ccr_restore : std_logic;

    -- CCR Signals
    SIGNAL ccr_write_z, ccr_write_n, ccr_write_c : std_logic;
    SIGNAL ccr_z_in, ccr_n_in, ccr_c_in : std_logic;
    SIGNAL ccr_out : std_logic_vector(3 DOWNTO 0);

BEGIN
    
    -- Unit for managing Reset and Interrupt sequences
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
    -- Assign Signals for Port Map
    pc_write_sig <= '1'
        WHEN (rst_load_pc = '1' OR (if_stall = '0') OR -- If we're not stalling
            (mem_branch_type = "110") OR -- RET/RTI Jump
            (mem_branch_type = "111" AND int_phase = '1')) -- Or if we're in INT Phase 1
        ELSE '0'; -- STALL 
    
    -- Flush Logic removed in favor of NOP injection
    if_id_en_sig <= NOT if_stall;

    ----------------------------------------------------------------------------
    -- 1. FETCH STAGE
    ----------------------------------------------------------------------------
    -- Arbitrate Memory: IF MEM Stage needs it, give it.
    mem_busy <= '1' WHEN (mem_mem_write = '1' OR mem_mem_read = '1') ELSE '0';
    
    -- Mux for Memory Inputs
    memory_addr <= (OTHERS => '0')    WHEN rst_init_pending = '1' ELSE -- Fetch from 0 during Reset Init
                   mem_sp_val         WHEN (mem_is_stack = '1' AND mem_mem_write = '1' AND int_phase = '0') ELSE -- PUSH or INT Phase 0 (Push)
                   mem_alu_result     WHEN (mem_branch_type = "111" AND int_phase = '1')                   ELSE -- INT Phase 1 (Vector Fetch)
                   mem_sp_new_val     WHEN (mem_is_stack = '1' AND mem_mem_read = '1')                      ELSE -- POP/RET/RTI
                   pc_current;    -- Default (LDD/STD/etc) fetch instruction basically
    
    -- Memory WE logic (Only write in INT Phase 0, or normal writes)
    memory_we <= '1' WHEN (mem_mem_write = '1' AND (mem_branch_type /= "111" OR int_phase = '0')) ELSE '0';
    
    -- Memory Data In
    memory_data_in <= mem_write_data;
    
    -- Stalling Fetch if Memory Busy or INT is in progress (waiting for jump)
    if_stall <= '1' WHEN (rst_init_pending = '1' OR mem_busy = '1' OR (mem_branch_type = "111" AND int_phase = '0')) ELSE '0'; 
    
    -- PC Logic
    pc_plus_1 <= std_logic_vector(unsigned(pc_current) + 1);
    -- Use full 32-bit PC (Flags are now handled internally by CCR shadow reg)
    mem_restored_pc <= mem_read_data;
    pc_next   <= mem_restored_pc WHEN (rst_load_pc = '1' OR mem_branch_type = "110" OR (mem_branch_type = "111" AND int_phase = '1')) ELSE -- Reset/RET/RTI/INT Jump Target
                 ex_imm_ext      WHEN (ex_branch_taken = '1') ELSE -- JMP/CALL/JZ/JN/JC
                 pc_current      WHEN (force_nop_sig = '1') ELSE -- Force NOP
                 pc_plus_1; -- Default Next
    -- TODO: Add Branching Mux Here (using EX branching results)
    
    U_PC: PC PORT MAP (
        clk => clk, rst => rst,
        pc_write => pc_write_sig, -- Fixed invalid expression
        pc_inc => '0', -- We calc externally
        pc_in => pc_next,
        pc_out => pc_current
    );
    
    -- IF Inst Injection for RTI/INT (Marker Bits 17:16)
    if_inst <= x"00000000" WHEN (force_nop_sig = '1' OR ex_branch_taken = '1') ELSE memory_data_out;
    
    -- IF/ID Reg
    U_IF_ID: IF_ID_Reg PORT MAP (
        clk => clk, rst => rst, en => if_id_en_sig,
        pc_in => pc_current, inst_in => if_inst, -- Direct instruction
        pc_out => id_pc, inst_out => id_inst
    );
    force_nop_sig <= '1' WHEN (id_inst(16 downto 15) = "10" OR id_inst(16 downto 15) = "01") ELSE '0';
    -- Logic moved to InterruptControlUnit

    ----------------------------------------------------------------------------
    -- 2. DECODE STAGE
    ----------------------------------------------------------------------------
    id_opcode <= id_inst_mux(31 DOWNTO 27);
    id_r1     <= id_inst_mux(26 DOWNTO 24); -- Rsrc1
    id_r2     <= id_inst_mux(23 DOWNTO 21); -- Rsrc2
    id_w      <= id_inst_mux(20 DOWNTO 18); -- Rdst
    
    -- Instruction Mux for Hardware Interrupt injection
    -- Opcodes: INT is 11000 (0x18). 
    id_inst_mux <= x"C0040000" WHEN (hw_int_pending = '1' AND if_stall = '0') ELSE id_inst;
    
    -- Mux for Immediate or Input Port (Routing Input via Immediate Path)
    -- HW INT gets a special internal immediate value with bit 31 set to flag it as hardware-triggered.
    id_imm_ext  <= x"80000001" WHEN (hw_int_pending = '1' AND if_stall = '0') ELSE
                   input_port  WHEN id_opcode = OP_IN  ELSE
                   std_logic_vector(resize(unsigned(id_inst_mux(15 DOWNTO 0)), 32)) WHEN (id_opcode = OP_LDM OR id_opcode = OP_INT) ELSE
                   std_logic_vector(resize(signed(id_inst_mux(15 DOWNTO 0)), 32));
    
    -- Mux for Read Address 1 (Fix for PUSH/NOT/INC where 'Rdst' field holds the Source Reg)
    -- Assembler puts the reg in bits 20-18 (id_w) for these instructions.
    id_r1_mux <= id_w WHEN (id_opcode = OP_PUSH OR id_opcode = OP_NOT OR id_opcode = OP_INC OR id_opcode = OP_OUT) 
                 ELSE id_r1;

    U_Control: ControlUnit PORT MAP (
        opcode => id_opcode,
        reg_write => c_reg_write, wb_sel => c_wb_sel,
        mem_write => c_mem_write, mem_read => c_mem_read,
        alu_sel => c_alu_sel, alu_src_b => c_alu_src_b,
        branch_type => c_branch_type, sp_write => c_sp_write,
        is_stack => c_is_stack,
        ccr_z_en => c_ccr_z_en, ccr_n_en => c_ccr_n_en, ccr_c_en => c_ccr_c_en,
        rti_en => c_rti_en,
        port_sel => OPEN, out_en => out_en, reg_write_2 => OPEN
    );

    -- Detect STD Opcode
    c_is_std <= '1' WHEN id_opcode = OP_STD ELSE '0';
    
    U_RegFile: RegisterFile PORT MAP (
        clk => clk, rst => rst,
        reg_write_en1 => wb_reg_write, -- Write from WB Stage
        reg_write_en2 => '0',
        read_addr1 => id_r1_mux, read_addr2 => id_r2,
        write_addr1 => wb_w_addr_dest, write_data1 => wb_write_data,
        write_addr2 => (others=>'0'), write_data2 => (others=>'0'),
        read_data1 => id_r_data1, read_data2 => id_r_data2
    );
    U_SP: SP PORT MAP (
    clk      => clk,
    rst      => rst,
    sp_write => mem_sp_write, -- Updated from the MEM stage (Writeback)
    sp_in    => mem_sp_new_val, -- Usually the result of SP +/- 1
    sp_out   => sp_current
);


    
    -- STALL LOGIC: Insert Bubble (NOP) if stalling or branching
    pipe_reg_write <= '0' WHEN (if_stall = '1' OR ex_branch_taken = '1') ELSE c_reg_write;
    pipe_mem_write <= '0' WHEN (if_stall = '1' OR ex_branch_taken = '1') ELSE c_mem_write;
    pipe_mem_read  <= '0' WHEN (if_stall = '1' OR ex_branch_taken = '1') ELSE c_mem_read;
    pipe_sp_write  <= '0' WHEN (if_stall = '1' OR ex_branch_taken = '1') ELSE c_sp_write;
    pipe_is_stack  <= '0' WHEN (if_stall = '1' OR ex_branch_taken = '1') ELSE c_is_stack;
    pipe_ccr_z_en  <= '0' WHEN (if_stall = '1' OR ex_branch_taken = '1') ELSE c_ccr_z_en;
    pipe_ccr_n_en  <= '0' WHEN (if_stall = '1' OR ex_branch_taken = '1') ELSE c_ccr_n_en;
    pipe_ccr_c_en  <= '0' WHEN (if_stall = '1' OR ex_branch_taken = '1') ELSE c_ccr_c_en;
    pipe_rti_en    <= '0' WHEN (if_stall = '1' OR ex_branch_taken = '1') ELSE c_rti_en;
    
    U_ID_EX: ID_EX_Reg PORT MAP (
        clk => clk, rst => rst, en => '1',
        reg_write_in => pipe_reg_write, wb_sel_in => c_wb_sel, 
        mem_write_in => pipe_mem_write, mem_read_in => pipe_mem_read, 
        alu_src_b_in => c_alu_src_b, alu_sel_in => c_alu_sel,
        is_std_in => c_is_std,
        sp_write_in  => pipe_sp_write, -- Squashed
        is_stack_in  => pipe_is_stack, -- Squashed
        branch_type_in => c_branch_type,
        ccr_z_en_in => pipe_ccr_z_en, ccr_n_en_in => pipe_ccr_n_en, ccr_c_en_in => pipe_ccr_c_en,
        rti_en_in => pipe_rti_en,
        sp_val_in    => sp_current,     -- Read directly from SP register
        pc_in => id_pc, r_data1_in => id_r_data1, r_data2_in => id_r_data2, 
        imm_extended_in => id_imm_ext,
        r_addr1_in => id_r1, r_addr2_in => id_r2, w_addr_dest_in => id_w,
        
        sp_write_out => ex_sp_write,
        is_stack_out => ex_is_stack,
        branch_type_out => ex_branch_type,
        sp_val_out => ex_sp_val,
        reg_write_out => ex_reg_write, wb_sel_out => ex_wb_sel, 
        mem_write_out => ex_mem_write, mem_read_out => ex_mem_read, 
        alu_src_b_out => ex_alu_src_b, alu_sel_out => ex_alu_sel,
        is_std_out => ex_is_std,
        pc_out => ex_pc, r_data1_out => ex_r_data1, r_data2_out => ex_r_data2, 
        imm_extended_out => ex_imm_ext,
        r_addr1_out => ex_r_addr1, r_addr2_out => ex_r_addr2, w_addr_dest_out => ex_w_addr_dest,
        ccr_z_en_out => ex_ccr_z_en, ccr_n_en_out => ex_ccr_n_en, ccr_c_en_out => ex_ccr_c_en,
        rti_en_out => ex_rti_en
    );

    ----------------------------------------------------------------------------
    -- 3. EXECUTE STAGE
    ----------------------------------------------------------------------------
    ex_src_a <= ex_r_data2 WHEN ex_is_std = '1' ELSE ex_r_data1; -- Swap for STD (Base in R2)
    ex_src_b <= ex_r_data2 WHEN ex_alu_src_b = '0' ELSE ex_imm_ext;
    
    U_ALU: ALU PORT MAP (
        SrcA => ex_src_a, SrcB => ex_src_b,
        ALU_Sel => ex_alu_sel,
        ALU_Result => ex_alu_result,
        Zero => ex_zero, Negative => ex_neg, Carry => ex_carry
    );
    
    U_CCR: CCR PORT MAP (
        clk => clk, rst => rst,
        write_z => ccr_write_z, write_n => ccr_write_n, write_c => ccr_write_c,
        z_in => ccr_z_in, n_in => ccr_n_in, c_in => ccr_c_in,
        save_ccr => ccr_save, restore_ccr => ccr_restore,
        ccr_out => ccr_out
    );

    ccr_save <= '1' WHEN (ex_branch_type = "111") ELSE '0';
    ccr_restore <= ex_rti_en;

    ccr_write_z <= ex_ccr_z_en; -- Removed OR mem_rti_en as we use CCR internal restore
    ccr_write_n <= ex_ccr_n_en;
    ccr_write_c <= ex_ccr_c_en;
    
    ccr_z_in <= ex_zero;
    ccr_n_in <= ex_neg;
    ccr_c_in <= ex_carry;

    -- EX Stage logic
    ex_sp_side_result <= std_logic_vector(unsigned(ex_sp_val) + 1) WHEN (ex_mem_read = '1' AND ex_is_stack = '1') ELSE -- POP
                      std_logic_vector(unsigned(ex_sp_val) - 1) WHEN (ex_mem_write = '1' AND ex_is_stack = '1') ELSE -- PUSH/INT
                      ex_sp_val;
    
    -- ALU Result Mux for INT Vector Addr Calculation
    -- Vector Addr = index + 2. Index is in bits 15-0 (ex_imm_ext).
    -- HARDWARE INTERRUPT: Fixed at M[1] (signaled by bit 31 of ex_imm_ext)
    ex_int_addr <= x"00000001" WHEN ex_imm_ext(31) = '1' ELSE 
                   std_logic_vector(unsigned(ex_imm_ext(31 DOWNTO 0)) + 2);
    
    ex_alu_result_final <= ex_int_addr WHEN ex_branch_type = "111" ELSE ex_alu_result;

    ex_pc_plus_1 <= std_logic_vector(unsigned(ex_pc) + 1);

    -- Mux for Memory Write Data
    -- Flags are now saved internally in CCR shadow registers. Pushing full 32-bit PC.
    ex_write_data <= ex_pc WHEN (ex_mem_write = '1' AND ex_is_stack = '1' AND ex_branch_type = "111") ELSE -- INT (Save current PC)
                     ex_pc_plus_1 WHEN (ex_mem_write = '1' AND ex_is_stack = '1' AND ex_branch_type = "101") ELSE -- CALL (Save PC+1)
                     ex_r_data1    WHEN (ex_is_std = '1' OR (ex_mem_write = '1' AND ex_is_stack = '1')) ELSE 
                     ex_r_data2;

    -- Branch Condition Evaluation
    ex_branch_taken <= '1' WHEN (ex_branch_type = "001" AND ccr_out(0) = '1') ELSE -- JZ
                       '1' WHEN (ex_branch_type = "010" AND ccr_out(1) = '1') ELSE -- JN
                       '1' WHEN (ex_branch_type = "011" AND ccr_out(2) = '1') ELSE -- JC
                       '1' WHEN (ex_branch_type = "100") ELSE -- JMP
                       '1' WHEN (ex_branch_type = "101") ELSE -- CALL
                       '0';

    U_EX_MEM: EX_MEM_Reg PORT MAP (
        clk => clk, rst => rst, en => ex_mem_en_sig,
        reg_write_in => ex_reg_write, wb_sel_in => ex_wb_sel,
        mem_write_in => ex_mem_write, mem_read_in => ex_mem_read,
        sp_write_in => ex_sp_write, is_stack_in => ex_is_stack,
        branch_type_in => ex_branch_type,
        pc_in => ex_pc,
        alu_result_in => ex_alu_result_final, -- Use final result (vector addr for INT)
        write_data_in => ex_write_data,
        sp_new_val_in => ex_sp_side_result,
        sp_val_in     => ex_sp_val, -- Pass original SP for POP
        w_addr_dest_in => ex_w_addr_dest,
        rti_en_in => ex_rti_en,
        
        reg_write_out => mem_reg_write, wb_sel_out => mem_wb_sel,
        mem_write_out => mem_mem_write, mem_read_out => mem_mem_read,
        sp_write_out => mem_sp_write, is_stack_out => mem_is_stack,
        branch_type_out => mem_branch_type,
        pc_out => mem_pc,
        alu_result_out => mem_alu_result,
        write_data_out => mem_write_data,
        sp_new_val_out => mem_sp_new_val,
        sp_val_out => mem_sp_val,
        w_addr_dest_out => mem_w_addr_dest,
        rti_en_out => mem_rti_en
    );

    ----------------------------------------------------------------------------
    -- 4. MEMORY STAGE
    ----------------------------------------------------------------------------
    U_Memory: Memory PORT MAP (
        clk => clk,
        addr => memory_addr,    -- From Arbiter
        data_in => memory_data_in, -- From Arbiter
        we => memory_we,        -- From Arbiter
        data_out => memory_data_out
    );
    
    -- If MEM stage was reading, grab data. Else garbage.
    mem_read_data <= memory_data_out; 
    
    U_MEM_WB: MEM_WB_Reg PORT MAP (
        clk => clk, rst => rst, en => '1',
        reg_write_in => mem_reg_write, wb_sel_in => mem_wb_sel,
        pc_in => mem_pc,
        mem_data_in => mem_read_data, alu_result_in => mem_alu_result,
        w_addr_dest_in => mem_w_addr_dest,
        
        reg_write_out => wb_reg_write, wb_sel_out => wb_wb_sel,
        pc_out => wb_pc,
        mem_data_out => wb_mem_data, alu_result_out => wb_alu_result,
        w_addr_dest_out => wb_w_addr_dest
    );

    ----------------------------------------------------------------------------
    -- 5. WRITE BACK STAGE
    ----------------------------------------------------------------------------
    wb_write_data <= wb_alu_result WHEN wb_wb_sel = '0' ELSE wb_mem_data;

    ----------------------------------------------------------------------------
    -- DEBUG
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- DEBUG
    --------------------------------------------------------------------------    -- Debug Signal Assignments
    debug_pc       <= pc_current;
    debug_if_pc    <= pc_current;
    debug_id_pc    <= id_pc;
    debug_ex_pc    <= ex_pc;
    debug_mem_pc   <= mem_pc;
    debug_wb_pc    <= wb_pc;
    
    debug_inst     <= id_inst; -- instruction currently being decoded
    debug_reg_w_en <= wb_reg_write;
    debug_mem_w_en <= mem_mem_write;
    debug_alu      <= mem_alu_result; -- result of EX stage moving into MEM
END Structure;
