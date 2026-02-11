# *********************************************************
# *
# * A very simple script that shows the basic Genus flow
# *
# *********************************************************
source pfx_vars.tcl

set design $pfx_design_design_top
# design_nickname should be set in pfx_vars.tcl

# Canonical absolute path to stage dir is $pfx_current_stage_dir
set output_dir ${pfx_current_stage_dir}/outputs

# $lib_dirs defined in pfx_vars.tcl
init_lib_search_path ${pfx_tech_lib_dirs}

# $pfx_hdl_search_dirs set in pfx_vars.tcl
init_hdl_search_path ${pfx_design_hdl_search_dirs}

# set init_hdl_search_path ../rtl/${design_nickname}

# $pfx_lib_files set in pfx_vars.tcl
set_db library ${pfx_tech_collateral_lib_files}

# set_db library {\
# 		    asap7sc6t_SEQ_LVT_TT_nldm_211010.lib \
# 		    asap7sc6t_AO_LVT_TT_nldm_211010.lib \
# 		    asap7sc6t_OA_LVT_TT_nldm_211010.lib \
# 		    asap7sc6t_INVBUF_LVT_TT_nldm_211010.lib \
# 		    asap7sc6t_SIMPLE_LVT_TT_nldm_211010.lib
# }

read_hdl -sv ${pfx_design_hdl_filelist}
# read_hdl -sv { \
# 		   cone_100_104_ch.v \
# 		   cone_1008_61_ch.v \
# 		   cone_1443_203_ch.v \
# 		   cone_173_1_ch.v \
# 		   cone_1862_128_ch.v \
# 		   cone_229_128_ch.v \
# 		   cone_431_45_ch.v \
# 		   conehead.v \
# 		   functions_ch.v
# }

elaborate ${design}

## Set timing constraints
read_sdc ${pfx_design_constraints_sdc_file}

## Synthesize logic
syn_generic

syn_map

## Report results
# report_timing > <filename>
# report_area > <filename>

## Write out netlist
## This needs to match what's in `pipeline.toml` exactly:
write_hdl > ${output_dir}/netlist.v


exit
