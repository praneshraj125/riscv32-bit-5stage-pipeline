// Hazard Detection Unit for Load-Use Stalls and Control Branch Flushes
module hazard_unit (
    input  wire [4:0] rs1_id,
    input  wire [4:0] rs2_id,
    input  wire [4:0] rd_ex,
    input  wire       mem_read_ex,
    input  wire       branch_taken_ex,
    output reg        stall,
    output reg        flush
);
    always @(*) begin
        stall = 1'b0;
        flush = 1'b0;

        // 1. Load-Use Hazard Stall Logic
        if (mem_read_ex && (rd_ex != 5'd0) && ((rd_ex == rs1_id) || (rd_ex == rs2_id))) begin
            stall = 1'b1; // Freeze PC and IF/ID, clear ID/EX to NOP
        end

        // 2. Control Hazard Branch Flush Logic
        if (branch_taken_ex) begin
            flush = 1'b1; // Flush IF/ID and ID/EX registers to NOP
        end
    end
endmodule
