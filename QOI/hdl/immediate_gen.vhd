--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC - Emerging technologies, Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     immediate_gen - Behavioural
-- Project Name:    immediate_gen
-- Description:     
--
-- Revision     Date       Author     Comments
-- v0.1         20241126   VlJo       Initial version
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
    use work.PKG_hwswcd.ALL;

entity immediate_gen is
    port(
        instruction : in STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
        immediate : out STD_LOGIC_VECTOR(C_WIDTH-1 downto 0)
    );
end entity immediate_gen;

architecture Behavioural of immediate_gen is

    signal instruction_i : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal immediate_o : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    alias opcode : STD_LOGIC_VECTOR(6 downto 0) is instruction_i(6 downto 0);
    
    signal prepadding_Itype : STD_LOGIC_VECTOR(20-1 downto 0);
    signal immediate_Itype : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal prepadding_Stype : STD_LOGIC_VECTOR(20-1 downto 0);
    signal immediate_Stype : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal prepadding_SBtype : STD_LOGIC_VECTOR(20-1 downto 0);
    signal immediate_SBtype : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal prepadding_Utype : STD_LOGIC_VECTOR(12-1 downto 0);
    signal immediate_Utype : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);
    signal prepadding_UJtype : STD_LOGIC_VECTOR(12-1 downto 0);
    signal immediate_UJtype : STD_LOGIC_VECTOR(C_WIDTH-1 downto 0);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    instruction_i <= instruction;
    immediate <= immediate_o;

    -------------------------------------------------------------------------------
    -- COMBINATORIAL
    -------------------------------------------------------------------------------
    
    -- mux
    process(opcode, immediate_Itype, immediate_Stype, immediate_SBtype, immediate_Utype, immediate_UJtype)
    begin
        case opcode is
            when "0010011" => immediate_o <= immediate_Itype;
            when "0000011" => immediate_o <= immediate_Itype;
            when "0100011" => immediate_o <= immediate_Stype;
            when "1100011" => immediate_o <= immediate_SBtype;
            when "1100111" => immediate_o <= immediate_Itype;
            when "0110111" => immediate_o <= immediate_Utype;
            when "0010111" => immediate_o <= immediate_Utype;
            when "1101111" => immediate_o <= immediate_UJtype;
            when others => immediate_o <= (others => '0');
        end case;       
    end process ; 

    -- reconstructing different options
    prepadding_Itype <= (others => instruction_i(C_WIDTH-1));
    immediate_Itype <= prepadding_Itype & instruction_i(31 downto 20);
    prepadding_Stype <= (others => instruction_i(C_WIDTH-1));
    immediate_Stype <= prepadding_Stype & instruction_i(31 downto 25) & instruction_i(11 downto 7);
    prepadding_SBtype <= (others => instruction_i(C_WIDTH-1));
    immediate_SBtype <= prepadding_SBtype 
            & instruction_i(31) 
            & instruction_i(7) 
            & instruction_i(30 downto 25) 
            & instruction_i(11 downto 8);
    prepadding_Utype <= (others => instruction_i(C_WIDTH-1));
    immediate_Utype <= prepadding_Utype & instruction_i(31 downto 12);
    prepadding_UJtype <= (others => instruction_i(C_WIDTH-1));
    immediate_UJtype <= prepadding_UJtype 
        & instruction_i(31) 
        & instruction_i(19 downto 12) 
        & instruction_i(20) 
        & instruction_i(30 downto 21);

end Behavioural;
