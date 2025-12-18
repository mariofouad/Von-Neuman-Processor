library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Pipelined_Processor is
    Port ( clk, rst : in STD_LOGIC );
end Pipelined_Processor;

architecture Structural of Pipelined_Processor is
    
    -- === 1. FETCH STAGE SIGNALS ===
    signal pc_f, pc_next_f, pc_plus_1_f : STD_LOGIC_VECTOR(31 downto 0);
    signal inst_f : STD_LOGIC_VECTOR(31 downto 0);

    -- === 2. DECODE STAGE SIGNALS ===
    signal pc_d, inst_d : STD_LOGIC_VECTOR(31 downto 0);
    signal rd_addr_d, rs1_addr_d, rs2_addr_d : STD_LOGIC_VECTOR(2 downto 0);
    signal reg_data1_d, reg_data2_d, imm_d : STD_LOGIC_VECTOR(31 downto 0);
    -- Control Signals in Decode
    signal reg_write_d, mem_write_d, mem_to_reg_d, alu_src_d : STD_LOGIC;
    signal alu_sel_d : STD_LOGIC_VECTOR(2 downto 0);

    -- === 3. EXECUTE STAGE SIGNALS ===
    signal reg_write_e, mem_write_e, mem_to_reg_e, alu_src_e : STD_LOGIC;
    signal alu_sel_e : STD_LOGIC_VECTOR(2 downto 0);
    signal reg_data1_e, reg_data2_e, imm_e : STD_LOGIC_VECTOR(31 downto 0);
    signal rd_addr_e, rs1_addr_e, rs2_addr_e : STD_LOGIC_VECTOR(2 downto 0);
    signal alu_src_b_e, alu_result_e : STD_LOGIC_VECTOR(31 downto 0);

    -- === 4. MEMORY STAGE SIGNALS ===
    signal reg_write_m, mem_write_m, mem_to_reg_m : STD_LOGIC;
    signal alu_result_m, write_data_m, mem_read_data_m : STD_LOGIC_VECTOR(31 downto 0);
    signal rd_addr_m : STD_LOGIC_VECTOR(2 downto 0);

    -- === 5. WRITEBACK STAGE SIGNALS ===
    signal reg_write_w, mem_to_reg_w : STD_LOGIC;
    signal alu_result_w, mem_read_data_w, final_wb_data_w : STD_LOGIC_VECTOR(31 downto 0);
    signal rd_addr_w : STD_LOGIC_VECTOR(2 downto 0);

    -- === HAZARD / BRANCH SIGNALS ===
    signal branch_taken : STD_LOGIC;
    signal branch_target_address : STD_LOGIC_VECTOR(31 downto 0);
    signal stall_f, stall_d, flush_d, flush_e : STD_LOGIC := '0';

begin

    -- =========================================================================
    -- STAGE 1: FETCH
    -- =========================================================================
    
    -- PC Logic: Determine Next PC Value
    pc_plus_1_f <= std_logic_vector(unsigned(pc_f) + 1);

    -- PC Mux: Choose between Next Line (PC+1) or Branch Target
    process(pc_plus_1_f, branch_target_address, branch_taken)
    begin
        if branch_taken = '1' then
            pc_next_f <= branch_target_address;
        else
            pc_next_f <= pc_plus_1_f;
        end if;
    end process;

    PC_Reg: entity work.PC port map(
        clk => clk, rst => rst, 
        pc_write => '1', -- (This will be controlled by Stall later)
        pc_inc => '0', pc_in => pc_next_f, pc_out => pc_f
    );

    Inst_Mem: entity work.Memory port map(
        clk => clk, rst => rst, addr => pc_f, 
        data_in => (others=>'0'), we => '0', data_out => inst_f
    );

    -- IF/ID PIPELINE REGISTER
    -- Connect flush_d here to kill instruction if jumping
    IF_ID: entity work.IF_ID_Reg port map(
        clk => clk, rst => rst, stall => stall_d, flush => flush_d,
        pc_in => pc_f, inst_in => inst_f,
        pc_out => pc_d, inst_out => inst_d
    );

    -- =========================================================================
    -- STAGE 2: DECODE
    -- =========================================================================

    -- 1. Fixed Source Addresses
    rs1_addr_d <= inst_d(26 downto 24);
    rs2_addr_d <= inst_d(23 downto 21);

    -- 2. Destination Address Logic (Corrected for your ISA)
    rd_addr_d <= inst_d(20 downto 18);

    -- 3. === NEW BRANCH LOGIC STARTS HERE ===
    
    -- Calculate Target: Just use the Immediate value (Absolute Jump)
    -- (If you want PC-Relative, change to: pc_d + imm_d)
    branch_target_address <= imm_d;

    -- Decide if we should branch
    process(inst_d, reg_data1_d)
    begin
        branch_taken <= '0'; -- Default to Not Taken

        -- Check Opcode (High 5 bits)
        case inst_d(31 downto 27) is
            when "10101" => -- JMP (Unconditional)
                branch_taken <= '1';

            when "10010" => -- JZ (Jump if Zero)
                if unsigned(reg_data1_d) = 0 then
                    branch_taken <= '1';
                end if;
            
            when others =>
                branch_taken <= '0';
        end case;
    end process;

    -- Connect the Flush Signal
    -- If we take a branch, the instruction currently in Fetch (PC+1) is wrong.
    -- We flush it so it becomes a bubble.
    flush_d <= branch_taken;

    -- === NEW BRANCH LOGIC ENDS HERE ===

    Control: entity work.ControlUnit port map(
        Opcode => inst_d(31 downto 27),
        RegWrite => reg_write_d, MemWrite => mem_write_d,
        MemToReg => mem_to_reg_d, ALU_Src => alu_src_d,
        ALU_Sel => alu_sel_d
    );

    RegFile: entity work.RegisterFile port map(
        clk => clk, rst => rst,
        -- Write Port comes from WRITEBACK Stage
        reg_write_en1 => reg_write_w, reg_write_en2 => '0',
        write_addr1 => rd_addr_w, write_data1 => final_wb_data_w,
        write_addr2 => "000", write_data2 => (others=>'0'),
        
        -- Read Ports
        read_addr1 => rs1_addr_d, read_addr2 => rs2_addr_d,
        read_data1 => reg_data1_d, read_data2 => reg_data2_d
    );

    SignExt: entity work.SignExtend port map(inst_d(15 downto 0), imm_d);

    -- ID/EX PIPELINE REGISTER
    ID_EX: entity work.ID_EX_Reg port map(
        clk => clk, rst => rst, stall => '0', flush => flush_e,
        -- Control
        wb_reg_write_in => reg_write_d, mem_write_in => mem_write_d,
        mem_to_reg_in => mem_to_reg_d, alu_src_in => alu_src_d, alu_sel_in => alu_sel_d,
        -- Data
        data1_in => reg_data1_d, data2_in => reg_data2_d, imm_in => imm_d,
        rd_addr_in => rd_addr_d, rs1_addr_in => rs1_addr_d, rs2_addr_in => rs2_addr_d,
        
        -- Outputs
        wb_reg_write_out => reg_write_e, mem_write_out => mem_write_e,
        mem_to_reg_out => mem_to_reg_e, alu_src_out => alu_src_e, alu_sel_out => alu_sel_e,
        data1_out => reg_data1_e, data2_out => reg_data2_e, imm_out => imm_e,
        rd_addr_out => rd_addr_e, rs1_addr_out => rs1_addr_e, rs2_addr_out => rs2_addr_e
    );

    -- =========================================================================
    -- STAGE 3: EXECUTE
    -- =========================================================================

    -- ALU Mux
    alu_src_b_e <= imm_e when alu_src_e = '1' else reg_data2_e;

    ALU_Unit: entity work.ALU port map(
        SrcA => reg_data1_e, SrcB => alu_src_b_e,
        ALU_Sel => alu_sel_e, ALU_Result => alu_result_e
    );

    -- EX/MEM PIPELINE REGISTER
    EX_MEM: entity work.EX_MEM_Reg port map(
        clk => clk, rst => rst, stall => '0', flush => '0',
        -- Control
        wb_reg_write_in => reg_write_e, mem_write_in => mem_write_e,
        mem_to_reg_in => mem_to_reg_e,
        -- Data
        alu_result_in => alu_result_e, write_data_in => reg_data2_e, 
        rd_addr_in => rd_addr_e,
        
        -- Outputs
        wb_reg_write_out => reg_write_m, mem_write_out => mem_write_m,
        mem_to_reg_out => mem_to_reg_m,
        alu_result_out => alu_result_m, write_data_out => write_data_m,
        rd_addr_out => rd_addr_m
    );

    -- =========================================================================
    -- STAGE 4: MEMORY
    -- =========================================================================

    Data_Mem: entity work.Memory port map(
        clk => clk, rst => rst,
        addr => alu_result_m, data_in => write_data_m,
        we => mem_write_m, data_out => mem_read_data_m
    );

    -- MEM/WB PIPELINE REGISTER
    MEM_WB: entity work.MEM_WB_Reg port map(
        clk => clk, rst => rst, stall => '0', flush => '0',
        -- Control
        wb_reg_write_in => reg_write_m, mem_to_reg_in => mem_to_reg_m,
        -- Data
        mem_data_in => mem_read_data_m, alu_result_in => alu_result_m,
        rd_addr_in => rd_addr_m,
        
        -- Outputs
        wb_reg_write_out => reg_write_w, mem_to_reg_out => mem_to_reg_w,
        mem_data_out => mem_read_data_w, alu_result_out => alu_result_w,
        rd_addr_out => rd_addr_w
    );

    -- =========================================================================
    -- STAGE 5: WRITEBACK
    -- =========================================================================

    -- Write Back Mux
    final_wb_data_w <= mem_read_data_w when mem_to_reg_w = '1' else alu_result_w;

end Structural;