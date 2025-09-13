--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     sensor_r - Behavioural
-- Project Name:    sensor_r
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20250328   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    -- use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
    use UNISIM.vcomponents.all;

entity sensor_r is
    port(
        clock : in STD_LOGIC;
        address : in STD_LOGIC_VECTOR(11 downto 0);
        data_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
end entity sensor_r;

architecture Behavioural of sensor_r is

    -- (DE-)LOCALISING IN/OUTPUTS
    signal clock_i : STD_LOGIC;
    signal address_i : STD_LOGIC_VECTOR(11 downto 0);
    signal data_out_o : STD_LOGIC_VECTOR(7 downto 0);

    constant C_NULL : STD_LOGIC_VECTOR(31 downto 0) := x"00000000";
    constant C_ONES : STD_LOGIC_VECTOR(31 downto 0) := x"FFFFFFFF";

    signal address_00 : STD_LOGIC_VECTOR(15 downto 0);
    signal data_out_00 : STD_LOGIC_VECTOR(31 downto 0);


begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    clock_i <= clock;
    address_i <= address;
    data_out <= data_out_o;

    address_00 <= "0" & address_i & "000";
    data_out_o <= data_out_00(7 downto 0);
    
    -------------------------------------------------------------------------------
    -- BRAM PRIMITIVES
    -------------------------------------------------------------------------------
    RAMB36E1_inst00 : RAMB36E1
    generic map (
        RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
        SIM_COLLISION_CHECK => "ALL",
        DOA_REG => 0,
        DOB_REG => 0,
        EN_ECC_READ => FALSE,
        EN_ECC_WRITE => FALSE,
        -- INIT_00 to INIT_7F: Initial contents of the data memory array
        INIT_00 => x"00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF",
        INIT_01 => x"7F7F7F7F000000007F7F7F7F000000007F7F7F7F000000007F7F7F7F00000000",
        INIT_A => X"000000000",
        INIT_B => X"000000000",
        INIT_FILE => "NONE",
        RAM_MODE => "TDP", -- RAM Mode: "SDP" or "TDP" 
        RAM_EXTENSION_A => "NONE", -- RAM_EXTENSION_A, RAM_EXTENSION_B: Selects cascade mode ("UPPER", "LOWER", or "NONE")
        RAM_EXTENSION_B => "NONE",
        READ_WIDTH_A => 9, -- 0-72
        READ_WIDTH_B => 9, -- 0-36
        WRITE_WIDTH_A => 9, -- 0-36
        WRITE_WIDTH_B => 9, -- 0-72
        RSTREG_PRIORITY_A => "RSTREG", ---- RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG" or "REGCE")
        RSTREG_PRIORITY_B => "RSTREG",
        SRVAL_A => X"000000000", -- SRVAL_A, SRVAL_B: Set/reset value for output
        SRVAL_B => X"000000000",
        SIM_DEVICE => "7SERIES",
        WRITE_MODE_A => "WRITE_FIRST",  -- WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
        WRITE_MODE_B => "WRITE_FIRST" 
    )
   port map (
       
        CASCADEINA => C_NULL(0),
        CASCADEINB => C_NULL(0),
        CASCADEOUTA => open,
        CASCADEOUTB => open,
        SBITERR => open,
        DBITERR => open,
        INJECTDBITERR => C_NULL(0),
        INJECTSBITERR => C_NULL(0),
        ECCPARITY => open,
        RDADDRECC => open,
        RSTRAMARSTRAM => C_NULL(0),
        RSTREGARSTREG => C_NULL(0),
        RSTRAMB => C_NULL(0),
        RSTREGB => C_NULL(0),
                
        CLKARDCLK => clock_i,
        ADDRARDADDR => address_00,
        WEA => C_NULL(3 downto 0),
        DIADI => C_NULL,
        DIPADIP => C_NULL(3 downto 0),
        DOADO => data_out_00,
        DOPADOP => open,
        ENARDEN => C_ONES(0),
        REGCEAREGCE => C_NULL(0),
        
        CLKBWRCLK => C_NULL(0),
        ADDRBWRADDR => C_NULL(15 downto 0),
        WEBWE => C_NULL(7 downto 0),
        DIBDI => C_NULL,
        DIPBDIP => C_NULL(3 downto 0),
        DOBDO => open,
        DOPBDOP => open,
        ENBWREN => C_ONES(0),
        REGCEB => C_NULL(0)
    );
                
end Behavioural;
