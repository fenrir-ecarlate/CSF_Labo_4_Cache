----------------------------------------------------------------------------------
-- Company: HEIG-VD REDS
-- Engineer: JoÃ£o Domingues, Rick Wertenbroek
-- 
-- Create Date: 18.02.2016 09:56:53
-- Design Name: 
-- Module Name: memory_emul_tb - Behavioral
-- Project Name: Memoire Cache
-- Target Devices: (This is a testbench !)
-- Tool Versions: 
-- Description: Memory controller emulator
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

entity memory_emul_tb is
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
end memory_emul_tb;

architecture testbench of memory_emul_tb is
  -- Constants
  constant READ_LATENCY_CLKS : integer := 10;
  
  -- Signals
  -- On ne va simuler qu'une partie de la mémoire (adresses de 0xFF à 0x0)
  type memory_type is array (0 to 2**8-1) of std_logic_vector(DATA_SIZE-1 downto 0);
  signal memory : memory_type; -- La mémoire
begin
  
  process
    begin
      if (reset_i = '1') then
        memory <= (others => (others => '0'));
      end if;      

      wait until rising_edge(clk_i);
      mem_o.busy <= '0';
      mem_o.dready <= '0';
        if (mem_i.wr = '1') then
          if (mem_i.burst = '0') then -- Ecriture simple
            mem_o.busy <= '1';
            for i in 0 to 5*READ_LATENCY_CLKS loop -- Simulation de latence
              wait until rising_edge(clk_i);
            end loop;
            memory(to_integer(unsigned(mem_i.addr(7 downto 0)))) <= mem_i.data;
            mem_o.busy <= '0';
          else -- Ecriture en burst
            for i in 0 to to_integer(unsigned(mem_i.burst_range))-1 loop
              mem_o.busy <= '1';
              for i in 0 to READ_LATENCY_CLKS loop -- Simulation de latence
                wait until rising_edge(clk_i);
              end loop;
              memory(to_integer(unsigned(mem_i.addr(7 downto 0)))+i) <= mem_i.data;
              --report "_____MEM: Ecriture de" & LF &
              --  "Valeur   : " & to_bstring(mem_i.data) & LF &
              -- "Adresse : " & to_bstring(unsigned(mem_i.addr(7 downto 0))+i);
              mem_o.busy <= '0';
              wait until rising_edge(clk_i);
            end loop;
          end if;
        elsif (mem_i.rd = '1') then
          if (mem_i.burst = '0') then -- Lecture simple
            mem_o.busy <= '1';
            mem_o.dready <= '0';
            for i in 0 to 5*READ_LATENCY_CLKS loop -- Simulation de latence
              wait until rising_edge(clk_i);
            end loop;
            mem_o.busy <= '0';
            mem_o.data <= memory(to_integer(unsigned(mem_i.addr(7 downto 0))));
            mem_o.dready <= '1';
          else -- Lecture en burst
            for i in 0 to to_integer(unsigned(mem_i.burst_range))-1 loop
              mem_o.dready <= '0';
              mem_o.busy <= '1';
              for i in 0 to READ_LATENCY_CLKS loop -- Simulation de latence
                wait until rising_edge(clk_i);
              end loop;
              --report "_____MEM: Lecture de" & LF &
              --  "Valeur   : " & to_bstring(memory(to_integer(unsigned(mem_i.addr(7 downto 0)))+i)) & LF &
              --  "Adresse : " & to_bstring(unsigned(mem_i.addr(7 downto 0))+i);
              mem_o.busy <= '0';
              mem_o.data <= memory(to_integer(unsigned(mem_i.addr(7 downto 0)))+i);
              mem_o.dready <= '1';
              wait until rising_edge(clk_i);
            end loop;
          end if;
        end if;
  end process;
end testbench;


