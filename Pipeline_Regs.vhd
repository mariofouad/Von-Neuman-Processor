library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ============================================================
-- 1. IF/ID Register (Fetch -> Decode)
-- ============================================================
entity IF_ID_Reg is
    Port (
        clk, rst, stall, flush : in STD_LOGIC;
        pc_in, inst_in         : in STD_LOGIC_VECTOR(31 downto 0);
        pc_out, inst_out       : out STD_LOGIC_VECTOR(31 downto 0)
    );
end IF_ID_Reg;

architecture Behavioral of IF_ID_Reg is
begin
    process(clk, rst)
    begin
        if rst = '1' or flush = '1' then
            pc_out <= (others => '0');
            inst_out <= (others => '0'); -- NOP
        elsif rising_edge(clk) then
            if stall = '0' then -- Only update if NOT stalled
                pc_out <= pc_in;
                inst_out <= inst_in;
            end if;
        end if;
    end process;
end Behavioral;

-- ============================================================
-- 2. ID/EX Register (Decode -> Execute)
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ID_EX_Reg is
    Port (
        clk, rst, stall, flush : in STD_LOGIC;
        
        -- Control Signals (Passed from CU)
        wb_reg_write_in, mem_write_in, mem_to_reg_in, alu_src_in : in STD_LOGIC;
        alu_sel_in : in STD_LOGIC_VECTOR(2 downto 0);
        
        -- Data
        data1_in, data2_in, imm_in : in STD_LOGIC_VECTOR(31 downto 0);
        rd_addr_in, rs1_addr_in, rs2_addr_in : in STD_LOGIC_VECTOR(2 downto 0);
        
        -- Outputs
        wb_reg_write_out, mem_write_out, mem_to_reg_out, alu_src_out : out STD_LOGIC;
        alu_sel_out : out STD_LOGIC_VECTOR(2 downto 0);
        data1_out, data2_out, imm_out : out STD_LOGIC_VECTOR(31 downto 0);
        rd_addr_out, rs1_addr_out, rs2_addr_out : out STD_LOGIC_VECTOR(2 downto 0)
    );
end ID_EX_Reg;

architecture Behavioral of ID_EX_Reg is
begin
    process(clk, rst)
    begin
        if rst = '1' or flush = '1' then
            wb_reg_write_out <= '0'; mem_write_out <= '0';
            data1_out <= (others=>'0'); rd_addr_out <= (others=>'0');
            -- Reset other signals...
        elsif rising_edge(clk) then
            if stall = '0' then
                wb_reg_write_out <= wb_reg_write_in;
                mem_write_out    <= mem_write_in;
                mem_to_reg_out   <= mem_to_reg_in;
                alu_src_out      <= alu_src_in;
                alu_sel_out      <= alu_sel_in;
                
                data1_out   <= data1_in;
                data2_out   <= data2_in;
                imm_out     <= imm_in;
                rd_addr_out <= rd_addr_in;
                rs1_addr_out <= rs1_addr_in;
                rs2_addr_out <= rs2_addr_in;
            end if;
        end if;
    end process;
end Behavioral;

-- ============================================================
-- 3. EX/MEM Register (Execute -> Memory)
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity EX_MEM_Reg is
    Port (
        clk, rst, stall, flush : in STD_LOGIC;
        
        -- Control
        wb_reg_write_in, mem_write_in, mem_to_reg_in : in STD_LOGIC;
        
        -- Data
        alu_result_in, write_data_in : in STD_LOGIC_VECTOR(31 downto 0);
        rd_addr_in : in STD_LOGIC_VECTOR(2 downto 0);
        
        -- Outputs
        wb_reg_write_out, mem_write_out, mem_to_reg_out : out STD_LOGIC;
        alu_result_out, write_data_out : out STD_LOGIC_VECTOR(31 downto 0);
        rd_addr_out : out STD_LOGIC_VECTOR(2 downto 0)
    );
end EX_MEM_Reg;

architecture Behavioral of EX_MEM_Reg is
begin
    process(clk, rst)
    begin
        if rst = '1' or flush = '1' then
            wb_reg_write_out <= '0'; mem_write_out <= '0';
            alu_result_out <= (others=>'0');
        elsif rising_edge(clk) then
            if stall = '0' then
                wb_reg_write_out <= wb_reg_write_in;
                mem_write_out    <= mem_write_in;
                mem_to_reg_out   <= mem_to_reg_in;
                alu_result_out   <= alu_result_in;
                write_data_out   <= write_data_in;
                rd_addr_out      <= rd_addr_in;
            end if;
        end if;
    end process;
end Behavioral;

-- ============================================================
-- 4. MEM/WB Register (Memory -> Writeback)
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MEM_WB_Reg is
    Port (
        clk, rst, stall, flush : in STD_LOGIC;
        
        -- Control
        wb_reg_write_in, mem_to_reg_in : in STD_LOGIC;
        
        -- Data
        mem_data_in, alu_result_in : in STD_LOGIC_VECTOR(31 downto 0);
        rd_addr_in : in STD_LOGIC_VECTOR(2 downto 0);
        
        -- Outputs
        wb_reg_write_out, mem_to_reg_out : out STD_LOGIC;
        mem_data_out, alu_result_out : out STD_LOGIC_VECTOR(31 downto 0);
        rd_addr_out : out STD_LOGIC_VECTOR(2 downto 0)
    );
end MEM_WB_Reg;

architecture Behavioral of MEM_WB_Reg is
begin
    process(clk, rst)
    begin
        if rst = '1' or flush = '1' then
            wb_reg_write_out <= '0';
        elsif rising_edge(clk) then
            if stall = '0' then
                wb_reg_write_out <= wb_reg_write_in;
                mem_to_reg_out   <= mem_to_reg_in;
                mem_data_out     <= mem_data_in;
                alu_result_out   <= alu_result_in;
                rd_addr_out      <= rd_addr_in;
            end if;
        end if;
    end process;
end Behavioral;