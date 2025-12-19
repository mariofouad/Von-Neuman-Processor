LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- =============================================================================
-- IF/ID REGISTER
-- =============================================================================
ENTITY IF_ID_Reg IS
    PORT (
        clk         : IN  std_logic;
        rst         : IN  std_logic;
        en          : IN  std_logic; -- Enable (for Stalling)
        
        -- Inputs
        pc_in       : IN  std_logic_vector(31 DOWNTO 0);
        inst_in     : IN  std_logic_vector(31 DOWNTO 0);
        
        -- Outputs
        pc_out      : OUT std_logic_vector(31 DOWNTO 0);
        inst_out    : OUT std_logic_vector(31 DOWNTO 0)
    );
END IF_ID_Reg;

ARCHITECTURE Behavior OF IF_ID_Reg IS
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            pc_out   <= (others => '0');
            inst_out <= (others => '0');
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                pc_out   <= pc_in;
                inst_out <= inst_in;
            END IF;
        END IF;
    END PROCESS;
END Behavior;

-- =============================================================================
-- ID/EX REGISTER
-- =============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ID_EX_Reg IS
    PORT (
        clk, rst, en : IN std_logic;
        -- Control Signals
        reg_write_in, wb_sel_in, mem_write_in, mem_read_in : IN std_logic;
        alu_sel_in   : IN std_logic_vector(2 DOWNTO 0);
        alu_src_b_in : IN std_logic;
        is_std_in    : IN std_logic;
        sp_write_in  : IN std_logic; -- NEW
        is_stack_in  : IN std_logic; -- NEW (Identifies PUSH/POP/CALL/RET)
        branch_type_in : IN std_logic_vector(2 DOWNTO 0); -- NEW
        ccr_z_en_in, ccr_n_en_in, ccr_c_en_in : IN std_logic;
        rti_en_in : IN std_logic;
        
        -- Data Signals
        pc_in, r_data1_in, r_data2_in, imm_extended_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in    : IN std_logic_vector(31 DOWNTO 0); -- NEW
        r_addr1_in, r_addr2_in, w_addr_dest_in : IN std_logic_vector(2 DOWNTO 0);
        
        -- Outputs
        reg_write_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        alu_sel_out   : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b_out : OUT std_logic;
        is_std_out    : OUT std_logic;
        sp_write_out  : OUT std_logic; -- NEW
        is_stack_out  : OUT std_logic; -- NEW
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0); -- NEW
        ccr_z_en_out, ccr_n_en_out, ccr_c_en_out : OUT std_logic;
        rti_en_out : OUT std_logic;
        pc_out, r_data1_out, r_data2_out, imm_extended_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_val_out    : OUT std_logic_vector(31 DOWNTO 0); -- NEW
        r_addr1_out, r_addr2_out, w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0)
    );
END ID_EX_Reg;

ARCHITECTURE Behavior OF ID_EX_Reg IS
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reg_write_out <= '0'; mem_write_out <= '0'; sp_write_out <= '0'; is_stack_out <= '0';
            ccr_z_en_out <= '0'; ccr_n_en_out <= '0'; ccr_c_en_out <= '0';
            rti_en_out <= '0';
            branch_type_out <= (others => '0');
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                reg_write_out <= reg_write_in; wb_sel_out <= wb_sel_in;
                mem_write_out <= mem_write_in; mem_read_out <= mem_read_in;
                alu_sel_out <= alu_sel_in; alu_src_b_out <= alu_src_b_in;
                is_std_out <= is_std_in; sp_write_out <= sp_write_in;
                is_stack_out <= is_stack_in; 
                branch_type_out <= branch_type_in;
                ccr_z_en_out <= ccr_z_en_in; ccr_n_en_out <= ccr_n_en_in; ccr_c_en_out <= ccr_c_en_in;
                rti_en_out <= rti_en_in;
                pc_out <= pc_in;
                r_data1_out <= r_data1_in; r_data2_out <= r_data2_in;
                imm_extended_out <= imm_extended_in; sp_val_out <= sp_val_in;
                r_addr1_out <= r_addr1_in; r_addr2_out <= r_addr2_in;
                w_addr_dest_out <= w_addr_dest_in;
            END IF;
        END IF;
    END PROCESS;
END Behavior;

-- =============================================================================
-- EX/MEM REGISTER
-- =============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY EX_MEM_Reg IS
    PORT (
        clk, rst, en : IN std_logic;
        reg_write_in, wb_sel_in, mem_write_in, mem_read_in : IN std_logic;
        sp_write_in  : IN std_logic; -- NEW
        is_stack_in  : IN std_logic; -- NEW
        branch_type_in : IN std_logic_vector(2 DOWNTO 0); -- NEW
        pc_in        : IN std_logic_vector(31 DOWNTO 0);
        alu_result_in, write_data_in : IN std_logic_vector(31 DOWNTO 0);
        sp_new_val_in : IN std_logic_vector(31 DOWNTO 0);
        sp_val_in     : IN std_logic_vector(31 DOWNTO 0); -- NEW (Original SP for POP)
        w_addr_dest_in : IN std_logic_vector(2 DOWNTO 0);
        rti_en_in      : IN std_logic;
        
        reg_write_out, wb_sel_out, mem_write_out, mem_read_out : OUT std_logic;
        sp_write_out  : OUT std_logic; 
        is_stack_out  : OUT std_logic; 
        branch_type_out : OUT std_logic_vector(2 DOWNTO 0); -- NEW
        pc_out        : OUT std_logic_vector(31 DOWNTO 0);
        alu_result_out, write_data_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_new_val_out : OUT std_logic_vector(31 DOWNTO 0);
        sp_val_out     : OUT std_logic_vector(31 DOWNTO 0); -- NEW
        w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0);
        rti_en_out      : OUT std_logic
    );
END EX_MEM_Reg;

ARCHITECTURE Behavior OF EX_MEM_Reg IS
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reg_write_out <= '0'; mem_write_out <= '0'; sp_write_out <= '0'; is_stack_out <= '0';
            rti_en_out <= '0'; branch_type_out <= (others => '0');
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                reg_write_out <= reg_write_in; wb_sel_out <= wb_sel_in;
                mem_write_out <= mem_write_in; mem_read_out <= mem_read_in;
                sp_write_out <= sp_write_in; is_stack_out <= is_stack_in;
                branch_type_out <= branch_type_in;
                pc_out <= pc_in; alu_result_out <= alu_result_in;
                write_data_out <= write_data_in; sp_new_val_out <= sp_new_val_in;
                sp_val_out <= sp_val_in;
                w_addr_dest_out <= w_addr_dest_in;
                rti_en_out <= rti_en_in;
            END IF;
        END IF;
    END PROCESS;
END Behavior;
-- =============================================================================
-- MEM/WB REGISTER
-- =============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY MEM_WB_Reg IS
    PORT (
        clk             : IN  std_logic;
        rst             : IN  std_logic;
        en              : IN  std_logic;

        -- CONTROL
        reg_write_in    : IN  std_logic;
        wb_sel_in       : IN  std_logic;

        -- DATA
        pc_in           : IN  std_logic_vector(31 DOWNTO 0);
        mem_data_in     : IN  std_logic_vector(31 DOWNTO 0);
        alu_result_in   : IN  std_logic_vector(31 DOWNTO 0);
        w_addr_dest_in  : IN  std_logic_vector(2 DOWNTO 0);
        
        -- OUTPUTS
        reg_write_out   : OUT std_logic;
        wb_sel_out      : OUT std_logic;
        
        pc_out          : OUT std_logic_vector(31 DOWNTO 0);
        mem_data_out    : OUT std_logic_vector(31 DOWNTO 0);
        alu_result_out  : OUT std_logic_vector(31 DOWNTO 0);
        w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0)
    );
END MEM_WB_Reg;

ARCHITECTURE Behavior OF MEM_WB_Reg IS
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reg_write_out   <= '0';
            wb_sel_out      <= '0';
            pc_out          <= (others => '0');
            mem_data_out    <= (others => '0');
            alu_result_out  <= (others => '0');
            w_addr_dest_out <= (others => '0');
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                reg_write_out   <= reg_write_in;
                wb_sel_out      <= wb_sel_in;
                pc_out          <= pc_in;
                mem_data_out    <= mem_data_in;
                alu_result_out  <= alu_result_in;
                w_addr_dest_out <= w_addr_dest_in;
            END IF;
        END IF;
    END PROCESS;
END Behavior;
