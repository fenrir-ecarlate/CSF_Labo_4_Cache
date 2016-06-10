----------------------------------------------------------------------------------
-- Company: HEIG-VD REDS
-- Engineer: JoÃ£o Domingues, Rick Wertenbroek
-- 
-- Create Date: 18.02.2016 09:56:53
-- Design Name: 
-- Module Name: cache_memory_tb - Behavioral
-- Project Name: Memoire Cache
-- Target Devices: (This is a testbench !)
-- Tool Versions: 
-- Description: Test Bench for Cache Memory
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


library work;
use work.cmf_pkg.all;

entity cache_memory_tb is
generic(
    ADDR_SIZE         : integer :=11;
    INDEX_SIZE        : integer :=5;   --Memory depth = 2^INDEX_SIZE                
    TAG_SIZE          : integer :=6;   --TAG_SIZE must have the same size than the DDR3 memory @ddress - INDEX
    DATA_SIZE         : integer :=8    --Data field must have the same size than the DDR3 memory data  
);    
end cache_memory_tb;



architecture testbench of cache_memory_tb is

    component cache_memory is
    generic(
        ADDR_SIZE         : integer := 11;
        INDEX_SIZE        : integer :=5; --Memory depth = 2^INDEX_SIZE                
        TAG_SIZE          : integer :=6; --TAG_SIZE must have the same size than the DDR3 memory @ddress - INDEX
        DATA_SIZE         : integer :=8  --Data field must have the same size than the DDR3 memory data  
            );    
    
    port (
        clk_i             : in  std_logic;
        reset             : in  std_logic;
        --CPU interface------------------ 
        agent_i           : in  agent_to_cache_t;
        agent_o           : out cache_to_agent_t;
        --CPU interface------------------
        
        --memory interface------------------ 
        mem_i             : in  mem_to_cache_t;
        mem_o             : out cache_to_mem_t;    
        --memory interface------------------
        
        --|monitoring|-------------------
        mon_info_o        : out cache_monitor_t
    );
    end component;

    signal clk_sti : std_logic;
    signal reset_sti : std_logic;
    
    signal from_agent_sti       : agent_to_cache_t(addr(ADDR_SIZE-1 downto 0),
                                                 data(DATA_SIZE-1 downto 0));
    signal cache_to_agent_obs : cache_to_agent_t(data(DATA_SIZE-1 downto 0));
    signal from_mem_obs       : mem_to_cache_t(data(DATA_SIZE-1 downto 0));
    signal cache_to_mem_obs   : cache_to_mem_t(burst_range(ADDR_SIZE-1 downto 0),
                                               addr(ADDR_SIZE-1 downto 0),
                                               data(DATA_SIZE-1 downto 0));


    signal monitor_obs    : cache_monitor_t;                                  

    signal synchro_verif  : std_logic;
    signal verification_going : std_logic;
begin
        
    dut : cache_memory
    generic map(
        ADDR_SIZE  => ADDR_SIZE,
        DATA_SIZE  => DATA_SIZE,
        INDEX_SIZE => INDEX_SIZE,
        TAG_SIZE   => TAG_SIZE
            )
    port map(
        clk_i => clk_sti,
        reset => reset_sti,
        --Agent interface-----
        agent_i => from_agent_sti,
        agent_o => cache_to_agent_obs, 
        --Agent interface-----
        
        --DDR interface-----
        mem_i => from_mem_obs,
   	 	mem_o => cache_to_mem_obs,          
        --DDR interface-----
        
        --|monitoring|------
        mon_info_o => monitor_obs
    );

    -- Processus de commande et synchronisation
    chef_d_orchestre: process
    begin
      synchro_verif <= '1';
      wait until rising_edge(verification_going);
      loop
        wait for 10 ns;
        synchro_verif <= '0';
        wait for 10 ns;
        synchro_verif <= '1';
        if verification_going = '0' then
          wait for 20 ns;
          report "Fin de la verification !";
          wait;
        end if;
      end loop;
    end process;

    stimuli: process
    begin

    end process;

    verification: process
      wait until rising_edge(verification_going); -- Pourrait être fait autrement

      loop
        wait until rising_edge(synchro_verif); -- On est synchronisé avec tout
                                               -- le monde

      end loop;

      wait;
    end process;

end testbench;


