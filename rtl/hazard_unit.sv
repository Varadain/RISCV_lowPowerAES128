module hazard_unit (
    input  logic [4:0] id_rs1_i,
    input  logic [4:0] id_rs2_i,
    input  logic [4:0] ex_rd_i,
    input  logic       ex_mem_read_i,
    output logic       stall_o,
    output logic       flush_ifid_o
);
    always_comb begin
        stall_o = 1'b0;
        flush_ifid_o = 1'b0;

        if (ex_mem_read_i && (ex_rd_i != 5'h0) && ((ex_rd_i == id_rs1_i) || (ex_rd_i == id_rs2_i))) begin
            stall_o = 1'b1;
            flush_ifid_o = 1'b1;
        end
    end
  input  logic       id_ex_mem_read,
  input  logic [4:0] id_ex_rd,
  input  logic [4:0] if_id_rs1,
  input  logic [4:0] if_id_rs2,
  output logic       stall
);
  always_comb begin
    stall = 1'b0;
    if (id_ex_mem_read && (id_ex_rd != 5'd0) &&
        ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
      stall = 1'b1;
    end
  end
endmodule
