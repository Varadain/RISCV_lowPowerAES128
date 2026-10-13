# Match the archived standalone AES clock assumption: 10 ns (100 MHz).
set_units -time 1000ps
create_clock -name clk -period 10.0 -waveform {0.0 5.0} [get_ports clk]
set_clock_transition 0.1 [get_clocks clk]
set_clock_uncertainty -setup 0.01 [get_clocks clk]
set_clock_uncertainty -hold 0.01 [get_clocks clk]
