# =============================================================================
# Cadence Genus synthesis script
#
# Design : Iterative and hardware-reusable AES-128 encryption core
# Top    : AES128_updated_new
# Process: TSMC 55 nm low-power RVT, typical corner, 1.0 V, 25 C
#
# The technology library is not included in Git because it is licensed.
# By default, the script expects it inside ../lib/. The search path can be
# changed to the location provided by the VLSI laboratory.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Project configuration
# -----------------------------------------------------------------------------
# Keeping names and paths in variables makes the flow easier to reuse and
# prevents the same path from being repeated throughout the script.
set TOP        AES128_updated_new
set RTL_FILE   ../AES128_updated_new/rtl/aes128_all_rtl.sv
set SDC_FILE   ../AES128_updated_new/scripts/timing.sdc
set LIB_DIR    ../lib
set LIB_FILE   sc9_55lpx_base_rvt_tt_nominal_max_1p00v_25c.lib

# Create report and netlist directories if they do not already exist.
file mkdir reports
file mkdir outputs

# -----------------------------------------------------------------------------
# 2. Technology-library and RTL search paths
# -----------------------------------------------------------------------------
# The liberty file describes the delay, area, leakage, internal power, and
# switching-power characteristics of each standard cell available to Genus.
set_db init_lib_search_path $LIB_DIR

# The RTL search path is the directory containing the combined AES source.
set_db init_hdl_search_path [file dirname $RTL_FILE]

# Load the TSMC 55 nm low-power standard-cell timing/power library.
read_libs $LIB_FILE

# -----------------------------------------------------------------------------
# 3. Read and elaborate the synthesizable AES RTL
# -----------------------------------------------------------------------------
# The combined SystemVerilog file contains the top-level iterative AES FSM,
# sequential S-box, reusable MixColumns block, and reusable key-expansion block.
# The -sv option enables SystemVerilog constructs used by the design.
read_hdl -sv $RTL_FILE

# Elaborate resolves parameters, module instances, widths, and hierarchy, then
# constructs the complete design rooted at AES128_updated_new.
elaborate $TOP

# -----------------------------------------------------------------------------
# 4. Apply timing constraints
# -----------------------------------------------------------------------------
# The SDC defines a 10 ns clock period, corresponding to a 100 MHz target, and
# marks reset as a non-timed control path. These constraints guide optimization
# and provide the reference for setup/hold timing reports.
read_sdc $SDC_FILE

# Report unresolved references or structural problems before synthesis begins.
check_design -unresolved > reports/report_check_design.rpt

# -----------------------------------------------------------------------------
# 5. Select synthesis effort
# -----------------------------------------------------------------------------
# Medium effort gives a practical balance between synthesis runtime and quality
# of results for area, timing, and power comparison.
set_db syn_generic_effort medium
set_db syn_map_effort     medium
set_db syn_opt_effort     medium

# -----------------------------------------------------------------------------
# 6. Run the three main Genus synthesis stages
# -----------------------------------------------------------------------------
# syn_generic converts behavioral RTL into technology-independent logic.
syn_generic

# syn_map replaces generic logic with cells from the loaded 55 nm library.
syn_map

# syn_opt improves the mapped design to satisfy timing, area, power, fanout,
# and other design constraints.
syn_opt

# -----------------------------------------------------------------------------
# 7. Generate synthesis reports
# -----------------------------------------------------------------------------
# Timing report: critical paths, arrival/required times, and timing slack.
report_timing > reports/report_timing.rpt

# Power report: leakage, internal, switching, clock, register, and logic power.
report_power > reports/report_power.rpt

# Area report: mapped cell count and standard-cell area by hierarchy.
report_area > reports/report_area.rpt

# QoR report: compact summary of timing, area, design rules, and synthesis state.
report_qor > reports/report_qor.rpt

# -----------------------------------------------------------------------------
# 8. Export implementation files
# -----------------------------------------------------------------------------
# Technology-mapped gate-level netlist for downstream simulation or P&R.
write_hdl > outputs/AES128_netlist.sv

# Genus-normalized timing constraints associated with the synthesized netlist.
write_sdc > outputs/AES128_sdc.sdc

# Standard Delay Format file containing cell and path delays for gate-level
# timing simulation. Delays are written in nanoseconds.
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge \
          -setuphold split > outputs/delays.sdf

# A clear completion marker is useful in batch logs and automated scripts.
puts "GENUS_SYNTHESIS_COMPLETE: $TOP"
puts "Reports are available in ./reports"
puts "Netlist, SDC, and SDF are available in ./outputs"
