#!/usr/bin/tclsh

# Main proc at the end #

#------------------------------------------------------------------------------
proc vhdl_compil { } {
  global Path_VHDL
  global Path_VHDL_TB

  puts "\nVHDL compilation :"
  
  vlib work
  
  vcom -2008 -work work $Path_VHDL/cmf_pkg.vhd
  vcom -2008 -work work $Path_VHDL/cache_memory.vhd
  
  vcom -2008 $Path_VHDL_TB/memory_emul_tb.vhd
  vcom -2008 $Path_VHDL_TB/cache_memory_tb.vhd
}

#------------------------------------------------------------------------------
proc sim_start { } {
  
  vsim -t 1ns -novopt work.cache_memory_tb
  add wave -r *
  wave refresh
  run -all
}

#------------------------------------------------------------------------------
proc do_all { } {
  vhdl_compil
  sim_start
}

## MAIN #######################################################################
  
# Compile folder ----------------------------------------------------
if {[file exists work] == 0} {
  vlib work
}

puts -nonewline "  Path_VHDL => "
set Path_VHDL     "../src_vhdl"
puts -nonewline "  Path_VHDL_TB => "
set Path_VHDL_TB     "../src_tb"

global Path_VHDL
global Path_VHDL_TB

# start of sequence -------------------------------------------------
  
if {$argc==1} {
  if {[string compare $1 "all"] == 0} {
    do_all
  } elseif {[string compare $1 "comp_vhdl"] == 0} {
    vhdl_compil
  } elseif {[string compare $1 "sim"] == 0} {
    sim_start
  }
  
} else {
    do_all
}

