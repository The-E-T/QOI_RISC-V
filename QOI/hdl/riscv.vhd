--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     riscv - Behavioural
-- Project Name:    HWSWCD
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20241126   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.NUMERIC_STD.ALL;

library work;
    use work.PKG_hwswcd.ALL;

entity riscv is
    port(
        clock : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        ce : IN STD_LOGIC;

        -- interrupts
        irq : in STD_LOGIC_VECTOR(31 downto 0);

        -- dmem
        dmem_do : in STD_LOGIC_VECTOR(31 downto 0);
        dmem_we : out STD_LOGIC;
        dmem_a : out STD_LOGIC_VECTOR(31 downto 0);
        dmem_di : out STD_LOGIC_VECTOR(31 downto 0);

        -- imem
        instruction : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
        PC : out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0)
    );
end entity riscv;

architecture Behavioural of riscv is

    -- (DE-)LOCALISING IN/OUTPUTS
    signal clock_i : STD_LOGIC;
    signal reset_i : STD_LOGIC;
    signal ce_i : STD_LOGIC;
    signal irq_i : STD_LOGIC_VECTOR(31 downto 0);
    signal dmem_di_o : STD_LOGIC_VECTOR(31 downto 0);
    signal dmem_we_o : STD_LOGIC;
    signal dmem_a_o : STD_LOGIC_VECTOR(31 downto 0);
    signal dmem_do_i : STD_LOGIC_VECTOR(31 downto 0);
    signal instruction_i : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal PC_o : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

    -- instruction decoding
    alias inst_funct7 : STD_LOGIC_VECTOR(6 downto 0) is instruction_i(31 downto 25);
    alias inst_rs2 : STD_LOGIC_VECTOR(4 downto 0) is instruction_i(24 downto 20);
    alias inst_rs1 : STD_LOGIC_VECTOR(4 downto 0) is instruction_i(19 downto 15);
    alias inst_funct3 : STD_LOGIC_VECTOR(2 downto 0) is instruction_i(14 downto 12);
    alias inst_rd : STD_LOGIC_VECTOR(4 downto 0) is instruction_i(11 downto 7);
    alias inst_opcode : STD_LOGIC_VECTOR(6 downto 0) is instruction_i(6 downto 0);

    alias inst_csr_address : STD_LOGIC_VECTOR(11 downto 0) is instruction_i(31 downto 20);

    -- regfile
    signal regfile_data1 : std_logic_vector(C_WIDTH-1 downto 0);
    signal regfile_data2 : std_logic_vector(C_WIDTH-1 downto 0);
    signal regfile_data : std_logic_vector(C_WIDTH-1 downto 0);

    -- control
    signal ctrl_ToRegister : std_logic_vector(2 downto 0);
    signal ctrl_mem_we : std_logic;
    signal ctrl_Branch : std_logic_vector(3 downto 0);
    signal ctrl_ALUOp : std_logic_vector(2 downto 0);
    signal ctrl_StoreSel : std_logic_vector(1 downto 0);
    signal ctrl_ALUSrc : std_logic;
    signal ctrl_regfile_we : std_logic;
    signal ctrl_arith_logic_b : STD_LOGIC;
    signal ctrl_signed_unsigned_b : STD_LOGIC;
    signal ctrl_result_filter : STD_LOGIC_VECTOR(1 downto 0);
    signal ctrl_csr_src : STD_LOGIC;
    signal ctrl_CSR_rw : STD_LOGIC;
    signal ctrl_CSR_rs : STD_LOGIC;
    signal ctrl_CSR_rc : STD_LOGIC;
    signal ctrl_csr_mret : STD_LOGIC;

    -- immediate
    signal immediate : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

    -- alu
    signal alu_operator2 : std_logic_vector(C_WIDTH-1 downto 0);
    signal alu_result : std_logic_vector(C_WIDTH-1 downto 0);
    signal alu_zero : std_logic;
    signal alu_equal : std_logic;
    signal alu_carryOut : std_logic;
    signal alu_x_lt_y_u : std_logic;
    signal alu_x_lt_y_s : std_logic;

    -- PC
    signal program_counter, program_counter_next : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal pc_adder_x, pc_adder_y, pc_sum, pc_inc4 : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal pc_sum_c, pc_inc4_c : STD_LOGIC_VECTOR(C_WIDTH downto 0);
    signal pc_adder_x_sel, pc_adder_y_sel : STD_LOGIC;
    signal jump, jump_condition : STD_LOGIC;
    
    -- other
    signal imm_sh12, pc_inc_imm_sh12 : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal pc_inc_imm_sh12_c : STD_LOGIC_VECTOR(C_WIDTH downto 0);
    signal dmem_do_i_signpadding : std_logic_vector(C_WIDTH-1 downto 0);
    
    -- ZiCSR extension
    signal from_CSR : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal to_CSR : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal pc_interrupted : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal interrupt : STD_LOGIC;
    -- signal csr_src, csr_we, csr_set_bits, csr_clear_bits, csr_mret : STD_LOGIC;

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    clock_i <= clock;
    reset_i <= reset;
    ce_i <= ce;
    irq_i <= irq;
    dmem_di <= dmem_di_o;
    dmem_we <= dmem_we_o;
    dmem_a <= dmem_a_o;
    dmem_do_i <= dmem_do;
    instruction_i <= instruction;
    PC <= PC_o;


    -------------------------------------------------------------------------------
    -- MAPPINGS
    -------------------------------------------------------------------------------
    dmem_we_o <= ctrl_mem_we;
    dmem_a_o <= alu_result;
    dmem_do_i_signpadding <= (others => dmem_di_o(C_WIDTH-1));
    PC_o <= program_counter;

    -------------------------------------------------------------------------------
    -- COMPONENTS
    -------------------------------------------------------------------------------
    reg_file_inst00: component reg_file port map(
        clock => clock_i,
        reset => reset_i,
        ce => ce_i,
        we => ctrl_regfile_we,
        src1 => inst_rs1,
        src2 => inst_rs2,
        dest => inst_rd,
        data => regfile_data,
        data1 => regfile_data1,
        data2 => regfile_data2
    );

    control_inst00: component control port map(
        opcode => inst_opcode,
        funct3 => inst_funct3,
        funct7 => inst_funct7,
        rd => inst_rd,
        rs1 => inst_rs1,

        -- jumping and branching
        Branch => ctrl_Branch,

        -- to DMEM
        mem_we => ctrl_mem_we,
        StoreSel => ctrl_StoreSel,

        -- to ALU
        ALUOp => ctrl_ALUOp,
        arith_logic_b => ctrl_arith_logic_b,
        signed_unsigned_b => ctrl_signed_unsigned_b,
        ALUSrc => ctrl_ALUSrc,

        -- to RegFile
        regfile_we => ctrl_regfile_we,
        ToRegister => ctrl_ToRegister,
        result_filter => ctrl_result_filter,

        -- ZiCSR extension
        csr_src => ctrl_csr_src,
        csr_we => ctrl_CSR_rw,
        csr_set_bits => ctrl_CSR_rs,
        csr_clear_bits => ctrl_CSR_rc,
        csr_mret => ctrl_csr_mret
    );


    immediate_gen_inst00: component immediate_gen port map(
        instruction => instruction_i,
        immediate => immediate
    );


    alu_inst00: component alu port map(
        operator1 => regfile_data1,
        operator2 => alu_operator2,
        ALUOp => ctrl_ALUOp,
        arith_logic_b => ctrl_arith_logic_b,
        signed_unsigned_b => ctrl_signed_unsigned_b,
        result => alu_result,
        zero => alu_zero,
        equal => alu_equal,
        carryOut => alu_carryOut,
        x_lt_y_u => alu_x_lt_y_u,
        x_lt_y_s => alu_x_lt_y_s
    );

    -------------------------------------------------------------------------------
    -- MUXES
    -------------------------------------------------------------------------------
    alu_operator2 <= immediate when ctrl_ALUSrc = '0' else regfile_data2;

    PMUX_DMEM_DI: process(ctrl_StoreSel, dmem_do_i, regfile_data2)
    begin
        case ctrl_StoreSel is
            when "01" => dmem_di_o <= dmem_do_i(31 downto 8) & regfile_data2(7 downto 0);
            when "10" => dmem_di_o <= dmem_do_i(31 downto 16) & regfile_data2(15 downto 0);
            when others => dmem_di_o <= regfile_data2;
        end case;
    end process;

    PMUX_REGFILE: process(ctrl_ToRegister, ctrl_result_filter, dmem_do_i, dmem_do_i_signpadding, program_counter, pc_inc4, immediate, alu_result, pc_inc_imm_sh12, from_CSR)
    begin

        case ctrl_ToRegister is
            when "001" =>
                regfile_data <= dmem_do_i;                                                          -- LW
            when "010" => 
                if ctrl_result_filter = "01" then
                    regfile_data <= dmem_do_i_signpadding(31 downto 8) & dmem_do_i(7 downto 0);     -- LB
                elsif ctrl_result_filter = "00" then
                    regfile_data <= C_GND(31 downto 8) & dmem_do_i(7 downto 0);                     -- LBU
                elsif ctrl_result_filter = "11" then
                    regfile_data <= dmem_do_i_signpadding(31 downto 16) & dmem_do_i(15 downto 0);   -- LH
                else
                    regfile_data <= C_GND(31 downto 16) & dmem_do_i(15 downto 0);                   -- LHU
                end if;

            when "011" => regfile_data <= program_counter;                                                     -- for JALR
            when "100" => regfile_data <= immediate(19 downto 0) & C_GND(11 downto 0);              -- for LUI
            when "101" => regfile_data <= pc_inc4;                                                  -- for JAL
            when "111" => regfile_data <= pc_inc_imm_sh12;                                          -- for auipc
            when "110" => regfile_data <= from_CSR;                                               -- for ALU
            when others => regfile_data <= alu_result;
        end case;
    end process;


    -------------------------------------------------------------------------------
    -- PC
    -------------------------------------------------------------------------------
    
    PMUX_PCNEXT: process(interrupt, ctrl_csr_mret, pc_interrupted, pc_sum)
    begin
        if interrupt = '1' then 
            program_counter_next <= pc_interrupted;
        elsif ctrl_csr_mret = '1' then 
            program_counter_next <= pc_interrupted;
        else
            program_counter_next <= pc_sum;
        end if;
    end process;

    PREG_PC: process(clock_i)
    begin
        if rising_edge(clock_i) then
            if reset_i = '1' then 
                program_counter <= C_GND;
            else
                if ce_i = '1' then 
                    program_counter <= program_counter_next;
                end if;
            end if;
        end if;
    end process;

    pc_adder_x <= program_counter when pc_adder_x_sel = '0' else regfile_data1;
    pc_adder_y <= x"00000004" when pc_adder_y_sel = '0' else immediate(30 downto 0) & '0';
    
    pc_sum_c(0) <= '0';
    GENRCA_2 : for i in 0 to C_WIDTH-1 generate
        pc_sum(i) <= pc_adder_x(i) XOR pc_adder_y(i) XOR pc_sum_c(i);
        pc_sum_c(i+1) <= (pc_adder_x(i) AND pc_adder_y(i)) OR (pc_sum_c(i) AND (pc_adder_x(i) XOR pc_adder_y(i)));
    end generate GENRCA_2;

    pc_adder_x_sel <= '1' when ctrl_branch = "1110" else '0';   -- only on JALR
    pc_adder_y_sel <= '0' when jump = '0' else '1';   -- only on JMP or CJMP

    jump <= ctrl_branch(3) and jump_condition;

    process(ctrl_Branch, alu_equal, alu_x_lt_y_s, alu_x_lt_y_u)
    begin
        case ctrl_Branch(2 downto 0) is
            when "001" => jump_condition <= alu_equal;
            when "010" => jump_condition <= not(alu_equal);
            when "011" => jump_condition <= alu_x_lt_y_s;
            when "100" => jump_condition <= not(alu_x_lt_y_s);
            when "101" => jump_condition <= '1';  --JAL
            when "110" => jump_condition <= '1';  --JALR
            when "111" => jump_condition <= not(alu_x_lt_y_u);           -- BGEU
            when others => jump_condition <= alu_x_lt_y_u;               -- BLTU 
        end case;
    end process ;
    
    pc_inc4_c(0) <= '0';
    GENRCA_1 : for i in 0 to C_WIDTH-1 generate
        pc_inc4(i) <= program_counter(i) XOR C_FOUR(i) XOR pc_inc4_c(i);
        pc_inc4_c(i+1) <= (program_counter(i) AND C_FOUR(i)) OR (pc_inc4_c(i) AND (program_counter(i) XOR C_FOUR(i)));
    end generate GENRCA_1;

    imm_sh12 <= immediate(19 downto 0) & x"000";
    pc_inc_imm_sh12_c(0) <= '0';
    GENRCA_3 : for i in 0 to C_WIDTH-1 generate
        pc_inc_imm_sh12(i) <= program_counter(i) XOR imm_sh12(i) XOR pc_inc_imm_sh12_c(i);
        pc_inc_imm_sh12_c(i+1) <= (program_counter(i) AND imm_sh12(i)) OR (pc_inc_imm_sh12_c(i) AND (program_counter(i) XOR imm_sh12(i)));
    end generate GENRCA_3;

    -------------------------------------------------------------------------------
    -- ZiCSR extension
    -------------------------------------------------------------------------------

    to_CSR <= regfile_data1 when ctrl_csr_src = '0' else x"000000" & "000" & inst_rs1;

    riscv_csr_inst00: component riscv_csr generic map(G_HARTID => C_HARTID_0) port map(
        clock => clock_i,
        reset => reset_i,
        ce => ce_i,
        data_in => to_CSR,
        CSR_address => inst_csr_address,
        rw => ctrl_CSR_rw,
        rs => ctrl_CSR_rs,
        rc => ctrl_CSR_rc,
        interrupt_request => irq_i,
        mret => ctrl_csr_mret,
        data_out => from_CSR,
        interrupt => interrupt,
        pc_in => program_counter,
        pc_out => pc_interrupted
    );
   
end Behavioural;
