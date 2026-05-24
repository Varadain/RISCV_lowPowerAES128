package riscv_pkg;
  typedef enum logic [1:0] {
    WB_SRC_ALU = 2'b00,
    WB_SRC_MEM = 2'b01,
    WB_SRC_PC4 = 2'b10
  } wb_src_e;

  typedef struct packed {
    logic       reg_write;
    logic       mem_read;
    logic       mem_write;
    logic       alu_src;
    logic [3:0] alu_ctrl;
    logic       branch;
    logic       jump;
    logic       jalr;
    wb_src_e    wb_src;
  } control_s;
endpackage