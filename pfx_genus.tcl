set out_dir "outputs"
file mkdir $out_dir
write_hdl -mapped > ${out_dir}/netlist.v
write_sdc          ${out_dir}/constraints.sdc
