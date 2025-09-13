--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     wrapped_timer - Behavioural
-- Project Name:    wrapped_timer
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20241212   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;

library work;
    use work.PKG_hwswcd.ALL;

entity wrapped_timer is
    generic(
        G_WIDTH : natural := 8
    );
    port(
        clock : in STD_LOGIC;
        reset : in STD_LOGIC;
        irq : out STD_LOGIC;
        iface_di : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
        iface_a : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
        iface_we : in STD_LOGIC;
        iface_do : out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0)
    );
end entity wrapped_timer;

architecture Behavioural of wrapped_timer is

    -- (DE-)LOCALISING IN/OUTPUTS
    signal clock_i : STD_LOGIC;
    signal reset_i : STD_LOGIC;
    signal irq_o : STD_LOGIC;
    signal iface_di_i : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal iface_a_i : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal iface_we_i : STD_LOGIC;
    signal iface_do_o : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

    signal reg0, reg1, reg2, reg3: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

    signal address_within_range : STD_LOGIC;
    signal targeted_register : STD_LOGIC_VECTOR(17 downto 0);

    signal timer_CS : STD_LOGIC_VECTOR(1 downto 0);
    signal timer_WGM : STD_LOGIC_VECTOR(1 downto 0);
    signal timer_CMP : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
    signal timer_OFl : std_LOGIC;
    signal timer_PWM : std_LOGIC;
    signal timer_CEQ : std_LOGIC;
    signal timer_TCNT : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);


    signal interrupt_request, interrupt_request_set, interrupt_request_reset : STD_LOGIC;

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
    irq <= irq_o;
    


    -------------------------------------------------------------------------------
    -- PARSING
    -------------------------------------------------------------------------------
    address_within_range <= '1' when iface_a_i(C_WIDTH-1 downto C_PERIPHERAL_MASK_LOWINDEX) = C_TIMER_BASE_ADDRESS_MASK else '0';
    targeted_register <= iface_a_i(19 downto 2);

    timer_CS <= reg0(1 downto 0);
    timer_WGM <= reg0(3 downto 2);
    interrupt_request_reset <= reg0(4);
    timer_CMP <= reg1(G_WIDTH-1 downto 0);
    reg2 <= C_GND(C_WIDTH-1 downto 3) & timer_PWM & timer_OFl & timer_CEQ;
    reg3 <= C_GND(C_WIDTH-1 downto G_WIDTH) & timer_TCNT;

    irq_o <= interrupt_request;

    -------------------------------------------------------------------------------
    -- WRITE
    -------------------------------------------------------------------------------
    PREG: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 
                reg0 <= (others => '0');
                reg1 <= (others => '0');
            else
                if address_within_range = '1' then 
                    if iface_we_i = '1' then 
                        if targeted_register = "000000000000000000" then 
                            reg0 <= iface_di_i;
                        elsif targeted_register = "000000000000000001" then 
                            reg1 <= iface_di_i;
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

    interrupt_request_set <= timer_CEQ;
    --interrupt_request_reset <= reg0(4);
    PSRFF: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 
                interrupt_request <= '0';
            else
                if interrupt_request_reset = '1' then 
                    interrupt_request <= '0';
                elsif interrupt_request_set = '1' then 
                    interrupt_request <= '1';
                end if;
            end if;
        end if;
    end process;


    -------------------------------------------------------------------------------
    -- CORE
    -------------------------------------------------------------------------------
    timer_inst00: component timer generic map(G_WIDTH => G_WIDTH) port map(
        clock => clock_i,
        reset => reset_i,
        CS => timer_CS,
        WGM => timer_WGM,
        CMP => timer_CMP,
        OFl => timer_OFl,
        PWM => timer_PWM,
        CEQ => timer_CEQ,
        TCNT => timer_TCNT
    );

end Behavioural;
