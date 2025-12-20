-- ============================================================================
-- INTERRUPT AND CONTROL FLOW COMPONENTS
-- Fast Bits (16:15): 11=CALL, 10=RET/RTI, 01=INT, 00=Normal
-- ============================================================================

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

-- ============================================================================
-- INTERRUPT CONTROLLER
-- Handles hardware interrupt line and injects INT instruction into pipeline
-- ============================================================================
ENTITY InterruptController IS
    PORT (
        clk           : IN  std_logic;
        rst           : IN  std_logic;
        
        -- Hardware Interrupt Line
        irq_line      : IN  std_logic;
        
        -- CPU Handshake
        -- Goes high when the ID stage is processing an INT opcode
        cpu_ack       : IN  std_logic;
        
        -- Pipeline clear signal - '1' when no control flow ops in pipeline
        pipeline_clear : IN std_logic;
        
        -- Outputs
        irq_req       : OUT std_logic;                     -- '1' when we want to inject instruction
        irq_inst      : OUT std_logic_vector(31 DOWNTO 0)  -- The instruction to inject
    );
END InterruptController;

ARCHITECTURE Behavior OF InterruptController IS
    TYPE state_t IS (IDLE, WAIT_CLEAR, ASSERT_INT, WAIT_ACK);
    SIGNAL state : state_t := IDLE;
    
    -- VIRTUAL INSTRUCTION: INT -1 (Hardware Interrupt - special index)
    -- Opcode: 11000 (INT)
    -- Fast Bits (16:15): 01 (For Hazard Unit detection)
    -- Index: -1 (all 1s) - Hardware interrupt vector at M[1]
    -- The processor will detect index = all 1s as HW interrupt and use M[1]
    -- Format: opcode(5) | 000 | 000 | 000 | 0 | 01 | 111111111111111
    CONSTANT HW_INT_INSTRUCTION : std_logic_vector(31 DOWNTO 0) := 
        "11000" & "000" & "000" & "000" & "0" & "01" & "111111111111111";

BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            state <= IDLE;
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN IDLE =>
                    IF irq_line = '1' THEN
                        IF pipeline_clear = '1' THEN
                            -- Pipeline is clear, inject INT immediately
                            state <= ASSERT_INT;
                        ELSE
                            -- Wait for pipeline to clear
                            state <= WAIT_CLEAR;
                        END IF;
                    END IF;
                
                WHEN WAIT_CLEAR =>
                    -- Wait for control flow operations to complete
                    IF pipeline_clear = '1' THEN
                        state <= ASSERT_INT;
                    END IF;
                    
                WHEN ASSERT_INT =>
                    -- Hold request until CPU acts on it (cpu_ack = '1')
                    IF cpu_ack = '1' THEN
                        state <= WAIT_ACK;
                    END IF;
                    
                WHEN WAIT_ACK =>
                    -- Wait for IRQ line to drop before accepting new interrupts
                    IF irq_line = '0' THEN
                        state <= IDLE;
                    END IF;
            END CASE;
        END IF;
    END PROCESS;

    irq_req  <= '1' WHEN state = ASSERT_INT ELSE '0';
    irq_inst <= HW_INT_INSTRUCTION;

END Behavior;

-- ============================================================================
-- STACK PACKER
-- Packs/unpacks PC and CCR for CALL/RET/INT/RTI operations
-- Memory is 4096 locations (12-bit addresses)
-- Stack word format for INT: [0...0][CCR(3)][PC(12)] = bits 14:12 = CCR, bits 11:0 = PC
-- Stack word format for CALL: [0...0][000][PC(12)] = bits 11:0 = PC+1
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY StackPacker IS
    PORT (
        -- Control Flags (From Decoder)
        is_call       : IN std_logic; -- '1' if Opcode is CALL
        is_int        : IN std_logic; -- '1' if Opcode is INT or HW Interrupt
        
        -- Data Inputs
        pc_current    : IN std_logic_vector(31 DOWNTO 0); -- Current PC (for INT)
        pc_plus_1     : IN std_logic_vector(31 DOWNTO 0); -- PC+1 (for CALL)
        ccr_flags     : IN std_logic_vector(2 DOWNTO 0);  -- Z, N, C flags
        normal_data   : IN std_logic_vector(31 DOWNTO 0); -- Normal push data (e.g., register)
        
        -- Output to Memory (for PUSH)
        mem_write_data: OUT std_logic_vector(31 DOWNTO 0);
        
        -- Input from Memory (for POP - unpacking)
        mem_read_data : IN  std_logic_vector(31 DOWNTO 0);
        
        -- Restored Outputs (for RET/RTI)
        restored_pc   : OUT std_logic_vector(31 DOWNTO 0);
        restored_ccr  : OUT std_logic_vector(2 DOWNTO 0)
    );
END StackPacker;

ARCHITECTURE Behavior OF StackPacker IS
BEGIN
    -- ========== PACKING (For PUSH during CALL/INT) ==========
    PROCESS(is_call, is_int, pc_current, pc_plus_1, ccr_flags, normal_data)
    BEGIN
        IF is_call = '1' THEN
            -- CALL: Push PC+1 (return address)
            -- Format: [0...0][000][PC+1(12 bits)]
            mem_write_data <= (31 DOWNTO 12 => '0') & pc_plus_1(11 DOWNTO 0);
            
        ELSIF is_int = '1' THEN
            -- INT: Push PC with CCR
            -- Format: [0...0][CCR(3 bits)][PC(12 bits)]
            -- CCR at bits 14:12, PC at bits 11:0
            mem_write_data <= (31 DOWNTO 15 => '0') & ccr_flags & pc_current(11 DOWNTO 0);
            
        ELSE
            -- Normal PUSH (e.g., PUSH Rx)
            mem_write_data <= normal_data;
        END IF;
    END PROCESS;

    -- ========== UNPACKING (For POP during RET/RTI) ==========
    -- Extract PC from bits 11:0 (zero-extend to 32 bits)
    restored_pc  <= (31 DOWNTO 12 => '0') & mem_read_data(11 DOWNTO 0);
    
    -- Extract CCR from bits 14:12 (for RTI)
    restored_ccr <= mem_read_data(14 DOWNTO 12);
    
END Behavior;

-- ============================================================================
-- INTERRUPT VECTOR READER
-- Reads interrupt vector address based on index
-- M[0] = Reset vector
-- M[1] = HW Interrupt handler address
-- M[2] = INT 0 handler address  
-- M[3] = INT 1 handler address
-- For software INT: PC <- M[index + 2] where index is 0 or 1
-- For HW Interrupt: PC <- M[1] (detected by index = all 1s)
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY InterruptVectorUnit IS
    PORT (
        -- INT index from instruction bits 14:0
        int_index     : IN std_logic_vector(14 DOWNTO 0);
        
        -- Vector address output (to memory address bus)
        vector_addr   : OUT std_logic_vector(31 DOWNTO 0)
    );
END InterruptVectorUnit;

ARCHITECTURE Behavior OF InterruptVectorUnit IS
BEGIN
    -- HW Interrupt: index = all 1s (0x7FFF) -> M[1]
    -- INT 0: index = 0 -> M[2]
    -- INT 1: index = 1 -> M[3]
    vector_addr <= x"00000001" WHEN int_index = "111111111111111" ELSE
                   x"00000002" WHEN int_index(0) = '0' ELSE 
                   x"00000003";
END Behavior;
