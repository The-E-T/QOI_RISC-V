--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     wrapped_sensor - Behavioural
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

library work;
    use work.PKG_hwswcd.ALL;

entity wrapped_sensor is
    generic(
        G_PIXELS : natural := 3750
    );
    port(
        clock : in STD_LOGIC;
        reset : in STD_LOGIC;
        iface_di : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
        iface_a : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
        iface_we : in STD_LOGIC;
        iface_do : out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0)
    );
end entity wrapped_sensor;


architecture Behavioural of wrapped_sensor is

    -- (DE-)LOCALISING IN/OUTPUTS
    signal clock_i : STD_LOGIC;
    signal reset_i : STD_LOGIC;
    signal iface_di_i : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal iface_a_i : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal iface_we_i : STD_LOGIC;
    signal iface_do_o : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

    signal reg0, reg1, reg2, reg3, diff_pixel, diff_pixel_luma: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    
    signal cur_pixel, buff_prev_pixel: unsigned(C_WIDTH-1 downto 0);
    signal cr, cg, cb, ca, pr, pg, pb, pa: unsigned(7 downto 0);
    signal dr, dg, db, temp_dr, temp_dg, temp_db, temp_dgg, temp_drg, temp_dbg: signed(7 downto 0);
    signal drg, dbg: signed(7 downto 0); 
    
    signal address_within_range : STD_LOGIC;
    signal targeted_register : STD_LOGIC_VECTOR(17 downto 0);



    signal sensor_re : STD_LOGIC;
    signal sensor_pixeldata : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal sensor_first : STD_LOGIC;

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    clock_i <= clock;
    reset_i <= reset;
    iface_di_i <= iface_di;
    iface_a_i <= iface_a;
    iface_we_i <= iface_we;
    iface_do <= iface_do_o;
    

    -------------------------------------------------------------------------------
    -- PARSING
    -------------------------------------------------------------------------------
    address_within_range <= '1' when iface_a_i(C_WIDTH-1 downto C_PERIPHERAL_MASK_LOWINDEX) = C_SENSOR_BASE_ADDRESS_MASK else '0';
    targeted_register <= iface_a_i(19 downto 2);

    sensor_re <= reg0(0);
    reg1 <= sensor_pixeldata;
    cur_pixel <= unsigned(sensor_pixeldata);
    -- reg2 <= (0 => sensor_first, others => '0');
    -- reg2 <= x"00" & x"08" & x"08" & "0000000" & sensor_first;
    reg2 <= x"00" & x"4B" & x"32" & "0000000" & sensor_first;
    
    cr <= cur_pixel(31 downto 24);
    cg <= cur_pixel(23 downto 16);
    cb <= cur_pixel(15 downto 8);
    ca <= cur_pixel(7 downto 0);

    pr <= buff_prev_pixel(31 downto 24);
    pg <= buff_prev_pixel(23 downto 16);
    pb <= buff_prev_pixel(15 downto 8);
    pa <= buff_prev_pixel(7 downto 0);
    
    temp_dr <= dr + 2;
    temp_dg <= dg + 2;
    temp_db <= db + 2;
    
    diff_pixel(31 downto 8) <= (others => '0');
    diff_pixel(7 downto 6) <= b"01";
    diff_pixel(5 downto 4) <= std_logic_vector(temp_dr(1 downto 0));
    diff_pixel(3 downto 2) <= std_logic_vector(temp_dg(1 downto 0));
    diff_pixel(1 downto 0) <= std_logic_vector(temp_db(1 downto 0));
    
    
    drg <= dr - dg;
    dbg <= db - dg;
    
    temp_dgg <= dg + 32;
    temp_drg <= drg + 8;
    temp_dbg <= dbg + 8;
    
    diff_pixel_luma(31 downto 16) <= (others => '0');
    diff_pixel_luma(15 downto 14) <= b"10";
    diff_pixel_luma(13 downto 8) <= std_logic_vector(temp_dgg(5 downto 0));
    diff_pixel_luma(7 downto 4) <= std_logic_vector(temp_drg(3 downto 0));
    diff_pixel_luma(3 downto 0) <= std_logic_vector(temp_dbg(3 downto 0));
    
--    dr <= signed(cr) - signed(pr);
--    dg <= signed(cg) - signed(pg);
--    db <= signed(cb) - signed(pb);
    
    CLOSE_DIFF: process(cr, pr, cg, pg, cb, pb)
    begin
        if cr > pr then
            dr <= signed(256 - (pr - cr));
        else
            dr <= signed(cr - pr);
        end if;
        
        if cg > pg then
            dg <= signed(256 - (pg - cg));
        else
            dg <= signed(cg - pg);
        end if;
        
        if cb > pb then
            db <= signed(256 - (pb - cb));
        else
            db <= signed(cb - pb);
        end if;
    end process;
        
    COMPUTE: process(dr, dg, db, ca, drg, dbg, diff_pixel, diff_pixel_luma)
    begin
        if (dr >= -2 and dr <= 1 and dg >= -2 and dg <= 1 and db >= -2 and db <= 1 and ca = pa) then
            reg3 <= diff_pixel;
        elsif (dg >= -32 and dg <= 31 and (dr - dg) >= -8 and (dr - dg) <= 7 and (db - dg) >= -8 and (db - dg) <= 7 and ca = pa) then
            reg3 <= diff_pixel_luma;
        else
            reg3 <= x"00000000";
        end if;
    end process;

    -------------------------------------------------------------------------------
    -- WRITE
    -------------------------------------------------------------------------------
    PREG: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 
                reg0 <= (others => '0');
                buff_prev_pixel <= x"000000ff";
                
            else
                if address_within_range = '1' then 
                    if iface_we_i = '1' then 
                        if targeted_register = "000000000000000000" then 
                            if iface_di_i(0) = '1' then
                                buff_prev_pixel <= cur_pixel;
                            end if;
                            reg0 <= iface_di_i;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;


    -------------------------------------------------------------------------------
    -- READ
    -------------------------------------------------------------------------------
    PMUX: process(address_within_range, iface_we_i, targeted_register, reg0, reg1, reg2, reg3)
    begin
        iface_do_o <= C_GND;
        if address_within_range = '1' and iface_we_i = '0' then 
            case targeted_register is
                when "000000000000000000" => iface_do_o <= reg0;
                when "000000000000000001" => iface_do_o <= reg1;
                when "000000000000000010" => iface_do_o <= reg2;
                when "000000000000000011" => iface_do_o <= reg3;
                when others  => iface_do_o <= C_GND;
            end case;
        end if;
    end process;


    -------------------------------------------------------------------------------
    -- CORE
    -------------------------------------------------------------------------------
    sensor_inst00: component sensor generic map(G_PIXELS => G_PIXELS) port map(
        clock => clock_i,
        reset => reset_i,
        pixel_data_out_re => sensor_re,
        pixel_data_out => sensor_pixeldata,
        first => sensor_first
    );

end Behavioural;
