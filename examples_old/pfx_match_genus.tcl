# genus.tcl
# Skeleton Genus batch script that produces:
#   outputs/netlist.v
#   outputs/constraints.sdc
#
# Assumptions:
# - Wrapper runs Genus with cwd = <run_dir>/stages/<order>_synth/
# - This script is located at: scripts/synth.tcl (or scripts/synth.tcl by convention)
# - Tech/lib setup is done elsewhere (you will add it)

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
# User-defined: set TOP and read design
# ----------------------------
# TODO: You handle design import (RTL/filelist, include dirs, defines, etc.)
# Example placeholders:
# set TOP "top_module"
# read_hdl -sv -f ../../resolved_inputs/design/rtl/filelist.f
# elaborate $TOP
# check_design -unresolved

# ----------------------------
# User-defined: constraints setup (input SDC)
# ----------------------------
# TODO: you handle initial constraints read, clocks, IO, etc.
# For a handoff-focused skeleton, assume constraints are established in Genus state.

# ----------------------------
# Synthesis / mapping (placeholder)
# ----------------------------
# TODO: you handle synth options and mapping.
# Example:
# synthesize -to_mapped

# ----------------------------
# Write mapped netlist
# ----------------------------
set netlist_path [file join $out_dir "netlist.v"]
puts "PFX: Writing mapped netlist to $netlist_path"

# Genus has multiple netlist writers depending on flow.
# One common form is write_hdl.
# Use the option set you prefer; this is just a skeleton:
write_hdl -mapped > $netlist_path

# ----------------------------
# Write SDC for handoff
# ----------------------------
set sdc_path [file join $out_dir "constraints.sdc"]
puts "PFX: Writing SDC handoff to $sdc_path"

# Genus can emit an SDC representing the implemented constraint state.
# Depending on your flow, you may prefer write_sdc or write_sdc -version ...
write_sdc $sdc_path

# ----------------------------
# Optional: quick sanity outputs
# ----------------------------
# report_timing -max_paths 10 > [file join $out_dir "timing_summary.rpt"]

puts "PFX: Genus synth stage complete"
exit
