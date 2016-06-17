-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : mem_ctrl_read_mss.vhd
--
-- Description  : Contrôleur entre la mémoire et la cache
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
-- 1.0            10.06.16  DPJ         Début du laboratoire
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.math_real.all;
--library work;
use work.cmf_pkg.all;


entity mem_ctrl_read_mss is

    generic(
        ADDR_SIZE         : integer := 11;
        DATA_SIZE         : integer := 8);


    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
        start_i           : in  std_logic;
        data_o            : out std_logic_vector(DATA_SIZE -1 downto 0);
        data_ok_o         : out std_logic;
        --agent interface------------------ 
        agent_i           : in  agent_to_cache_t;
        agent_o           : out cache_to_agent_t;
        --CPU interface------------------
        
        --memory interface------------------ 
        mem_i             : in  mem_to_cache_t;
        mem_o             : out cache_to_mem_t;    
        --memory interface------------------
        );  


end mem_ctrl_read_mss;


architecture struct of mem_ctrl_read_mss is

    type STATE_TYPE is (WAIT_START, WAIT_BUSY, WAIT_READY, STOCK_DATA);
    
    -- FSM
    signal state_s, next_state_s : STATE_TYPE;
    signal cnt_busrt : unsigned;
    
begin
    -- These asserts are used by simulation in order to check the generic 
    -- parameters with the instanciation of record ports

    cache_fsm_process : process (clk_i, reset_i) is
    begin
      if (reset_i = '1') then
        state_s <= WAIT_START;
        next_state_s <= WAIT_START;
      elsif rising_edge(clk_i) then
        case state_s is
            when state_s = WAIT_START =>
                data_ok_o <= '0';
                if(start_i = '1')then
                    mem_o.rd          <= '1';
                    mem_o.burst       <= '1';
                    cnt_busrt <= 16;
                    mem_o.burst_range <= std_logic_vector(16);
                    done <= '0';
                    next_state_s <= WAIT_BUSY;
                else
                    next_state_s <= WAIT_START
                end if;
                
            when state_s = WAIT_BUSY =>
                if(mem_i.busy='1') then
                    next_state_s <= WAIT_BUSY;
                else
                    next_state_s = WAIT_READY;
                end if;
                
           when state_s = WAIT_READY =>
                data_ok_o <= '0';
                if(mem_i.dready = '1') then
                    next_state_s <= STOCK_DATA;
                else
                    next_state_s <= WAIT_READY;
                end if;
                
            when state_s = STOCK_DATA =>
                data_o <= mem_i.data;
                data_ok_o <= '1';
                cnt_busrt<=cnt_busrt-1;
                if cnt_busrt = 0 then
                    next_state_s <= WAIT_START;
                else
                    next_state_s <= WAIT_READY;
                end if;
                
        end case;
            
            
      end if;
      state_s <= next_state_s;
    end process;

end struct;

