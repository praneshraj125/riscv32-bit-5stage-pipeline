#!/bin/bash
echo "Compiling RISC-V 5-Stage Processor simulation..."
iverilog -o riscv_sim ../rtl/*.v ../tb/tb_riscv_top.v
if [ $? -eq 0 ]; then
    echo "Running simulation..."
    vvp riscv_sim
    echo "Simulation finished! You can view waves using: gtkwave riscv_sim.vcd"
else
    echo "Compilation failed."
fi
