// Forwarding Unit for RAW Data Hazards
module forwarding_unit (
    input  wire [4:0] rs1_ex,
    input  wire [4:0] rs2_ex,
    input  wire [4:0] rd_mem,
    input  wire [4:0] rd_wb,
    input  wire       reg_write_mem,
    input  wire       reg_write_wb,
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);
    always @(*) begin
        // Forward A Logic
        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs1_ex)) begin
            forward_a = 2'b10; // Forward from EX/MEM stage
        end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs1_ex)) begin
            forward_a = 2'b01; // Forward from MEM/WB stage
        end else begin
            forward_a = 2'b00; // No forwarding (use ID/EX reg value)
        end

        // Forward B Logic
        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs2_ex)) begin
            forward_b = 2'b10; // Forward from EX/MEM stage
        end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs2_ex)) begin
            forward_b = 2'b01; // Forward from MEM/WB stage
        end else begin
            forward_b = 2'b00; // No forwarding (use ID/EX reg value)
        end
    end
endmodule
