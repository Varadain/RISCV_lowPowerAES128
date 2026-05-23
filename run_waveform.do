transcript file simulation_transcript.txt
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vlog -sv IterativeAES.sv tb_aes128_lowpower.sv
vsim -voptargs=+acc -wlf aes128_lowpower_multitest.wlf work.tb_aes128_lowpower
log -r /*
run -all
quit -f
