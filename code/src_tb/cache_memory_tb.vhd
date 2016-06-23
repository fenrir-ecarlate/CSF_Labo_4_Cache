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
    ADDR_SIZE         : integer :=12;
    INDEX_SIZE        : integer :=5;   --Memory depth = 2^INDEX_SIZE                
    TAG_SIZE          : integer :=6;   --TAG_SIZE must have the same size than the DDR3 memory @ddress - INDEX
    DATA_SIZE         : integer :=8    --Data field must have the same size than the DDR3 memory data  
);    
end cache_memory_tb;



architecture testbench of cache_memory_tb is

    component cache_memory is
    generic(
        ADDR_SIZE         : integer :=11;
        INDEX_SIZE        : integer :=5; --Memory depth = 2^INDEX_SIZE                
        TAG_SIZE          : integer :=6; --TAG_SIZE must have the same size than the DDR3 memory @ddress - INDEX
        DATA_SIZE         : integer :=8  --Data field must have the same size than the DDR3 memory data  
            );    
    
    port (
        clk_i             : in  std_logic;
        reset_i           : in  std_logic;
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

    component memory_emul_tb is
    generic(
        ADDR_SIZE         : integer :=11;
        INDEX_SIZE        : integer :=5;   --Memory depth = 2^INDEX_SIZE                
        TAG_SIZE          : integer :=6;   --TAG_SIZE must have the same size than the DDR3 memory @ddress - INDEX
        DATA_SIZE         : integer :=8    --Data field must have the same size than the DDR3 memory data
    );
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;

        mem_o               : out mem_to_cache_t;
        mem_i               : in cache_to_mem_t);
    end component;

    signal clk_sti : std_logic;
    signal reset_sti : std_logic;
    
    signal from_agent_sti     : agent_to_cache_t(addr(ADDR_SIZE-1 downto 0),
                                                data(DATA_SIZE-1 downto 0));
    signal cache_to_agent_obs : cache_to_agent_t(data(DATA_SIZE-1 downto 0));
    signal from_mem_obs       : mem_to_cache_t(data(DATA_SIZE-1 downto 0));
    signal cache_to_mem_obs   : cache_to_mem_t(burst_range(ADDR_SIZE-1 downto 0),
                                            addr(ADDR_SIZE-1 downto 0),
                                            data(DATA_SIZE-1 downto 0));


    signal monitor_obs    : cache_monitor_t;                                  

    signal sim_end : boolean := false;
    
    signal synchro_verif  : std_logic;
    signal verification_going : std_logic;

    constant CLK_PERIOD : time := 2 ns; -- Attention la simulation de base fait
                                        -- des pas de 1ns alors ne pas mettre
                                        -- le clock en dessous de 2ns ou alors
                                        -- changer les parametres de simulation
                                        -- pour faire des pas plus petit que 500ps
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
        reset_i => reset_sti,
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

    memory : memory_emul_tb
    generic map(
        ADDR_SIZE  => ADDR_SIZE,
        INDEX_SIZE => INDEX_SIZE,
        TAG_SIZE   => TAG_SIZE,
        DATA_SIZE  => DATA_SIZE
    )
    port map(
        clk_i   => clk_sti,
        reset_i => reset_sti,

        mem_o   => from_mem_obs,
        mem_i   => cache_to_mem_obs
    );

    reset_process : process
    begin
        reset_sti <= '1';
        wait for 5*CLK_PERIOD;
        reset_sti <= '0';
        wait;
    end process;
    
    clk_process : process
    begin
        clk_sti <= '0';
        wait for CLK_PERIOD / 2;
        clk_sti <= '1';
        wait for CLK_PERIOD / 2;
        if sim_end = true then
            report "Fin de la simulation." severity NOTE;
            wait;
        end if;
    end process;
    
    sti_process : process
        procedure write_to_cache (data_in : in std_logic_vector(DATA_SIZE-1 downto 0);
                                  addr_in : in std_logic_vector(ADDR_SIZE-1 downto 0)) is
        begin
          from_agent_sti.data <= data_in;
          from_agent_sti.addr <= addr_in;
          from_agent_sti.rd <= '0';
          from_agent_sti.wr <= '1';
          wait until rising_edge(cache_to_agent_obs.busy);
          from_agent_sti.wr <= '0';
          wait until falling_edge(cache_to_agent_obs.busy);
          report "Ecriture de" & LF &
                "Valeur   : " & to_bstring(data_in) & LF &
                "Adresse : " & to_bstring(addr_in);
        end write_to_cache;

        procedure read_cache (addr_in : in std_logic_vector(ADDR_SIZE-1 downto 0)) is
        begin
          from_agent_sti.addr <= addr_in;
          from_agent_sti.rd <= '1';
          from_agent_sti.wr <= '0';
          wait until rising_edge(cache_to_agent_obs.busy);
          from_agent_sti.rd <= '0';
          wait until falling_edge(cache_to_agent_obs.busy);
          report "Lecture de" & LF &
                "Valeur  : " & to_bstring(cache_to_agent_obs.data) & LF &
                "Adresse : " & to_bstring(addr_in);
        end read_cache;

        procedure control_read (expected_in : in std_logic_vector(DATA_SIZE-1 downto 0);
                                addr_in : in std_logic_vector(ADDR_SIZE-1 downto 0)) is
        begin
          read_cache (addr_in);
          if (cache_to_agent_obs.data = expected_in) then
            report "Résultat attendu" & LF &
                "Valeur  : " & to_bstring(cache_to_agent_obs.data) & LF &
                "Attendu : " & to_bstring(expected_in);
          else
            report "Résultat inattendu" & LF &
                "Valeur  : " & to_bstring(cache_to_agent_obs.data) & LF &
                "Attendu : " & to_bstring(expected_in);
          end if;
        end control_read;
          
        variable data : std_logic_vector(DATA_SIZE-1 downto 0);
    begin
        from_agent_sti.data <= (others => '0');
        from_agent_sti.addr <= (others => '0');
        from_agent_sti.rd <= '0';
        from_agent_sti.wr <= '0';
        
        wait until falling_edge(reset_sti);
        wait for 10 ns;
        wait until falling_edge(clk_sti);
        
        -- Ecriture
        report "Ecriture 1 !";

        data := (others => '1');
        write_to_cache(data, "000000000101");
        data := "10100101";
        write_to_cache(data, "000000000101"); -- Cette écriture devrait être
                                              -- bien plus rapide car la ligne
                                              -- est déjà en cache. On peut le
                                              -- voir dans le test bench
        wait for 10 ns;
        
        -- Ecriture
        report "Ecriture 2 !";

        data := "10101010";
        write_to_cache(data, "000000000000");
        write_to_cache(data, "000000000001"); -- Cette écriture est plus rapide
                                              -- car dans la même ligne de cache

        wait for 10 ns;
        
        -- Lecture bonne adresse 
        wait for 10 ns;
        report "Lecture cache bonne adresse";
        wait until falling_edge(clk_sti);
        -- Ces deux lectures sont ultra rapides car déjà dans la ligne de cache
        control_read(data, "000000000000");
        control_read(data, "000000000001");

        -- Lecture lente car pas dans la cache
        control_read((others => '0'), "000000000010");
        control_read((others => '0'), "000000000011");
        
        -- Lecture mauvais adresse
        report "Lecture cache mauvaise adresse";
        wait for 10 ns;
        wait until falling_edge(clk_sti);
        from_agent_sti.addr <= "000000100000";
        from_agent_sti.rd <= '1';
        wait until rising_edge(cache_to_agent_obs.busy);
        from_agent_sti.rd <= '0';
        wait until falling_edge(cache_to_agent_obs.busy);
        if (cache_to_agent_obs.data = data) then
            report "Lecture reussite" & LF &
                "Valeur  : " & to_bstring(cache_to_agent_obs.data) & LF &
                "Attendu : " & to_bstring(data);
        else
            report "Lecture echec" & LF &
                "Valeur  : " & to_bstring(cache_to_agent_obs.data) & LF &
                "Attendu : " & to_bstring(data);
        end if;
        
        sim_end <= true;
        wait;
    
    end process;
    
    -- Processus de commande et synchronisation
    --chef_d_orchestre: process
    --begin
    --  synchro_verif <= '1';
    --  wait until rising_edge(verification_going);
    --  loop
    --    wait for 10 ns;
    --    synchro_verif <= '0';
    --    wait for 10 ns;
    --    synchro_verif <= '1';
    --    if verification_going = '0' then
    --      wait for 20 ns;
    --      report "Fin de la verification !";
    --      wait;
    --    end if;
    --  end loop;
    --end process;

    --stimuli: process
    --begin

    --end process;

    --verification: process
    --  wait until rising_edge(verification_going); -- Pourrait être fait autrement

    --  loop
    --    wait until rising_edge(synchro_verif); -- On est synchronisé avec tout
    --                                           -- le monde

    --  end loop;

    --  wait;
    --end process;

end testbench;


