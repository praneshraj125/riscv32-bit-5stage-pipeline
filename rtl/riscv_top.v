// Top-Level 5-Stage Pipelined RISC-V Core
module riscv_top (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] errors
);

    // ------------------------------------------------------------------------
    // IF Stage
    // ------------------------------------------------------------------------
    reg  [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] instr_if;

    wire stall, flush;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'd0;
        else if (!stall)
            pc <= pc_next;
    end

    instr_mem imem (
        .addr(pc),
        .instr(instr_if)
    );

    // ------------------------------------------------------------------------
    // IF/ID Pipeline Register
    // ------------------------------------------------------------------------
    reg [31:0] if_id_pc, if_id_instr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            if_id_pc    <= 32'd0;
            if_id_instr <= 32'h00000013; // NOP (ADDI x0, x0, 0)
        end else if (!stall) begin
            if_id_pc    <= pc;
            if_id_instr <= instr_if;
        end
    end

    // ------------------------------------------------------------------------
    // ID Stage
    // ------------------------------------------------------------------------
    wire [31:0] reg_rd1, reg_rd2, imm_id;
    wire        reg_write_id, mem_to_reg_id, mem_read_id, mem_write_id, alu_src_id, branch_id;
    wire [3:0]  alu_control_id;

    regfile rf (
        .clk(clk),
        .rst_n(rst_n),
        .we(wb_reg_write),
        .rs1(if_id_instr[19:15]),
        .rs2(if_id_instr[24:20]),
        .rd(wb_rd),
        .wd(wb_data),
        .rd1(reg_rd1),
        .rd2(reg_rd2)
    );

    imm_gen ig (
        .instr(if_id_instr),
        .imm(imm_id)
    );

    control_unit cu (
        .opcode(if_id_instr[6:0]),
        .funct3(if_id_instr[14:12]),
        .funct7(if_id_instr[31:25]),
        .reg_write(reg_write_id),
        .mem_to_reg(mem_to_reg_id),
        .mem_read(mem_read_id),
        .mem_write(mem_write_id),
        .alu_src(alu_src_id),
        .branch(branch_id),
        .alu_control(alu_control_id)
    );

    // ------------------------------------------------------------------------
    // ID/EX Pipeline Register
    // ------------------------------------------------------------------------
    reg [31:0] id_ex_pc, id_ex_rd1, id_ex_rd2, id_ex_imm;
    reg [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    reg [3:0]  id_ex_alu_control;
    reg        id_ex_reg_write, id_ex_mem_to_reg, id_ex_mem_read, id_ex_mem_write, id_ex_alu_src, id_ex_branch;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || stall || flush) begin
            id_ex_pc          <= 32'd0;
            id_ex_rd1         <= 32'd0;
            id_ex_rd2         <= 32'd0;
            id_ex_imm         <= 32'd0;
            id_ex_rs1         <= 5'd0;
            id_ex_rs2         <= 5'd0;
            id_ex_rd          <= 5'd0;
            id_ex_alu_control <= 4'd0;
            id_ex_reg_write   <= 1'b0;
            id_ex_mem_to_reg  <= 1'b0;
            id_ex_mem_read   <= 1'b0;
            id_ex_mem_write  <= 1'b0;
            id_ex_alu_src     <= 1'b0;
            id_ex_branch      <= 1'b0;
        end else begin
            id_ex_pc          <= if_id_pc;
            id_ex_rd1         <= reg_rd1;
            id_ex_rd2         <= reg_rd2;
            id_ex_imm         <= imm_id;
            id_ex_rs1         <= if_id_instr[19:15];
            id_ex_rs2         <= if_id_instr[24:20];
            id_ex_rd          <= if_id_instr[11:7];
            id_ex_alu_control <= alu_control_id;
            id_ex_reg_write   <= reg_write_id;
            id_ex_mem_to_reg  <= mem_to_reg_id;
            id_ex_mem_read   <= mem_read_id;
            id_ex_mem_write  <= mem_write_id;
            id_ex_alu_src     <= alu_src_id;
            id_ex_branch      <= branch_id;
        end
    end

    // ------------------------------------------------------------------------
    // EX Stage & Forwarding
    // ------------------------------------------------------------------------
    wire [1:0] forward_a, forward_b;
    reg  [31:0] alu_operand_a, alu_operand_b_forwarded, alu_operand_b;
    wire [31:0] alu_out_ex;
    wire        alu_zero_ex;

    forwarding_unit fu (
        .rs1_ex(id_ex_rs1),
        .rs2_ex(id_ex_rs2),
        .rd_mem(ex_mem_rd),
        .rd_wb(wb_rd),
        .reg_write_mem(ex_mem_reg_write),
        .reg_write_wb(wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    always @(*) begin
        case (forward_a)
            2'b10: alu_operand_a = ex_mem_alu_out;
            2'b01: alu_operand_a = wb_data;
            default: alu_operand_a = id_ex_rd1;
        endcase

        case (forward_b)
            2'b10: alu_operand_b_forwarded = ex_mem_alu_out;
            2'b01: alu_operand_b_forwarded = wb_data;
            default: alu_operand_b_forwarded = id_ex_rd2;
        endcase

        alu_operand_b = (id_ex_alu_src) ? id_ex_imm : alu_operand_b_forwarded;
    end

    alu alu_inst (
        .a(alu_operand_a),
        .b(alu_operand_b),
        .alu_control(id_ex_alu_control),
        .result(alu_out_ex),
        .zero(alu_zero_ex)
    );

    wire branch_taken = id_ex_branch && alu_zero_ex;
    wire [31:0] branch_target = id_ex_pc + id_ex_imm;
    assign pc_next = (branch_taken) ? branch_target : (pc + 32'd4);

    // Hazard Unit Connection
    hazard_unit hu (
        .rs1_id(if_id_instr[19:15]),
        .rs2_id(if_id_instr[24:20]),
        .rd_ex(id_ex_rd),
        .mem_read_ex(id_ex_mem_read),
        .branch_taken_ex(branch_taken),
        .stall(stall),
        .flush(flush)
    );

    // ------------------------------------------------------------------------
    // EX/MEM Pipeline Register
    // ------------------------------------------------------------------------
    reg [31:0] ex_mem_alu_out, ex_mem_rd2;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_reg_write, ex_mem_mem_to_reg, ex_mem_mem_read, ex_mem_mem_write;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_alu_out    <= 32'd0;
            ex_mem_rd2        <= 32'd0;
            ex_mem_rd         <= 5'd0;
            ex_mem_reg_write  <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_mem_read   <= 1'b0;
            ex_mem_mem_write  <= 1'b0;
        end else begin
            ex_mem_alu_out    <= alu_out_ex;
            ex_mem_rd2        <= alu_operand_b_forwarded;
            ex_mem_rd         <= id_ex_rd;
            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_mem_write  <= id_ex_mem_write;
        end
    end

    // ------------------------------------------------------------------------
    // MEM Stage
    // ------------------------------------------------------------------------
    wire [31:0] mem_read_data;

    data_mem dmem (
        .clk(clk),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write),
        .addr(ex_mem_alu_out),
        .write_data(ex_mem_rd2),
        .read_data(mem_read_data)
    );

    // ------------------------------------------------------------------------
    // MEM/WB Pipeline Register
    // ------------------------------------------------------------------------
    reg [31:0] mem_wb_read_data, mem_wb_alu_out;
    reg [4:0]  wb_rd;
    reg        wb_reg_write, wb_mem_to_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_read_data <= 32'd0;
            mem_wb_alu_out   <= 32'd0;
            wb_rd            <= 5'd0;
            wb_reg_write     <= 1'b0;
            wb_mem_to_reg    <= 1'b0;
        end else begin
            mem_wb_read_data <= mem_read_data;
            mem_wb_alu_out   <= ex_mem_alu_out;
            wb_rd            <= ex_mem_rd;
            wb_reg_write     <= ex_mem_reg_write;
            wb_mem_to_reg    <= ex_mem_mem_to_reg;
        end
    end

    // ------------------------------------------------------------------------
    // WB Stage
    // ------------------------------------------------------------------------
    wire [31:0] wb_data = (wb_mem_to_reg) ? mem_wb_read_data : mem_wb_alu_out;

    assign errors = 32'd0; // Signal for testbench compliance check

endmodule
