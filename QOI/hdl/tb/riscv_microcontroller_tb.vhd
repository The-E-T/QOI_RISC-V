--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     riscv_microcontroller_tb - Behavioural
-- Project Name:    Testbench for RISC-V microcontroller
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20241128   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

library work;
    use work.PKG_hwswcd.ALL;

entity riscv_microcontroller_tb is
    generic (
        G_DATA_WIDTH : integer := 32;
        G_DEPTH_LOG2 : integer := 11;
        FNAME_OUT_FILE : string := "D:\School\MA\HWSW\Source_code\HWSW\QOI\firmware\course_example_1\simulation_output.dat"
    );
end entity riscv_microcontroller_tb;

architecture Behavioural of riscv_microcontroller_tb is


    -- clock and reset
    signal sys_clock : STD_LOGIC;
    signal sys_reset : STD_LOGIC;
    signal external_irq : STD_LOGIC;
    signal gpio_leds : STD_LOGIC_VECTOR(3 downto 0);
    signal riscv_clock : std_logic;

    -- constants
    constant C_ZEROES: STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 0) := (others => '0');
    constant clock_period : time := 8 ns;
    
    --dmem
    signal dmem_di : STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 0);
    signal dmem_ad : STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 0);
    signal dmem_we : STD_LOGIC;

begin

    PSTIM: process
    begin
        external_irq <= '0';
--        wait for 10 us;
--        irq <= (2 => '1', others => '0');
--        wait for 1 us;
--        irq <= (others => '0');
        wait;
    end process PSTIM;

    -------------------------------------------------------------------------------
    -- DUT
    -------------------------------------------------------------------------------
    DUT: component riscv_microcontroller port map(
        sys_clock => sys_clock,
        sys_reset => sys_reset,
        external_irq => external_irq,
        gpio_leds => gpio_leds,
        dmem_we_out => dmem_we,
        dmem_a_out => dmem_ad,
        dmem_di_out => dmem_di,
        riscv_clock => riscv_clock
    );



    -------------------------------------------------------------------------------
    -- CLOCK
    -------------------------------------------------------------------------------
    PCLK: process
    begin
        sys_clock <= '1';
        wait for clock_period/2;
        sys_clock <= '0';
        wait for clock_period/2;
    end process PCLK;


    -------------------------------------------------------------------------------
    -- RESET
    -------------------------------------------------------------------------------
    PRST: process
    begin
        sys_reset <= '1';
        wait for clock_period*9;
        wait for clock_period/2;
        sys_reset <= '0';
        wait;
    end process PRST;
    
    -------------------------------------------------------------------------------
    -- Basic IO
    -------------------------------------------------------------------------------
    basicIO_model_inst00: component basicIO_model generic map(
        G_DATA_WIDTH => G_DATA_WIDTH,
        FNAME_OUT_FILE => FNAME_OUT_FILE
    ) port map(
        clock => riscv_clock,
        reset => sys_reset,
        di => dmem_di,
        ad => dmem_ad,
        we => dmem_we,
        do => open
    );

end Behavioural;
