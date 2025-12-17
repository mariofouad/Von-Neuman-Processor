LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
-- USE work.Processor_Pkg.all; -- Package usage depends on user preference, we'll keep it explicit for now.

ENTITY Processor IS
    PORT (
        clk           : IN  std_logic;
        rst           : IN  std_logic;
        
        -- Control Signals (Input from Testbench/Control Unit)
        
        -- Register File Controls
        reg_write_en1 : IN  std_logic;
        reg_write_en2 : IN  std_logic;
        r_addr1       : IN  std_logic_vector(2 DOWNTO 0);
        r_addr2       : IN  std_logic_vector(2 DOWNTO 0);
        w_addr1       : IN  std_logic_vector(2 DOWNTO 0);
        w_addr2       : IN  std_logic_vector(2 DOWNTO 0);
        
        -- ALU Controls
        alu_sel       : IN  std_logic_vector(2 DOWNTO 0);
        src_b_sel     : IN  std_logic; -- NEW: 0 for RegB, 1 for Immediate
        
        -- Immediate Input
        imm_in        : IN  std_logic_vector(15 DOWNTO 0); -- NEW
        
        -- Memory Controls
        mem_write     : IN  std_logic;
        
        -- Mux Selections
        -- 0: ALU Result, 1: Memory Out
        wb_sel        : IN  std_logic; 
        
        -- PC Controls
        pc_write      : IN  std_logic;
        pc_inc        : IN  std_logic;
        
        -- SP Controls
        sp_write      : IN  std_logic;

        -- Address Selection
        -- 00: PC (Fetch)
        -- 01: ALU Result (Load/Store)
        -- 10: SP (Push/Pop)
        addr_sel      : IN  std_logic_vector(1 DOWNTO 0);
        
        -- ALU Src A Selection
        -- 00: Register A
        -- 01: PC
        -- 10: SP
        src_a_sel     : IN  std_logic_vector(1 DOWNTO 0);
        
        -- Memory Data Input Selection
        -- 0: Register B (Store)
        -- 1: PC (Push Return Address)
        mem_data_sel  : IN  std_logic;

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

    COMPONENT SP
    PORT (
        clk      : IN  std_logic;
        rst      : IN  std_logic;
        sp_write : IN  std_logic;
        sp_in    : IN  std_logic_vector(31 DOWNTO 0);
        sp_out   : OUT std_logic_vector(31 DOWNTO 0)
    );
    END COMPONENT;

    -- Internal Signals
    SIGNAL r_data1, r_data2 : std_logic_vector(31 DOWNTO 0);
    SIGNAL alu_result       : std_logic_vector(31 DOWNTO 0);
    SIGNAL mem_data_out     : std_logic_vector(31 DOWNTO 0);
    
    SIGNAL pc_val           : std_logic_vector(31 DOWNTO 0);
    SIGNAL sp_val           : std_logic_vector(31 DOWNTO 0);
    
    -- Mux Outputs
    SIGNAL write_back_data  : std_logic_vector(31 DOWNTO 0);
    SIGNAL mem_addr         : std_logic_vector(31 DOWNTO 0);
    SIGNAL alu_src_a        : std_logic_vector(31 DOWNTO 0);
    SIGNAL alu_src_b        : std_logic_vector(31 DOWNTO 0); -- NEW
    SIGNAL mem_data_in      : std_logic_vector(31 DOWNTO 0);
    
    SIGNAL imm_extended     : std_logic_vector(31 DOWNTO 0); -- NEW
    
    -- Flags
    SIGNAL z, n, c : std_logic;

BEGIN

    -- 0. IMMEDIATE EXTENSION (Sign extension)
    imm_extended <= std_logic_vector(resize(signed(imm_in), 32));

    -- 1. WRITE BACK MUX
    write_back_data <= alu_result WHEN wb_sel = '0' ELSE mem_data_out;

    -- 2. MEMORY ADDRESS MUX (PC, ALU, SP)
    -- 00: PC, 01: ALU, 10: SP
    WITH addr_sel SELECT
        mem_addr <= pc_val     WHEN "00",
                    alu_result WHEN "01",
                    sp_val     WHEN "10",
                    (others => '0') WHEN OTHERS;
    
    -- 3. ALU SRC A MUX (RegA, PC, SP)
    WITH src_a_sel SELECT
        alu_src_a <= r_data1 WHEN "00",
                     pc_val  WHEN "01",
                     sp_val  WHEN "10",
                     (others => '0') WHEN OTHERS;
                     
    -- 3.5 ALU SRC B MUX (RegB, Imm) --> NEW
    alu_src_b <= r_data2 WHEN src_b_sel = '0' ELSE imm_extended;

    -- 4. MEMORY DATA INPUT MUX (Store Value: RegB vs PC)
    -- 0: Reg B, 1: PC (for Push PC)
    mem_data_in <= r_data2 WHEN mem_data_sel = '0' ELSE pc_val;

    -- 5. Register File Instance
    U_RegFile: RegisterFile PORT MAP (
        clk           => clk,
        rst           => rst,
        reg_write_en1 => reg_write_en1,
        reg_write_en2 => reg_write_en2, 
        read_addr1    => r_addr1,
        read_addr2    => r_addr2,
        write_addr1   => w_addr1,  
        write_data1   => write_back_data, 
        write_addr2   => w_addr2,  
        write_data2   => r_data2,  
        read_data1    => r_data1,
        read_data2    => r_data2
    );

    -- 6. ALU Instance
    U_ALU: ALU PORT MAP (
        SrcA       => alu_src_a, 
        SrcB       => alu_src_b, -- CHANGED
        ALU_Sel    => alu_sel,
        ALU_Result => alu_result,
        Zero       => z,
        Negative   => n,
        Carry      => c
    );

    -- 7. Memory Instance
    U_Memory: Memory PORT MAP (
        clk      => clk,
        rst      => rst,
        addr     => mem_addr,  
        data_in  => mem_data_in, -- FROM DATA MUX
        we       => mem_write,
        data_out => mem_data_out
    );
    
    -- 8. Program Counter Instance
    U_PC: PC PORT MAP (
        clk      => clk,
        rst      => rst,
        pc_write => pc_write,
        pc_inc   => pc_inc,
        pc_in    => write_back_data, -- PC loads from common bus
        pc_out   => pc_val
    );
    
    -- 9. Stack Pointer Instance
    U_SP: SP PORT MAP (
        clk      => clk,
        rst      => rst,
        sp_write => sp_write,
        sp_in    => write_back_data, -- SP loads from common bus
        sp_out   => sp_val
    );

    -- Debug Connections
    alu_out_debug <= alu_result;
    mem_out_debug <= mem_data_out;

END Structure;
