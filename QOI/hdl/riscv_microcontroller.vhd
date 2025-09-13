--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     riscv_microcontroller - Behavioural
-- Project Name:    riscv_microcontroller
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20241210   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;

library work;
    use work.PKG_hwswcd.ALL;

entity riscv_microcontroller is
    port(
        sys_clock : in STD_LOGIC;
        sys_reset : in STD_LOGIC;
        external_irq : in STD_LOGIC;
        riscv_clock : out std_logic;
        gpio_leds : out STD_LOGIC_VECTOR(3 downto 0);
        dmem_we_out : out STD_LOGIC;
        dmem_a_out : out STD_LOGIC_VECTOR(31 downto 0);
        dmem_di_out : out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity riscv_microcontroller;

architecture Behavioural of riscv_microcontroller is


    -- (DE-)LOCALISING IN/OUTPUTS
    signal sys_clock_i : STD_LOGIC;
    signal sys_reset_i : STD_LOGIC;
    signal external_irq_i : STD_LOGIC;
    signal gpio_leds_o : STD_LOGIC_VECTOR(3 downto 0);

    -- dmem
    signal dmem_do : STD_LOGIC_VECTOR(31 downto 0);
    signal dmem_do_dmem : STD_LOGIC_VECTOR(31 downto 0);
    signal dmem_we, dmem_we_manip : STD_LOGIC;
    signal dmem_a : STD_LOGIC_VECTOR(31 downto 0);
    signal dmem_di : STD_LOGIC_VECTOR(31 downto 0);
    
    --imem
    signal instruction : STD_LOGIC_VECTOR(31 downto 0);
    signal PC : STD_LOGIC_VECTOR(31 downto 0);
    
    -- CLOCK AND RESET
    signal clock : STD_LOGIC;
    signal reset : STD_LOGIC;
    
    -- PERIPHERALS
    signal ce : STD_LOGIC_VECTOR(2 downto 0);
    signal dmem_do_tcnt : STD_LOGIC_VECTOR(31 downto 0);
    signal leds : STD_LOGIC_VECTOR(31 downto 0);

    -- INTERRUPTS
    signal linked_interrupts : STD_LOGIC_VECTOR(31 downto 0);
    signal timer_irq : STD_LOGIC;
    signal external_irq_d : STD_LOGIC;
    signal external_irq_dd : STD_LOGIC;
    signal debouncer : integer range 0 to 800000-1;
    signal external_irq_sync_dbnc, external_irq_set, external_irq_reset : STD_LOGIC;
    
    --Sensor
    
   signal dmem_sensor : std_logic_vector(31 downto 0);
   
   --Hash
   
   signal dmem_hash : std_logic_vector(31 downto 0);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_clock_i <= sys_clock;
    sys_reset_i <= sys_reset;
    external_irq_i <= external_irq;
    gpio_leds <= gpio_leds_o;

    gpio_leds_o <= leds(3 downto 0);
    
    dmem_we_out <= dmem_we;
    dmem_a_out <= dmem_a;
    dmem_di_out <= dmem_di;
    
    riscv_clock <= ce(0);


    -------------------------------------------------------------------------------
    -- MICROPROCESSOR
    -------------------------------------------------------------------------------
    riscv_inst00: component riscv port map(
        clock => clock,
        reset => reset,
        ce => ce(0),
        irq => linked_interrupts,
        dmem_do => dmem_do,
        dmem_we => dmem_we,
        dmem_a => dmem_a,
        dmem_di => dmem_di,
        instruction => instruction,
        PC => PC
    );

    PREG_CPU_CTRL: process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then 
                ce <= (0 => '1', others => '0');
            else
                ce <= ce(0) & ce(ce'high downto 1);
            end if;
        end if;
    end process;


    -------------------------------------------------------------------------------
    -- IMEM
    -------------------------------------------------------------------------------
    two_k_bram_imem_inst00: component two_k_bram_imem port map(
        clock => clock,
        init_data_in => C_GND,
        init_write_enable => C_GND(0),
        init_address => C_GND(10 downto 0),
        data_in => C_GND,
        write_enable => C_GND(0),
        address => PC(12 downto 2),
        data_out => instruction
    );

    -------------------------------------------------------------------------------
    -- PERIPHERALS
    -------------------------------------------------------------------------------
    two_k_bram_dmem_inst00: component two_k_bram_dmem port map(
        clock => clock,
        init_data_in => C_GND,
        init_write_enable => C_GND(0),
        init_address => C_GND(10 downto 0),
        data_in => dmem_di,
        write_enable => dmem_we_manip,
        address => dmem_a(12 downto 2),
        data_out  => dmem_do_dmem
    );

    dmem_we_manip <= dmem_we when  dmem_a(C_WIDTH-1 downto C_PERIPHERAL_MASK_LOWINDEX) = C_DMEM_BASE_ADDRESS_MASK else '0';

    PREG_LEDS: process(clock)
    begin
        if rising_edge(clock) then 
            if reset = '1' then 
                leds <= C_GND;
            else
                if dmem_we = '1' and dmem_a(C_WIDTH-1 downto C_PERIPHERAL_MASK_LOWINDEX) = C_LED_BASE_ADDRESS_MASK then 
                    leds <= dmem_di;
                end if;
            end if;
        end if;
    end process;

    wrapped_timer_inst00: component wrapped_timer generic map(G_WIDTH => C_WIDTH) port map (
        clock => clock,
        reset => reset,
        irq => timer_irq,
        iface_di => dmem_di,
        iface_a => dmem_a,
        iface_we => dmem_we,
        iface_do => dmem_do_tcnt
    );
    
    wrapped_sensor_inst: component wrapped_sensor port map(
        clock => clock,
        reset => reset,
        iface_di => dmem_di,
        iface_a => dmem_a,
        iface_we => dmem_we,
        iface_do => dmem_sensor  
    );
    
    hashcompute: component hashcomputer port map(
        clock => clock,
        reset => reset,
        iface_di => dmem_di,
        iface_a => dmem_a,
        iface_we => dmem_we,
        iface_do => dmem_hash
    );
    
    PMUX_bus: process(dmem_a, dmem_do_tcnt, dmem_do_dmem, leds, dmem_sensor, dmem_hash)
    begin
        case dmem_a(dmem_a'high downto C_PERIPHERAL_MASK_LOWINDEX) is
            when C_LED_BASE_ADDRESS_MASK =>  
            when C_TIMER_BASE_ADDRESS_MASK => dmem_do <= dmem_do_tcnt;
            when C_SENSOR_BASE_ADDRESS_MASK => dmem_do <= dmem_sensor;
            when C_HASH_BASE_ADDRESS_MASK => dmem_do <= dmem_hash;
            when others => dmem_do <= dmem_do_dmem;
        end case;
    end process;


    -------------------------------------------------------------------------------
    -- INTERRUPTS
    -------------------------------------------------------------------------------
    -- A debounce of 20 ms is used
    -- Given that the clock runs at 40 MHz, it has a period of 25 ns
    -- 20 ms / 25 ns = 800000
    external_irq_set <= '1' when debouncer = 800000-16 else '0';
    external_irq_reset <= '1' when debouncer = 800000-2 else '0';

    PREG_SYNC: process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then 
                external_irq_d <= '0';
                external_irq_dd <= '0';
                debouncer <= 0;
                external_irq_sync_dbnc <= '0';
            else
                external_irq_d <= external_irq_i;
                external_irq_dd <= external_irq_d;

                if external_irq_dd = '1' then
                    if debouncer < 800000-1 then
                        debouncer <= debouncer + 1;
                    end if;
                else
                    debouncer <= 0;
                end if;

                if external_irq_reset = '1' then 
                    external_irq_sync_dbnc <= '0';
                elsif external_irq_set = '1' then 
                    external_irq_sync_dbnc <= '1';
                end if;
            end if;
        end if;
    end process;

    -- linking the interrupts
    linked_interrupts(0) <= timer_irq;
    linked_interrupts(3 downto 1) <= (others => '0');
    linked_interrupts(4) <= external_irq_sync_dbnc;
    linked_interrupts(31 downto 5) <= (others => '0');


    -------------------------------------------------------------------------------
    -- CLOCK AND RESET
    -------------------------------------------------------------------------------
    clock_and_reset_pynq_inst00: component clock_and_reset_pynq port map(
        sysclock => sys_clock_i,
        sysreset => sys_reset_i,
        sreset => reset,
        clock => clock,
        heartbeat => open
    );

end Behavioural;
