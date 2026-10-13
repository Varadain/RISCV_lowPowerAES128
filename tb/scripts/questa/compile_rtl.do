# From the repository root in Questa: do tb/scripts/questa/compile_rtl.do
set ROOT [file normalize [file join [file dirname [info script]] ../../..]]
set WORK [file join $ROOT build questa_gui work]
file mkdir [file dirname $WORK]
if {![file exists $WORK]} { vlib $WORK }
vmap work $WORK
set fd [open [file join $ROOT tb filelists soc.f] r]
set sources {}
foreach path [split [read $fd] "\n"] {
    set path [string trim $path]
    if {$path ne ""} { lappend sources [file join $ROOT $path] }
}
close $fd
vlog -sv -work work {*}$sources
puts {Compile complete. Next: vsim -voptargs=+acc work.riscv_core_tb +AES_KAT_ONLY}
