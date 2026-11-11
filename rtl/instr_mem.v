// Instruction Memory (32-bit word aligned)
module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] memory [0:255];

    initial begin
        // Initialize memory with program hex
        $readmemh("program.hex", memory);
    end

    assign instr = memory[addr[9:2]];
endmodule
