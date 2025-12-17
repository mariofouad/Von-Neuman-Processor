LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
-- USE work.Processor_Pkg.all; -- Package usage depends on user preference, we'll keep it explicit for now.

ENTITY Processor IS
    PORT (
        clk           : IN  std_logic;
        rst           : IN  std_logic;
        
        -- Control Signals (Input from Testbench/Control Unit)
        -- In a full CPU, these come from the Control Unit entity.
        -- For this integration test, we drive them manually.
        
        -- Register File Controls
        reg_write_en1 : IN  std_logic;
        reg_write_en2 : IN  std_logic; -- From your custom RegFile
        r_addr1       : IN  std_logic_vector(2 DOWNTO 0);
        r_addr2       : IN  std_logic_vector(2 DOWNTO 0);
        w_addr1       : IN  std_logic_vector(2 DOWNTO 0);
        w_addr2       : IN  std_logic_vector(2 DOWNTO 0);
        
        -- ALU Controls
        alu_sel       : IN  std_logic_vector(2 DOWNTO 0);
        
        -- Memory Controls
        mem_write     : IN  std_logic;
        
        -- Mux Selections
        -- 0: ALU Result, 1: Memory Out
        wb_sel        : IN  std_logic; 
        
        -- PC (Simulated for simpler integration now)
        pc_in         : IN  std_logic_vector(31 DOWNTO 0);
        -- 0: Use PC, 1: Use ALU Result (for Load/Store)
        addr_sel      : IN  std_logic;

        -- Debug Outputs (To see what's happening in TB)
        alu_out_debug : OUT std_logic_vector(31 DOWNTO 0);
        mem_out_debug : OUT std_logic_vector(31 DOWNTO 0)
    );
END Processor;

ARCHITECTURE Structure OF Processor IS

    -- Component Declarations
    COMPONENT RegisterFile
    PORT(
        clk           : IN  std_logic;
        rst           : IN  std_logic;
        reg_write_en1 : IN  std_logic;
        reg_write_en2 : IN  std_logic;
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

    -- Internal Signals
    SIGNAL r_data1, r_data2 : std_logic_vector(31 DOWNTO 0);
    SIGNAL alu_result       : std_logic_vector(31 DOWNTO 0);
    SIGNAL mem_data_out     : std_logic_vector(31 DOWNTO 0);
    
    -- Mux Outputs
    SIGNAL write_back_data  : std_logic_vector(31 DOWNTO 0);
    SIGNAL mem_addr         : std_logic_vector(31 DOWNTO 0);
    
    -- Flags (Unused for now but wired)
    SIGNAL z, n, c : std_logic;

BEGIN

    -- 1. WRITE BACK MUX
    -- Selects data to write into Register File (Port 1)
    write_back_data <= alu_result WHEN wb_sel = '0' ELSE mem_data_out;

    -- 2. MEMORY ADDRESS MUX
    -- Selects PC (Instruction Fetch) or ALU Result (Data Access)
    mem_addr <= pc_in WHEN addr_sel = '0' ELSE alu_result;

    -- 3. Register File Instance
    U_RegFile: RegisterFile PORT MAP (
        clk           => clk,
        rst           => rst,
        reg_write_en1 => reg_write_en1,
        reg_write_en2 => reg_write_en2, 
        read_addr1    => r_addr1,
        read_addr2    => r_addr2,
        write_addr1   => w_addr1,  -- Usually dest reg
        write_data1   => write_back_data, -- DATA COMES FROM WB MUX
        write_addr2   => w_addr2,  -- Aux port
        write_data2   => r_data2,  -- Usually used for Swap, simplified here
        read_data1    => r_data1,
        read_data2    => r_data2
    );

    -- 4. ALU Instance
    U_ALU: ALU PORT MAP (
        SrcA       => r_data1,
        SrcB       => r_data2, -- Simplification: No Immediate Mux yet
        ALU_Sel    => alu_sel,
        ALU_Result => alu_result,
        Zero       => z,
        Negative   => n,
        Carry      => c
    );

    -- 5. Memory Instance
    U_Memory: Memory PORT MAP (
        clk      => clk,
        rst      => rst,
        addr     => mem_addr,  -- FROM ADDR MUX
        data_in  => r_data2,   -- Store Value usually comes from Reg B
        we       => mem_write,
        data_out => mem_data_out
    );

    -- Debug Connections
    alu_out_debug <= alu_result;
    mem_out_debug <= mem_data_out;

END Structure;
