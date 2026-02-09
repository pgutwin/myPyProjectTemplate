# *********************************************************
# *
# * A very simple script that shows the basic Genus flow
# *
# *********************************************************
source pfx_vars.tcl

set design conehead
set design_nickname conehead
set output_dir ../mapped_verilog/genus/${design_nickname}

set_db init_lib_search_path ../enablement

set_db init_hdl_search_path ../rtl/${design_nickname}
set init_hdl_search_path ../rtl/${design_nickname}

set_db library {\
		    asap7sc6t_SEQ_LVT_TT_nldm_211010.lib \
		    asap7sc6t_AO_LVT_TT_nldm_211010.lib \
		    asap7sc6t_OA_LVT_TT_nldm_211010.lib \
		    asap7sc6t_INVBUF_LVT_TT_nldm_211010.lib \
		    asap7sc6t_SIMPLE_LVT_TT_nldm_211010.lib
}

read_hdl -sv { \
		   cone_100_104_ch.v \
		   cone_1008_61_ch.v \
		   cone_1443_203_ch.v \
		   cone_173_1_ch.v \
		   cone_1862_128_ch.v \
		   cone_229_128_ch.v \
		   cone_431_45_ch.v \
		   conehead.v \
		   functions_ch.v
}

elaborate ${design}

## Set timing constraints
read_sdc $init_hdl_search_path/${design}.sdc

## Synthesize logic
syn_generic

syn_map

## Report results
# report_timing > <filename>
# report_area > <filename>

## Write out netlist
write_hdl > ${output_dir}/${design}_mapped.v
##write_script > <file_name>

exit
