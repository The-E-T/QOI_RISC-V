--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     sensor - Behavioural
-- Project Name:    sensor
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20250324   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

library UNISIM;
    use UNISIM.vcomponents.all;

entity sensor is
    generic (G_PIXELS : natural := 3750);
    port(
        clock : in STD_LOGIC;
        reset : in STD_LOGIC;
        pixel_data_out_re : in STD_LOGIC;
        pixel_data_out : out STD_LOGIC_VECTOR(31 downto 0);
        first : out std_logic
    );
end entity sensor;

architecture Behavioural of sensor is

    -- (DE-)LOCALISING IN/OUTPUTS
    signal clock_i : STD_LOGIC;
    signal reset_i : STD_LOGIC;
    signal pixel_data_out_o : STD_LOGIC_VECTOR(31 downto 0);
    signal pixel_data_out_re_i : STD_LOGIC;
    signal pixel_data_out_re_d : STD_LOGIC;
    signal first_o : STD_LOGIC;

    signal address : natural range 0 to G_PIXELS-1+2;
    signal address_vec : STD_LOGIC_VECTOR(11 downto 0);
    
    constant C_NULL : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    constant C_ONES : STD_LOGIC_VECTOR(31 downto 0) := (others => '1');

    component sensor_r is
        port(
            clock : in STD_LOGIC;
            address : in STD_LOGIC_VECTOR(11 downto 0);
            data_out : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component sensor_r;

    component sensor_g is
        port(
            clock : in STD_LOGIC;
            address : in STD_LOGIC_VECTOR(11 downto 0);
            data_out : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component sensor_g;

    component sensor_b is
        port(
            clock : in STD_LOGIC;
            address : in STD_LOGIC_VECTOR(11 downto 0);
            data_out : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component sensor_b;

    signal pixel_r, pixel_g, pixel_b : STD_LOGIC_VECTOR(7 downto 0);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    clock_i <= clock;
    reset_i <= reset;
    pixel_data_out <= pixel_data_out_o;
    pixel_data_out_re_i <= pixel_data_out_re;
    first <= first_o;


    PREG: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 
                address <= 0;
                pixel_data_out_re_d <= '0';
                first_o <= '1';
            else
                if pixel_data_out_re_i = '1' and pixel_data_out_re_d = '0' then
                    if address = G_PIXELS-1+2 then
                        address <= 0;
                    else
                        address <= address + 1;
                    end if;
                end if;

                pixel_data_out_re_d <= pixel_data_out_re_i;

                if address = 0 then
                    first_o <= '1'; 
                else
                    first_o <= '0'; 
                end if;

            end if;
        end if;
    end process;

    address_vec <= std_logic_vector(to_unsigned(address, 12));

    pixel_data_out_o <= pixel_r & pixel_g & pixel_b & x"FF";

    sensor_r_inst00: component sensor_r port map(
        clock => clock_i,
        address => address_vec,
        data_out => pixel_r
    );

    sensor_g_inst00: component sensor_g port map(
        clock => clock_i,
        address => address_vec,
        data_out => pixel_g
    );

    sensor_b_inst00: component sensor_b port map(
        clock => clock_i,
        address => address_vec,
        data_out => pixel_b
    );
        

end Behavioural;
