import uvm_pkg::*;
`include "uvm_macros.svh"
// ============================================================
// PACKAGE: riscv_pkg
// ============================================================
//
// This package defines shared types used across the RISC-V core.
// It mainly contains:
//   1. Writeback source selection enum
//   2. Control signal structure for pipeline stages
//
// ------------------------------------------------------------
// CONTROL FLOW OVERVIEW (Simplified)
//
//                +----------------------
//                |   CONTROL UNIT      |
//                +----------+----------
//                           |
//                           v
//        ----------------------------------------
//        |         control_s (this struct)       |
//        ----------------------------------------
//           |       |       |        |
//           v       v       v        v
//          EX      MEM      WB     Branch/Jump
//
// ------------------------------------------------------------
// WRITEBACK PATH DIAGRAM:
//
//                 +------------------+
//                 |   WB STAGE MUX   |
//                 +--------+---------+
//                          |
//        --------------------------------------
//        |            wb_src_e                |
//        --------------------------------------
//        |   ALU Result   |   Memory Data     |
//        |     PC + 4     |                  |
//        --------------------------------------
//
//   wb_src decides which data goes back to register file.
//
// ------------------------------------------------------------
// PURPOSE:
//
// This package ensures:
//   - Clean separation of control logic
//   - Reusable and consistent signal definitions
//   - Easier debugging and scalability
//
// ============================================================

package riscv_pkg;

  // ========================================================
  // ENUM: Writeback Source Selection
  // ========================================================
  //
  // Defines which value is written back to the register file
  // during the WB (Writeback) stage.
  //
  // Used in WB stage multiplexer.
  //
  // --------------------------------------------------------
  // WB SOURCE OPTIONS:
  //
  //   00 → ALU Result
  //   01 → Data from Memory (Load instructions)
  //   10 → PC + 4 (Used in JAL/JALR for return address)
  //
  // --------------------------------------------------------
  typedef enum logic [1:0] {
    WB_SRC_ALU = 2'b00,  // Write ALU computation result
    WB_SRC_MEM = 2'b01,  // Write data read from memory
    WB_SRC_PC4 = 2'b10   // Write PC + 4 (link address)
  } wb_src_e;


  // ========================================================
  // STRUCT: control_s (Control Signals Bundle)
  // ========================================================
  //
  // This structure groups all control signals generated
  // in the ID (Instruction Decode) stage and passed
  // through pipeline registers.
  //
  // It simplifies signal management across pipeline stages.
  //
  // --------------------------------------------------------
  // PIPELINE USAGE:
  //
  //   ID Stage → Generates control signals
  //   EX Stage → Uses ALU control, branch, alu_src
  //   MEM Stage → Uses mem_read, mem_write
  //   WB Stage → Uses reg_write, wb_src
  //
  // --------------------------------------------------------
  // CONTROL SIGNAL FLOW:
  //
  //   control_s
  //      |
  //      +--> EX (ALU operations)
  //      +--> MEM (memory access)
  //      +--> WB (writeback selection)
  //
  // ========================================================
  typedef struct packed {

    // ----------------------------------------------------
    // REGISTER WRITE CONTROL
    // ----------------------------------------------------
    logic reg_write;  
    // Enables writing data into register file (rd)

    // ----------------------------------------------------
    // MEMORY ACCESS CONTROL
    // ----------------------------------------------------
    logic mem_read;   
    // Enables memory read (Load instructions)

    logic mem_write;  
    // Enables memory write (Store instructions)

    // ----------------------------------------------------
    // ALU CONTROL
    // ----------------------------------------------------
    logic alu_src;    
    // Selects second ALU operand:
    // 0 → register value
    // 1 → immediate value

    logic [3:0] alu_ctrl; 
    // Specifies ALU operation (ADD, SUB, AND, etc.)

    // ----------------------------------------------------
    // CONTROL FLOW (BRANCH / JUMP)
    // ----------------------------------------------------
    logic branch;     
    // Indicates branch instruction

    logic jump;       
    // Indicates jump instruction (JAL)

    logic jalr;       
    // Indicates JALR (indirect jump)

    // ----------------------------------------------------
    // WRITEBACK CONTROL
    // ----------------------------------------------------
    wb_src_e wb_src;  
    // Selects data source for writeback stage

  } control_s;

endpackage
