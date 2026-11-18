module test_submodules;
    test_mux2 u_mux2();
    test_add32 u_add32();
    test_regfile u_regfile();

    initial begin
        u_mux2.run();
        $display("-------------------------");
        u_add32.run();
        $display("-------------------------");
        u_regfile.run();

        $finish(2);
    end
endmodule

module test_processor;
    test_komplet test_komplet_u();

    initial begin
        $dumpfile(`DUMP);
        $dumpvars;
        test_komplet_u.run();
        $finish(2);
    end
endmodule

module test_mux2;
    reg select = 0;
  
    wire[31:0] data0 = 32'hffffffff;
    wire[31:0] data1 = 32'hf0f0f0f0;
    wire[31:0] out;
  
    mux2 m0(select, data0, data1, out);
  
    task automatic run;
    begin
        $display("Testing mux2");
        $monitor("At time %t, out = %h (%0b), select = %d",
                 $time, out, out, select);
        # 10 select = 0;
        # 10 select = 1;
        # 10;
    end
    endtask
  
endmodule

module test_add32;
    reg[31:0] a;
    reg[31:0] b;
    wire[31:0] out;
  
    add32 adder(
        .a(a),
        .b(b),
        .out(out) );
    
    task automatic run;
    begin
        $display("Testing add32");
        $monitor("At time %t, a = %d, b = %d, out = %d",
                 $time, a, b, out);
        # 10 a = 3298; b = 33209;
        # 10 a = 2093209; b = 3209;
        # 10 a = 2309; b = 3209;
        # 10 a = 320932; b = 32090932;
    end
    endtask
  
endmodule

module test_regfile;
    reg clk = 0;
    reg[4:0] a1, a2, a3;
    reg[31:0] wd3;
    wire[31:0] rd1, rd2;
  
    regfile regfile0(
        .clk(clk),
        .ra1(a1),
        .ra2(a2),
        .ra3(a3),
        .wd3(wd3),
        .rs1(rd1),
        .rs2(rd2) );
  
    always #5 clk = ~clk;
    
    task automatic run;
    begin
        $display("Testing regfile");
        $monitor("At time %t,\na1 = %d, a2 = %d, a3 = %d\nwd3 = %d, rd1 = %d, rd2 = %d",
                 $time, a1, a2, a3, wd3, rd1, rd2);
        # 1 wd3 <= 10; a3 <= 1; a1 <= 1; a2 <= 0;
        # 100;
    end
    endtask
  
endmodule

module test_komplet;

    reg clk = 0;
    wire ebreak;

    always #1 clk = ~clk;

    komplet komplet_u(
        .clk(clk),
        .ebreak(ebreak) );

    wire[31:0] _ra  = komplet_u.regfile_u.file[1];
    wire[31:0] _sp  = komplet_u.regfile_u.file[2];
    wire[31:0] _gp  = komplet_u.regfile_u.file[3];
    wire[31:0] _tp  = komplet_u.regfile_u.file[4];
    wire[31:0] _t0  = komplet_u.regfile_u.file[5];
    wire[31:0] _t1  = komplet_u.regfile_u.file[6];
    wire[31:0] _t2  = komplet_u.regfile_u.file[7];
    wire[31:0] _s0  = komplet_u.regfile_u.file[8];
    wire[31:0] _s1  = komplet_u.regfile_u.file[9];
    wire[31:0] _a0  = komplet_u.regfile_u.file[10];
    wire[31:0] _a1  = komplet_u.regfile_u.file[11];
    wire[31:0] _a2  = komplet_u.regfile_u.file[12];
    wire[31:0] _a3  = komplet_u.regfile_u.file[13];
    wire[31:0] _a4  = komplet_u.regfile_u.file[14];
    wire[31:0] _a5  = komplet_u.regfile_u.file[15];
    wire[31:0] _a6  = komplet_u.regfile_u.file[16];
    wire[31:0] _a7  = komplet_u.regfile_u.file[17];
    wire[31:0] _s2  = komplet_u.regfile_u.file[18];
    wire[31:0] _s3  = komplet_u.regfile_u.file[19];
    wire[31:0] _s4  = komplet_u.regfile_u.file[20];
    wire[31:0] _s5  = komplet_u.regfile_u.file[21];
    wire[31:0] _s6  = komplet_u.regfile_u.file[22];
    wire[31:0] _s7  = komplet_u.regfile_u.file[23];
    wire[31:0] _s8  = komplet_u.regfile_u.file[24];
    wire[31:0] _s9  = komplet_u.regfile_u.file[25];
    wire[31:0] _s10 = komplet_u.regfile_u.file[26];
    wire[31:0] _s11 = komplet_u.regfile_u.file[27];
    wire[31:0] _t3  = komplet_u.regfile_u.file[28];
    wire[31:0] _t4  = komplet_u.regfile_u.file[29];
    wire[31:0] _t5  = komplet_u.regfile_u.file[30];
    wire[31:0] _t6  = komplet_u.regfile_u.file[31];

    always @(posedge ebreak) begin
        # 1;
        $display("gp: %d (%b)", _gp, _gp);
        $display("a0: %d (%b)", _a0, _a0);
        $display("a1: %d (%b)", _a1, _a1);
        $display("a7: %d (%b)", _a7, _a7);
        if ((_gp == 1) && (_a7 == 93) && (_a0 == 0)) begin
            $display("PASS");
        end
        $finish(2);
    end

    task automatic run;
    begin
        #10000000;
    end
    endtask

endmodule
