# Standalone AES synthesis, independent of the RISC-V system.
# Supply a licensed Liberty library: setenv AES_LIBERTY /path/to/cells.lib
set ROOT [file normalize [file join [file dirname [info script]] ../../..]]
set TOP AES128_updated_new
if {![info exists env(AES_LIBERTY)] || ![file exists $env(AES_LIBERTY)]} {
    error {Set AES_LIBERTY to your licensed Liberty file before running Genus.}
}
set OUT [file join $ROOT build genus_aes]
file mkdir [file join $OUT reports] [file join $OUT outputs]
set_db init_lib_search_path [file dirname $env(AES_LIBERTY)]
read_libs $env(AES_LIBERTY)
read_hdl -sv [file join $ROOT asic cadence_genus rtl aes128_standalone.sv]
elaborate $TOP
read_sdc [file join $ROOT asic cadence_genus constraints aes128.sdc]
check_design -unresolved > [file join $OUT reports check_design.rpt]
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium
syn_generic
syn_map
syn_opt
report_timing > [file join $OUT reports timing.rpt]
report_power > [file join $OUT reports power.rpt]
report_area > [file join $OUT reports area.rpt]
report_qor > [file join $OUT reports qor.rpt]
write_hdl > [file join $OUT outputs aes128_netlist.sv]
write_sdc > [file join $OUT outputs aes128.sdc]
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge -setuphold split > [file join $OUT outputs aes128.sdf]
puts "GENUS_SYNTHESIS_COMPLETE: $TOP; output=$OUT"
