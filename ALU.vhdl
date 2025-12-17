library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port (
        -- Data Inputs
        SrcA        : in  STD_LOGIC_VECTOR (31 downto 0);
        SrcB        : in  STD_LOGIC_VECTOR (31 downto 0);
        
        -- Control Signal (3 bits is enough for 8 distinct operations)
        ALU_Sel     : in  STD_LOGIC_VECTOR (2 downto 0);
        
        -- Outputs
        ALU_Result  : out STD_LOGIC_VECTOR (31 downto 0);
        Zero        : out STD_LOGIC;
        Negative    : out STD_LOGIC;
        Carry       : out STD_LOGIC
    );
end ALU;

architecture Behavioral of ALU is
    -- Internal signals for calculation (33 bits to capture Carry)
    signal result_temp : unsigned(32 downto 0) := (others => '0');
    signal a_uns       : unsigned(32 downto 0);
    signal b_uns       : unsigned(32 downto 0);
    
    -- Flag intermediates
    signal z_flag, n_flag, c_flag : std_logic;

begin
    
    -- Zero-extend inputs to 33 bits for arithmetic
    a_uns <= resize(unsigned(SrcA), 33);
    b_uns <= resize(unsigned(SrcB), 33);

    process(a_uns, b_uns, ALU_Sel)
    begin
        -- Default: Clear Carry/Result
        result_temp <= (others => '0');
        c_flag <= '0'; 

        case ALU_Sel is
            -- 000: MOV / NOP / OUT (Pass SrcA)
            when "000" => 
                result_temp <= a_uns;
                
            -- 001: LDM (Pass SrcB / Immediate)
            when "001" => 
                result_temp <= b_uns;
                
            -- 010: ADD / IADD / LDD / STD / POP / RET (A + B)
            when "010" => 
                result_temp <= a_uns + b_uns;
                
            -- 011: SUB / PUSH / CALL (A - B)
            when "011" => 
                result_temp <= a_uns - b_uns;
                
            -- 100: AND
            when "100" => 
                result_temp <= a_uns and b_uns;
                
            -- 101: NOT (1's Complement)
            when "101" => 
                result_temp <= not a_uns;
                -- 'Not' on unsigned 33-bit will invert the MSB (carry bit) too.
                -- We mask it out later or ignore the carry bit for logical ops.
                
            -- 110: INC (A + 1)
            when "110" => 
                result_temp <= a_uns + 1;
                
            -- 111: SETC (Result = 0, Carry = 1)
            when "111" => 
                result_temp <= (others => '0');
                -- We will force the carry output below
                
            when others =>
                result_temp <= (others => '0');
        end case;
    end process;

    -- --- OUTPUT ASSIGNMENTS ---
    
    -- 1. Result (Lower 32 bits)
    ALU_Result <= std_logic_vector(result_temp(31 downto 0));

    -- 2. Zero Flag (Z): Set if Result is 0
    Zero <= '1' when result_temp(31 downto 0) = x"00000000" else '0';

    -- 3. Negative Flag (N): Set if MSB (bit 31) is 1
    Negative <= result_temp(31);

    -- 4. Carry Flag (C): Logic depends on Operation
    process(ALU_Sel, result_temp)
    begin
        case ALU_Sel is
            when "010" | "011" | "110" => -- ADD, SUB, INC
                Carry <= result_temp(32); -- Bit 32 is the arithmetic carry/borrow
                
            when "111" => -- SETC
                Carry <= '1'; -- Force Carry to 1
                
            when others => -- MOV, AND, NOT, LDM
                Carry <= '0'; -- Logical ops/Moves don't generate arithmetic carry
        end case;
    end process;

end Behavioral;