# This compiles UVM only; scripts/run_simulation.ps1 also builds the C-DPI DLL.
set ROOT [file normalize [file join [file dirname [info script]] ../../..]]
set WORK [file join $ROOT build questa_uvm_gui work]
file mkdir [file dirname $WORK]
if {![file exists $WORK]} { vlib $WORK }
vmap work $WORK
set fd [open [file join $ROOT tb filelists uvm.f] r]
set sources {}
foreach path [split [read $fd] "\n"] {
    set path [string trim $path]
    if {$path ne ""} { lappend sources [file join $ROOT $path] }
}
close $fd
vlog -sv +incdir+[file join $ROOT tb uvm] -work work {*}$sources
puts {For a complete run including DPI, use scripts/run_simulation.ps1 -Mode UvmE2e.}
