-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : cmf_pkg.vhd
--
-- Description  : Package for cmf
-- 
-- Auteur       : Yann Thoma
-- Date         : 14.03.2016
-- Version      : 0
-- 
-- Utilise      :  
--              :  
-- 
--| Modifications |------------------------------------------------------------
-- 
-- 
--                                          
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


package cmf_pkg is


    type agent_to_cache_t is 
    record
        wr          : std_logic;
        rd          : std_logic;
        addr        : std_logic_vector;
        data        : std_logic_vector;
    end record agent_to_cache_t;

    type cache_to_agent_t is 
    record
        dready      : std_logic;  
        data        : std_logic_vector;                                                
        busy        : std_logic;
    end record cache_to_agent_t;

    type cache_to_mem_t is
    record
        wr          : std_logic;
        rd          : std_logic;
        burst_range : std_logic_vector;
        burst       : std_logic;
        addr        : std_logic_vector;
        data        : std_logic_vector; 
    end record cache_to_mem_t;

    type mem_to_cache_t is 
    record  
        busy        : std_logic;
        dready      : std_logic;
        data        : std_logic_vector;     
    end record mem_to_cache_t;

    type cache_monitor_t is
    record
        watchdog    : std_logic;
        instr_error : std_logic;
        miss        : std_logic;
        hit         : std_logic; 
	end record cache_monitor_t;

    -- type agent_to_cache_array_t is array (integer range <>) of agent_to_cache_t;
    -- type cache_to_agent_array_t is array (integer range <>) of cache_to_agent_t;


end cmf_pkg;

