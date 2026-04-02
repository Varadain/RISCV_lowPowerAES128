SIM ?= iverilog
TOP ?= tb_top

RTL_SRCS := \
  rtl/riscv_core.sv

TB_SRCS := \
  tb/riscv_if.sv \
  tb/riscv_scoreboard.sv \
  tb/tb_top.sv

ALL_SRCS := $(RTL_SRCS) $(TB_SRCS)

.PHONY: lint run clean

lint:
	$(SIM) -g2012 -t null $(ALL_SRCS)

run:
	$(SIM) -g2012 -s $(TOP) -o simv $(ALL_SRCS)
	vvp simv

clean:
	rm -f simv
