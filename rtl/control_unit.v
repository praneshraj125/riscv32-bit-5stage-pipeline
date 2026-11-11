// Main Control Unit & ALU Decoder
module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        reg_write,
    output reg        mem_to_reg,
    output reg        mem_read,
    output reg        mem_write,
    output reg        alu_src,
    output reg        branch,
    output reg  [3:0] alu_control
);
    always @(*) begin
        // Default control signals
        reg_write   = 1'b0;
        mem_to_reg  = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        alu_src     = 1'b0;
        branch      = 1'b0;
        alu_control = 4'b0000;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                case (funct3)
                    3'b000: alu_control = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b111: alu_control = 4'b0010; // AND
                    3'b110: alu_control = 4'b0011; // OR
                    3'b100: alu_control = 4'b0100; // XOR
                    3'b001: alu_control = 4'b0101; // SLL
                    3'b101: alu_control = (funct7[5]) ? 4'b0111 : 4'b0110; // SRA : SRL
                    3'b010: alu_control = 4'b1000; // SLT
                    3'b011: alu_control = 4'b1001; // SLTU
                    default: alu_control = 4'b0000;
                endcase
            end
            7'b0010013: begin // I-type Arithmetic (ADDI, etc.)
                reg_write = 1'b1;
                alu_src   = 1'b1;
                case (funct3)
                    3'b000: alu_control = 4'b0000; // ADDI
                    3'b111: alu_control = 4'b0010; // ANDI
                    3'b110: alu_control = 4'b0011; // ORI
                    3'b100: alu_control = 4'b0100; // XORI
                    3'b010: alu_control = 4'b1000; // SLTI
                    default: alu_control = 4'b0000;
                endcase
            end
            7'b0000013: begin // Load (LW)
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = 1'b1;
                mem_read   = 1'b1;
                alu_control= 4'b0000; // Address ADD calculation
            end
            7'b0100013: begin // Store (SW)
                alu_src    = 1'b1;
                mem_write  = 1'b1;
                alu_control= 4'b0000; // Address ADD calculation
            end
            7'b1100011: begin // Branch (BEQ/BNE)
                branch     = 1'b1;
                alu_control= 4'b0001; // SUB for comparison
            end
            default: ;
        endcase
    end
endmodule
