--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Package Name:    PKG_hwswcd
-- Project Name:    HWSWCD
-- Description:     Package for the HWSWCD code
--
-- Revision     Date       Author     Comments
-- v0.1         20241126   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
--    use IEEE.NUMERIC_STD.ALL;

package PKG_hwswcd is

    -------------------------------------------------------------------------------
    -- CONSTANTS
    -------------------------------------------------------------------------------
    constant C_REGCOUNT : natural := 32;
    constant C_REGCOUNT_LOG2 : natural := 5;
    constant C_WIDTH : natural := 32;
    constant C_GND : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0) := (others => '0');
    constant C_VCC : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0) := (others => '1');
    constant C_FOUR : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0) := (2 => '1', others => '0');
    constant C_HARTID_0 : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0) := (others => '0');

    constant C_PERIPHERAL_MASK_WIDTH: natural := 16;
    constant C_PERIPHERAL_MASK_LOWINDEX: natural := C_WIDTH - C_PERIPHERAL_MASK_WIDTH;


    -- Peripherals are all assigned a BASE ADDRESS.
    -- From this address 4096 positions are reserved.
    -- This comes down to 1024 32-bit words.
    -- A peripheral can hence have 1024 memory-mapped registers
    constant C_DMEM_BASE_ADDRESS_MASK : STD_LOGIC_VECTOR(C_WIDTH-1 downto C_PERIPHERAL_MASK_LOWINDEX) := x"0000";
    constant C_LED_BASE_ADDRESS_MASK : STD_LOGIC_VECTOR(C_WIDTH-1 downto C_PERIPHERAL_MASK_LOWINDEX) := x"8000";
    constant C_TIMER_BASE_ADDRESS_MASK : STD_LOGIC_VECTOR(C_WIDTH-1 downto C_PERIPHERAL_MASK_LOWINDEX) := x"8100";
    constant C_SENSOR_BASE_ADDRESS_MASK : std_logic_vector (C_WIDTH-1 downto C_PERIPHERAL_MASK_LOWINDEX) := x"8200";
    constant C_HASH_BASE_ADDRESS_MASK : std_logic_vector (C_WIDTH-1 downto C_PERIPHERAL_MASK_LOWINDEX) := x"8300";

    constant C_MRO_xF11_MVENDORID : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0) := x"01234568";
    constant C_MRO_xF14_MHARTID : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0) := x"CAFEBABE";

    -------------------------------------------------------------------------------
    -- TYPES
    -------------------------------------------------------------------------------
    type T_regfile is array (0 to C_REGCOUNT-1) of STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    type T_imem is array(0 to 255) of STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    type T_dmem is array(0 to 255) of STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);


    -------------------------------------------------------------------------------
    -- DECLARATIONS
    -------------------------------------------------------------------------------
    component reg_file is
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
    end component reg_file;

    component alu is
        port(
            operator1 : in std_logic_vector(C_WIDTH-1 downto 0);
            operator2 : in std_logic_vector(C_WIDTH-1 downto 0);
            ALUOp : in std_logic_vector(2 downto 0);
            arith_logic_b : in STD_LOGIC;
            signed_unsigned_b : in STD_LOGIC;
            result : out std_logic_vector(C_WIDTH-1 downto 0);
            zero : out std_logic;
            equal : out std_logic;
            carryOut : out std_logic;
            x_lt_y_u : out std_logic;
            x_lt_y_s : out std_logic
        );
    end component alu;

    component immediate_gen is
        port(
            instruction : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
            immediate : out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0)
        );
    end component immediate_gen;

    component control is
        port(
            opcode : in std_logic_vector(6 downto 0);
            funct3 : in std_logic_vector(2 downto 0);
            funct7 : in std_logic_vector(6 downto 0);
            rd : in std_logic_vector(4 downto 0);
            rs1 : in std_logic_vector(4 downto 0);
            ToRegister : out std_logic_vector(2 downto 0);
            mem_we : out std_logic;
            Branch : out std_logic_vector(3 downto 0);
            ALUOp : out std_logic_vector(2 downto 0);
            StoreSel : out std_logic_vector(1 downto 0);
            ALUSrc : out std_logic;
            regfile_we : out std_logic;
            arith_logic_b : out STD_LOGIC;
            signed_unsigned_b : out STD_LOGIC;
            result_filter : out STD_LOGIC_VECTOR(1 downto 0);
            csr_src : out STD_LOGIC;
            csr_we : out STD_LOGIC;
            csr_set_bits : out STD_LOGIC;
            csr_clear_bits : out STD_LOGIC;
            csr_mret : out STD_LOGIC
        );
    end component control;

    component riscv is
        port(
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            ce: IN STD_LOGIC;
            irq : in STD_LOGIC_VECTOR(31 downto 0);
            dmem_do : in STD_LOGIC_VECTOR(31 downto 0);
            dmem_we : out STD_LOGIC;
            dmem_a : out STD_LOGIC_VECTOR(31 downto 0);
            dmem_di : out STD_LOGIC_VECTOR(31 downto 0);
            instruction : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
            PC : out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0)
        );
    end component riscv;

    component riscv_microcontroller is
        port(
            sys_clock : in STD_LOGIC;
            sys_reset : in STD_LOGIC;
            external_irq : in STD_LOGIC;
            gpio_leds : out STD_LOGIC_VECTOR(3 downto 0);
            dmem_we_out : out STD_LOGIC;
            dmem_a_out : out STD_LOGIC_VECTOR(31 downto 0);
            dmem_di_out : out STD_LOGIC_VECTOR(31 downto 0);
            riscv_clock : out std_logic
        );
    end component riscv_microcontroller;

    component dmem_model is
        generic (
            G_DATA_WIDTH : integer := 32;
            G_DEPTH_LOG2 : integer := 10;
            FNAME_INIT_FILE : string := "data.dat"
        );
        port (
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            di : IN STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 0);
            ad : IN STD_LOGIC_VECTOR(G_DEPTH_LOG2-1 downto 0);
            we : IN STD_LOGIC;
            do : OUT STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 0)
        );
    end component dmem_model;

    component imem_model is
        generic (
            G_DATA_WIDTH : integer := 32;
            G_DEPTH_LOG2 : integer := 10;
            FNAME_INIT_FILE : string := "data.dat"
        );
        port (
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            ad : IN STD_LOGIC_VECTOR(G_DEPTH_LOG2-1 downto 0);
            do : OUT STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 0)
        );
    end component imem_model;
    
    component basicIO_model is
        generic (
            G_DATA_WIDTH : integer := 32;
            FNAME_OUT_FILE : string := "data.dat"
        );
        port (
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            di : IN STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 0);
            ad : IN STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 0);
            we : IN STD_LOGIC;
            do : OUT STD_LOGIC_VECTOR(G_DATA_WIDTH-1 downto 0);
            writing_out_flag : OUT STD_LOGIC
        );
    end component basicIO_model;

    component wrapped_timer is
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
    end component wrapped_timer;

    component timer is
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
    end component timer;

    component riscv_csr is
        generic (
            G_HARTID : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0) := (others => '0')
        );
        port(
            clock : in STD_LOGIC;
            reset : in STD_LOGIC;
            ce : in STD_LOGIC;
            data_in : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
            CSR_address : in STD_LOGIC_VECTOR(11 downto 0);
            rw : in STD_LOGIC;
            rs : in STD_LOGIC;
            rc : in STD_LOGIC;
            interrupt_request : in STD_LOGIC_VECTOR(32-1 downto 0);
            mret : in STD_LOGIC;
            data_out : out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
            interrupt : out STD_LOGIC;
            pc_in : in STD_LOGIC_VECTOR(31 downto 0);
            pc_out : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component riscv_csr;

    component clock_and_reset_pynq is
        port(
            sysclock : IN STD_LOGIC;
            sysreset : IN STD_LOGIC;
            sreset : out STD_LOGIC;
            clock : out STD_LOGIC;
            heartbeat : out STD_LOGIC
        );
    end component clock_and_reset_pynq;

    component two_k_bram_dmem is
        port(
            clock : in STD_LOGIC;
            init_data_in : in STD_LOGIC_VECTOR(31 downto 0);
            init_write_enable : in STD_LOGIC;
            init_address : in STD_LOGIC_VECTOR(10 downto 0);
            data_in : in STD_LOGIC_VECTOR(31 downto 0);
            write_enable : in STD_LOGIC;
            address : in STD_LOGIC_VECTOR(10 downto 0);
            data_out : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component two_k_bram_dmem;

    component two_k_bram_imem is
        port(
            clock : in STD_LOGIC;
            init_data_in : in STD_LOGIC_VECTOR(31 downto 0);
            init_write_enable : in STD_LOGIC;
            init_address : in STD_LOGIC_VECTOR(10 downto 0);
            data_in : in STD_LOGIC_VECTOR(31 downto 0);
            write_enable : in STD_LOGIC;
            address : in STD_LOGIC_VECTOR(10 downto 0);
            data_out : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component two_k_bram_imem;
    
    component sensor is
        generic(
            G_PIXELS : natural := 3750
        );
        
        port(
        clock : in STD_LOGIC;
        reset : in STD_LOGIC;
        pixel_data_out_re : in STD_LOGIC;
        pixel_data_out : out STD_LOGIC_VECTOR(31 downto 0);
        first : out std_logic
      );
    end component sensor;
    
   component wrapped_sensor is
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
    end component wrapped_sensor;
    
    component hashcomputer is
    port(
        clock : in STD_LOGIC;
        reset : in STD_LOGIC;
        iface_di : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
        iface_a : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
        iface_we : in STD_LOGIC;
        iface_do : out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0)
    );
    end component;


end package;

package body PKG_hwswcd is

end package body;
