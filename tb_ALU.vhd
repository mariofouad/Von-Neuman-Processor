library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU_tb is
-- Testbenches do not have ports
end ALU_tb;

architecture Behavior of ALU_tb is

    -- 1. Component Declaration (Must match your ALU entity exactly)
    component ALU
    Port (
        SrcA        : in  STD_LOGIC_VECTOR (31 downto 0);
        SrcB        : in  STD_LOGIC_VECTOR (31 downto 0);
        ALU_Control : in  STD_LOGIC_VECTOR (3 downto 0);
        ALU_Result  : out STD_LOGIC_VECTOR (31 downto 0);
        Zero        : out STD_LOGIC;
        Negative    : out STD_LOGIC;
        Carry       : out STD_LOGIC
    );
    end component;

    -- 2. Signal Definitions (Wires to connect to the ALU)
    signal t_SrcA        : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal t_SrcB        : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal t_ALU_Control : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
    
    signal t_ALU_Result  : STD_LOGIC_VECTOR (31 downto 0);
    signal t_Zero        : STD_LOGIC;
    signal t_Negative    : STD_LOGIC;
    signal t_Carry       : STD_LOGIC;

begin

    -- 3. Instantiate the Unit Under Test (UUT)
    uut: ALU Port Map (
        SrcA        => t_SrcA,
        SrcB        => t_SrcB,
        ALU_Control => t_ALU_Control,
        ALU_Result  => t_ALU_Result,
        Zero        => t_Zero,
        Negative    => t_Negative,
        Carry       => t_Carry
    );

    -- 4. Stimulus Process (Apply inputs over time)
    -- Stimulus Process
    stim_proc: process
    begin
        -- Initial wait
        wait for 100 ps;

        -- Test Case 1: ADD
        t_SrcA <= x"0000000A"; 
        t_SrcB <= x"00000005"; 
        t_ALU_Control <= "0000"; 
        wait for 100 ps; -- Wait 100 ps before next change

        -- Test Case 2: SUB
        t_SrcA <= x"00000014"; 
        t_SrcB <= x"00000005"; 
        t_ALU_Control <= "0001"; 
        wait for 100 ps;

        -- Test Case 3: NOT
        t_SrcA <= x"00000000"; 
        t_ALU_Control <= "0101"; 
        wait for 100 ps;

        wait; -- Stop
    end process;
end Behavior;