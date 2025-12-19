LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- =============================================================================
-- IF/ID REGISTER (Fetch -> Decode)
-- =============================================================================
ENTITY IF_ID_Reg is
    PORT (
        clk         : IN  std_logic;
        rst         : IN  std_logic;
        en          : IN  std_logic; -- 0: Freeze (Stall)
        
        pc_in       : IN  std_logic_vector(31 DOWNTO 0);
        inst_in     : IN  std_logic_vector(31 DOWNTO 0);
        
        pc_out      : OUT std_logic_vector(31 DOWNTO 0);
        inst_out    : OUT std_logic_vector(31 DOWNTO 0)
    );
END IF_ID_Reg;

ARCHITECTURE Behavior OF IF_ID_Reg is
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1'THEN
            pc_out   <= (others => '0');
            inst_out <= (others => '0'); -- Becomes NOP
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                pc_out   <= pc_in;
                inst_out <= inst_in;
            END IF;
        END IF;
    END PROCESS;
END Behavior;

-- =============================================================================
-- ID/EX REGISTER (Decode -> Execute)
-- =============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ID_EX_Reg is
    PORT (
        clk, rst, en : IN std_logic;
        -- Control Inputs
        reg_write_in, reg_write_2_in, wb_sel_in, mem_write_in, mem_read_in : IN std_logic;
        alu_sel_in   : IN std_logic_vector(2 DOWNTO 0);
        alu_src_b_in : IN std_logic;
        is_std_in    : IN std_logic;
        sp_write_in  : IN std_logic;
        is_stack_in  : IN std_logic;
        out_en_in    : IN std_logic;
        rti_en_in    : IN std_logic;
        branch_type_in : IN std_logic_vector(2 DOWNTO 0);
        port_sel_in     : IN  std_logic; -- Choose IN.PORT
        flags_en_in  : IN std_logic;
        
        -- Data Inputs
        pc_in, r_data1_in, r_data2_in, imm_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in    : IN std_logic_vector(31 DOWNTO 0);
        r_addr1_in, r_addr2_in, rdst_addr_in : IN std_logic_vector(2 DOWNTO 0);
        
        -- Control Outputs
        reg_write_out, reg_write_2_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        alu_sel_out   : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b_out : OUT std_logic;
        is_std_out    : OUT std_logic;
        sp_write_out  : OUT std_logic;
        is_stack_out  : OUT std_logic;
        out_en_out    : OUT std_logic;
        rti_en_out    : OUT std_logic;
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0);
        -- *** NEW ***
        flags_en_out  : OUT std_logic;
        
        -- Data Outputs
        port_sel_out : OUT std_logic;
        pc_out, r_data1_out, r_data2_out, imm_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_val_out    : OUT std_logic_vector(31 DOWNTO 0);
        r_addr1_out, r_addr2_out, rdst_addr_out : OUT std_logic_vector(2 DOWNTO 0)
    );
END ID_EX_Reg;

ARCHITECTURE Behavior OF ID_EX_Reg is
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reg_write_out <= '0'; reg_write_2_out <= '0';
            mem_write_out <= '0'; sp_write_out <= '0'; is_stack_out <= '0';
            out_en_out <= '0'; rti_en_out <= '0'; flags_en_out <= '0';
            branch_type_out <= (others => '0');
            mem_read_out <= '0';
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                reg_write_out <= reg_write_in; reg_write_2_out <= reg_write_2_in;
                wb_sel_out <= wb_sel_in;
                mem_write_out <= mem_write_in; mem_read_out <= mem_read_in;
                alu_sel_out <= alu_sel_in; alu_src_b_out <= alu_src_b_in;
                is_std_out <= is_std_in; sp_write_out <= sp_write_in;
                is_stack_out <= is_stack_in;
                out_en_out <= out_en_in; rti_en_out <= rti_en_in;
                branch_type_out <= branch_type_in;
                port_sel_out <= port_sel_in;
                flags_en_out <= flags_en_in;
                pc_out <= pc_in;
                r_data1_out <= r_data1_in; r_data2_out <= r_data2_in;
                imm_out <= imm_in; sp_val_out <= sp_val_in;
                r_addr1_out <= r_addr1_in; r_addr2_out <= r_addr2_in;
                rdst_addr_out <= rdst_addr_in;
            END IF;
        END IF;
    END PROCESS;
END Behavior;
-- =============================================================================
-- EX/MEM REGISTER (Execute -> Memory)
-- =============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY EX_MEM_Reg is
    PORT (
        clk, rst, en : IN std_logic;
        
        -- Control Inputs
        reg_write_in, reg_write_2_in : IN std_logic;
        wb_sel_in, mem_write_in, mem_read_in : IN std_logic;
        sp_write_in  : IN std_logic;
        is_stack_in  : IN std_logic;
        out_en_in    : IN std_logic;
        rti_en_in    : IN std_logic;
        
        -- *** NEW: Branch Type must pass to MEM stage for RET/RTI detection ***
        branch_type_in : IN std_logic_vector(2 DOWNTO 0);

        -- Data Inputs
        pc_in         : IN std_logic_vector(31 DOWNTO 0);
        alu_res_in, r_data2_in : IN std_logic_vector(31 DOWNTO 0);
        sp_new_val_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in     : IN std_logic_vector(31 DOWNTO 0);
        rdst_addr_in: IN std_logic_vector(2 DOWNTO 0);
        rsrc_addr_in : IN std_logic_vector(2 DOWNTO 0);
        
        -- Outputs
        reg_write_out, reg_write_2_out : OUT std_logic;
        wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        sp_write_out  : OUT std_logic;
        is_stack_out  : OUT std_logic;
        out_en_out    : OUT std_logic;
        rti_en_out    : OUT std_logic;
        
        -- *** NEW: Output ***
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0);
        
        pc_out        : OUT std_logic_vector(31 DOWNTO 0);
        alu_res_out, r_data2_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_new_val_out: OUT std_logic_vector(31 DOWNTO 0);
        sp_val_out    : OUT std_logic_vector(31 DOWNTO 0);
        rdst_addr_out: OUT std_logic_vector(2 DOWNTO 0);
        rsrc_addr_out : OUT std_logic_vector(2 DOWNTO 0)
    );
END EX_MEM_Reg;

ARCHITECTURE Behavior OF EX_MEM_Reg is
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reg_write_out <= '0'; reg_write_2_out <= '0';
            mem_write_out <= '0'; sp_write_out <= '0'; is_stack_out <= '0';
            mem_read_out <= '0';
            out_en_out <= '0'; rti_en_out <= '0';
            branch_type_out <= (others => '0'); -- Reset Branch Type
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                reg_write_out <= reg_write_in; reg_write_2_out <= reg_write_2_in;
                wb_sel_out <= wb_sel_in;
                mem_write_out <= mem_write_in; mem_read_out <= mem_read_in;
                sp_write_out <= sp_write_in; is_stack_out <= is_stack_in;
                out_en_out <= out_en_in; rti_en_out <= rti_en_in;
                
                -- Pass Branch Type
                branch_type_out <= branch_type_in;
                
                pc_out <= pc_in; alu_res_out <= alu_res_in;
                sp_new_val_out <= sp_new_val_in;
                sp_val_out <= sp_val_in;
                rdst_addr_out <= rdst_addr_in;
                rsrc_addr_out <= rsrc_addr_in;
                r_data2_out <= r_data2_in;
            END IF;
        END IF;
    END PROCESS;
END Behavior;
-- =============================================================================
-- MEM/WB REGISTER (Memory -> Write Back)
-- =============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY MEM_WB_Reg is
    PORT (
        clk, rst, en : IN std_logic;
        
        -- Control Inputs
        reg_write_in, reg_write_2_in : IN std_logic; -- Added reg_write_2
        wb_sel_in : IN std_logic;
        
        -- Data Inputs
        pc_in          : IN std_logic_vector(31 DOWNTO 0);
        mem_data_in    : IN std_logic_vector(31 DOWNTO 0);
        alu_res_in  : IN std_logic_vector(31 DOWNTO 0);
        r_data2_in   : IN std_logic_vector(31 DOWNTO 0);
        rdst_addr_in   : IN std_logic_vector(2 DOWNTO 0);
        
        -- SWAP Data Inputs (Added)
        rsrc_addr_in   : IN std_logic_vector(2 DOWNTO 0);
        
        -- Control Outputs
        reg_write_out, reg_write_2_out : OUT std_logic;
        wb_sel_out : OUT std_logic;
        
        -- Data Outputs
        pc_out         : OUT std_logic_vector(31 DOWNTO 0);
        mem_data_out   : OUT std_logic_vector(31 DOWNTO 0);
        alu_res_out : OUT std_logic_vector(31 DOWNTO 0);
        rdst_addr_out: OUT std_logic_vector(2 DOWNTO 0);
        
        -- SWAP Data Outputs (Added)
        rsrc_addr_out : OUT std_logic_vector(2 DOWNTO 0);
        r_data2_out   : OUT std_logic_vector(31 DOWNTO 0)
    );
END MEM_WB_Reg;

ARCHITECTURE Behavior OF MEM_WB_Reg is
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reg_write_out <= '0'; reg_write_2_out <= '0';
            wb_sel_out <= '0';
            pc_out <= (others => '0');
            mem_data_out <= (others => '0');
            alu_res_out <= (others => '0');
            rdst_addr_out <= (others => '0');
            rsrc_addr_out <= (others => '0');
            r_data2_out <= (others => '0');
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                reg_write_out <= reg_write_in; reg_write_2_out <= reg_write_2_in;
                wb_sel_out <= wb_sel_in;
                
                pc_out <= pc_in;
                mem_data_out <= mem_data_in;
                alu_res_out <= alu_res_in;
                rdst_addr_out <= rdst_addr_in;
                
                rsrc_addr_out <= rsrc_addr_in;
                r_data2_out <= r_data2_in;
            END IF;
        END IF;
    END PROCESS;
END Behavior;