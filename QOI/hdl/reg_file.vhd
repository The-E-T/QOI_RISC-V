--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     reg_file - Behavioural
-- Project Name:    HWSWCD
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20241126   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

library work;
    use work.PKG_hwswcd.ALL;

entity reg_file is
    port(
        clock : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        ce : in std_logic;
        we : in std_logic;
        src1 : in std_logic_vector(C_REGCOUNT_LOG2-1 downto 0);
        src2 : in std_logic_vector(C_REGCOUNT_LOG2-1 downto 0);
        dest : in std_logic_vector(C_REGCOUNT_LOG2-1 downto 0);
        data : in std_logic_vector(C_WIDTH-1 downto 0);
        data1 : out std_logic_vector(C_WIDTH-1 downto 0);
        data2 : out std_logic_vector(C_WIDTH-1 downto 0)
    );
end entity reg_file;

architecture Behavioural of reg_file is

    -- (DE-)LOCALISING IN/OUTPUTS
    signal clock_i : STD_LOGIC;
    signal reset_i : STD_LOGIC;
    signal ce_i : std_logic;
    signal we_i : std_logic;
    signal src1_i : std_logic_vector(C_REGCOUNT_LOG2-1 downto 0);
    signal src2_i : std_logic_vector(C_REGCOUNT_LOG2-1 downto 0);
    signal dest_i : std_logic_vector(C_REGCOUNT_LOG2-1 downto 0);
    signal data_i : std_logic_vector(C_WIDTH-1 downto 0);
    signal data1_o : std_logic_vector(C_WIDTH-1 downto 0);
    signal data2_o : std_logic_vector(C_WIDTH-1 downto 0); 

    signal src1_int : natural range 0 to C_REGCOUNT-1;
    signal src2_int : natural range 0 to C_REGCOUNT-1;
    signal dest_int : natural range 0 to C_REGCOUNT-1;

    signal rf : T_regfile;
begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    clock_i <= clock;
    reset_i <= reset;
    ce_i <= ce;
    we_i <= we;
    src1_i <= src1;
    src2_i <= src2;
    dest_i <= dest;
    data_i <= data;
    data1 <= data1_o;
    data2 <= data2_o;


    -------------------------------------------------------------------------------
    -- COMBINATORIAL
    -------------------------------------------------------------------------------
    -- src1_int <= to_integer(unsigned(src1_i));
    -- src2_int <= to_integer(unsigned(src2_i));
    dest_int <= to_integer(unsigned(dest_i));


    -------------------------------------------------------------------------------
    -- REGISTER
    -------------------------------------------------------------------------------
    PREG: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 
                rf <= (others => (others => '0'));
            else
                if ce_i = '1' then 
                    if we_i = '1' and dest_int /= 0 then 
                        rf(dest_int) <= data_i;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- data1_o <= rf(src1_int);
    -- data2_o <= rf(src2_int);
    
    PMUX_source1: process(src1_i, rf)
    begin
        case src1_i is
            when "00001" => data1_o <= rf(1);
            when "00010" => data1_o <= rf(2);
            when "00011" => data1_o <= rf(3);
            when "00100" => data1_o <= rf(4);
            when "00101" => data1_o <= rf(5);
            when "00110" => data1_o <= rf(6);
            when "00111" => data1_o <= rf(7);
            when "01000" => data1_o <= rf(8);
            when "01001" => data1_o <= rf(9);
            when "01010" => data1_o <= rf(10);
            when "01011" => data1_o <= rf(11);
            when "01100" => data1_o <= rf(12);
            when "01101" => data1_o <= rf(13);
            when "01110" => data1_o <= rf(14);
            when "01111" => data1_o <= rf(15);
            when "10000" => data1_o <= rf(16);
            when "10001" => data1_o <= rf(17);
            when "10010" => data1_o <= rf(18);
            when "10011" => data1_o <= rf(19);
            when "10100" => data1_o <= rf(20);
            when "10101" => data1_o <= rf(21);
            when "10110" => data1_o <= rf(22);
            when "10111" => data1_o <= rf(23);
            when "11000" => data1_o <= rf(24);
            when "11001" => data1_o <= rf(25);
            when "11010" => data1_o <= rf(26);
            when "11011" => data1_o <= rf(27);
            when "11100" => data1_o <= rf(28);
            when "11101" => data1_o <= rf(29);
            when "11110" => data1_o <= rf(30);
            when "11111" => data1_o <= rf(31);
            when others => data1_o <= rf(0);
        end case;
    end process;

    PMUX_source2: process(src2_i, rf)
    begin
        case src2_i is
            when "00001" => data2_o <= rf(1);
            when "00010" => data2_o <= rf(2);
            when "00011" => data2_o <= rf(3);
            when "00100" => data2_o <= rf(4);
            when "00101" => data2_o <= rf(5);
            when "00110" => data2_o <= rf(6);
            when "00111" => data2_o <= rf(7);
            when "01000" => data2_o <= rf(8);
            when "01001" => data2_o <= rf(9);
            when "01010" => data2_o <= rf(10);
            when "01011" => data2_o <= rf(11);
            when "01100" => data2_o <= rf(12);
            when "01101" => data2_o <= rf(13);
            when "01110" => data2_o <= rf(14);
            when "01111" => data2_o <= rf(15);
            when "10000" => data2_o <= rf(16);
            when "10001" => data2_o <= rf(17);
            when "10010" => data2_o <= rf(18);
            when "10011" => data2_o <= rf(19);
            when "10100" => data2_o <= rf(20);
            when "10101" => data2_o <= rf(21);
            when "10110" => data2_o <= rf(22);
            when "10111" => data2_o <= rf(23);
            when "11000" => data2_o <= rf(24);
            when "11001" => data2_o <= rf(25);
            when "11010" => data2_o <= rf(26);
            when "11011" => data2_o <= rf(27);
            when "11100" => data2_o <= rf(28);
            when "11101" => data2_o <= rf(29);
            when "11110" => data2_o <= rf(30);
            when "11111" => data2_o <= rf(31);
            when others => data2_o <= rf(0);
        end case;
    end process;

end Behavioural;
