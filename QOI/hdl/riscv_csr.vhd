--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     riscv_csr - Behavioural
-- Project Name:    riscv_csr
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20250108   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_MISC.or_reduce;
-- use IEEE.NUMERIC_STD.ALL;

library work;
    use work.PKG_hwswcd.ALL;

entity riscv_csr is
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
end entity riscv_csr;

architecture Behavioural of riscv_csr is

    -- (DE-)LOCALISING IN/OUTPUTS
    signal clock_i : STD_LOGIC;
    signal reset_i : STD_LOGIC;
    signal ce_i : STD_LOGIC;
    signal data_in_i : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_address_i : STD_LOGIC_VECTOR(11 downto 0);
    signal rw_i : STD_LOGIC;
    signal rs_i : STD_LOGIC;
    signal rc_i : STD_LOGIC;
    signal interrupt_request_i : STD_LOGIC_VECTOR(32-1 downto 0);
    signal mret_i : STD_LOGIC;
    signal data_out_o : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

    signal interrupt_o : STD_LOGIC;
    signal pc_in_i : STD_LOGIC_VECTOR(31 downto 0);
    signal pc_out_o : STD_LOGIC_VECTOR(31 downto 0);

    signal CSR_selected : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_selected_manip : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

    signal CSR_MRO_mhartid: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_MRW_mstatus: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_MRW_misa: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_MRW_mie: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_MRW_mip: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_MRW_mtvec: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_MRW_mstatush: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_MRW_mscratch: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_MRW_mepc: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal CSR_MRW_mcause: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
--    signal CSR_MRW_mcause: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    
    signal irq : STD_LOGIC;
    signal pc_out_select : STD_LOGIC;

    alias MIE : STD_LOGIC is CSR_MRW_mstatus(3);
    alias MPIE : STD_LOGIC is CSR_MRW_mstatus(7);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    clock_i <= clock;
    reset_i <= reset;
    ce_i <= ce;
    data_in_i <= data_in;
    CSR_address_i <= CSR_address;
    rw_i <= rw;
    rs_i <= rs;
    rc_i <= rc;
    interrupt_request_i <= interrupt_request;
    mret_i <= mret;
    data_out <= data_out_o;


    interrupt <= interrupt_o;
    pc_in_i <= pc_in;
    pc_out <= pc_out_o;

    -------------------------------------------------------------------------------
    -- MAPPING
    -------------------------------------------------------------------------------
    data_out_o <= CSR_selected;
    interrupt_o <= irq;
    pc_out_o <= (CSR_MRW_mtvec and x"FFFFFFFC") when pc_out_select = '0' else CSR_MRW_mepc;

    irq <= or_reduce(interrupt_request_i and CSR_MRW_mie) AND CSR_MRW_mstatus(3);

    -------------------------------------------------------------------------------
    -- REGISTERS
    -------------------------------------------------------------------------------
    PREG: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 

                pc_out_select <= '0';

                CSR_MRO_mhartid <= G_HARTID;

                CSR_MRW_mstatus <= (others => '0');
                CSR_MRW_misa <= "01" & "0000" &  ("00" & x"000100");
                CSR_MRW_mie <= (others => '0');
                CSR_MRW_mip <= (others => '0');
                CSR_MRW_mtvec <= x"00000000";
                CSR_MRW_mcause <= (others => '0');
                CSR_MRW_mstatush <= (others => '0');
                CSR_MRW_mepc <= (others => '0');
                CSR_MRW_mscratch <= (others => '0');
            else
                if ce_i = '1' then
                    -- Machine Information Registers
                    CSR_MRO_mhartid <= G_HARTID;

                    if irq = '1' then
                        CSR_MRW_mepc <= pc_in_i and x"FFFFFFFC";        -- backup PC
                        CSR_MRW_mstatus <=                              -- backup xIE in xPIE and clear xIE
                                CSR_MRW_mstatus(CSR_MRW_mstatus'high downto 8) & 
                                CSR_MRW_mstatus(3) & 
                                CSR_MRW_mstatus(6 downto 4) &
                                '0' & 
                                CSR_MRW_mstatus(2 downto 0);
                        pc_out_select <= '1';
                        CSR_MRW_mcause <= interrupt_request_i and CSR_MRW_mie;
                        
                    elsif mret_i = '1' then 
                        pc_out_select <= '0';
                        CSR_MRW_mstatus <=                              -- backup xIE in xPIE and clear xIE
                                CSR_MRW_mstatus(CSR_MRW_mstatus'high downto 8) & 
                                '1' & 
                                CSR_MRW_mstatus(6 downto 4) &
                                CSR_MRW_mstatus(7) & 
                                CSR_MRW_mstatus(2 downto 0);
                        CSR_MRW_mcause <= (others => '0');

                    elsif rw_i = '1' or rs_i = '1' or rc_i = '1' then 
                        -- Machine Trap Setup
                        if CSR_address_i = x"300" then 
                            CSR_MRW_mstatus <= CSR_selected_manip;
                        end if;

                        if CSR_address_i = x"301" then 
                            CSR_MRW_misa <= CSR_selected_manip;
                        end if;

                        if CSR_address_i = x"304" then 
                            CSR_MRW_mie <= CSR_selected_manip;
                        end if;

                        if CSR_address_i = x"305" then 
                            CSR_MRW_mtvec <= CSR_selected_manip;
                        end if;

                        if CSR_address_i = x"310" then 
                            CSR_MRW_mstatush <= CSR_selected_manip;
                        end if;


                        -- Machine Trap Handling
                        if CSR_address_i = x"340" then 
                            CSR_MRW_mscratch <= CSR_selected_manip;
                        end if;

                        if CSR_address_i = x"341" then 
                            CSR_MRW_mepc <= CSR_selected_manip;
                        end if;

                        if CSR_address_i = x"342" then 
                            CSR_MRW_mcause <= CSR_selected_manip;
                        end if;

                        if CSR_address_i = x"344" then 
                            CSR_MRW_mip <= CSR_selected_manip;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;


    -- CSR manipulation
    PMUX_manip: process(rw_i, rs_i, rc_i, data_in_i, CSR_selected)
    begin 
        if rw_i = '1' then 
            -- CSRRW (Atomic Read/Write CSR)
            CSR_selected_manip <= data_in_i;
        elsif rs_i = '1' then 
            -- CSRRS (Atomic Read and Set Bits in CSR)
            CSR_selected_manip <= CSR_selected OR data_in_i;
        elsif rc_i = '1' then 
            -- CSRRC (Atomic Read and Clear Bits in CSR)
            CSR_selected_manip <= CSR_selected AND not(data_in_i);
        else
            CSR_selected_manip <= (others => '0');
        end if;
    end process;


    -- CSR selection
    PMUX_csr_select: process(CSR_address_i, CSR_MRO_mhartid, CSR_MRW_mstatus, CSR_MRW_misa, CSR_MRW_mie, CSR_MRW_mtvec, 
            CSR_MRW_mstatush, CSR_MRW_mscratch, CSR_MRW_mepc, CSR_MRW_mcause, CSR_MRW_mip)
    begin 
        case CSR_address_i is
            -- Machine Information Registers
            -- when x"F11" => from_CSR <= C_MRO_MVENDORID;
            -- when x"F12" => from_CSR <= C_MRO_MARCHID;
            -- when x"F13" => from_CSR <= C_MRO_MIMPID;
            when x"F14" => CSR_selected <= CSR_MRO_mhartid;
            -- when x"F15" => from_CSR <= C_MRO_xF15_MCONFIGPTR;

            -- Machine Trap Setup
            when x"300" => CSR_selected <= CSR_MRW_mstatus;
            when x"301" => CSR_selected <= CSR_MRW_misa;
            when x"304" => CSR_selected <= CSR_MRW_mie;
            when x"305" => CSR_selected <= CSR_MRW_mtvec;
            when x"310" => CSR_selected <= CSR_MRW_mstatush;
            
            -- -- Machine Trap Handling
            when x"340" => CSR_selected <= CSR_MRW_mscratch;
            when x"341" => CSR_selected <= CSR_MRW_mepc;
            when x"342" => CSR_selected <= CSR_MRW_mcause;
            when x"344" => CSR_selected <= CSR_MRW_mip;
            
            -- Machine Configuration
            -- Machine Memory Protection
            -- Machine State Enable Registers
            -- Machine Non-Maskable Interrupt Handling
            -- Machine Counter/Timers
            -- Machine Counter Setup
            when others => CSR_selected <= (others => '0');
        end case;
    end process;

        -- signal Smode_interrupt_enable, Mmode_interrupt_enable : STD_LOGIC;
        -- signal mstatus, mstatush : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

        -- Smode_interrupt_enable <= C_GND(0); -- global interrupt enable bit (S-mode)
        -- Mmode_interrupt_enable <= C_GND(0); -- global interrupt enable bit (M-mode)


        -- mstatus(1) <= Smode_interrupt_enable;
                -- mstatus(3) <= Mmode_interrupt_enable;
        
        -- -- Writes Preserve value, Reads ignore values (WPRI)
        -- -- For future use, must be made zero
        -- mstatus(0) <= C_GND(0); --WPRI;
        -- mstatus(2) <= C_GND(0); --WPRI;
        -- mstatus(4) <= C_GND(0); --WPRI;
        -- mstatus(6) <= C_GND(0); -- UBE (Umode not supported)

        -- -- PP previous priviledge mode (for nested traps)
        -- --   upon xRET, xPIE is restored in xIE
        -- mstatus(5) <= C_GND(0); -- SPIE;
        -- mstatus(7) <= C_GND(0); -- MPIE;
        -- mstatus(8) <= C_GND(0); -- SPP;
        -- mstatus(12 downto 11) <= C_GND(1 downto 00); -- MPP;

        -- -- to reduce the effor of context switches, Vector or Float can indicate no-bckp  XS does usermode
        -- -- SD, finally, summarises
        -- mstatus(10 downto 9) <= C_GND(1 downto 0);-- VS;
        -- mstatus(14 downto 13) <= C_GND(1 downto 0);-- FS;
        -- mstatus(16 downto 15) <= C_GND(1 downto 0);-- XS;
        -- mstatus(17) <= C_GND(0); -- MPRV is read-only 0 if U-mode is not supported.;
        -- mstatus(18) <= C_GND(0); -- SUM (permit Supervisor User Memory access)
        -- mstatus(19) <= C_GND(0); -- MXR; (Make Executable Readable) modifies privilege for virtual mem. -- MXR is read-only 0 if S-mode is notsupported.
        -- mstatus(20) <= C_GND(0); -- TVM -- Trap Virtual Memory
        -- mstatus(21) <= C_GND(0); -- TW -- timeout wait (TW is read-only 0 when there are no modes less privileged than M.)
        -- mstatus(22) <= C_GND(0); -- TSR -- supports intercepting the supervisor exception return instruction, SRET. - TSR is read-only 0 when S-mode is not supported.
        -- mstatus(30 downto 23) <= C_GND(30 downto 23); --WPRI;
        -- mstatus(31) <= C_GND(0); --SD;
        

        -- mstatush(3 downto 0) <=  C_GND(3 downto 0); --WPRI;
        -- mstatush(4) <= C_GND(0); -- SBE (Smode not supported)
        -- mstatush(5) <= C_GND(0); -- MBE ()non-instrution-fetch mem acces is little endian 
        -- mstatush(31 downto 6) <=  C_GND(31 downto 3); --WPRI;

end Behavioural;
