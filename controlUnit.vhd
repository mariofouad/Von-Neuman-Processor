library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ControlUnit is
    Port (
        Opcode      : in  STD_LOGIC_VECTOR (4 downto 0);
        
        -- Control Signals
        RegWrite    : out STD_LOGIC;
        MemWrite    : out STD_LOGIC;
        MemToReg    : out STD_LOGIC; -- 1=Memory, 0=ALU
        ALU_Src     : out STD_LOGIC; -- 1=Immediate, 0=Register
        ALU_Sel     : out STD_LOGIC_VECTOR (2 downto 0); -- Selects ALU Operation
        Branch      : out STD_LOGIC  -- 1 indicates a Jump/Branch/Call
    );
end ControlUnit;

architecture Behavioral of ControlUnit is
begin
    process(Opcode)
    begin
        -- 1. Default Values (To prevent Latches and Unintended Writes)
        RegWrite <= '0'; 
        MemWrite <= '0'; 
        MemToReg <= '0';
        ALU_Src  <= '0'; 
        Branch   <= '0'; 
        ALU_Sel  <= "000"; -- Default to MOV/PassA

        case Opcode is
            -- ===============================
            -- R-TYPE OPERATIONS
            -- ===============================
            
            -- NOP (00000)
            when "00000" => 
                null; -- Do nothing

            -- HLT (00001)
            when "00001" => 
                -- Usually handled by a separate "Halt" signal, 
                -- for now, ensures no state changes.
                null;

            -- SETC (00010) -> Set Carry Flag
            when "00010" => 
                ALU_Sel <= "111"; -- ALU operation specific for SETC

            -- NOT (00011)
            when "00011" => 
                RegWrite <= '1'; 
                ALU_Sel  <= "101"; -- NOT operation

            -- INC (00100)
            when "00100" => 
                RegWrite <= '1'; 
                ALU_Sel  <= "110"; -- INC operation

            -- OUT (00101)
            when "00101" => 
                -- Note: Needs an "Out_Enable" signal in the future
                ALU_Sel <= "000"; -- Pass Data

            -- IN (00110)
            when "00110" => 
                RegWrite <= '1'; 
                -- Note: Needs a Mux to select InPort instead of ALU/Mem
                ALU_Sel <= "000"; 

            -- MOV (00111) -> Pass A
            when "00111" => 
                RegWrite <= '1'; 
                ALU_Sel  <= "000"; -- Pass SrcA

            -- SWAP (01000)
            when "01000" => 
                -- Complex: Requires temp reg or stalls. 
                -- For now, acts like MOV (One way swap)
                RegWrite <= '1';
                ALU_Sel  <= "000"; 

            -- ADD (01001)
            when "01001" => 
                RegWrite <= '1'; 
                ALU_Sel  <= "010"; 

            -- SUB (01010)
            when "01010" => 
                RegWrite <= '1'; 
                ALU_Sel  <= "011"; 

            -- AND (01011)
            when "01011" => 
                RegWrite <= '1'; 
                ALU_Sel  <= "100"; 

            -- ===============================
            -- I-TYPE OPERATIONS
            -- ===============================
            
            -- IADD (01100) -> Add Immediate
            when "01100" => 
                RegWrite <= '1'; 
                ALU_Src  <= '1';   -- Use Immediate
                ALU_Sel  <= "010"; -- ADD

            -- PUSH (01101)
            when "01101" => 
                MemWrite <= '1'; 
                -- Note: Requires SP control logic (Decrement SP)
                ALU_Sel  <= "011"; -- Sub (for SP-1 calculation logic if handled here)

            -- POP (01110)
            when "01110" => 
                RegWrite <= '1'; 
                MemToReg <= '1';   -- Load from Memory
                -- Note: Requires SP control logic (Increment SP)

            -- LDM (01111) -> Load Immediate
            when "01111" =>
                RegWrite <= '1'; 
                ALU_Src  <= '1';   -- Use Immediate
                ALU_Sel  <= "001"; -- Pass B (Immediate)

            -- LDD (10000) -> Load Direct (Mem[Reg+Off])
            when "10000" =>
                RegWrite <= '1'; 
                ALU_Src  <= '1';   -- Use Offset
                ALU_Sel  <= "010"; -- Add (Base + Offset)
                MemToReg <= '1';   -- Data comes from Memory

            -- STD (10001) -> Store Direct (Mem[Reg+Off] = Reg)
            when "10001" =>
                MemWrite <= '1'; 
                ALU_Src  <= '1';   -- Use Offset
                ALU_Sel  <= "010"; -- Add (Base + Offset)

            -- ===============================
            -- J-TYPE / BRANCH OPERATIONS
            -- ===============================
            
            -- JZ (10010), JN (10011), JC (10100), JMP (10101), CALL (10110), RET (10111)
            -- All these require the PC to load a new value.
            when "10010" | "10011" | "10100" | "10101" | "10110" | "10111" =>
                Branch <= '1';
                
            -- INT (11000), RTI (11001)
            when "11000" | "11001" =>
                -- Interrupt logic usually handled by specialized unit, 
                -- but treated as Control Flow change here.
                Branch <= '1';

            when others => 
                -- Safety: treat unknown opcodes as NOPs
                RegWrite <= '0';
        end case;
    end process;
end Behavioral;