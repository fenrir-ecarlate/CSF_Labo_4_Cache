-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : cache_memory.vhd
--
-- Description  : Cache memory.
-- 
-- Auteur       : Yann Thoma
-- Date         : 12.05.2016
-- Version      : 0.1 ports
-- 
-- Utilise      :  
--              :  
-- 
--| Modifications |------------------------------------------------------------
--                                          
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
    constant NUMBER_OF_WORDS_IN_CACHE_LINE : integer := 16 -- Nombre de mots par ligne de cache
    type cache_type is array (0 to (2**INDEX_SIZE)-1) of std_logic_vector(NUMBER_OF_WORDS_IN_CACHE_LINE * DATA_SIZE);
    
    signal cache : cache_type;
    
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
      elsif rising_edge(clk_i) then
        
      end if;
    end process;

end struct;

