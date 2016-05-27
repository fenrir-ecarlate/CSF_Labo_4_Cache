-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : cache_memory.vhd
--
-- Description  : Cache memory.
-- 
-- Auteur       : João Domingues, Rick Wertenbroek sur chablon de Yann Thoma
-- Date         : 12.05.2016
-- Version      : 0.1 ports
-- 
-- Utilise      :  
--              :  
-- 
--| Modifications |------------------------------------------------------------
-- Version        Date      Auteur      Description
-- 1.0            20.05.16  RWK         Début du laboratoire
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.math_real.all;
--library work;
use work.cmf_pkg.all;


entity cache_memory is

    generic(
        ADDR_SIZE         : integer := 11;
        INDEX_SIZE        : integer := 5;    --Memory depth = 2^INDEX_SIZE           
        TAG_SIZE          : integer := 6;   --TAG_SIZE must have the same size than the DDR3 memory @ddress - INDEX
        DATA_SIZE         : integer := 8);


    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
        --agent interface------------------ 
        agent_i           : in  agent_to_cache_t;
        agent_o           : out cache_to_agent_t;
        --CPU interface------------------
        
        --memory interface------------------ 
        mem_i             : in  mem_to_cache_t;
        mem_o             : out cache_to_mem_t;    
        --memory interface------------------
        
        --|monitoring|-------------------
        mon_info_o        : out cache_monitor_t);  


end cache_memory;


architecture struct of cache_memory is
    constant NUMBER_OF_WORDS_IN_CACHE_LINE : integer := 16; -- Nombre de mots par ligne de cache
    constant OFFSET_SIZE : integer := 4; -- LOG2(NUMBER_OF_WORDS_IN_CACHE_LINE)
    type cache_type is array (0 to (2**INDEX_SIZE)-1) of std_logic_vector((NUMBER_OF_WORDS_IN_CACHE_LINE * DATA_SIZE)-1 downto 0);
    type bit_array_type is array (0 to (2**INDEX_SIZE)-1) of std_logic;
    type tag_type   is array (0 to (2**INDEX_SIZE)-1) of std_logic_vector(TAG_SIZE-1 downto 0);
    
    signal cache : cache_type;            -- La cache (lignes de mots)
    signal dirty_bits : bit_array_type;   -- Les bits dirty de la cache
    signal valid_bits : bit_array_type;   -- Les bits valid
    signal tags : tag_type;               -- La liste des tags

    -- Signaux d'entrée de la cache
    signal cache_index_s : std_logic_vector(INDEX_SIZE-1 downto 0);
    signal cache_tag_s : std_logic_vector(TAG_SIZE-1 downto 0);
    signal cache_b_off_s : std_logic_vector(OFFSET_SIZE-1 downto 0);
    signal cache_read_s : std_logic;
    signal cache_write_s : std_logic;
    
    -- Signaux de sortie de la cache
    signal cache_data_s : std_logic_vector(DATA_SIZE-1 downto 0);
    signal cache_hit_s : std_logic;
begin
    -- These asserts are used by simulation in order to check the generic 
    -- parameters with the instanciation of record ports
    assert agent_i.addr'length = ADDR_SIZE report "Address size do not match" severity failure;
    assert agent_i.data'length = DATA_SIZE report "Data size do not match" severity failure;
    assert agent_o.data'length = DATA_SIZE report "Data size do not match" severity failure;
    assert mem_i.data'length = DATA_SIZE report "Data size do not match" severity failure;
    assert mem_o.addr'length = ADDR_SIZE report "Address size do not match" severity failure;
    assert mem_o.burst_range'length = ADDR_SIZE report "Burst range size do not match" severity failure;
    assert mem_o.data'length = DATA_SIZE report "Data size do not match" severity failure;

    Cache_process : process (clk_i, reset_i) is
    begin
      if (reset_i = '1') then
        valid_bits <= (others => '0'); -- Au reset toutes les lignes de cache
                                       -- sont invalidées
      elsif rising_edge(clk_i) then
        cache_hit_s <= '1' when ((tags(to_integer(unsigned(cache_index_s))) = cache_tag_s) and valid_bits(to_integer(unsigned(cache_index_s))) = '1')
                       '0';
        cache_data_s <= cache(((to_integer(unsigned(cache_b_off_s))+1) * DATA_SIZE) - 1 downto to_integer(unsigned(cache_b_off_s)) * DATA_SIZE);
      end if;
    end process;

end struct;

