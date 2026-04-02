module riscv_core_top (
  input logic clk,
  input logic rst_n
);
  import riscv_pkg::*;

  // IF stage wires
  logic [31:0] if_pc;
  logic [31:0] if_instr;

  // IF/ID pipeline registers
  logic [31:0] if_id_pc;
  logic [31:0] if_id_instr;

  // ID stage decode wires
  logic [4:0]  id_rs1, id_rs2, id_rd;
  logic [31:0] id_rs1_data, id_rs2_data;
  logic [31:0] id_imm;
  control_s    id_ctrl;

  // ID/EX pipeline registers
  logic [31:0] id_ex_pc;
  logic [31:0] id_ex_rs1_data, id_ex_rs2_data;
  logic [31:0] id_ex_imm;
  logic [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
  logic [2:0]  id_ex_funct3;
  control_s    id_ex_ctrl;

  // EX stage wires
  logic [31:0] ex_alu_out;
  logic [31:0] ex_rs2_forwarded;
  logic [31:0] ex_branch_target;
  logic        ex_branch_taken;
  logic [31:0] ex_pc_plus4;

  // EX/MEM pipeline registers
  logic [31:0] ex_mem_alu_out;
  logic [31:0] ex_mem_store_data;
  logic [31:0] ex_mem_pc_plus4;
  logic [4:0]  ex_mem_rd;
  control_s    ex_mem_ctrl;

  // MEM stage wires
  logic [31:0] mem_load_data;

  // MEM/WB pipeline registers
  logic [31:0] mem_wb_alu_out;
  logic [31:0] mem_wb_load_data;
  logic [31:0] mem_wb_pc_plus4;
  logic [4:0]  mem_wb_rd;
  control_s    mem_wb_ctrl;

  // WB stage wires
  logic [31:0] wb_data;

  // Hazard + forwarding
  logic        stall;
  logic [1:0]  fwd_a_sel;
  logic [1:0]  fwd_b_sel;

  // IF stage
  if_stage u_if (
    .clk        (clk),
    .rst_n      (rst_n),
    .stall      (stall),
    .pc_redirect(ex_branch_taken),
    .redirect_pc(ex_branch_target),
    .if_pc      (if_pc),
    .if_instr   (if_instr)
  );

  // IF/ID register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      if_id_pc    <= 32'h0;
      if_id_instr <= 32'h00000013; // NOP
    end else if (ex_branch_taken) begin
      if_id_pc    <= 32'h0;
      if_id_instr <= 32'h00000013;
    end else if (!stall) begin
      if_id_pc    <= if_pc;
      if_id_instr <= if_instr;
    end
  end

  // ID stage
  id_stage u_id (
    .clk    (clk),
    .instr  (if_id_instr),
    .wb_data(wb_data),
    .wb_rd  (mem_wb_rd),
    .wb_we  (mem_wb_ctrl.reg_write),
    .rs1    (id_rs1),
    .rs2    (id_rs2),
    .rd     (id_rd),
    .reg_rs1(id_rs1_data),
    .reg_rs2(id_rs2_data),
    .imm    (id_imm),
    .ctrl   (id_ctrl)
  );

  hazard_unit u_hazard (
    .id_ex_mem_read(id_ex_ctrl.mem_read),
    .id_ex_rd      (id_ex_rd),
    .if_id_rs1     (id_rs1),
    .if_id_rs2     (id_rs2),
    .stall         (stall)
  );

  // ID/EX register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc       <= 32'h0;
      id_ex_rs1_data <= 32'h0;
      id_ex_rs2_data <= 32'h0;
      id_ex_imm      <= 32'h0;
      id_ex_rs1      <= 5'h0;
      id_ex_rs2      <= 5'h0;
      id_ex_rd       <= 5'h0;
      id_ex_funct3   <= 3'h0;
      id_ex_ctrl     <= '0;
    end else if (ex_branch_taken || stall) begin
      id_ex_pc       <= 32'h0;
      id_ex_rs1_data <= 32'h0;
      id_ex_rs2_data <= 32'h0;
      id_ex_imm      <= 32'h0;
      id_ex_rs1      <= 5'h0;
      id_ex_rs2      <= 5'h0;
      id_ex_rd       <= 5'h0;
      id_ex_funct3   <= 3'h0;
      id_ex_ctrl     <= '0;
    end else begin
      id_ex_pc       <= if_id_pc;
      id_ex_rs1_data <= id_rs1_data;
      id_ex_rs2_data <= id_rs2_data;
      id_ex_imm      <= id_imm;
      id_ex_rs1      <= id_rs1;
      id_ex_rs2      <= id_rs2;
      id_ex_rd       <= id_rd;
      id_ex_funct3   <= if_id_instr[14:12];
      id_ex_ctrl     <= id_ctrl;
    end
  end

  forwarding_unit u_fwd (
    .ex_mem_reg_write(ex_mem_ctrl.reg_write),
    .ex_mem_rd       (ex_mem_rd),
    .mem_wb_reg_write(mem_wb_ctrl.reg_write),
    .mem_wb_rd       (mem_wb_rd),
    .id_ex_rs1       (id_ex_rs1),
    .id_ex_rs2       (id_ex_rs2),
    .fwd_a_sel       (fwd_a_sel),
    .fwd_b_sel       (fwd_b_sel)
  );

  // EX stage
  ex_stage u_ex (
    .pc           (id_ex_pc),
    .rs1_data     (id_ex_rs1_data),
    .rs2_data     (id_ex_rs2_data),
    .imm          (id_ex_imm),
    .ex_mem_alu   (ex_mem_alu_out),
    .wb_data      (wb_data),
    .fwd_a_sel    (fwd_a_sel),
    .fwd_b_sel    (fwd_b_sel),
    .ctrl         (id_ex_ctrl),
    .funct3       (id_ex_funct3),
    .alu_out      (ex_alu_out),
    .rs2_forwarded(ex_rs2_forwarded),
    .branch_target(ex_branch_target),
    .branch_taken (ex_branch_taken),
    .pc_plus4     (ex_pc_plus4)
  );

  // EX/MEM register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_alu_out    <= 32'h0;
      ex_mem_store_data <= 32'h0;
      ex_mem_pc_plus4   <= 32'h0;
      ex_mem_rd         <= 5'h0;
      ex_mem_ctrl       <= '0;
    end else begin
      ex_mem_alu_out    <= ex_alu_out;
      ex_mem_store_data <= ex_rs2_forwarded;
      ex_mem_pc_plus4   <= ex_pc_plus4;
      ex_mem_rd         <= id_ex_rd;
      ex_mem_ctrl       <= id_ex_ctrl;
    end
  end

  // MEM stage
  mem_stage u_mem (
    .clk       (clk),
    .ctrl      (ex_mem_ctrl),
    .addr      (ex_mem_alu_out),
    .store_data(ex_mem_store_data),
    .load_data (mem_load_data)
  );

  // MEM/WB register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_alu_out   <= 32'h0;
      mem_wb_load_data <= 32'h0;
      mem_wb_pc_plus4  <= 32'h0;
      mem_wb_rd        <= 5'h0;
      mem_wb_ctrl      <= '0;
    end else begin
      mem_wb_alu_out   <= ex_mem_alu_out;
      mem_wb_load_data <= mem_load_data;
      mem_wb_pc_plus4  <= ex_mem_pc_plus4;
      mem_wb_rd        <= ex_mem_rd;
      mem_wb_ctrl      <= ex_mem_ctrl;
    end
  end

  // WB stage
  wb_stage u_wb (
    .ctrl     (mem_wb_ctrl),
    .alu_out  (mem_wb_alu_out),
    .load_data(mem_wb_load_data),
    .pc_plus4 (mem_wb_pc_plus4),
    .wb_data  (wb_data)
  );
endmodule
