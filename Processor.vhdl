library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Processor is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC
    );
end Processor;

architecture Structural of Processor is
    -- === SIGNALS ===
    signal pc_current, pc_next : STD_LOGIC_VECTOR(31 downto 0);
    signal instruction         : STD_LOGIC_VECTOR(31 downto 0);
    signal imm_ext             : STD_LOGIC_VECTOR(31 downto 0);
    
    -- Register File Signals
    signal read_data1, read_data2 : STD_LOGIC_VECTOR(31 downto 0);
    signal write_data             : STD_LOGIC_VECTOR(31 downto 0);
    
    -- ALU Signals
    signal alu_src_b, alu_result  : STD_LOGIC_VECTOR(31 downto 0);
    
    -- Control Signals
    signal reg_write, mem_write, mem_to_reg, alu_src, branch : STD_LOGIC;
    signal alu_sel : STD_LOGIC_VECTOR(2 downto 0);

begin

    -- ==========================================================
    -- 1. FETCH STAGE
    -- ==========================================================
    
    -- Simple PC Increment (PC = PC + 1)
    pc_next <= std_logic_vector(unsigned(pc_current) + 1);

    PC_Reg: entity work.PC port map(
        clk => clk, rst => rst, 
        pc_write => '1', pc_inc => '0', 
        pc_in => pc_next, pc_out => pc_current
    );

    -- ONE MEMORY INSTANCE (Instruction Fetch ONLY for now)
    -- We wire the Address directly to PC.
    -- Warning: If you try 'LDD' (Load Data), this wiring prevents it.
    Main_Memory: entity work.Memory port map(
        clk => clk, rst => rst,
        addr => pc_current,  -- Always Fetching Instruction
        data_in => (others=>'0'), 
        we => '0',           -- Never writing (yet)
        data_out => instruction
    );

    -- ==========================================================
    -- 2. DECODE STAGE
    -- ==========================================================

    CU: entity work.ControlUnit port map(
        Opcode   => instruction(31 downto 27),
        RegWrite => reg_write, MemWrite => mem_write,
        MemToReg => mem_to_reg, ALU_Src => alu_src,
        ALU_Sel  => alu_sel, Branch => branch
    );

    RegFile: entity work.RegisterFile port map(
        clk => clk, rst => rst,
        reg_write_en1 => reg_write, reg_write_en2 => '0',
        
        read_addr1 => instruction(26 downto 24), -- Src1
        read_addr2 => instruction(23 downto 21), -- Src2
        
        -- DESTINATION ADDR: Your ISA uses bits 20-18 for Rdst in LDM/ADD
        write_addr1 => instruction(20 downto 18), 
        
        write_addr2 => "000", write_data2 => (others=>'0'),
        write_data1 => write_data, -- Coming from WriteBack
        read_data1 => read_data1, read_data2 => read_data2
    );

    SE: entity work.SignExtend port map(
        Input => instruction(15 downto 0), 
        Output => imm_ext
    );

    -- ==========================================================
    -- 3. EXECUTE STAGE
    -- ==========================================================
    
    -- Mux: Choose between Register Data or Immediate (for LDM)
    alu_src_b <= imm_ext when alu_src = '1' else read_data2;

    ALU_Unit: entity work.ALU port map(
        SrcA => read_data1, SrcB => alu_src_b,
        ALU_Sel => alu_sel, 
        ALU_Result => alu_result
        -- Flags unconnected for this simple test
    );

    -- ==========================================================
    -- 4. WRITE BACK STAGE
    -- ==========================================================
    
    -- Since we have no data memory access, Result is always ALU Result
    write_data <= alu_result;

end Structural;