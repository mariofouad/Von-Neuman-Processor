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
        clk             : IN  std_logic;
        rst             : IN  std_logic;
        en              : IN  std_logic;

        -- CONTROL SIGNALS (WB, M, EX)
        -- WB
        reg_write_in    : IN  std_logic;
        wb_sel_in       : IN  std_logic; -- MemToReg
        -- M
        mem_write_in    : IN  std_logic;
        mem_read_in     : IN  std_logic;
        -- EX
        alu_sel_in      : IN  std_logic_vector(2 DOWNTO 0);
        alu_src_b_in    : IN  std_logic; -- ALUSrc
        
        -- DATA
        pc_in           : IN  std_logic_vector(31 DOWNTO 0);
        r_data1_in      : IN  std_logic_vector(31 DOWNTO 0);
        r_data2_in      : IN  std_logic_vector(31 DOWNTO 0);
        imm_extended_in : IN  std_logic_vector(31 DOWNTO 0);
        r_addr1_in      : IN  std_logic_vector(2 DOWNTO 0); -- For forwarding
        r_addr2_in      : IN  std_logic_vector(2 DOWNTO 0); -- For forwarding
        w_addr_dest_in  : IN  std_logic_vector(2 DOWNTO 0); -- Destination Reg

        -- OUTPUTS
        reg_write_out   : OUT std_logic;
        wb_sel_out      : OUT std_logic;
        mem_write_out   : OUT std_logic;
        mem_read_out    : OUT std_logic;
        alu_sel_out     : OUT std_logic_vector(2 DOWNTO 0);
        alu_src_b_out   : OUT std_logic;
        
        pc_out          : OUT std_logic_vector(31 DOWNTO 0);
        r_data1_out     : OUT std_logic_vector(31 DOWNTO 0);
        r_data2_out     : OUT std_logic_vector(31 DOWNTO 0);
        imm_extended_out: OUT std_logic_vector(31 DOWNTO 0);
        r_addr1_out     : OUT std_logic_vector(2 DOWNTO 0);
        r_addr2_out     : OUT std_logic_vector(2 DOWNTO 0);
        w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0)
    );
END ID_EX_Reg;

ARCHITECTURE Behavior OF ID_EX_Reg IS
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- Reset all outputs
            reg_write_out   <= '0';
            wb_sel_out      <= '0';
            mem_write_out   <= '0';
            mem_read_out    <= '0';
            alu_sel_out     <= (others => '0');
            alu_src_b_out   <= '0';
            pc_out          <= (others => '0');
            r_data1_out     <= (others => '0');
            r_data2_out     <= (others => '0');
            imm_extended_out<= (others => '0');
            r_addr1_out     <= (others => '0');
            r_addr2_out     <= (others => '0');
            w_addr_dest_out <= (others => '0');
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                reg_write_out   <= reg_write_in;
                wb_sel_out      <= wb_sel_in;
                mem_write_out   <= mem_write_in;
                mem_read_out    <= mem_read_in;
                alu_sel_out     <= alu_sel_in;
                alu_src_b_out   <= alu_src_b_in;
                
                pc_out          <= pc_in;
                r_data1_out     <= r_data1_in;
                r_data2_out     <= r_data2_in;
                imm_extended_out<= imm_extended_in;
                r_addr1_out     <= r_addr1_in;
                r_addr2_out     <= r_addr2_in;
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
        clk             : IN  std_logic;
        rst             : IN  std_logic;
        en              : IN  std_logic;

        -- CONTROL
        reg_write_in    : IN  std_logic;
        wb_sel_in       : IN  std_logic;
        mem_write_in    : IN  std_logic;
        mem_read_in     : IN  std_logic;

        -- DATA
        alu_result_in   : IN  std_logic_vector(31 DOWNTO 0);
        write_data_in   : IN  std_logic_vector(31 DOWNTO 0); -- For Store
        w_addr_dest_in  : IN  std_logic_vector(2 DOWNTO 0);
        
        -- OUTPUTS
        reg_write_out   : OUT std_logic;
        wb_sel_out      : OUT std_logic;
        mem_write_out   : OUT std_logic;
        mem_read_out    : OUT std_logic;
        
        alu_result_out  : OUT std_logic_vector(31 DOWNTO 0);
        write_data_out  : OUT std_logic_vector(31 DOWNTO 0);
        w_addr_dest_out : OUT std_logic_vector(2 DOWNTO 0)
    );
END EX_MEM_Reg;

ARCHITECTURE Behavior OF EX_MEM_Reg IS
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reg_write_out   <= '0';
            wb_sel_out      <= '0';
            mem_write_out   <= '0';
            mem_read_out    <= '0';
            alu_result_out  <= (others => '0');
            write_data_out  <= (others => '0');
            w_addr_dest_out <= (others => '0');
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                reg_write_out   <= reg_write_in;
                wb_sel_out      <= wb_sel_in;
                mem_write_out   <= mem_write_in;
                mem_read_out    <= mem_read_in;
                alu_result_out  <= alu_result_in;
                write_data_out  <= write_data_in;
                w_addr_dest_out <= w_addr_dest_in;
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
        mem_data_in     : IN  std_logic_vector(31 DOWNTO 0);
        alu_result_in   : IN  std_logic_vector(31 DOWNTO 0);
        w_addr_dest_in  : IN  std_logic_vector(2 DOWNTO 0);
        
        -- OUTPUTS
        reg_write_out   : OUT std_logic;
        wb_sel_out      : OUT std_logic;
        
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
            mem_data_out    <= (others => '0');
            alu_result_out  <= (others => '0');
            w_addr_dest_out <= (others => '0');
        ELSIF rising_edge(clk) THEN
            IF en = '1' THEN
                reg_write_out   <= reg_write_in;
                wb_sel_out      <= wb_sel_in;
                mem_data_out    <= mem_data_in;
                alu_result_out  <= alu_result_in;
                w_addr_dest_out <= w_addr_dest_in;
            END IF;
        END IF;
    END PROCESS;
END Behavior;
