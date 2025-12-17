LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY tb_ALU IS
END tb_ALU;

ARCHITECTURE Behavior OF tb_ALU IS
    -- Component Declaration for the Unit Under Test (UUT)
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

    -- Inputs
    SIGNAL SrcA     : std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL SrcB     : std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL ALU_Sel  : std_logic_vector(2 downto 0) := (others => '0');

    -- Outputs
    SIGNAL ALU_Result : std_logic_vector(31 downto 0);
    SIGNAL Zero       : std_logic;
    SIGNAL Negative   : std_logic;
    SIGNAL Carry      : std_logic;

    CONSTANT clk_period : time := 10 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: ALU PORT MAP (
        SrcA        => SrcA,
        SrcB        => SrcB,
        ALU_Sel     => ALU_Sel,
        ALU_Result  => ALU_Result,
        Zero        => Zero,
        Negative    => Negative,
        Carry       => Carry
    );

    -- Stimulus process
    stim_proc: process
    begin		
        -- hold reset state for 100 ns.
        wait for 100 ns;	

        -- 1. Test MOV (Pass A) - Op "000"
        SrcA <= x"AAAA5555";
        ALU_Sel <= "000";
        wait for clk_period;
        ASSERT (ALU_Result = x"AAAA5555") REPORT "MOV Failed" SEVERITY ERROR;

        -- 2. Test LDM (Pass B) - Op "001"
        SrcB <= x"12345678";
        ALU_Sel <= "001";
        wait for clk_period;
        ASSERT (ALU_Result = x"12345678") REPORT "LDM Failed" SEVERITY ERROR;

        -- 3. Test ADD - Op "010"
        SrcA <= x"00000005";
        SrcB <= x"00000002";
        ALU_Sel <= "010";
        wait for clk_period;
        ASSERT (ALU_Result = x"00000007") REPORT "ADD Failed" SEVERITY ERROR;
        
        -- Test ADD Carry
        SrcA <= x"FFFFFFFF";
        SrcB <= x"00000001";
        wait for clk_period;
        ASSERT (ALU_Result = x"00000000") REPORT "ADD Overflow Value Failed" SEVERITY ERROR;
        ASSERT (Carry = '1') REPORT "ADD Carry Failed" SEVERITY ERROR;
        ASSERT (Zero = '1') REPORT "ADD Zero Flag Failed" SEVERITY ERROR;

        -- 4. Test SUB - Op "011"
        SrcA <= x"00000005";
        SrcB <= x"00000002";
        ALU_Sel <= "011";
        wait for clk_period;
        ASSERT (ALU_Result = x"00000003") REPORT "SUB Failed" SEVERITY ERROR;
        ASSERT (Carry = '0') REPORT "SUB No Carry Failed" SEVERITY ERROR;

        -- Test SUB Negative
        SrcA <= x"00000002";
        SrcB <= x"00000005";
        wait for clk_period;
        -- 2 - 5 = -3 = 0xFFFFFFFD
        ASSERT (ALU_Result = x"FFFFFFFD") REPORT "SUB Negative Value Failed" SEVERITY ERROR;
        ASSERT (Negative = '1') REPORT "SUB Negative Flag Failed" SEVERITY ERROR;

        -- 5. Test AND - Op "100"
        SrcA <= x"F0F0F0F0";
        SrcB <= x"FFFF0000";
        ALU_Sel <= "100";
        wait for clk_period;
        ASSERT (ALU_Result = x"F0F00000") REPORT "AND Failed" SEVERITY ERROR;

        -- 6. Test NOT - Op "101"
        SrcA <= x"00000000";
        ALU_Sel <= "101";
        wait for clk_period;
        ASSERT (ALU_Result = x"FFFFFFFF") REPORT "NOT Failed" SEVERITY ERROR;

        -- 7. Test INC - Op "110"
        SrcA <= x"0000000A";
        ALU_Sel <= "110";
        wait for clk_period;
        ASSERT (ALU_Result = x"0000000B") REPORT "INC Failed" SEVERITY ERROR;

        -- 8. Test SETC - Op "111"
        ALU_Sel <= "111";
        wait for clk_period;
        ASSERT (ALU_Result = x"00000000") REPORT "SETC Value Failed" SEVERITY ERROR;
        ASSERT (Carry = '1') REPORT "SETC Carry Flag Failed" SEVERITY ERROR;

        REPORT "ALU Simulation Completed Successfully";
        wait;
    end process;

END Behavior;