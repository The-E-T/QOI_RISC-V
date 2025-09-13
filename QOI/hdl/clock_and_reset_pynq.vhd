--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:   clock_and_reset_pynq - Behavioural
-- Project Name:  HW/SW codesign  
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20250214   VlJo       Initial version
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

library UNISIM;
    use UNISIM.vcomponents.all;

entity clock_and_reset_pynq is
    port(
        sysclock : IN STD_LOGIC;
        sysreset : IN STD_LOGIC;
        sreset : out STD_LOGIC;
        clock : out STD_LOGIC;
        heartbeat : out STD_LOGIC
    );
end entity clock_and_reset_pynq;

architecture Behavioural of clock_and_reset_pynq is

    -- F_VCO = 125 MHz * 8 / 1 = 1000 MHz
    constant C_D_MASTER : integer := 1;
    constant C_M_MASTER : real := 8.0;
    
    constant C_D_CLK0 : real := 20.0; -- this sets CLKOUT0 to 1000MHz / 25 = 40 MHz
    --constant C_D_CLK0 : real := 20; -- this sets CLKOUT0 to 1000MHz / 20 = 50 MHz

    -- (DE-)LOCALISING IN/OUTPUTS
    signal sysclock_i : STD_LOGIC;
    signal sysreset_i : STD_LOGIC;
    signal sreset_o : STD_LOGIC;
    signal clock_o : STD_LOGIC;

    signal sysclk_single_ended : STD_LOGIC;
    signal clock0_b4buf : STD_LOGIC;
    signal fbclock, fbclock_bufg : STD_LOGIC;
    signal locked : STD_LOGIC;

    signal reset_synchroniser_A : STD_LOGIC_VECTOR(9 downto 0);

    -- heartbeat
    signal heartbeat_int : integer;
    signal heartbeat_v : STD_LOGIC_VECTOR(26 downto 0);
    
    constant C_GND32 : STD_LOGIC_VECTOR(31 downto 0) := x"00000000";
    constant C_VCC32 : STD_LOGIC_VECTOR(31 downto 0) := x"FFFFFFFF";
    
    signal sysclock_buffed : STD_LOGIC;
    
begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sysclock_i <= sysclock;
    sysreset_i <= sysreset;
    sreset <= sreset_o;
    clock <= clock_o;


    IBUF_inst : IBUF generic map (IOSTANDARD => "DEFAULT") port map (
      O => sysclock_buffed,
      I => sysclock_i
    );
  

    -------------------------------------------------------------------------------
    -- HEARTBEAT
    -------------------------------------------------------------------------------
    heartbeat <= heartbeat_v(heartbeat_v'high);
    heartbeat_v <= std_logic_vector(to_unsigned(heartbeat_int, heartbeat_v'length));
    PREG_HEARTBEAT: process(clock_o)
    begin
        if rising_edge(clock_o) then
            if sreset_o = '1' then 
                heartbeat_int <= 0;
            else
                if heartbeat_int = 99999999 then
                    heartbeat_int <= 0;
                else
                    heartbeat_int <= heartbeat_int + 1;
                end if;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------------
    -- CLOCK BUFFERS
    -------------------------------------------------------------------------------
    BUFG_inst00: component BUFG port map(
        I => fbclock,
        O => fbclock_bufg
    );

    BUFG_inst01: component BUFG port map(
        I => clock0_b4buf,
        O => clock_o
    );


    -------------------------------------------------------------------------------
    -- RESET SYNCHRONISER
    -------------------------------------------------------------------------------
    sreset_o <= not(reset_synchroniser_A(reset_synchroniser_A'high));

    PREG_SYNCHRO_A: process(sysreset_i, clock_o)
    begin
        if sysreset_i = '1' then 
            reset_synchroniser_A <= (others => '0');
        elsif rising_edge(clock_o) then
            reset_synchroniser_A <= reset_synchroniser_A(reset_synchroniser_A'high-1 downto 0) & locked;
        end if;
    end process;


    -------------------------------------------------------------------------------
    -- CLOCK MANAGER
    -------------------------------------------------------------------------------
    MMCME2_ADV_inst : MMCME2_ADV
    generic map (
        BANDWIDTH => "OPTIMIZED",      -- Jitter programming (OPTIMIZED, HIGH, LOW)
        CLKFBOUT_MULT_F => C_M_MASTER,        -- Multiply value for all CLKOUT (2.000-64.000).
        CLKFBOUT_PHASE => 0.0,         -- Phase offset in degrees of CLKFB (-360.000-360.000).
        -- CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
        CLKIN1_PERIOD => 8.0,
        CLKIN2_PERIOD => 0.0,
        -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
        CLKOUT1_DIVIDE => 1,
        CLKOUT2_DIVIDE => 1,
        CLKOUT3_DIVIDE => 1,
        CLKOUT4_DIVIDE => 1,
        CLKOUT5_DIVIDE => 1,
        CLKOUT6_DIVIDE => 1,
        CLKOUT0_DIVIDE_F => C_D_CLK0,
        -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
        CLKOUT0_DUTY_CYCLE => 0.5,
        CLKOUT1_DUTY_CYCLE => 0.5,
        CLKOUT2_DUTY_CYCLE => 0.5,
        CLKOUT3_DUTY_CYCLE => 0.5,
        CLKOUT4_DUTY_CYCLE => 0.5,
        CLKOUT5_DUTY_CYCLE => 0.5,
        CLKOUT6_DUTY_CYCLE => 0.5,
        -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
        CLKOUT0_PHASE => 0.0,
        CLKOUT1_PHASE => 0.0,
        CLKOUT2_PHASE => 0.0,
        CLKOUT3_PHASE => 0.0,
        CLKOUT4_PHASE => 0.0,
        CLKOUT5_PHASE => 0.0,
        CLKOUT6_PHASE => 0.0,
        CLKOUT4_CASCADE => FALSE,      -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        COMPENSATION => "ZHOLD",       -- ZHOLD, BUF_IN, EXTERNAL, INTERNAL
        DIVCLK_DIVIDE => C_D_MASTER,            -- Master division value (1-106)
        -- REF_JITTER: Reference input jitter in UI (0.000-0.999).
        REF_JITTER1 => 0.0,
        REF_JITTER2 => 0.0,
        STARTUP_WAIT => FALSE,         -- Delays DONE until MMCM is locked (FALSE, TRUE)
        -- Spread Spectrum: Spread Spectrum Attributes
        SS_EN => "FALSE",              -- Enables spread spectrum (FALSE, TRUE)
        SS_MODE => "CENTER_HIGH",      -- CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
        SS_MOD_PERIOD => 10000,        -- Spread spectrum modulation period (ns) (VALUES)
        -- USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
        CLKFBOUT_USE_FINE_PS => FALSE,
        CLKOUT0_USE_FINE_PS => FALSE,
        CLKOUT1_USE_FINE_PS => FALSE,
        CLKOUT2_USE_FINE_PS => FALSE,
        CLKOUT3_USE_FINE_PS => FALSE,
        CLKOUT4_USE_FINE_PS => FALSE,
        CLKOUT5_USE_FINE_PS => FALSE,
        CLKOUT6_USE_FINE_PS => FALSE)
    port map (
        -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
        CLKOUT0 => clock0_b4buf,           -- 1-bit output: CLKOUT0
        CLKOUT0B => open,         -- 1-bit output: Inverted CLKOUT0
        CLKOUT1 => open,           -- 1-bit output: CLKOUT1
        CLKOUT1B => open,         -- 1-bit output: Inverted CLKOUT1
        CLKOUT2 => open,           -- 1-bit output: CLKOUT2
        CLKOUT2B => open,         -- 1-bit output: Inverted CLKOUT2
        CLKOUT3 => open,           -- 1-bit output: CLKOUT3
        CLKOUT3B => open,         -- 1-bit output: Inverted CLKOUT3
        CLKOUT4 => open,           -- 1-bit output: CLKOUT4
        CLKOUT5 => open,           -- 1-bit output: CLKOUT5
        CLKOUT6 => open,           -- 1-bit output: CLKOUT6
        -- DRP Ports: 16-bit (each) output: Dynamic reconfiguration ports
        DO => open,                     -- 16-bit output: DRP data
        DRDY => open,                 -- 1-bit output: DRP ready
        -- Dynamic Phase Shift Ports: 1-bit (each) output: Ports used for dynamic phase shifting of the outputs
        PSDONE => open,             -- 1-bit output: Phase shift done
        -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
        CLKFBOUT => fbclock,         -- 1-bit output: Feedback clock
        CLKFBOUTB => open,       -- 1-bit output: Inverted CLKFBOUT
        -- Status Ports: 1-bit (each) output: MMCM status ports
        CLKFBSTOPPED => open, -- 1-bit output: Feedback clock stopped
        CLKINSTOPPED => open, -- 1-bit output: Input clock stopped
        LOCKED => locked,             -- 1-bit output: LOCK
        -- Clock Inputs: 1-bit (each) input: Clock inputs
        CLKIN1 => sysclock_buffed,             -- 1-bit input: Primary clock
        CLKIN2 => C_GND32(0),             -- 1-bit input: Secondary clock
        -- Control Ports: 1-bit (each) input: MMCM control ports
        CLKINSEL => C_VCC32(0),         -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
        PWRDWN => C_GND32(0),             -- 1-bit input: Power-down
        RST => sysreset_i,                   -- 1-bit input: Reset
        -- DRP Ports: 7-bit (each) input: Dynamic reconfiguration ports
        DADDR => C_GND32(6 downto 0),               -- 7-bit input: DRP address
        DCLK => C_GND32(0),                 -- 1-bit input: DRP clock
        DEN => C_GND32(0),                   -- 1-bit input: DRP enable
        DI => C_GND32(15 downto 0),                     -- 16-bit input: DRP data
        DWE => C_GND32(0),                   -- 1-bit input: DRP write enable
        -- Dynamic Phase Shift Ports: 1-bit (each) input: Ports used for dynamic phase shifting of the outputs
        PSCLK => C_GND32(0),               -- 1-bit input: Phase shift clock
        PSEN => C_GND32(0),                 -- 1-bit input: Phase shift enable
        PSINCDEC => C_GND32(0),         -- 1-bit input: Phase shift increment/decrement
        -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
        CLKFBIN => fbclock_bufg            -- 1-bit input: Feedback clock
    );

end Behavioural;
