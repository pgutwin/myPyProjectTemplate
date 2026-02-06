# innovus_init.tcl
# Skeleton Innovus init script that consumes:
#   <run_dir>/current/netlist.v
#   <run_dir>/current/constraints.sdc
# And produces:
#   outputs/design.enc   (checkpoint)
#


# ATTENTION:ATTENTION:ATTENTION
# Assumptions:
# - Wrapper runs Innovus with cwd = <run_dir>/stages/<order>_init/
# - Tech/floorplan init is done elsewhere (you will add it)
# - Uses common Innovus commands; you may adjust for your internal methodology

proc pfx_mkdir {d} {
  if {![file isdirectory $d]} {
    file mkdir $d
  }
}

# ----------------------------
# Stage-local output directory
# ----------------------------
set out_dir "outputs"
pfx_mkdir $out_dir

# ----------------------------
# Resolve handoff paths
# ----------------------------
# Stage dir is: <run_dir>/stages/20_init/
# current/ is:  <run_dir>/current/
#
# So relative path is:
set netlist_path "../../current/netlist.v"
set sdc_path     "../../current/constraints.sdc"

if {![file exists $netlist_path]} {
  puts "ERROR: Missing netlist handoff: $netlist_path"
  exit 1
}
if {![file exists $sdc_path]} {
  puts "ERROR: Missing SDC handoff: $sdc_path"
  exit 1
}

puts "PFX: Reading netlist: $netlist_path"
puts "PFX: Reading SDC:     $sdc_path"

# ----------------------------
# Read design
# ----------------------------
# Command choices vary by methodology:
# - read_verilog for RTL/netlist
# - init_design with -verilog/-top etc.
#
# Minimal skeleton:
read_verilog $netlist_path

# You may need to set top cell explicitly; depends on your flow:
# set TOP "top_module"
# set_db top_cell $TOP

# ----------------------------
# Tech / libs / LEFs / MMMC
# ----------------------------
# TODO: you will add:
# - read_lef (tech + cells)
# - read_liberty / MMMC setup
# - init_design or equivalent
# - floorplan / power grid / etc.

# ----------------------------
# Constraints
# ----------------------------
# MMMC flows might use create_constraint_mode + read_sdc.
# Minimal:
read_sdc $sdc_path

# ----------------------------
# Basic init steps placeholder
# ----------------------------
# TODO: you will add the minimum to get a legal database:
# - floorplan
# - place IOs
# - create power nets
# - etc.

# ----------------------------
# Save checkpoint
# ----------------------------
set enc_path [file join $out_dir "design.enc"]
puts "PFX: Saving checkpoint: $enc_path"

# In Innovus, common checkpoint save is:
saveDesign $enc_path

puts "PFX: Innovus init stage complete"
exit
