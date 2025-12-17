LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY tb_Processor IS
END tb_Processor;

ARCHITECTURE Behavior OF tb_Processor IS

    COMPONENT Processor
    PORT(
        clk, rst      : IN std_logic;
        reg_write_en1 : IN std_logic;
        reg_write_en2 : IN std_logic;
        r_addr1, r_addr2 : IN std_logic_vector(2 DOWNTO 0);
        w_addr1, w_addr2 : IN std_logic_vector(2 DOWNTO 0);
        alu_sel       : IN std_logic_vector(2 DOWNTO 0);
        src_b_sel     : IN std_logic; -- NEW
        imm_in        : IN std_logic_vector(15 DOWNTO 0); -- NEW
        mem_write     : IN std_logic;
        wb_sel        : IN std_logic;
        pc_write      : IN std_logic;
        pc_inc        : IN std_logic;
        sp_write      : IN std_logic;
        addr_sel      : IN std_logic_vector(1 DOWNTO 0);
        src_a_sel     : IN std_logic_vector(1 DOWNTO 0);
        mem_data_sel  : IN std_logic;
        alu_out_debug : OUT std_logic_vector(31 DOWNTO 0);
        mem_out_debug : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    -- Signals
    SIGNAL clk, rst : std_logic := '0';
    SIGNAL reg_write_en1, reg_write_en2, mem_write, wb_sel, pc_write, pc_inc, sp_write, mem_data_sel, src_b_sel : std_logic := '0';
    SIGNAL r_addr1, r_addr2, w_addr1, w_addr2 : std_logic_vector(2 DOWNTO 0) := (others => '0');
    SIGNAL alu_sel : std_logic_vector(2 DOWNTO 0) := (others => '0');
    SIGNAL addr_sel, src_a_sel : std_logic_vector(1 DOWNTO 0) := "00";
    SIGNAL imm_in : std_logic_vector(15 DOWNTO 0) := (others => '0');
    SIGNAL alu_out, mem_out : std_logic_vector(31 DOWNTO 0);

    CONSTANT clk_period : time := 10 ns;

BEGIN

    uut: Processor PORT MAP (
        clk => clk, rst => rst,
        reg_write_en1 => reg_write_en1, reg_write_en2 => reg_write_en2,
        r_addr1 => r_addr1, r_addr2 => r_addr2,
        w_addr1 => w_addr1, w_addr2 => w_addr2,
        alu_sel => alu_sel,
        src_b_sel => src_b_sel,
        imm_in => imm_in,
        mem_write => mem_write,
        wb_sel => wb_sel,
        pc_write => pc_write,
        pc_inc => pc_inc,
        sp_write => sp_write,
        addr_sel => addr_sel,
        src_a_sel => src_a_sel,
        mem_data_sel => mem_data_sel,
        alu_out_debug => alu_out,
        mem_out_debug => mem_out
    );

    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        -- 1. Reset
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for clk_period;
        
        REPORT "--- STARTING SIMULATION ---";

        -- -------------------------------------------------------
        -- Boot Sequence: Load PC from Reset Vector (M[0])
        -- -------------------------------------------------------
        addr_sel <= "00"; -- PC (currently 0)
        wait for clk_period;
        -- Assume M[0] = 16. Latch it into PC.
        wb_sel <= '1'; -- From Memory
        pc_write <= '1';
        wait for clk_period;
        pc_write <= '0';
        REPORT "PC Initialized to " & integer'image(to_integer(unsigned(mem_out)));

        -- -------------------------------------------------------
        -- Execute Instruction 1: LDM R1, 5
        -- Op: LDM(01111), Rdst=1(001), Imm=5
        -- -------------------------------------------------------
        REPORT "Executing I1: LDM R1, 5";
        -- Fetch
        addr_sel <= "00"; -- PC
        wait for clk_period; 
        
        -- Decode/Execute
        -- LDM means: Reg[w_addr] <= Imm
        src_b_sel <= '1';   -- Select Imm
        alu_sel <= "001";   -- Pass B
        wb_sel <= '0';      -- From ALU
        w_addr1 <= "001";   -- R1
        reg_write_en1 <= '1';
        imm_in <= x"0005";  -- Immediate 5
        wait for clk_period;
        
        -- Reset Control Signals
        reg_write_en1 <= '0';
        
        -- Increment PC
        pc_inc <= '1';
        wait for clk_period;
        pc_inc <= '0';
        
        -- -------------------------------------------------------
        -- Execute Instruction 2: LDM R2, 10
        -- Op: LDM(01111), Rdst=2(010), Imm=10
        -- -------------------------------------------------------
        REPORT "Executing I2: LDM R2, 10";
        -- Fetch
        addr_sel <= "00"; 
        wait for clk_period;
        
        -- Decode/Execute
        src_b_sel <= '1';
        alu_sel <= "001"; 
        w_addr1 <= "010"; -- R2
        reg_write_en1 <= '1';
        imm_in <= x"000A"; -- 10
        wait for clk_period;
        
        reg_write_en1 <= '0';
        
        -- Increment PC
        pc_inc <= '1';
        wait for clk_period;
        pc_inc <= '0';

        -- -------------------------------------------------------
        -- Execute Instruction 3: ADD R4, R1, R2
        -- Op: ADD(01001), Rdst=4, Rsrc1=1, Rsrc2=2
        -- -------------------------------------------------------
        REPORT "Executing I3: ADD R4, R1, R2";
        -- Fetch
        addr_sel <= "00";
        wait for clk_period;
        
        -- Decode/Execute
        src_b_sel <= '0';   -- Select Reg B
        alu_sel <= "010";   -- ADD
        wb_sel <= '0';      -- ALU Result
        r_addr1 <= "001";   -- R1
        r_addr2 <= "010";   -- R2
        w_addr1 <= "100";   -- R4
        reg_write_en1 <= '1';
        src_a_sel <= "00";  -- Reg A
        wait for clk_period;
        
        reg_write_en1 <= '0';
        
        -- Increment PC
        pc_inc <= '1';
        wait for clk_period;
        pc_inc <= '0';

        -- -------------------------------------------------------
        -- Verification: Check R4
        -- -------------------------------------------------------
        REPORT "Verifying R4 Content...";
        -- Read R4 onto ALU Bus (Pass A)
        r_addr1 <= "100";   -- R4
        src_a_sel <= "00";  -- Reg A
        alu_sel <= "000";   -- Pass A
        wb_sel <= '0';      -- ALU Result (into Debug)
        wait for clk_period;
        
        ASSERT (alu_out = x"0000000F") 
            REPORT "R4 Verification Failed. Expected 15, Got " & integer'image(to_integer(unsigned(alu_out))) 
            SEVERITY ERROR;
            
        IF alu_out = x"0000000F" THEN
            REPORT "R4 Verification SUCCESS. Value = 15";
        END IF;

        wait;
    end process;
    
END Behavior;
