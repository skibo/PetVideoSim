#
# simulate.tcl
#
set project_name [lindex $argv 0]
set topname [lindex $argv 1]
set origin_proj_dir [file normalize ./$project_name]

open_project $origin_proj_dir/$project_name.xpr

set_property top $topname [get_filesets sim_1]
update_compile_order -fileset sim_1

launch_simulation
restart
open_vcd
log_vcd [get_objects /$topname/*]
run 36ms
close_vcd
close_sim
close_project

