-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : gestion_write.vhd
--
-- Description  : Gestion de l'accès write à la cache
-- 
-- Auteur       : João Domingues, Rick Wertenbroek
-- Date         : 12.05.2016
-- Version      : 0.1 ports
-- 
-- Utilise      :  
--              :  
-- 
--| Modifications |------------------------------------------------------------
-- Version        Date      Auteur      Description
-- 1.0            27.05.16  DPJ         Début du laboratoire
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.math_real.all;
--library work;
use work.cmf_pkg.all;


entity gestion_write is

   generic(
        ADDR_SIZE         : integer := 11;
        DATA_SIZE         : integer := 8);


    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
        busy_i            : in  std_logic;
        hit_i             : in  std_logic;
        data_o            : out std_logic_vector((ADDR_SIZE-1) downto 0);
        
        );  
        
end gestion_write;


architecture struct of cache_memory is
    
begin
    
    process (clk_i, reset_i)
    begin
        if(rising_edge(clk_i)) then
            if(not(busy)) then
                
            end if;
        end if;
    end process;

end struct;

