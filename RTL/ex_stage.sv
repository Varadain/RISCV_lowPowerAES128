// ============================================================
// EXECUTE (EX) STAGE
// ============================================================
//
// This stage performs:
//  - ALU operations (ADD, SUB, shifts, etc.)
//  - Branch decision (BEQ, BNE, BLT, etc.)
//  - Branch target calculation
//  - Operand forwarding (hazard resolution)
//  - Special operations (LUI, AUIPC, JAL, JALR)
//
// ------------------------------------------------------------
// EX STAGE DATAFLOW (SIMPLIFIED)
//
//        rs1 --------┐
//                    │        ┌────────────┐
//        rs2 ----┐   ├------→ │ FORWARDING │
//                │   │        └─────┬──────┘
//                │   │              │
//                │   │              ↓
//                │   │         ┌────────┐
//                │   └--------→│  ALU   │────→ alu_result
//                │             └────────┘
//                │
//                └→ store data (forwarded)
//
// ------------------------------------------------------------
// FORWARDING PATHS:
//
//   MEM stage ────────────────┐
//                             ↓
//   WB stage ───────────────→ MUX → ALU inputs
//
// Avoids pipeline stalls for data hazards
//
// ------------------------------------------------------------
// BRANCH LOGIC:
//
//   - Compare operands (zero / signed compare)
//   - Compute target:
//       PC + imm        (normal branch)
//       rs1 + imm       (JALR)
//   - Decide branch_taken
//
// ------------------------------------------------------------
// LOAD/STORE SPECIAL HANDLING:
//
//   Some ALU control signals are reused as "tags"
//   to encode load/store type (byte/halfword/unsigned)
//
//   These tags are embedded into upper bits of ALU result
//
// ============================================================

module ex_stage (
    input  logic [31:0] pc_i,             // Current PC from EX stage
    input  logic [31:0] rs1_data_i,       // Source register 1 value
    input  logic [31:0] rs2_data_i,       // Source register 2 value
    input  logic [31:0] imm_i,            // Immediate value
    input  logic        alu_src_i,        // Select between rs2 or immediate
    input  logic        branch_i,         // Indicates branch instruction
    input  logic [3:0]  alu_ctrl_i,       // ALU operation control
    input  logic        custom_instr_i,   // RISC-V custom-0 security instruction
    input  logic [1:0]  forward_a_i,      // Forward select for operand A
    input  logic [1:0]  forward_b_i,      // Forward select for operand B
    input  logic [31:0] mem_alu_result_i, // Forwarded value from MEM stage
    input  logic [31:0] wb_data_i,        // Forwarded value from WB stage

    output logic [31:0] alu_result_o,     // Final ALU result (possibly tagged)
    output logic [31:0] rs2_forwarded_o,  // Forwarded rs2 (for store)
    output logic [31:0] branch_target_o,  // Branch target address
    output logic        branch_taken_o    // Branch decision
);

    // ========================================================
    // ALU CONTROL DEFINITIONS
    // ========================================================
    localparam logic [3:0] ALU_ADD   = 4'h0;
    localparam logic [3:0] ALU_SUB   = 4'h1;
    localparam logic [3:0] ALU_LUI   = 4'hA;
    localparam logic [3:0] ALU_AUIPC = 4'hB;
    localparam logic [3:0] ALU_BNE   = 4'hC;
    localparam logic [3:0] ALU_BLT   = 4'hD;
    localparam logic [3:0] ALU_BGE   = 4'hE;
    localparam logic [3:0] ALU_LINK  = 4'hF;

    // ========================================================
    // INTERNAL SIGNALS
    // ========================================================
    logic [31:0] op_a_raw;       // Raw operand A (before ALU mux)
    logic [31:0] op_b_raw;       // Raw operand B
    logic [31:0] op_a;           // Final operand A to ALU
    logic [31:0] op_b;           // Final operand B to ALU

    logic [3:0]  alu_ctrl_eff;   // Effective ALU control
    logic [31:0] alu_result_raw; // Raw ALU output

    logic [2:0]  ls_tag;         // Load/store type tag
    logic        is_mem_variant; // Indicates load/store encoding

    logic        zero;           // ALU zero flag
    logic        cmp_lt_signed;  // Signed comparison result

    // ========================================================
    // FORWARDING MUXES (DATA HAZARD RESOLUTION)
    // ========================================================
    always_comb begin
        // Select source for operand A
        case (forward_a_i)
            2'b10: op_a_raw = mem_alu_result_i; // Forward from MEM
            2'b01: op_a_raw = wb_data_i;        // Forward from WB
            default: op_a_raw = rs1_data_i;     // Normal case
        endcase

        // Select source for operand B
        case (forward_b_i)
            2'b10: op_b_raw = mem_alu_result_i;
            2'b01: op_b_raw = wb_data_i;
            default: op_b_raw = rs2_data_i;
        endcase
    end

    // ========================================================
    // OPERAND SELECTION + SPECIAL CASE HANDLING
    // ========================================================
    always_comb begin
        op_a = op_a_raw;

        // Select between register or immediate
        op_b = alu_src_i ? imm_i : op_b_raw;

        // Detect if instruction is load/store variant
        is_mem_variant = !branch_i && (
            (alu_ctrl_i == ALU_BNE) ||
            (alu_ctrl_i == ALU_BLT) ||
            (alu_ctrl_i == ALU_BGE) ||
            (alu_ctrl_i == ALU_LINK)
        );

        // For memory ops → ALU always does address = base + offset
        alu_ctrl_eff = is_mem_variant ? ALU_ADD : alu_ctrl_i;

        // Special cases for different instructions

        // LUI: load upper immediate
        if (alu_ctrl_i == ALU_LUI) begin
            op_a = 32'h0;
            op_b = imm_i;
        end

        // AUIPC: PC + immediate
        else if (alu_ctrl_i == ALU_AUIPC) begin
            op_a = pc_i;
            op_b = imm_i;
        end

        // JAL/JALR: link value = PC + 4
        else if (branch_i && (alu_ctrl_i == ALU_LINK)) begin
            op_a = pc_i;
            op_b = 32'd4;
        end

        // Load/store type encoding
        ls_tag = 3'b000;
        if (is_mem_variant) begin
            case (alu_ctrl_i)
                ALU_BNE:  ls_tag = 3'b001; // byte
                ALU_BLT:  ls_tag = 3'b010; // half
                ALU_BGE:  ls_tag = 3'b011; // byte unsigned
                ALU_LINK: ls_tag = 3'b100; // half unsigned
                default:  ls_tag = 3'b000;
            endcase
        end
    end

    // Forwarded rs2 used for store operations
    assign rs2_forwarded_o = op_b_raw;

    // Signed comparison (used for BLT/BGE)
    assign cmp_lt_signed = ($signed(op_a_raw) < $signed(op_b_raw));

    // ========================================================
    // BRANCH TARGET COMPUTATION
    // ========================================================
    always_comb begin
        if (branch_i && alu_src_i && (alu_ctrl_i == ALU_LINK)) begin
            // JALR: (rs1 + imm) aligned
            branch_target_o = (op_a_raw + imm_i) & 32'hFFFF_FFFE;
        end else begin
            // Normal branch/JAL
            branch_target_o = pc_i + imm_i;
        end
    end

    // ========================================================
    // ALU INSTANCE
    // ========================================================
    alu u_alu (
        .a_i(op_a),
        .b_i(op_b),
        .alu_ctrl_i(alu_ctrl_eff),
        .result_o(alu_result_raw),
        .zero_o(zero)
    );

    // ========================================================
    // OUTPUT FORMATTING
    // Embed load/store tag into upper bits if needed
    // ========================================================
    always_comb begin
        if (custom_instr_i) begin
            // MEM stage consumes rs1 through addr_i and rs2 through write_data_i
            // for custom security instructions.
            alu_result_o = op_a_raw;
        end else if (is_mem_variant) begin
            alu_result_o = {ls_tag, alu_result_raw[28:0]};
        end else begin
            alu_result_o = alu_result_raw;
        end
    end

    // ========================================================
    // BRANCH DECISION LOGIC
    // ========================================================
    always_comb begin
        branch_taken_o = 1'b0;

        if (branch_i) begin
             case (alu_ctrl_i)
                ALU_SUB:  branch_taken_o = zero;             // BEQ
                ALU_BNE:  branch_taken_o = !zero;            // BNE
                ALU_BLT:  branch_taken_o = cmp_lt_signed;    // BLT
                ALU_BGE:  branch_taken_o = !cmp_lt_signed;   // BGE
                ALU_LINK: branch_taken_o = 1'b1;             // JAL/JALR
                default:  branch_taken_o = 1'b0;
            endcase
        end
    end



endmodule
