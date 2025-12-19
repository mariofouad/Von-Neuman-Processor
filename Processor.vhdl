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
        input_port    : IN  std_logic_vector(31 DOWNTO 0)

        -- Output Port
        output_port   : OUT std_logic_vector(31 DOWNTO 0)
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
        sp_write    : OUT std_logic
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
        rst     : IN  std_logic;
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
        pc_in, r_data1_in, r_data2_in, imm_extended_in : IN std_logic_vector(31 DOWNTO 0);
        r_addr1_in, r_addr2_in, w_addr_dest_in : IN std_logic_vector(2 DOWNTO 0);
        
        reg_write_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        alu_sel_out : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b_out : OUT std_logic;
        is_std_out  : OUT std_logic;
        pc_out, r_data1_out, r_data2_out, imm_extended_out : OUT std_logic_vector(31 DOWNTO 0);
        r_addr1_out, r_addr2_out, w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT EX_MEM_Reg
    PORT (
        clk, rst, en : IN std_logic;
        reg_write_in, wb_sel_in, mem_write_in, mem_read_in : IN std_logic;
        pc_in         : IN  std_logic_vector(31 DOWNTO 0); -- NEW
        alu_result_in, write_data_in : IN std_logic_vector(31 DOWNTO 0);
        w_addr_dest_in : IN std_logic_vector(2 DOWNTO 0);
        
        reg_write_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        pc_out          : OUT std_logic_vector(31 DOWNTO 0); -- NEW
        alu_result_out, write_data_out : OUT std_logic_vector(31 DOWNTO 0);
        w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0)
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
    
    -- Control Signals in ID
    SIGNAL c_reg_write, c_wb_sel, c_mem_write, c_mem_read, c_alu_src_b, c_sp_write : std_logic;
    SIGNAL c_alu_sel : std_logic_vector(2 DOWNTO 0);
    SIGNAL c_branch_type : std_logic_vector(2 DOWNTO 0);
    SIGNAL c_is_std : std_logic; -- NEW
    
    -- STAGE: EX
    SIGNAL ex_reg_write, ex_wb_sel, ex_mem_write, ex_mem_read, ex_alu_src_b : std_logic;
    SIGNAL ex_alu_sel : std_logic_vector(2 DOWNTO 0);
    SIGNAL ex_is_std  : std_logic; -- NEW
    SIGNAL ex_pc, ex_r_data1, ex_r_data2, ex_imm_ext : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_r_addr1, ex_r_addr2, ex_w_addr_dest : std_logic_vector(2 DOWNTO 0);
    SIGNAL ex_write_data : std_logic_vector(31 DOWNTO 0); -- NEW for STD swap
    
    SIGNAL ex_src_a, ex_src_b : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_alu_result : std_logic_vector(31 DOWNTO 0);
    SIGNAL ex_zero, ex_neg, ex_carry : std_logic;
    
    -- STAGE: MEM
    SIGNAL mem_reg_write, mem_wb_sel, mem_mem_write, mem_mem_read : std_logic;
    SIGNAL mem_pc : std_logic_vector(31 DOWNTO 0); -- NEW
    SIGNAL mem_alu_result, mem_write_data : std_logic_vector(31 DOWNTO 0);
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

    -- Signals for Static Port Mapping
    SIGNAL pc_write_sig : std_logic;
    SIGNAL if_id_en_sig : std_logic;
    
BEGIN
    
    -- Assign Signals for Port Map
    pc_write_sig <= NOT if_stall;
    if_id_en_sig <= NOT if_stall;

    ----------------------------------------------------------------------------
    -- 1. FETCH STAGE
    ----------------------------------------------------------------------------
    -- Arbitrate Memory: IF MEM Stage needs it, give it.
    mem_busy <= '1' WHEN (mem_mem_write = '1' OR mem_mem_read = '1') ELSE '0';
    
    -- Mux for Memory Inputs
    memory_addr    <= mem_alu_result WHEN mem_busy = '1' ELSE pc_current;
    memory_data_in <= mem_write_data; -- Only used when WE=1 (MEM stage)
    memory_we      <= mem_mem_write;
    
    -- Stalling Fetch if Memory Busy
    if_stall <= mem_busy; -- If busy, stall IF
    
    -- PC Logic
    pc_plus_1 <= std_logic_vector(unsigned(pc_current) + 1);
    pc_next   <= pc_plus_1; -- Default Next
    -- TODO: Add Branching Mux Here (using EX branching results)
    
    U_PC: PC PORT MAP (
        clk => clk, rst => rst,
        pc_write => pc_write_sig, -- Fixed invalid expression
        pc_inc => '0', -- We calc externally
        pc_in => pc_next,
        pc_out => pc_current
    );
    
    -- IF Inst is Mem Out (Only valid if NOT busy)
    if_inst <= memory_data_out;
    
    -- IF/ID Reg
    U_IF_ID: IF_ID_Reg PORT MAP (
        clk => clk, rst => rst, en => if_id_en_sig, -- Fixed invalid expression
        pc_in => pc_current, inst_in => if_inst,
        pc_out => id_pc, inst_out => id_inst
    );

    ----------------------------------------------------------------------------
    -- 2. DECODE STAGE
    ----------------------------------------------------------------------------
    id_opcode <= id_inst(31 DOWNTO 27);
    id_r1     <= id_inst(26 DOWNTO 24); -- Rsrc1
    id_r2     <= id_inst(23 DOWNTO 21); -- Rsrc2
    id_w      <= id_inst(20 DOWNTO 18); -- Rdst
    
    -- Mux for Immediate or Input Port (Routing Input via Immediate Path)
    id_imm_ext <= input_port WHEN id_opcode = OP_IN ELSE
                  std_logic_vector(resize(unsigned(id_inst(15 DOWNTO 0)), 32)) WHEN id_opcode = OP_LDM ELSE
                  std_logic_vector(resize(signed(id_inst(15 DOWNTO 0)), 32));
    
    U_Control: ControlUnit PORT MAP (
        opcode => id_opcode,
        reg_write => c_reg_write, wb_sel => c_wb_sel,
        mem_write => c_mem_write, mem_read => c_mem_read,
        alu_sel => c_alu_sel, alu_src_b => c_alu_src_b,
        branch_type => c_branch_type, sp_write => c_sp_write
    );

    -- Detect STD Opcode
    c_is_std <= '1' WHEN id_opcode = OP_STD ELSE '0';
    
    U_RegFile: RegisterFile PORT MAP (
        clk => clk, rst => rst,
        reg_write_en1 => wb_reg_write, -- Write from WB Stage
        reg_write_en2 => '0',
        read_addr1 => id_r1, read_addr2 => id_r2,
        write_addr1 => wb_w_addr_dest, write_data1 => wb_write_data,
        write_addr2 => (others=>'0'), write_data2 => (others=>'0'),
        read_data1 => id_r_data1, read_data2 => id_r_data2
    );
    
    U_ID_EX: ID_EX_Reg PORT MAP (
        clk => clk, rst => rst, en => '1',
        reg_write_in => c_reg_write, wb_sel_in => c_wb_sel, 
        mem_write_in => c_mem_write, mem_read_in => c_mem_read, 
        alu_src_b_in => c_alu_src_b, alu_sel_in => c_alu_sel,
        is_std_in => c_is_std,
        pc_in => id_pc, r_data1_in => id_r_data1, r_data2_in => id_r_data2, 
        imm_extended_in => id_imm_ext,
        r_addr1_in => id_r1, r_addr2_in => id_r2, w_addr_dest_in => id_w,
        
        reg_write_out => ex_reg_write, wb_sel_out => ex_wb_sel, 
        mem_write_out => ex_mem_write, mem_read_out => ex_mem_read, 
        alu_src_b_out => ex_alu_src_b, alu_sel_out => ex_alu_sel,
        is_std_out => ex_is_std,
        pc_out => ex_pc, r_data1_out => ex_r_data1, r_data2_out => ex_r_data2, 
        imm_extended_out => ex_imm_ext,
        r_addr1_out => ex_r_addr1, r_addr2_out => ex_r_addr2, w_addr_dest_out => ex_w_addr_dest
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
    
    ex_write_data <= ex_r_data1 WHEN ex_is_std = '1' ELSE ex_r_data2;

    U_EX_MEM: EX_MEM_Reg PORT MAP (
        clk => clk, rst => rst, en => '1',
        reg_write_in => ex_reg_write, wb_sel_in => ex_wb_sel,
        mem_write_in => ex_mem_write, mem_read_in => ex_mem_read,
        pc_in => ex_pc,
        alu_result_in => ex_alu_result, 
        write_data_in => ex_write_data,
        w_addr_dest_in => ex_w_addr_dest,
        
        reg_write_out => mem_reg_write, wb_sel_out => mem_wb_sel,
        mem_write_out => mem_mem_write, mem_read_out => mem_mem_read,
        pc_out => mem_pc,
        alu_result_out => mem_alu_result, write_data_out => mem_write_data,
        w_addr_dest_out => mem_w_addr_dest
    );

    ----------------------------------------------------------------------------
    -- 4. MEMORY STAGE
    ----------------------------------------------------------------------------
    U_Memory: Memory PORT MAP (
        clk => clk, rst => rst,
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
