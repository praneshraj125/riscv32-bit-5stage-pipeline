// Immediate Generator for RV32I Types (I, S, B, U, J)
module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);
    always @(*) begin
        case (instr[6:0])
            7'b0010013, 7'b0000013, 7'b1100111: // I-type (ADDI, LW, JALR)
                imm = {{20{instr[31]}}, instr[31:20]};
            7'b0100013: // S-type (SW)
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011: // B-type (BEQ, BNE)
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            7'b0110111, 7'b0010111: // U-type (LUI, AUIPC)
                imm = {instr[31:12], 12'b0};
            7'b1101111: // J-type (JAL)
                imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default:
                imm = 32'd0;
        endcase
    end
endmodule
