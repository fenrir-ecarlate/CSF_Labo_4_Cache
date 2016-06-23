-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : cache_memory.vhd
--
-- Description  : Cache memory.
-- 
-- Auteur       : Jo�o Domingues, Rick Wertenbroek sur chablon de Yann Thoma
-- Date         : 12.05.2016
-- Version      : 0.1 ports
-- 
-- Utilise      :  
--              :  
-- 
--| Modifications |------------------------------------------------------------
-- Version        Date      Auteur      Description
-- 1.0            20.05.16  RWK         D�but du laboratoire
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
    -- constant
    constant NUMBER_OF_WORDS_IN_CACHE_LINE : integer := 2**(ADDR_SIZE-(TAG_SIZE+INDEX_SIZE)); -- Nombre de mots par ligne de cache
    constant OFFSET_SIZE : integer := (ADDR_SIZE-(TAG_SIZE+INDEX_SIZE));
    constant TAG_HIGH : integer := ADDR_SIZE - 1;
    constant TAG_LOW : integer := TAG_HIGH - (TAG_SIZE - 1);
    constant INDEX_HIGH : integer := TAG_LOW - 1;
    constant INDEX_LOW : integer := INDEX_HIGH - (INDEX_SIZE - 1);
    constant BLOCK_HIGH : integer := INDEX_LOW - 1;
    constant BLOCK_LOW : integer := BLOCK_HIGH - (OFFSET_SIZE - 1);
    
    type cache_type is array (0 to (2**INDEX_SIZE)-1) of std_logic_vector((NUMBER_OF_WORDS_IN_CACHE_LINE * DATA_SIZE)-1 downto 0);
    type bit_array_type is array (0 to (2**INDEX_SIZE)-1) of std_logic;
    type tag_type   is array (0 to (2**INDEX_SIZE)-1) of std_logic_vector(TAG_SIZE-1 downto 0);

    type STATE_TYPE is (
        RESET, 
        INIT, 
        WAIT_FOR_DEMAND, 
        READ_CACHE, 
        READ_BURST_1,
        READ_BURST_2,
        GIVE_DATA, 
        CHECK_DIRTY, 
        WRITE_BURST_1,
        HIT_AND_VALID, 
        READ_BEFORE_WRITE_1,
        READ_BEFORE_WRITE_2,
        WRITE_CACHE_WORD);
    
    signal cache : cache_type;            -- La cache (lignes de mots)
    signal dirty_bits : bit_array_type;   -- Les bits dirty de la cache
    signal valid_bits : bit_array_type;   -- Les bits valid
    signal tags : tag_type;               -- La liste des tags

    -- FSM
    signal state_s, next_state_s : STATE_TYPE;
    signal fsm_dready_out_s, fsm_busy_out_s, fsm_read_s, fsm_write_s : std_logic;
    
    signal fsm_data_out_s,fsm_word_in_s : std_logic_vector(DATA_SIZE - 1 downto 0);
    signal fsm_addr_in_s : std_logic_vector(ADDR_SIZE - 1 downto 0);
    
    -- Signaux d'entr�e de la cache
    signal cache_index_s : std_logic_vector(INDEX_SIZE-1 downto 0);
    signal cache_tag_s : std_logic_vector(TAG_SIZE-1 downto 0);
    signal cache_b_off_s : std_logic_vector(OFFSET_SIZE-1 downto 0);
    signal cache_read_s : std_logic;
    signal cache_write_s : std_logic;
    
    -- Signaux de sortie de la cache
    signal cache_data_s : std_logic_vector(DATA_SIZE-1 downto 0);
    signal cache_hit_s : std_logic;
    signal burst_counter_s : unsigned(OFFSET_SIZE downto 0);
   
begin
    assert (ADDR_SIZE-(TAG_SIZE+OFFSET_SIZE)) > 0 report "Address Malformation" severity failure;
    -- These asserts are used by simulation in order to check the generic 
    -- parameters with the instanciation of record ports
    assert agent_i.addr'length = ADDR_SIZE report "Address size do not match" severity failure;
    assert agent_i.data'length = DATA_SIZE report "Data size do not match" severity failure;
    assert agent_o.data'length = DATA_SIZE report "Data size do not match" severity failure;
    assert mem_i.data'length = DATA_SIZE report "Data size do not match" severity failure;
    assert mem_o.addr'length = ADDR_SIZE report "Address size do not match" severity failure;
    assert mem_o.burst_range'length = ADDR_SIZE report "Burst range size do not match" severity failure;
    assert mem_o.data'length = DATA_SIZE report "Data size do not match" severity failure;

    agent_o.busy <= fsm_busy_out_s;
    agent_o.dready <= fsm_dready_out_s;
    agent_o.data <= fsm_data_out_s;
    
    fsm_write_s <= agent_i.wr;
    fsm_read_s <= agent_i.rd;

    -- D�composition de l'adresse :
    cache_tag_s <= fsm_addr_in_s(TAG_HIGH downto TAG_LOW);
    cache_index_s <= fsm_addr_in_s(INDEX_HIGH downto INDEX_LOW);
    cache_b_off_s <= fsm_addr_in_s(BLOCK_HIGH downto BLOCK_LOW);
    
    cache_fsm_process : process (clk_i, reset_i) is
    variable index_v : integer;
    variable block_off_v : integer;
    begin
      if (reset_i = '1') then
        state_s <= RESET;
        next_state_s <= RESET;
      elsif rising_edge(clk_i) then
        index_v := to_integer(unsigned(cache_index_s));
        block_off_v := to_integer(unsigned(cache_b_off_s));
        case state_s is
          
          when RESET => -- Etat de d�part
            next_state_s <= INIT;
            fsm_addr_in_s <= (others => '0');
            fsm_word_in_s <= (others => '0');
            burst_counter_s <= (others => '0');
            
          when INIT => -- Initialisations
            valid_bits <= (others => '0'); -- Ceci suffit la cache n'a pas
                                           -- besoin d'�tre mise � z�ro
            dirty_bits <= (others => '0'); -- Tout est beau propre !
            fsm_dready_out_s <= '0';
            fsm_busy_out_s <= '0';
            fsm_data_out_s <= (others => '0');
            next_state_s <= WAIT_FOR_DEMAND;
            
          when WAIT_FOR_DEMAND =>
            mem_o.rd <= '0';
            mem_o.wr <= '0';
            burst_counter_s <= (others => '0');
            if (fsm_read_s = '1') then -- read prioritaire au write (mais avoir les deux n'aurait pas de sens)
              next_state_s <= READ_CACHE;
              fsm_dready_out_s <= '0';
              fsm_busy_out_s <= '1';
              fsm_addr_in_s <= agent_i.addr;
            elsif (fsm_write_s = '1') then
              fsm_word_in_s <= agent_i.data;
              fsm_addr_in_s <= agent_i.addr;
              next_state_s <= CHECK_DIRTY;
              fsm_busy_out_s <= '1';
            else
              next_state_s <= WAIT_FOR_DEMAND; -- Etat d'attente
              fsm_busy_out_s <= '0';
            end if;
            
          when READ_CACHE =>
            -- v�rifie s'il y a hit
            if (tags(index_v) = cache_tag_s and valid_bits(index_v) = '1') then
              next_state_s <= GIVE_DATA;
            else
              burst_counter_s <= (others => '0');
              mem_o.wr <= '0';
              mem_o.rd <= '1';
              mem_o.burst <= '1';
              mem_o.addr <= fsm_addr_in_s(ADDR_SIZE-1 downto OFFSET_SIZE) & std_logic_vector(to_unsigned(0, OFFSET_SIZE)); -- Adresse de la ligne de cache voulue
              mem_o.burst_range <= std_logic_vector(to_unsigned(NUMBER_OF_WORDS_IN_CACHE_LINE, mem_o.burst_range'length));
              next_state_s <= READ_BURST_1;
            end if;
          
          when READ_BURST_1 =>
            if (mem_i.busy = '1') then -- Attente sur la m�moire
                next_state_s <= READ_BURST_1;
            else
                next_state_s <= READ_BURST_2;
            end if;
              
          when READ_BURST_2 =>
            if (burst_counter_s = NUMBER_OF_WORDS_IN_CACHE_LINE) then
                mem_o.rd <= '0'; -- Fini de lire
                valid_bits(index_v) <= '1'; -- Les donn�es sont maintenant valides
                tags(index_v) <= cache_tag_s; -- m�j du tag
                next_state_s <= GIVE_DATA;
            else
                if (mem_i.dready = '1') then -- Attente sur la m�moire
                    -- Mise � jour de la cache
                    cache(index_v)((to_integer(burst_counter_s)+1) * DATA_SIZE - 1 downto to_integer(burst_counter_s) * DATA_SIZE) <= mem_i.data;
                    burst_counter_s <= burst_counter_s + 1;
                end if;
                next_state_s <= READ_BURST_2;
            end if;
          
          when GIVE_DATA =>
            fsm_data_out_s <= cache(index_v)((block_off_v+1) * DATA_SIZE - 1 downto block_off_v * DATA_SIZE);
            fsm_dready_out_s <= '1';
            fsm_busy_out_s <= '0';
            next_state_s <= WAIT_FOR_DEMAND;
            
          when CHECK_DIRTY => -- Si dirty on doit stocker en m�moire
            if (tags(index_v) /= cache_tag_s and dirty_bits(index_v) = '1' and valid_bits(index_v) = '1') then
              if (mem_i.busy = '1') then -- Attente de la m�moire
                next_state_s <= CHECK_DIRTY;
              else  
                mem_o.wr <= '1';
                mem_o.rd <= '0';
                mem_o.burst <= '1';
                mem_o.addr <= tags(index_v) & cache_index_s & std_logic_vector(to_unsigned(0, OFFSET_SIZE)); -- Addresse de l'ancienne ligne de cache
                mem_o.data <= cache(index_v)((to_integer(burst_counter_s)+1) * DATA_SIZE - 1 downto to_integer(burst_counter_s) * DATA_SIZE);
                mem_o.burst_range <= std_logic_vector(to_unsigned(NUMBER_OF_WORDS_IN_CACHE_LINE, mem_o.burst_range'length));
                burst_counter_s <= (others => '0');
                next_state_s <= WRITE_BURST_1;
              end if;
            else
              next_state_s <= HIT_AND_VALID;
            end if;
          
          when WRITE_BURST_1 =>
            if (mem_i.busy = '1') then
                next_state_s <= WRITE_BURST_1;
            else
                if (burst_counter_s = NUMBER_OF_WORDS_IN_CACHE_LINE) then
                    mem_o.wr <= '0';
                    next_state_s <= HIT_AND_VALID;
                else
                    mem_o.data <= cache(index_v)((to_integer(burst_counter_s)+1) * DATA_SIZE - 1 downto to_integer(burst_counter_s) * DATA_SIZE);
                    burst_counter_s <= burst_counter_s + 1;
                    next_state_s <= WRITE_BURST_1;
                end if;
            end if;
          
          when HIT_AND_VALID =>
            if (tags(index_v) = cache_tag_s and valid_bits(index_v) = '1') then
              next_state_s <= WRITE_CACHE_WORD;
            else
              burst_counter_s <= (others => '0');
              mem_o.wr <= '0';
              mem_o.rd <= '1';
              mem_o.burst <= '1';
              mem_o.addr <= fsm_addr_in_s(ADDR_SIZE-1 downto OFFSET_SIZE) & std_logic_vector(to_unsigned(0, OFFSET_SIZE)); -- Adresse de la ligne de cache voulue
              mem_o.burst_range <= std_logic_vector(to_unsigned(NUMBER_OF_WORDS_IN_CACHE_LINE, mem_o.burst_range'length));
              next_state_s <= READ_BEFORE_WRITE_1;
            end if;
            
          when READ_BEFORE_WRITE_1 =>
            if (mem_i.busy = '1') then -- Attente sur la m�moire
                next_state_s <= READ_BEFORE_WRITE_1;
            else
                next_state_s <= READ_BEFORE_WRITE_2;
            end if;
            
          when READ_BEFORE_WRITE_2 => 
            if (burst_counter_s = NUMBER_OF_WORDS_IN_CACHE_LINE) then
                mem_o.rd <= '0'; -- Fini de lire
                valid_bits(index_v) <= '1'; -- Mise � jour du valid
                tags(index_v) <= cache_tag_s; -- Mise � jour du tag
                next_state_s <= WRITE_CACHE_WORD;
            else
                if (mem_i.dready = '1') then -- Attente sur la m�moire
                    -- Mise � jour de la cache
                    cache(index_v)((to_integer(burst_counter_s)+1) * DATA_SIZE - 1 downto to_integer(burst_counter_s) * DATA_SIZE) <= mem_i.data;
                    burst_counter_s <= burst_counter_s + 1;
                end if;
                next_state_s <= READ_BEFORE_WRITE_2;
            end if;
            -- R�cuperer la ligne de cache en m�moire avant d'�crire un mot dessus
            
          when WRITE_CACHE_WORD =>
            cache(index_v)((block_off_v+1) * DATA_SIZE - 1 downto block_off_v * DATA_SIZE) <= fsm_word_in_s;
            dirty_bits(index_v) <= '1'; -- Ecriture en cache donc dirty
            fsm_busy_out_s <= '0';
            next_state_s <= WAIT_FOR_DEMAND;
            
        end case;
            
      end if;
      state_s <= next_state_s;
    end process;

end struct;

