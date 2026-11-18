`define TYPE_R 3'd0
`define TYPE_I 3'd1
`define TYPE_S 3'd2
`define TYPE_U 3'd3
`define TYPE_J 3'd4
`define TYPE_B 3'd5
`define TYPE_NONE 3'd7

`define FUNC4_ADD  4'b0000
`define FUNC4_SUB  4'b1000
`define FUNC4_SLT  4'b?010
`define FUNC4_SLTU 4'b?011
`define FUNC4_XOR  4'b?100
`define FUNC4_OR   4'b?110
`define FUNC4_SLL  4'b?001
`define FUNC4_SRL  4'b0101
`define FUNC4_SRA  4'b1101
`define FUNC4_AND  4'b?111

`define FUNC3_BEQ  3'b000
`define FUNC3_BNE  3'b001
`define FUNC3_BLT  3'b100
`define FUNC3_BGE  3'b101
`define FUNC3_BLTU 3'b110
`define FUNC3_BGEU 3'b111

`define FUNC3_LB   3'b000
`define FUNC3_LH   3'b001
`define FUNC3_LW   3'b010
`define FUNC3_LBU  3'b100
`define FUNC3_LHU  3'b101

`define FUNC3_SB   3'b000
`define FUNC3_SH   3'b001
`define FUNC3_SW   3'b010

module program_counter(input clk,
                       input[31:0] pc_next,
                       output reg[31:0] pc);

    initial begin
        pc = 32'h200;
    end

    always @(posedge clk) begin
        pc = pc_next;
    end

endmodule

module mux2(input select,
            input[31:0] data0, data1,
            output[31:0] out);

    assign out = (select == 0) ? data0 : data1;

endmodule

module plus4(input[31:0] pc,
             output[31:0] pc_plus4);

    assign pc_plus4 = pc + 4;

 endmodule

module add32(input[31:0] a, b,
             output[31:0] out);

    assign out = a + b;

endmodule

module regfile(input clk,
               input[4:0] ra1, ra2, ra3,
               input[31:0] wd3,
               output [31:0] rs1, rs2);

    reg[31:0] file[31:0];

    assign rs1 = ra1 == 5'b0 ? 32'b0 : file[ra1];
    assign rs2 = ra2 == 5'b0 ? 32'b0 : file[ra2];

    always @(posedge clk) begin
        file[ra3] <= wd3;
    end

endmodule

module dmem(input clk, we,
            input[2:0] dmemctrl,
            input[31:0] a, wd,
            output reg[31:0] rd);

    reg[31:0] RAM[0:4095];

    wire[31:0] word;
    assign word = RAM[a[13:2]];

    wire[7:0] bytes[0:3];
    assign bytes[3] = word[31:24];
    assign bytes[2] = word[23:16];
    assign bytes[1] = word[15:8];
    assign bytes[0] = word[7:0];

    wire[15:0] halfwords[0:1];
    assign halfwords[1] = word[31:16];
    assign halfwords[0] = word[15:0];

    always @(*) begin
        case (dmemctrl)
            `FUNC3_LB:  rd = $signed({ 24'b0, bytes[a[1:0]] } << 24) >>> 24;
            `FUNC3_LH:  rd = $signed({ 16'b0, halfwords[a[1]] } << 16) >>> 16;
            `FUNC3_LBU: rd = { 24'b0, bytes[a[1:0]] };
            `FUNC3_LHU: rd = { 16'b0, halfwords[a[1]] };
            default: rd = word; // lw
        endcase
    end

    initial $readmemh(`PROGRAM, RAM);

    always@(posedge clk) begin
        if(we) begin
            case (dmemctrl)
                `FUNC3_SB:
                begin
                    case (a[1:0])
                        2'b00: RAM[a[31:2]][7:0] = wd[7:0];
                        2'b01: RAM[a[31:2]][15:8] = wd[7:0];
                        2'b10: RAM[a[31:2]][23:16] = wd[7:0];
                        2'b11: RAM[a[31:2]][31:24] = wd[7:0];
                    endcase
                end

                `FUNC3_SH:
                begin
                    case (a[1])
                        2'b0: RAM[a[31:2]][15:0] = wd[15:0];
                        2'b1: RAM[a[31:2]][31:16] = wd[15:0];
                    endcase
                end

                default: RAM[a[31:2]] = wd; // sw
            endcase
        end
    end

endmodule

module imem(input[31:0] a,
            output[31:0] rd);

    reg[31:0] RAM[0:4095];

    initial $readmemh(`PROGRAM, RAM);

    assign rd = RAM[a[13:2]]; // word aligned

endmodule

module alu(input[3:0] func4, // { bit 30, func3 }
           input[31:0] in1, in2,
           output reg[31:0] res,
           output reg should_branch);

    wire[2:0] func3;
    assign func3 = func4[2:0];

    always @(*) begin
        casez (func4)
            `FUNC4_ADD : res = in1 + in2;
            `FUNC4_SUB : res = in1 - in2;
            `FUNC4_SLT : res = ($signed(in1) < $signed(in2)) ? 32'b1 : 32'b0;
            `FUNC4_SLTU: res = in1 < in2 ? 32'b1 : 32'b0;
            `FUNC4_XOR : res = in1 ^ in2;
            `FUNC4_OR  : res = in1 | in2;
            `FUNC4_SLL : res = in1 << in2[4:0];
            `FUNC4_SRL : res = in1 >> in2[4:0];
            `FUNC4_SRA : res = $signed(in1) >>> in2[4:0];
            `FUNC4_AND : res = in1 & in2;
            default: res = in1;
        endcase
    end

    always @(*) begin
        case (func3)
            `FUNC3_BEQ : should_branch = in1 == in2;
            `FUNC3_BNE : should_branch = in1 != in2;
            `FUNC3_BLT : should_branch = $signed(in1) < $signed(in2);
            `FUNC3_BGE : should_branch = $signed(in1) >= $signed(in2);
            `FUNC3_BLTU: should_branch = in1 < in2;
            `FUNC3_BGEU: should_branch = in1 >= in2;
            default: should_branch = 0;
        endcase
    end

endmodule

module control_unit(input[31:0] inst,
                    output reg[2:0] itype,
                    output reg[4:0] ra1, ra2, ra3,
                    output reg[3:0] aluctrl,
                    output reg[2:0] dmemctrl,
                    output reg alu_imm,
                    output reg branch,
                    output reg jal,
                    output reg jalr,
                    output reg auipc,
                    output reg mem_to_reg,
                    output reg mem_write,
                    output reg ebreak);

    wire[2:0] func3 = inst[14:12];
    wire[3:0] func4 = { inst[30], func3 };  // bit 30 + func3 field
    wire[4:0] opcode = inst[6:2]; // bottom 2 bits always b11

    wire[4:0] rs1, rs2, rd;
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign rd  = inst[11:7];

    always @(*) begin
        itype      = `TYPE_NONE;
        ra1        = 0;
        ra2        = 0;
        ra3        = 0;
        aluctrl    = `FUNC4_ADD;
        dmemctrl   = func3;
        alu_imm    = 0;
        branch     = 0;
        jal        = 0;
        jalr       = 0;
        auipc      = 0;
        mem_to_reg = 0;
        mem_write  = 0;
        ebreak     = 0;

        casez (opcode)
            5'b01101: // lui
            begin
                itype = `TYPE_U;
                ra3 = rd;
                alu_imm = 1;
            end

            5'b00101: // auipc
            begin
                itype = `TYPE_U;
                ra3 = rd;
                alu_imm = 1;
                auipc = 1;
            end

            5'b11011: // jal
            begin
                itype = `TYPE_J;
                ra3 = rd;
                jal = 1;
            end

            5'b11001: // jalr
            begin
                itype = `TYPE_I;
                ra1 = rs1;
                ra3 = rd;
                jalr = 1;
            end

            5'b11000: // branches
            begin
                itype = `TYPE_B;
                ra1 = rs1;
                ra2 = rs2;
                aluctrl = func4;
                branch = 1;

            end

            5'b00000: // loads
            begin
                itype = `TYPE_I;
                ra1 = rs1;
                ra3 = rd;
                alu_imm = 1;
                mem_to_reg = 1;
            end

            5'b01000: // stores
            begin
                itype = `TYPE_S;
                ra1 = rs1;
                ra2 = rs2;
                alu_imm = 1;
                mem_write = 1;
            end

            5'b00100: // arithmetic immediate
            begin
                itype = `TYPE_I;
                ra1 = rs1;
                ra3 = rd;
                if (func4[2:0] == 3'b101) begin // srli/srai
                    aluctrl = func4;
                end else begin
                    aluctrl = { 1'b0, func3 };
                end
                alu_imm = 1;
            end

            5'b01100: // arithmetic register
            begin
                itype = `TYPE_R;
                ra1 = rs1;
                ra2 = rs2;
                ra3 = rd;
                aluctrl = func4;
            end

            5'b11100: // ebreak
            begin
                ebreak = 1;
            end
        endcase
    end

endmodule

module immediate_decode(input[31:0] inst,
                        input[2:0] itype,
                        output reg[31:0] imm);

    always @(*) begin
        casez (itype)  // see unprivileged ISA, page 26 (bottom)
            `TYPE_I: imm = { {21{inst[31]}}, inst[30:20] };
            `TYPE_S: imm = { {21{inst[31]}}, inst[30:25], inst[11:7] };
            `TYPE_B: imm = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
            `TYPE_U: imm = { inst[31:12], 12'b0 };
            `TYPE_J: imm = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
            default: imm = 32'b0;
        endcase
    end

endmodule

module komplet(input clk, output ebreak);

    // pc
    wire[31:0] pc;
    wire[31:0] pc_addend; // either rs1 (jalr) or pc (jal, branches)
    wire[31:0] pc_plus4;  // address of the next instruction
    wire[31:0] pc_result; // pc calculated by redirection adder
    wire[31:0] pc_next;   // pc to be loaded with new tick, either pc_result or pc_plus4
    wire should_redirect;

    // control unit
    wire[31:0] inst;
    wire[2:0] itype;
    wire[4:0] ra1, ra2, ra3;
    wire[3:0] aluctrl;
    wire[2:0] dmemctrl;
    wire alu_imm;
    wire branch;
    wire jal;
    wire jalr;
    wire auipc;
    wire mem_to_reg;
    wire mem_write;

    // regfile
    wire[31:0] rs1, rs2;
    wire[31:0] reg_in;

    // alu
    wire[31:0] alu_in1;
    wire[31:0] alu_in2;
    wire[31:0] alu_result;
    wire should_branch;

    // dmem
    wire[31:0] dmem_out;

    // dmem / alu result
    wire[31:0] alu_dmem_out;

    // immediate
    wire[31:0] imm;

    // calculate redirection status
    assign should_redirect = (branch && should_branch) | jal | jalr;

    program_counter program_counter_u(
        .clk(clk),
        .pc_next(pc_next),
        .pc(pc) );

    imem imem_u(
        .a(pc),
        .rd(inst) );

    control_unit control_unit_u(
        .inst(inst),
        .itype(itype),
        .ra1(ra1), .ra2(ra2), .ra3(ra3),
        .aluctrl(aluctrl),
        .dmemctrl(dmemctrl),
        .alu_imm(alu_imm),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .auipc(auipc),
        .mem_to_reg(mem_to_reg),
        .mem_write(mem_write),
        .ebreak(ebreak) );

    immediate_decode immediate_decode_u(
        .inst(inst),
        .itype(itype),
        .imm(imm) );

    regfile regfile_u(
        .clk(clk),
        .ra1(ra1), .ra2(ra2), .ra3(ra3),
        .wd3(reg_in),
        .rs1(rs1), .rs2(rs2) );

    alu alu_u(
        .func4(aluctrl),
        .in1(alu_in1),
        .in2(alu_in2),
        .res(alu_result),
        .should_branch(should_branch) );

    dmem dmem_u(
        .clk(clk),
        .we(mem_write),
        .dmemctrl(dmemctrl),
        .a(alu_result),
        .wd(rs2),
        .rd(dmem_out) );

    plus4 plus4_u(
        .pc(pc),
        .pc_plus4(pc_plus4));

    add32 redirection_adder_u(
        .a(pc_addend),
        .b(imm),
        .out(pc_result) );

    mux2 pc_addend_mux_u(
        .select(jalr),
        .data0(pc),
        .data1(rs1),
        .out(pc_addend) );

    mux2 pc_next_mux_u(
        .select(should_redirect),
        .data0(pc_plus4),
        .data1(pc_result),
        .out(pc_next) );

    mux2 alu_in1_mux_u(
        .select(auipc),
        .data0(rs1),
        .data1(pc),
        .out(alu_in1) );

    mux2 alu_in2_mux_u(
        .select(alu_imm),
        .data0(rs2),
        .data1(imm),
        .out(alu_in2) );

    mux2 mem_to_reg_mux_u(
        .select(mem_to_reg),
        .data0(alu_result),
        .data1(dmem_out),
        .out(alu_dmem_out) );

    mux2 link_mux_u(
        .select(jal || jalr),
        .data0(alu_dmem_out),
        .data1(pc_plus4),
        .out(reg_in) );

endmodule
