module riscv_core_top (
    input  logic clk,
    input  logic rst_n
);
    logic [31:0] pc_if;
    logic [31:0] instr_if;

    logic        stall_if;
    logic        flush_ifid;

    logic [31:0] pc_id;
    logic [31:0] instr_id;

    logic [4:0]  rs1_id;
    logic [4:0]  rs2_id;
    logic [4:0]  rd_id;
    logic [31:0] rs1_data_id;
    logic [31:0] rs2_data_id;
    logic [31:0] imm_id;

    logic        reg_write_id;
    logic        mem_read_id;
    logic        mem_write_id;
    logic        mem_to_reg_id;
    logic        alu_src_id;
    logic        branch_id;
    logic [3:0]  alu_ctrl_id;

    logic [31:0] pc_ex;
    logic [4:0]  rs1_ex;
    logic [4:0]  rs2_ex;
    logic [4:0]  rd_ex;
    logic [31:0] rs1_data_ex;
    logic [31:0] rs2_data_ex;
    logic [31:0] imm_ex;
    logic        reg_write_ex;
    logic        mem_read_ex;
    logic        mem_write_ex;
    logic        mem_to_reg_ex;
    logic        alu_src_ex;
    logic        branch_ex;
    logic [3:0]  alu_ctrl_ex;

    logic [1:0]  forward_a;
    logic [1:0]  forward_b;

    logic [31:0] alu_result_ex;
    logic [31:0] rs2_forwarded_ex;
    logic [31:0] branch_target_ex;
    logic        branch_taken_ex;

    logic [31:0] alu_result_mem;
    logic [31:0] rs2_data_mem;
    logic [4:0]  rd_mem;
    logic        reg_write_mem;
    logic        mem_read_mem;
    logic        mem_write_mem;
    logic        mem_to_reg_mem;

    logic [31:0] mem_read_data_mem;

    logic [31:0] alu_result_wb;
    logic [31:0] mem_read_data_wb;
    logic [4:0]  rd_wb;
    logic        reg_write_wb;
    logic        mem_to_reg_wb;

    logic [31:0] writeback_data;

    pc_reg u_pc_reg (
        .clk       (clk),
        .rst_n     (rst_n),
        .stall     (stall_if),
        .next_pc   (branch_taken_ex ? branch_target_ex : (pc_if + 32'd4)),
        .current_pc(pc_if)
    );

    if_stage u_if_stage (
        .pc_i       (pc_if),
        .instr_o    (instr_if)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush_ifid || branch_taken_ex) begin
            pc_id    <= 32'h0;
            instr_id <= 32'h00000013;
        end else if (!stall_if) begin
            pc_id    <= pc_if;
            instr_id <= instr_if;
        end
    end

    id_stage u_id_stage (
        .clk          (clk),
        .instr_i      (instr_id),
        .rs1_data_o   (rs1_data_id),
        .rs2_data_o   (rs2_data_id),
        .imm_o        (imm_id),
        .rs1_o        (rs1_id),
        .rs2_o        (rs2_id),
        .rd_o         (rd_id),
        .reg_write_o  (reg_write_id),
        .mem_read_o   (mem_read_id),
        .mem_write_o  (mem_write_id),
        .mem_to_reg_o (mem_to_reg_id),
        .alu_src_o    (alu_src_id),
        .branch_o     (branch_id),
        .alu_ctrl_o   (alu_ctrl_id),
        .wb_en_i      (reg_write_wb),
        .wb_rd_i      (rd_wb),
        .wb_data_i    (writeback_data)
    );

    hazard_unit u_hazard_unit (
        .id_rs1_i      (rs1_id),
        .id_rs2_i      (rs2_id),
        .ex_rd_i       (rd_ex),
        .ex_mem_read_i (mem_read_ex),
        .stall_o       (stall_if),
        .flush_ifid_o  (flush_ifid)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || branch_taken_ex) begin
            pc_ex         <= 32'h0;
            rs1_ex        <= 5'h0;
            rs2_ex        <= 5'h0;
            rd_ex         <= 5'h0;
            rs1_data_ex   <= 32'h0;
            rs2_data_ex   <= 32'h0;
            imm_ex        <= 32'h0;
            reg_write_ex  <= 1'b0;
            mem_read_ex   <= 1'b0;
            mem_write_ex  <= 1'b0;
            mem_to_reg_ex <= 1'b0;
            alu_src_ex    <= 1'b0;
            branch_ex     <= 1'b0;
            alu_ctrl_ex   <= 4'h0;
        end else if (!stall_if) begin
            pc_ex         <= pc_id;
            rs1_ex        <= rs1_id;
            rs2_ex        <= rs2_id;
            rd_ex         <= rd_id;
            rs1_data_ex   <= rs1_data_id;
            rs2_data_ex   <= rs2_data_id;
            imm_ex        <= imm_id;
            reg_write_ex  <= reg_write_id;
            mem_read_ex   <= mem_read_id;
            mem_write_ex  <= mem_write_id;
            mem_to_reg_ex <= mem_to_reg_id;
            alu_src_ex    <= alu_src_id;
            branch_ex     <= branch_id;
            alu_ctrl_ex   <= alu_ctrl_id;
        end
    end

    forwarding_unit u_forwarding_unit (
        .ex_rs1_i        (rs1_ex),
        .ex_rs2_i        (rs2_ex),
        .mem_rd_i        (rd_mem),
        .wb_rd_i         (rd_wb),
        .mem_reg_write_i (reg_write_mem),
        .wb_reg_write_i  (reg_write_wb),
        .forward_a_o     (forward_a),
        .forward_b_o     (forward_b)
    );

    ex_stage u_ex_stage (
        .pc_i             (pc_ex),
        .rs1_data_i       (rs1_data_ex),
        .rs2_data_i       (rs2_data_ex),
        .imm_i            (imm_ex),
        .alu_src_i        (alu_src_ex),
        .branch_i         (branch_ex),
        .alu_ctrl_i       (alu_ctrl_ex),
        .forward_a_i      (forward_a),
        .forward_b_i      (forward_b),
        .mem_alu_result_i (alu_result_mem),
        .wb_data_i        (writeback_data),
        .alu_result_o     (alu_result_ex),
        .rs2_forwarded_o  (rs2_forwarded_ex),
        .branch_target_o  (branch_target_ex),
        .branch_taken_o   (branch_taken_ex)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_mem <= 32'h0;
            rs2_data_mem   <= 32'h0;
            rd_mem         <= 5'h0;
            reg_write_mem  <= 1'b0;
            mem_read_mem   <= 1'b0;
            mem_write_mem  <= 1'b0;
            mem_to_reg_mem <= 1'b0;
        end else begin
            alu_result_mem <= alu_result_ex;
            rs2_data_mem   <= rs2_forwarded_ex;
            rd_mem         <= rd_ex;
            reg_write_mem  <= reg_write_ex;
            mem_read_mem   <= mem_read_ex;
            mem_write_mem  <= mem_write_ex;
            mem_to_reg_mem <= mem_to_reg_ex;
        end
    end

    mem_stage u_mem_stage (
        .clk         (clk),
        .addr_i      (alu_result_mem),
        .write_data_i(rs2_data_mem),
        .mem_read_i  (mem_read_mem),
        .mem_write_i (mem_write_mem),
        .read_data_o (mem_read_data_mem)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_wb    <= 32'h0;
            mem_read_data_wb <= 32'h0;
            rd_wb            <= 5'h0;
            reg_write_wb     <= 1'b0;
            mem_to_reg_wb    <= 1'b0;
        end else begin
            alu_result_wb    <= alu_result_mem;
            mem_read_data_wb <= mem_read_data_mem;
            rd_wb            <= rd_mem;
            reg_write_wb     <= reg_write_mem;
            mem_to_reg_wb    <= mem_to_reg_mem;
        end
    end

    wb_stage u_wb_stage (
        .alu_result_i   (alu_result_wb),
        .mem_read_data_i(mem_read_data_wb),
        .mem_to_reg_i   (mem_to_reg_wb),
        .wb_data_o      (writeback_data)
    );
endmodule
