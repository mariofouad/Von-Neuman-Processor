LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE Processor_Pkg IS
    -- Standard Word and Address widths
    CONSTANT WORD_WIDTH : integer := 32;
    CONSTANT ADDR_WIDTH : integer := 12; -- 4K Memory = 2^12 addresses

    SUBTYPE Word IS std_logic_vector(WORD_WIDTH-1 DOWNTO 0);
    SUBTYPE Address IS std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);

    -- Operation Codes
    CONSTANT OP_NOP  : std_logic_vector(4 DOWNTO 0) := "00000";
    CONSTANT OP_HLT  : std_logic_vector(4 DOWNTO 0) := "00001";
    CONSTANT OP_SETC : std_logic_vector(4 DOWNTO 0) := "00010";
    CONSTANT OP_NOT  : std_logic_vector(4 DOWNTO 0) := "00011";
    CONSTANT OP_INC  : std_logic_vector(4 DOWNTO 0) := "00100";
    CONSTANT OP_OUT  : std_logic_vector(4 DOWNTO 0) := "00101";
    CONSTANT OP_IN   : std_logic_vector(4 DOWNTO 0) := "00110";
    CONSTANT OP_MOV  : std_logic_vector(4 DOWNTO 0) := "00111";
    CONSTANT OP_SWAP : std_logic_vector(4 DOWNTO 0) := "01000";
    CONSTANT OP_ADD  : std_logic_vector(4 DOWNTO 0) := "01001";
    CONSTANT OP_SUB  : std_logic_vector(4 DOWNTO 0) := "01010";
    CONSTANT OP_AND  : std_logic_vector(4 DOWNTO 0) := "01011";
    CONSTANT OP_IADD : std_logic_vector(4 DOWNTO 0) := "01100";
    CONSTANT OP_PUSH : std_logic_vector(4 DOWNTO 0) := "01101";
    CONSTANT OP_POP  : std_logic_vector(4 DOWNTO 0) := "01110";
    CONSTANT OP_LDM  : std_logic_vector(4 DOWNTO 0) := "01111";
    CONSTANT OP_LDD  : std_logic_vector(4 DOWNTO 0) := "10000";
    CONSTANT OP_STD  : std_logic_vector(4 DOWNTO 0) := "10001";
    CONSTANT OP_JZ   : std_logic_vector(4 DOWNTO 0) := "10010";
    CONSTANT OP_JN   : std_logic_vector(4 DOWNTO 0) := "10011";
    CONSTANT OP_JC   : std_logic_vector(4 DOWNTO 0) := "10100";
    CONSTANT OP_JMP  : std_logic_vector(4 DOWNTO 0) := "10101";
    CONSTANT OP_CALL : std_logic_vector(4 DOWNTO 0) := "10110";
    CONSTANT OP_RET  : std_logic_vector(4 DOWNTO 0) := "10111";
    CONSTANT OP_INT  : std_logic_vector(4 DOWNTO 0) := "11000";
    CONSTANT OP_RTI  : std_logic_vector(4 DOWNTO 0) := "11001";

    -- Fast Bits (bits 16:15 of instruction) for hazard detection
    -- Used to quickly identify control flow instructions without full decode
    CONSTANT FAST_NORMAL : std_logic_vector(1 DOWNTO 0) := "00"; -- Normal instructions
    CONSTANT FAST_INT    : std_logic_vector(1 DOWNTO 0) := "01"; -- INT
    CONSTANT FAST_RET    : std_logic_vector(1 DOWNTO 0) := "10"; -- RET, RTI
    CONSTANT FAST_CALL   : std_logic_vector(1 DOWNTO 0) := "11"; -- CALL

END Processor_Pkg;
