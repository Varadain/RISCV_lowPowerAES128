module AESBoardTop(
    input  wire       clk,
    input  wire       reset,
    input  wire       clk_en,
    input  wire       load_valid,
    input  wire       load_key,
    input  wire       start,
    input  wire       read_next,
    input  wire [7:0] data_in,
    output wire [7:0] data_out,
    output wire       done,
    output reg        busy,
    output reg  [3:0] load_count,
    output reg  [3:0] read_count
);

    reg [127:0] plaintext_reg;
    reg [127:0] key_reg;
    reg [127:0] ciphertext_reg;
    reg         core_start;
    reg         result_valid;

    wire [127:0] core_ciphertext;
    wire         core_done;

    IterativeAES AES_CORE (
        .clk        (clk),
        .reset      (reset),
        .clk_en     (clk_en),
        .start      (core_start),
        .plaintext  (plaintext_reg),
        .key        (key_reg),
        .ciphertext (core_ciphertext),
        .done       (core_done)
    );

    assign done = result_valid;
    assign data_out = select_byte(ciphertext_reg, read_count[3:0]);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            plaintext_reg  <= 128'h0;
            key_reg        <= 128'h0;
            ciphertext_reg <= 128'h0;
            core_start     <= 1'b0;
            result_valid   <= 1'b0;
            busy           <= 1'b0;
            load_count     <= 4'd0;
            read_count     <= 4'd0;
        end else begin
            core_start <= 1'b0;

            if (clk_en) begin
                if (load_valid && !busy) begin
                    if (load_key) begin
                        key_reg <= {key_reg[119:0], data_in};
                    end else begin
                        plaintext_reg <= {plaintext_reg[119:0], data_in};
                    end

                    if (load_count == 4'd15) begin
                        load_count <= 4'd0;
                    end else begin
                        load_count <= load_count + 4'd1;
                    end
                end

                if (start && !busy) begin
                    core_start <= 1'b1;
                    busy <= 1'b1;
                    result_valid <= 1'b0;
                    read_count <= 4'd0;
                end

                if (busy && core_done) begin
                    ciphertext_reg <= core_ciphertext;
                    busy <= 1'b0;
                    result_valid <= 1'b1;
                    read_count <= 4'd0;
                end

                if (read_next && result_valid) begin
                    if (read_count < 4'd15) begin
                        read_count <= read_count + 4'd1;
                    end
                end
            end
        end
    end

    function [7:0] select_byte(input [127:0] value, input [3:0] index);
        case (index)
            4'd0:  select_byte = value[127:120];
            4'd1:  select_byte = value[119:112];
            4'd2:  select_byte = value[111:104];
            4'd3:  select_byte = value[103:96];
            4'd4:  select_byte = value[95:88];
            4'd5:  select_byte = value[87:80];
            4'd6:  select_byte = value[79:72];
            4'd7:  select_byte = value[71:64];
            4'd8:  select_byte = value[63:56];
            4'd9:  select_byte = value[55:48];
            4'd10: select_byte = value[47:40];
            4'd11: select_byte = value[39:32];
            4'd12: select_byte = value[31:24];
            4'd13: select_byte = value[23:16];
            4'd14: select_byte = value[15:8];
            default: select_byte = value[7:0];
        endcase
    endfunction

endmodule
