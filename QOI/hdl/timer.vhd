--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     timer - Behavioural
-- Project Name:    timer
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20241210   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;

entity timer is
    generic(
        G_WIDTH : natural := 8
    );
    port(
        clock : in STD_LOGIC;
        reset : in STD_LOGIC;

        CS : in STD_LOGIC_VECTOR(1 downto 0);               -- clock select
        WGM : in STD_LOGIC_VECTOR(1 downto 0);              -- waveform generation mode
        
        CMP : in STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);

        OFl : out std_LOGIC;
        PWM : out std_LOGIC;
        CEQ : out std_LOGIC;
        TCNT : out STD_LOGIC_VECTOR(G_WIDTH-1 downto 0)
    );
end entity timer;

architecture Behavioural of timer is

    -- (DE-)LOCALISING IN/OUTPUTS
    signal clock_i : STD_LOGIC;
    signal reset_i : STD_LOGIC;
    signal CS_i : STD_LOGIC_VECTOR(1 downto 0);
    signal WGM_i : STD_LOGIC_VECTOR(1 downto 0);
    signal CMP_i : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
    signal OFl_o : STD_LOGIC;    
    signal PWM_o : STD_LOGIC;    
    signal CEQ_o : STD_LOGIC;    
    signal TCNT_o : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
    
    -- CLOCK SELECT
    signal prescaler_8, prescaler_64 : STD_LOGIC_VECTOR(7 downto 0);
    
    -- TIMER/COUNTER
    signal count_ce, count_clr : STD_LOGIC;
    signal count, count_next, count_incremented : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
    signal count_incremented_c : STD_LOGIC_VECTOR(G_WIDTH downto 0);
    
    -- FLAGS
    signal overflow : STD_LOGIC;    

    -- CONSTANTS
    constant C_MAX : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0) := (others => '1');

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    clock_i <= clock;
    reset_i <= reset;
    CS_i <= CS;
    WGM_i <= WGM;
    CMP_i <= CMP;
    OFl <= OFl_o;
    PWM <= PWM_o;
    CEQ <= CEQ_o;
    TCNT <= TCNT_o;
    
    TCNT_o <= count;
  

    -------------------------------------------------------------------------------
    -- CLOCK SELECT
    -------------------------------------------------------------------------------
    PMUX_CS: process(CS_i, prescaler_8, prescaler_64)
    begin
        case CS_i is
            when "11" => count_ce <= '1';
            when "10" => count_ce <= prescaler_8(0) and prescaler_64(0);
            when "01" => count_ce <= prescaler_8(0);
            when others => count_ce <= '0';
        end case;
    end process;

    PRESCALER: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 
                prescaler_8 <= (7 => '1', others => '0');
                prescaler_64 <= (7 => '1', others => '0');
            else
                prescaler_8 <= prescaler_8(0) & prescaler_8(7 downto 1);
                if prescaler_8(0) = '1' then 
                    prescaler_64 <= prescaler_64(0) & prescaler_64(7 downto 1);
                end if;
            end if;
        end if;
    end process;


    -------------------------------------------------------------------------------
    -- TIMER/COUNTER
    -------------------------------------------------------------------------------
    PCTR: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 
                count <= (others => '0');
            else
                if count_clr = '1' then 
                    count <= (others => '0');
                elsif count_ce = '1' then 
                    count <= count_next;
                end if;
            end if;
        end if;
    end process;

    count_next <= count_incremented;

    PMUX_CLR: process(WGM_i, count, CMP_i)
    begin
        count_clr <= '0';
        overflow <= '0';
        PWM_o <= '0';
        CEQ_o <= '0'; 

        case WGM_i is
            when "00" => -- Normal mode
                if count = C_MAX then 
                    count_clr <= '1';
                    overflow <= '1';
                end if;
            when "01" => -- CTC mode
                if count = CMP_i then 
                    count_clr <= '1';
                    CEQ_o <= '1';
                end if;
            when "10" => -- PWM mode
                if count = C_MAX then 
                    count_clr <= '1';
                end if;
                if count <= CMP_i then 
                    PWM_o <= '1';
                end if;
            when others => -- Normal mode
                if count = C_MAX then 
                    count_clr <= '1';
                    overflow <= '1';
                end if;
        end case;
    end process;

    -------------------------------------------------------------------------------
    -- FLAGS
    -------------------------------------------------------------------------------
    PREG_FLAGS: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 
                OFl_o <= '0';
            else
                OFl_o <= overflow;
            end if;
        end if;
    end process;


    -------------------------------------------------------------------------------
    -- ADDERs
    -------------------------------------------------------------------------------
    count_incremented(0) <= not(count(0));
    count_incremented_c(0) <= count(0);
    GEN_INC : for i in 1 to G_WIDTH-1 generate
        count_incremented(i) <= count(i) XOR count_incremented_c(i-1);
        count_incremented_c(i) <= count_incremented_c(i-1) AND count(i);
    end generate GEN_INC;

    -- count_decremented(0) <= not(count(0));
    -- count_decremented_c(0) <= count(0);
    -- GEN_DEC : for i in 1 to G_WIDTH-1 generate
    --     count_decremented(i) <= not(count(i) XOR count_decremented_c(i-1));
    --     count_decremented_c(i) <= count(i) or count_decremented_c(i-1);
    -- end generate GEN_DEC;

end Behavioural;
