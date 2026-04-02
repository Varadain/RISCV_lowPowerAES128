module wb_stage (
    input  logic [31:0] alu_result_i,
    input  logic [31:0] mem_read_data_i,
    input  logic        mem_to_reg_i,
    output logic [31:0] wb_data_o
);
    assign wb_data_o = mem_to_reg_i ? mem_read_data_i : alu_result_i;
  input  riscv_pkg::control_s ctrl,
  input  logic [31:0]         alu_out,
  input  logic [31:0]         load_data,
  input  logic [31:0]         pc_plus4,
  output logic [31:0]         wb_data
);
  import riscv_pkg::*;

  always_comb begin
    unique case (ctrl.wb_src)
      WB_SRC_ALU: wb_data = alu_out;
      WB_SRC_MEM: wb_data = load_data;
      WB_SRC_PC4: wb_data = pc_plus4;
      default:    wb_data = alu_out;
    endcase
  end
endmodule
