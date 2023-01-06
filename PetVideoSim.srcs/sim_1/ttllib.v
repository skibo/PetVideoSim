`timescale 1ns / 1ps
////////////////
//
// ttllib.v
//
//	Some quick and dirty 74xx TTL models for PET Video simulations.
//	The whole simulation is a hack and these models shouldn't be relied
//	upon as accurate.
//
////////////////

//
// Copyright (c) 2015, 2017, 2022  Thomas Skibo. <ThomasSkibo@yahoo.com>
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//

// Half a 74107
module jk(output reg q,
          output q_,
          input  j,
          input  k,
          input  c_,
          input  clk);

    initial
        q = 0;

    always @(negedge c_)
        q <= 1'b0;

    always @(negedge clk)
        if (c_)
            case ({j,k})
                2'b00: ;
                2'b01: q <= 0;
                2'b10: q <= 1'b1;
                2'b11: q <= ~q;
            endcase

    assign q_ = ~q;
endmodule

// 7493 4-bit binary counters
module c7493(output reg qa, // pin 12
             output reg qb, // pin 9
             output reg qc, // pin 8
             output reg qd, // pin 11
             input r01,     // pin 2
             input r02,     // pin 3
             input cka,     // pin 14
             input ckb);    // pin 1

    initial begin
        qa = 0;
        qb = 0;
        qc = 0;
        qd = 0;
    end

    always @(*)
        if (r01 && r02)
            {qd, qc, qb, qa} = 4'b0000;

    always @(negedge cka)
        if (!r01 || !r02)
            qa <= ~qa;

    always @(negedge ckb)
        if (!r01 || !r02)
            {qd, qc, qb} <= {qd, qc, qb} + 1'b1;

endmodule // c7493

// 74100 latches
module l74100(output reg q1,
              output reg q2,
              output reg q3,
              output reg q4,
              output reg q5,
              output reg q6,
              output reg q7,
              output reg q8,
              input      d1,
              input      d2,
              input      d3,
              input      d4,
              input      d5,
              input      d6,
              input      d7,
              input      d8,
              input      g1,
              input      g2);

    initial begin
        q1 = 1'b0;
        q2 = 1'b0;
        q3 = 1'b0;
        q4 = 1'b0;
        q5 = 1'b0;
        q6 = 1'b0;
        q7 = 1'b0;
        q8 = 1'b0;
    end

    always @(*)
        if (g1)
            {q4, q3, q2, q1} = {d4, d3, d2, d1};

    always @(*)
        if (g2)
            {q8, q7, q6, q5} = {d8, d7, d6, d5};

endmodule // l74100

// 74177 presettable decade and binary counters/latches
module c74177(output reg qa,    // pin 5
              output reg qb,    // pin 9
              output reg qc,    // pin 2
              output reg qd,    // pin 12
              input      a,     // pin 4
              input      b,     // pin 10
              input      c,     // pin 3
              input      d,     // pin 11
              input      load_, // pin 1
              input      clr_,  // pin 13
              input      clk1,  // pin 8
              input      clk2); // pin 6

    initial begin
        qa = 1'b0;
        qb = 1'b0;
        qc = 1'b0;
        qd = 1'b0;
    end

    always @(negedge load_)
        if (!load_ && clr_)
            {qa, qb, qc, qd} <= {a, b, c, d};

    always @(negedge clr_)
        if (!clr_)
            {qa, qb, qc, qd} <= 4'b0000;

    always @(negedge clk1)
        if (load_ && clr_)
            qa <= ~qa;

    always @(negedge clk2)
        if (load_ && clr_)
            {qd, qc, qb} <= {qd, qc, qb} + 1'b1;

endmodule // c74177

// Half a 7474 D-type flip flop
module h7474(output reg q,
             output q_,
             input d,
             input pre_,
             input clr_,
             input clk);

    always @(negedge pre_ or negedge clr_ or posedge clk)
        if (!pre_ && !clr_)
            q <= 1'bX;
        else if (!pre_)
            q <= 1'b1;
        else if (!clr_)
            q <= 1'b0;
        else
            q <= d;

    assign q_ = ~q;

endmodule // h7474

// Character ROM (not including chip selects 1-5).
module c6540(output reg [7:0]   D,
             input [10:0]       A,
             input              clk);

    reg [7:0]   mem[2047:0];
    initial $readmemh("charrom.mem", mem);

    always @(posedge clk)
        D <= mem[A];

endmodule // c6540

// Character ROM (not including chip selects 1-3).
module c6316(output reg [7:0]   D,
             input [10:0] A);

    reg [7:0]   mem[2047:0];
    initial $readmemh("charrom.mem", mem);

    always @(A)
        D = mem[A];

endmodule // c316

// 74157 quad 2-line to 1-line data selectors/multiplexors.
module c74157(output [3:0] Y,
              input [3:0] A,
              input [3:0] B,
              input       S,
              input       G_);

    assign Y = (A & {4{!S && !G_}}) | (B & {4{S && !G_}});

endmodule // c74157

// 74164 8-bit shift register.
module c74164(input 	       a,
              input            b,
              output reg [7:0] Q, // HGFEDCBA on data sheet
              input            clk,
              input            cl_);

    always @(cl_)
        if (!cl_)
            Q = 8'd0;

    always @(posedge clk)
        Q <= { Q[6:0], a && b };

endmodule // c74164

// 74165 8-bit shift register.
module c74165(output      q,
              output      q_,
              input [7:0] D, // HGFEDCBA on data sheet
              input       ld_,
              input       clk_inh,
              input       ser,
              input       clk);

    reg [7:0]   sr;

    always @(negedge ld_ or D)
        if (!ld_)
            sr <= D;

    always @(posedge clk)
        if (ld_ && !clk_inh)
            sr <= {sr[6:0], ser};

    assign q = sr[7];
    assign q_ = ~sr[7];

endmodule // c74165

// Half a 74LS244 octal 3-state buffer
module h74244(output [3:0] Y,
              input [3:0]  A,
              input        G_);
    assign Y = G_ ? 4'bZZZZ : A;
endmodule // h74244

// 6550 * 2, Video RAMs
module c6550s(output [7:0] DB,
              input [9:0]  A,
              input        RW,
              input        clk);

    reg [7:0]   mem[1023:0];

    always @(posedge clk)
        if (!RW)
            mem[A] <= DB;

    assign DB = RW ? mem[A] : 8'hZZ;

endmodule // c6550s

// 6114 1Kx4 RAM
module c6114(output [3:0] D,
             input [9:0] A,
             input RW_,
             input CS_
          );

    reg [3:0]      mem[1023:0];

    always @(*)
        if (!CS_ && !RW_)
            mem[A] <= D;

    assign D = (!CS_ && RW_) ? mem[A] : 8'hZZ;

endmodule // c6114


// 74191 4-bit up/down counter
module c74191(input en_,
              input dnup,
              input a,
              input b,
              input c,
              input d,
              input ld_,
              input clk,
              output reg qa,
              output reg qb,
              output reg qc,
              output reg qd,
              output rc, // XXX: unimplemented
              output maxmin // XXX: unimplemented
              );

    initial
        {qd, qc, qb, qa} = 4'b0000;

    always @(ld_)
        if (!ld_)
            {qd, qc, qb, qa} = {d, c, b, a};

    always @(posedge clk)
        if (!en_) begin
            if (!dnup)
                {qd, qc, qb, qa} <= {qd, qc, qb, qa} + 1'b1;
            else
                {qd, qc, qb, qa} <= {qd, qc, qb, qa} - 1'b1;
        end

endmodule // c74191

module c74373(output [7:0] q,
              input [7:0] d,
              input       oc_,
              input       g);

    reg [7:0]             Qo;
    initial Qo = 8'd0;

    always @(*)
        if (g)
            Qo = d;

    assign q = oc_ ? 8'hZZ : Qo;

endmodule // 74373
