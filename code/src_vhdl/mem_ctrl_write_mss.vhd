-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : mem_ctrl_write_mss.vhd
--
-- Description  : Contrôleur entre la mémoire et la cache
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
-- 1.0            10.06.16  DPJ         Début du laboratoire
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.math_real.all;
--library work;
use work.cmf_pkg.all;


entity mem_ctrl_write_mss is

    generic(
        ADDR_SIZE         : integer := 11;
        DATA_SIZE         : integer := 8);

    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
        start_i           : in  std_logic;
        data_i            : in  std_logic_vector(DATA_SIZE -1 downto 0);
        data_ok_o         : out std_logic;
        done_o            : out std_logic;
        
        --memory interface------------------ 
        mem_i             : in  mem_to_cache_t;
        mem_o             : out cache_to_mem_t    
        );  


end mem_ctrl_write_mss;


architecture struct of mem_ctrl_write_mss is

    type STATE_TYPE is (WAIT_START, WAIT_BUSY, SEND_DATA);
    
    -- FSM
    signal state_s, next_state_s : STATE_TYPE;
    signal cnt_burst : unsigned(4 downto 0);
    
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
            when WAIT_START =>
                data_ok_o <= '0';
                if(start_i = '1')then
                    mem_o.wr          <= '1';
                    mem_o.burst       <= '1';
                    cnt_burst <= to_unsigned(16, cnt_burst'length);
                    mem_o.burst_range <= std_logic_vector(cnt_burst);
                    done_o <= '0';
                    next_state_s <= WAIT_BUSY;
                else
                    next_state_s <= WAIT_START;
                end if;
                
            when WAIT_BUSY =>
                if(mem_i.busy='1') then
                    next_state_s <= WAIT_BUSY;
                else
                    next_state_s <= SEND_DATA;
                end if;

            when SEND_DATA =>
                mem_o.data <= data_i;
                data_ok_o <= '1';
                cnt_burst <= cnt_burst-1;
                if cnt_burst = 0 then
                    mem_o.wr     <= '0';
                    mem_o.burst  <= '0';
                    done_o       <= '1';
                    next_state_s <= WAIT_START;
                else
                    next_state_s <= WAIT_BUSY;
                end if;
                
        end case;
            
            
      end if;
      state_s <= next_state_s;
    end process;

end struct;

