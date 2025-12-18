library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegisterFile is
    Port (
        clk           : in  STD_LOGIC;
        rst           : in  STD_LOGIC;
        
        -- Control Signals (One for each write port)
        reg_write_en1 : in  STD_LOGIC;
        reg_write_en2 : in  STD_LOGIC;
        
        -- Read Addresses
        read_addr1    : in  STD_LOGIC_VECTOR (2 downto 0);
        read_addr2    : in  STD_LOGIC_VECTOR (2 downto 0);
        
        -- Write Port 1
        write_addr1   : in  STD_LOGIC_VECTOR (2 downto 0);
        write_data1   : in  STD_LOGIC_VECTOR (31 downto 0);

        -- Write Port 2 (The new addition)
        write_addr2   : in  STD_LOGIC_VECTOR (2 downto 0);
        write_data2   : in  STD_LOGIC_VECTOR (31 downto 0);
        
        -- Data Outputs
        read_data1    : out STD_LOGIC_VECTOR (31 downto 0);
        read_data2    : out STD_LOGIC_VECTOR (31 downto 0)
    );
end RegisterFile;

architecture Behavioral of RegisterFile is
    type reg_array is array (0 to 7) of STD_LOGIC_VECTOR (31 downto 0);
    signal registers : reg_array := (others => (others => '0'));
begin

    -- Write Process (Synchronous)
    process(clk, rst)
    begin
        if rst = '1' then
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            -- Write Port 1
            if reg_write_en1 = '1' then
                registers(to_integer(unsigned(write_addr1))) <= write_data1;
            end if;

            -- Write Port 2
            -- Note: If addr1 = addr2, Port 2 will overwrite Port 1 (Priority to Port 2)
            if reg_write_en2 = '1' then
                registers(to_integer(unsigned(write_addr2))) <= write_data2;
            end if;
        end if;
    end process;

    -- Read Process (Asynchronous with Internal Forwarding/Write-First)
    read_data1 <= write_data2 when (reg_write_en2 = '1' and read_addr1 = write_addr2) else
                  write_data1 when (reg_write_en1 = '1' and read_addr1 = write_addr1) else
                  registers(to_integer(unsigned(read_addr1)));

    read_data2 <= write_data2 when (reg_write_en2 = '1' and read_addr2 = write_addr2) else
                  write_data1 when (reg_write_en1 = '1' and read_addr2 = write_addr1) else
                  registers(to_integer(unsigned(read_addr2)));

end Behavioral;