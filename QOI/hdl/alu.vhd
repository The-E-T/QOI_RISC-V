--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     alu - Behavioural
-- Project Name:    HWSWCD
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20241126   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

library work;
    use work.PKG_hwswcd.ALL;

entity alu is
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
end entity ;

architecture Behavioural of alu is

    -- (DE-)LOCALISING IN/OUTPUTS
    signal operator1_i : std_logic_vector(C_WIDTH-1 downto 0);
    signal operator2_i : std_logic_vector(C_WIDTH-1 downto 0);
    signal ALUOp_i : std_logic_vector(2 downto 0);
    signal arith_logic_b_i : STD_LOGIC;
    signal signed_unsigned_b_i : STD_LOGIC;
    signal result_o : std_logic_vector(C_WIDTH-1 downto 0);
    signal zero_o : std_logic;
    signal equal_o : std_logic;
    signal carryOut_o : std_logic;
    signal x_lt_y_u_o : std_logic;
    signal x_lt_y_s_o : std_logic;

    --
    signal aluResult : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal temp_sign : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    
    -- intermediate adder signals
    signal addition_sum, subtraction_sum : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal addition_c, subtraction_c : STD_LOGIC_VECTOR(C_WIDTH downto 0);
    
    -- shift
    signal ShiLe: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal ShiRi: STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal offset : natural range 0 to C_WIDTH-1;
    signal shift_right_input : STD_LOGIC;
    signal shift_right_input_vector : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

    -- comparator
    signal op1_uint, op2_uint : integer;
    signal op1_int, op2_int : integer;
    signal x_lt_y_int, x_lt_y_uint : STD_LOGIC;
    signal x_lt_y : STD_LOGIC;

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    operator1_i <= operator1;
    operator2_i <= operator2;
    ALUOp_i <= ALUOp;
    arith_logic_b_i <= arith_logic_b;
    signed_unsigned_b_i <= signed_unsigned_b;

    result <= result_o;
    zero <= zero_o;
    equal <= equal_o;
    carryOut <= carryOut_o;
    x_lt_y_u <= x_lt_y_u_o;
    x_lt_y_s <= x_lt_y_s_o;

    -------------------------------------------------------------------------------
    -- COMBINATORIAL
    -------------------------------------------------------------------------------
    zero_o <= '1' when aluResult = C_GND else '0';
    equal_o <= '1' when operator1_i = operator2_i else '0';
    carryOut_o <= addition_c(C_WIDTH) when ALUOp = "100" else subtraction_c(C_WIDTH);
    result_o <= aluResult;
    -- signo_o <= aluResult(C_WIDTH-1);
    x_lt_y_u_o <= x_lt_y_uint;
    x_lt_y_s_o <= x_lt_y_int;


    op1_uint <= to_integer(unsigned(operator1_i));
    op2_uint <= to_integer(unsigned(operator2_i));
    op1_int <= to_integer(signed(operator1_i));
    op2_int <= to_integer(signed(operator2_i));
    x_lt_y_uint <= '1' when op1_uint < op2_uint else '0';
    x_lt_y_int <= '1' when op1_int < op2_int else '0';
    x_lt_y <= x_lt_y_int when signed_unsigned_b_i = '0' else x_lt_y_uint;
    temp_sign <= C_GND(C_WIDTH-1 downto 1) & x_lt_y;


    PMUX: process(operator2_i, operator1_i, shift_right_input_vector)
    begin
        case(operator2_i(C_REGCOUNT_LOG2-1 downto 0)) is
            when "00001" => ShiLe <= operator1_i(C_WIDTH-1-1 downto 0) & C_GND(1-1 downto 0);        ShiRi <= shift_right_input_vector(1-1 downto 0) & operator1_i(C_WIDTH-1 downto 1);
            when "00010" => ShiLe <= operator1_i(C_WIDTH-1-2 downto 0) & C_GND(2-1 downto 0);        ShiRi <= shift_right_input_vector(2-1 downto 0) & operator1_i(C_WIDTH-1 downto 2);
            when "00011" => ShiLe <= operator1_i(C_WIDTH-1-3 downto 0) & C_GND(3-1 downto 0);        ShiRi <= shift_right_input_vector(3-1 downto 0) & operator1_i(C_WIDTH-1 downto 3);
            when "00100" => ShiLe <= operator1_i(C_WIDTH-1-4 downto 0) & C_GND(4-1 downto 0);        ShiRi <= shift_right_input_vector(4-1 downto 0) & operator1_i(C_WIDTH-1 downto 4);
            when "00101" => ShiLe <= operator1_i(C_WIDTH-1-5 downto 0) & C_GND(5-1 downto 0);        ShiRi <= shift_right_input_vector(5-1 downto 0) & operator1_i(C_WIDTH-1 downto 5);
            when "00110" => ShiLe <= operator1_i(C_WIDTH-1-6 downto 0) & C_GND(6-1 downto 0);        ShiRi <= shift_right_input_vector(6-1 downto 0) & operator1_i(C_WIDTH-1 downto 6);
            when "00111" => ShiLe <= operator1_i(C_WIDTH-1-7 downto 0) & C_GND(7-1 downto 0);        ShiRi <= shift_right_input_vector(7-1 downto 0) & operator1_i(C_WIDTH-1 downto 7);
            when "01000" => ShiLe <= operator1_i(C_WIDTH-1-8 downto 0) & C_GND(8-1 downto 0);        ShiRi <= shift_right_input_vector(8-1 downto 0) & operator1_i(C_WIDTH-1 downto 8);
            when "01001" => ShiLe <= operator1_i(C_WIDTH-1-9 downto 0) & C_GND(9-1 downto 0);        ShiRi <= shift_right_input_vector(9-1 downto 0) & operator1_i(C_WIDTH-1 downto 9);
            when "01010" => ShiLe <= operator1_i(C_WIDTH-1-10 downto 0) & C_GND(10-1 downto 0);      ShiRi <= shift_right_input_vector(10-1 downto 0) & operator1_i(C_WIDTH-1 downto 10);
            when "01011" => ShiLe <= operator1_i(C_WIDTH-1-11 downto 0) & C_GND(11-1 downto 0);      ShiRi <= shift_right_input_vector(11-1 downto 0) & operator1_i(C_WIDTH-1 downto 11);
            when "01100" => ShiLe <= operator1_i(C_WIDTH-1-12 downto 0) & C_GND(12-1 downto 0);      ShiRi <= shift_right_input_vector(12-1 downto 0) & operator1_i(C_WIDTH-1 downto 12);
            when "01101" => ShiLe <= operator1_i(C_WIDTH-1-13 downto 0) & C_GND(13-1 downto 0);      ShiRi <= shift_right_input_vector(13-1 downto 0) & operator1_i(C_WIDTH-1 downto 13);
            when "01110" => ShiLe <= operator1_i(C_WIDTH-1-14 downto 0) & C_GND(14-1 downto 0);      ShiRi <= shift_right_input_vector(14-1 downto 0) & operator1_i(C_WIDTH-1 downto 14);
            when "01111" => ShiLe <= operator1_i(C_WIDTH-1-15 downto 0) & C_GND(15-1 downto 0);      ShiRi <= shift_right_input_vector(15-1 downto 0) & operator1_i(C_WIDTH-1 downto 15);
            when "10000" => ShiLe <= operator1_i(C_WIDTH-1-16 downto 0) & C_GND(16-1 downto 0);      ShiRi <= shift_right_input_vector(16-1 downto 0) & operator1_i(C_WIDTH-1 downto 16);
            when "10001" => ShiLe <= operator1_i(C_WIDTH-1-17 downto 0) & C_GND(17-1 downto 0);      ShiRi <= shift_right_input_vector(17-1 downto 0) & operator1_i(C_WIDTH-1 downto 17);
            when "10010" => ShiLe <= operator1_i(C_WIDTH-1-18 downto 0) & C_GND(18-1 downto 0);      ShiRi <= shift_right_input_vector(18-1 downto 0) & operator1_i(C_WIDTH-1 downto 18);
            when "10011" => ShiLe <= operator1_i(C_WIDTH-1-20 downto 0) & C_GND(20-1 downto 0);      ShiRi <= shift_right_input_vector(20-1 downto 0) & operator1_i(C_WIDTH-1 downto 20);
            when "10100" => ShiLe <= operator1_i(C_WIDTH-1-21 downto 0) & C_GND(21-1 downto 0);      ShiRi <= shift_right_input_vector(21-1 downto 0) & operator1_i(C_WIDTH-1 downto 21);
            when "10101" => ShiLe <= operator1_i(C_WIDTH-1-22 downto 0) & C_GND(22-1 downto 0);      ShiRi <= shift_right_input_vector(22-1 downto 0) & operator1_i(C_WIDTH-1 downto 22);
            when "10110" => ShiLe <= operator1_i(C_WIDTH-1-23 downto 0) & C_GND(23-1 downto 0);      ShiRi <= shift_right_input_vector(23-1 downto 0) & operator1_i(C_WIDTH-1 downto 23);
            when "10111" => ShiLe <= operator1_i(C_WIDTH-1-24 downto 0) & C_GND(24-1 downto 0);      ShiRi <= shift_right_input_vector(24-1 downto 0) & operator1_i(C_WIDTH-1 downto 24);
            when "11000" => ShiLe <= operator1_i(C_WIDTH-1-24 downto 0) & C_GND(24-1 downto 0);      ShiRi <= shift_right_input_vector(24-1 downto 0) & operator1_i(C_WIDTH-1 downto 24);
            when "11001" => ShiLe <= operator1_i(C_WIDTH-1-25 downto 0) & C_GND(25-1 downto 0);      ShiRi <= shift_right_input_vector(25-1 downto 0) & operator1_i(C_WIDTH-1 downto 25);
            when "11010" => ShiLe <= operator1_i(C_WIDTH-1-26 downto 0) & C_GND(26-1 downto 0);      ShiRi <= shift_right_input_vector(26-1 downto 0) & operator1_i(C_WIDTH-1 downto 26);
            when "11011" => ShiLe <= operator1_i(C_WIDTH-1-27 downto 0) & C_GND(27-1 downto 0);      ShiRi <= shift_right_input_vector(27-1 downto 0) & operator1_i(C_WIDTH-1 downto 27);
            when "11100" => ShiLe <= operator1_i(C_WIDTH-1-28 downto 0) & C_GND(28-1 downto 0);      ShiRi <= shift_right_input_vector(28-1 downto 0) & operator1_i(C_WIDTH-1 downto 28);
            when "11101" => ShiLe <= operator1_i(C_WIDTH-1-29 downto 0) & C_GND(29-1 downto 0);      ShiRi <= shift_right_input_vector(29-1 downto 0) & operator1_i(C_WIDTH-1 downto 29);
            when "11110" => ShiLe <= operator1_i(C_WIDTH-1-30 downto 0) & C_GND(30-1 downto 0);      ShiRi <= shift_right_input_vector(30-1 downto 0) & operator1_i(C_WIDTH-1 downto 30);
            when "11111" => ShiLe <= operator1_i(C_WIDTH-1-31 downto 0) & C_GND(31-1 downto 0);      ShiRi <= shift_right_input_vector(31-1 downto 0) & operator1_i(C_WIDTH-1 downto 31);
            when others => ShiLe <= operator1_i; Shiri <= operator1_i;
        end case;
    end process;


    -- offset <= to_integer(unsigned(operator2_i(C_REGCOUNT_LOG2-1 downto 0)));
    -- ShiLe <= operator1_i(C_WIDTH-1-offset downto 0) & C_GND(offset-1 downto 0);

    -- ShiRi <= shift_right_input_vector(offset-1 downto 0) & operator1_i(C_WIDTH-1 downto offset);

    -- if it's logic, the 'and' with 0 forces a 0 to be shifted in
    -- otherwise the msb of the operator1 is shifted in
    shift_right_input <= operator1_i(operator1_i'high) and arith_logic_b_i;
    shift_right_input_vector <= (others => shift_right_input);



    -- MUX
    process(operator1_i, operator2_i, ALUOp_i, addition_sum, subtraction_sum, ShiLe, ShiRi, temp_sign)
    begin
        case(ALUOp_i) is
            when "000" => aluResult <= operator1_i and operator2_i;
            when "001" => aluResult <= operator1_i or operator2_i;
            when "010" => aluResult <= operator1_i xor operator2_i;
            when "011" => aluResult <= temp_sign;
            when "100" => aluResult <= addition_sum;
            when "101" => aluResult <= subtraction_sum;
            when "110" => aluResult <= ShiLe;
            when "111" => aluResult <= ShiRi;
            when others => aluResult <= operator1_i;
        end case ;       
    end process ;


    -------------------------------------------------------------------------------
    -- ARITHMETIC
    -------------------------------------------------------------------------------
    addition_c(0) <= '0';
    subtraction_c(0) <= '1';

    GEN : for i in 0 to C_WIDTH-1 generate
        addition_sum(i) <= operator1_i(i) XOR operator2_i(i) XOR addition_c(i);
        addition_c(i+1) <= (operator1_i(i) AND operator2_i(i)) OR (addition_c(i) AND (operator1_i(i) XOR operator2_i(i)));

        subtraction_sum(i) <= operator1_i(i) XOR not(operator2_i(i)) XOR subtraction_c(i);
        subtraction_c(i+1) <= (operator1_i(i) AND not(operator2_i(i))) OR (subtraction_c(i) AND (operator1_i(i) XOR not(operator2_i(i))));
    end generate;

end Behavioural;
