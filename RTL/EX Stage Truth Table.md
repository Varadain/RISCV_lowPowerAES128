| Instruction         | branch_i | alu_src_i | alu_ctrl_i | op_a      | op_b      | alu_ctrl_eff  | branch_taken | branch_target      |
| ------------------- | -------: | --------: | ---------- | --------- | --------- | ------------- | ------------ | ------------------ |
| R-type ADD/SUB/etc. |        0 |         0 | ALU op     | `rs1/fwd` | `rs2/fwd` | Same as input | 0            | `pc + imm`         |
| I-type ADDI/etc.    |        0 |         1 | ALU op     | `rs1/fwd` | `imm`     | Same as input | 0            | `pc + imm`         |
| LOAD                |        0 |         1 | load tag   | `rs1/fwd` | `imm`     | ADD           | 0            | `pc + imm`         |
| STORE               |        0 |         1 | store tag  | `rs1/fwd` | `imm`     | ADD           | 0            | `pc + imm`         |
| BEQ                 |        1 |         0 | SUB        | `rs1/fwd` | `rs2/fwd` | SUB           | `zero`       | `pc + imm`         |
| BNE                 |        1 |         0 | BNE        | `rs1/fwd` | `rs2/fwd` | BNE           | `!zero`      | `pc + imm`         |
| BLT                 |        1 |         0 | BLT        | `rs1/fwd` | `rs2/fwd` | BLT           | `rs1 < rs2`  | `pc + imm`         |
| BGE                 |        1 |         0 | BGE        | `rs1/fwd` | `rs2/fwd` | BGE           | `rs1 >= rs2` | `pc + imm`         |
| LUI                 |        0 |         1 | LUI        | `0`       | `imm`     | LUI           | 0            | `pc + imm`         |
| AUIPC               |        0 |         1 | AUIPC      | `pc`      | `imm`     | AUIPC         | 0            | `pc + imm`         |
| JAL                 |        1 |         0 | LINK       | `pc`      | `4`       | LINK          | 1            | `pc + imm`         |
| JALR                |        1 |         1 | LINK       | `pc`      | `4`       | LINK          | 1            | `(rs1 + imm) & ~1` |
| CUSTOM              |        0 |         x | ADD        | `rs1/fwd` | depends   | ADD           | 0            | `pc + imm`         |
