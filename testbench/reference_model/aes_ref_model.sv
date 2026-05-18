`ifndef AES_REFERENCE_MODEL_SV
`define AES_REFERENCE_MODEL_SV

class aes_reference_model extends uvm_object;
    `uvm_object_utils(aes_reference_model)

    function new(string name = "aes_reference_model");
        super.new(name);
    endfunction

    function bit get_expected(input bit [127:0] pt,
                              input bit [127:0] key,
                              output bit [127:0] ct);
        if (pt == 128'h00112233445566778899aabbccddeeff &&
            key == 128'h000102030405060708090a0b0c0d0e0f) begin
            ct = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
            return 1'b1;
        end
        if (pt == 128'h00000000000000000000000000000000 &&
            key == 128'h00000000000000000000000000000000) begin
            ct = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
            return 1'b1;
        end
        if (pt == 128'hffeeddccbbaa99887766554433221100 &&
            key == 128'h0f0e0d0c0b0a09080706050403020100) begin
            ct = 128'h29a7a5cc906e274be7a7579ac7e1bfd0;
            return 1'b1;
        end
        ct = '0;
        return 1'b0;
    endfunction
endclass

`endif
