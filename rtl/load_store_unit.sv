module load_store_unit (
    input  logic [2:0]  ls_tag_i,
    input  logic [1:0]  byte_off_i,
    input  logic [31:0] mem_word_i,
    input  logic [31:0] store_data_i,
    output logic [31:0] load_data_o,
    output logic [31:0] merged_store_word_o
);
    logic [7:0]  sel_byte;
    logic [15:0] sel_half;

    always_comb begin
        case (byte_off_i)
            2'b00: sel_byte = mem_word_i[7:0];
            2'b01: sel_byte = mem_word_i[15:8];
            2'b10: sel_byte = mem_word_i[23:16];
            default: sel_byte = mem_word_i[31:24];
        endcase

        sel_half = byte_off_i[1] ? mem_word_i[31:16] : mem_word_i[15:0];

        // Default pass-through for LW/SW.
        load_data_o = mem_word_i;
        merged_store_word_o = store_data_i;

        case (ls_tag_i)
            3'b001: begin // LB / SB
                load_data_o = {{24{sel_byte[7]}}, sel_byte};
                case (byte_off_i)
                    2'b00: merged_store_word_o = {mem_word_i[31:8], store_data_i[7:0]};
                    2'b01: merged_store_word_o = {mem_word_i[31:16], store_data_i[7:0], mem_word_i[7:0]};
                    2'b10: merged_store_word_o = {mem_word_i[31:24], store_data_i[7:0], mem_word_i[15:0]};
                    default: merged_store_word_o = {store_data_i[7:0], mem_word_i[23:0]};
                endcase
            end

            3'b010: begin // LH / SH
                load_data_o = {{16{sel_half[15]}}, sel_half};
                if (byte_off_i[1]) begin
                    merged_store_word_o = {store_data_i[15:0], mem_word_i[15:0]};
                end else begin
                    merged_store_word_o = {mem_word_i[31:16], store_data_i[15:0]};
                end
            end

            3'b011: begin // LBU
                load_data_o = {24'h0, sel_byte};
            end

            3'b100: begin // LHU
                load_data_o = {16'h0, sel_half};
            end

            default: begin
            end
        endcase
    end
endmodule
