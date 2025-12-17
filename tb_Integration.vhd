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
        mem_write     : IN std_logic;
        wb_sel        : IN std_logic;
        pc_in         : IN std_logic_vector(31 DOWNTO 0);
        addr_sel      : IN std_logic;
        alu_out_debug : OUT std_logic_vector(31 DOWNTO 0);
        mem_out_debug : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    -- Signals
    SIGNAL clk, rst : std_logic := '0';
    SIGNAL reg_write_en1, reg_write_en2, mem_write, wb_sel, addr_sel : std_logic := '0';
    SIGNAL r_addr1, r_addr2, w_addr1, w_addr2 : std_logic_vector(2 DOWNTO 0) := (others => '0');
    SIGNAL alu_sel : std_logic_vector(2 DOWNTO 0) := (others => '0');
    SIGNAL pc_in : std_logic_vector(31 DOWNTO 0) := (others => '0');
    SIGNAL alu_out, mem_out : std_logic_vector(31 DOWNTO 0);

    CONSTANT clk_period : time := 10 ns;

BEGIN

    uut: Processor PORT MAP (
        clk => clk, rst => rst,
        reg_write_en1 => reg_write_en1, reg_write_en2 => reg_write_en2,
        r_addr1 => r_addr1, r_addr2 => r_addr2,
        w_addr1 => w_addr1, w_addr2 => w_addr2,
        alu_sel => alu_sel,
        mem_write => mem_write,
        wb_sel => wb_sel,
        pc_in => pc_in,
        addr_sel => addr_sel,
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
        
        -- PRE-LOAD MEMORY (HACK): 
        -- Since we can't easily preload memory in VHDL without a file or special command,
        -- We will manually Write to Memory first using the processor datapath!
        
        -- OPERATION 0: STORE IMEM (Simulate Initialization)
        -- Can't do this easily without Immediate Mux, but we can rely on Reg Reset = 0
        -- Let's Assume Memory[0] is initialized to Zero or specific value in Memory.vhdl 
        -- (Wait, we need data to test!)
        
        -- Let's try to write 0 into Mem[5] using R0 (which is 0 after reset)
        -- Data comes from R_Data2 -> Mem_Data_In.
        -- R0 is 0. 
        -- Addr comes from ALU (since addr_sel=1). ALU(0,0, ADD) = 0.
        
        -- TEST SEQUENCE:
        
        -- STEP A: ALU ADD (R0 + R0 = 0) -> Write to R1.
        -- Purpose: Ensure R1 = 0
        r_addr1 <= "000"; r_addr2 <= "000"; -- Read R0, R0
        alu_sel <= "010"; -- ADD
        wb_sel <= '0';    -- Select ALU Result
        reg_write_en1 <= '1';
        w_addr1 <= "001"; -- Write R1
        wait for clk_period;
        reg_write_en1 <= '0';
        
        -- STEP B: WRITE TO MEMORY
        -- R1 (Data=0) -> Mem[4]
        -- We need ALU to output 4.
        -- Problem: We can't inject immediate '4' without appropriate MUX.
        -- WE CAN USE 'INC' (Op 110) repeated 4 times on R1?
        
        -- ACTUALLY, simpler test for datapath without Control Unit/Immediates:
        -- Just verify connection paths valid.
        
        -- 1. Reg Loopback
        -- INC R0 (0) -> 1. Write to R1.
        alu_sel <= "110"; -- INC A
        r_addr1 <= "000"; -- R0
        wb_sel <= '0';    -- ALU Out
        reg_write_en1 <= '1';
        w_addr1 <= "001"; -- R1
        wait for clk_period;
        reg_write_en1 <= '0';
        -- R1 should be 1.
        
        -- 2. Mem Write
        -- Write R1 (Val=1) to Address 0 (From PC=0)
        pc_in <= x"00000000";
        addr_sel <= '0'; -- Select PC as Addr
        r_addr2 <= "001"; -- Data from R1
        mem_write <= '1';
        wait for clk_period;
        mem_write <= '0';
        
        -- 3. Mem Read
        -- Read Address 0 -> Write to R2
        -- Mem[0] should be 1.
        pc_in <= x"00000000";
        addr_sel <= '0'; -- PC
        wb_sel <= '1';   -- Select Mem Out
        reg_write_en1 <= '1';
        w_addr1 <= "010"; -- R2
        wait for clk_period;
        reg_write_en1 <= '0';
        
        -- CHECK R2
        -- We can't read R2 directly, but we can put it on ALU.
        r_addr1 <= "010";
        alu_sel <= "000"; -- MOV (Pass A)
        wait for clk_period;
        
        ASSERT (alu_out = x"00000001") REPORT "Integration Test Failed: R2 should be 1" SEVERITY ERROR;
        
        REPORT "Integration Simulation Completed";
        wait;
    end process;
    
END Behavior;
