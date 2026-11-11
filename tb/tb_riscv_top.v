`timescale 1ns / 1ps

module tb_riscv_top;

    reg clk;
    reg rst_n;
    wire [31:0] errors;

    // Instantiate Top Module
    riscv_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .errors(errors)
    );

    // Clock Generation (100MHz / 10ns period)
    always #5 clk = ~clk;

    initial begin
        // Dump waves for GTKWave / Vivado
        $dumpfile("riscv_sim.vcd");
        $dumpvars(0, tb_riscv_top);

        // Initialize signals
        clk = 0;
        rst_n = 0;

        // Reset sequence
        #20;
        rst_n = 1;

        // Run simulation for 200ns
        #200;

        $display("--------------------------------------------------");
        $display("Simulation Completed. Errors = %d", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
