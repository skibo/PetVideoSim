`timescale 1ns / 1ps
////////////////
//
// dynamicpet.v
//
//  Incomplete and crude simulation of Commodore PET 2001N (dynamic board)
//  video logic.
//
//  This simulation is derived from the PET schematic found at:
//  http://www.zimmers.net/anonftp/pub/cbm/schematics/computers/pet/2001N/320349.pdf
//
//  Except for signals and buses that are named on the schematic, node
//  names correspond to the chip name and pin number that drives the node.
//
////////////////

//
// Copyright (c) 2015, 2017, 2022-2023  Thomas Skibo. <ThomasSkibo@yahoo.com>
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

// Top module.
module dynamicpet;

    // 16 Mhz clock generation.
    reg     clk16mhz;
    initial clk16mhz = 1'b0;
    always #31.25 clk16mhz = ~clk16mhz;

    // External signals
    reg [11:0]  BA;     // address from schematic page 1
    wire [7:0]  BD;     // data to/from schematic page 1
    reg [7:0]   wrdata; // for simulating video RAM writes.
    reg         sel8;   // signal from page 1 address select video ram
    reg         b_rw; // "buffered r/w" from page 1.
    wire        b_rw_ = !b_rw;
    reg         graphic; // controls character set, from VIA.CA2, page 3
    initial begin
        BA = 12'bxx_xxxx_xxxx;
        sel8 = 0;
        b_rw = 1;
        graphic = 0;
    end

    // Drive BD from processor board.
    assign BD = (sel8 && !b_rw) ? wrdata : 8'hZZ;

    wire	clk1;
    wire	phi0 = clk1, phi1 = !phi0, phi2 = phi0;

    // Task to emulate cpu writing video memory.
    task wrmem(input [11:0] a,
               input [7:0] d);
        begin
            @(negedge phi2);
            BA <= a;
            wrdata = d;
            sel8 <= 1;

            @(negedge phi2);
            b_rw <= 0;

            @(negedge phi2);
            BA <= 12'bxxxx_xxxx_xxxx;
            sel8 <= 0;
            b_rw <= 1;

            @(posedge phi2);
        end
    endtask

    // Task to emulate cpu reading video memory.  Data ignored.
    task rdmem(input [11:0] a);
        begin
            @(negedge phi2);
            BA <= a;
            sel8 <= 1;

            @(negedge phi2);
            BA <= 12'bxxxx_xxxx_xxxx;
            sel8 <= 0;

            @(posedge phi2);
        end
    endtask

    initial begin:clrscrn
        integer i;

        repeat (3000) @(posedge phi0);

        // Emulate cpu clearing screen and writing opening banner.
        for (i = 0; i < 1024; i = i + 1)
            wrmem(12'd000 + i, 8'h20);

        // Time these writes to see snow effect.
        repeat (1000) @(posedge phi0);

        wrmem(12'h000, 8'h2a);  // *
        wrmem(12'h001, 8'h2a);  // *
        wrmem(12'h002, 8'h2a);  // *
        wrmem(12'h004, 8'h03);  // C
        wrmem(12'h005, 8'h0f);  // O
        wrmem(12'h006, 8'h0d);  // M
        wrmem(12'h007, 8'h0d);  // M
        wrmem(12'h008, 8'h0f);  // O
        wrmem(12'h009, 8'h04);  // D
        wrmem(12'h00a, 8'h0f);  // O
        wrmem(12'h00b, 8'h12);  // R
        wrmem(12'h00c, 8'h05);  // E
        wrmem(12'h00e, 8'h02);  // B
        wrmem(12'h00f, 8'h01);  // A
        wrmem(12'h010, 8'h13);  // S
        wrmem(12'h011, 8'h09);  // I
        wrmem(12'h012, 8'h03);  // C
        wrmem(12'h014, 8'h2a);  // *
        wrmem(12'h015, 8'h2a);  // *
        wrmem(12'h016, 8'h2a);  // *

        // This read creates snow effect too.
        repeat (100) @(posedge phi0);
        rdmem(12'h016);
    end

    // Nets that are otherwise unnamed are named after their driver (chip/pin).

    // Page 6

    // clock is output of G1 pin 6 (AND)
    wire        tp8 = 1'b1;
    wire        g1_6 = clk16mhz && tp8;
    wire        tp7 = 1'b1, init_ = tp7;
    wire        clk8;
    wire	B02H, B02G, B02F, B02E, B02D, B02C, B02B, B02A;

    // "8 phases of clk1"
    c74164 h3(.a(clk1),
              .b(1'b1),
              .cl_(init_),
              .Q({B02H, B02G, B02F, B02E, B02D, B02C, B02B, B02A}),
              .clk(g1_6)
              );

    c74191 g5(.en_(1'b0),
              .dnup(1'b0),
              .a(1'b0),
              .b(1'b0),
              .c(1'b0),
              .d(1'b0),
              .ld_(init_),
              .clk(g1_6),
              .qa(clk8),
              .qb(),
              .qc(),
              .qd(clk1),
              .rc(),
              .maxmin()
              );

    // Inverters at H2
    wire        B02A_ = !B02A;
    wire        B02B_ = !B02B;
    wire        B02F_ = !B02F;
    wire        B02G_ = !B02G;

    // "Refresh Address Counter"
    wire        RA1, RA1_, RA2, RA3, RA4, RA5, RA6, RA7, RA9;
    jk h6a(.q(RA1),
           .q_(RA1_),
           .j(init_),
           .k(init_),
           .c_(init_),
           .clk(B02A_)
        );

    wire        i1_10 = !init_;
    c7493 h9(.qa(RA2),
             .qb(RA3),
             .qc(RA4),
             .qd(RA5),
             .r01(i1_10),
             .r02(i1_10),
             .cka(RA1),
             .ckb(RA2)
        );

    wire        h6_6;
    jk h6b(.q(RA6),
           .q_(h6_6),
           .j(init_),
           .k(init_),
           .c_(init_),
           .clk(RA5)
        );

    wire        f1_8 = RA1 && RA3;   // AND at F1
    wire        h10_6 = RA4 && RA6;  // AND at H10
    wire        h10_3 = RA5 && h6_6; // AND at H10

    wire        horz_disp_on, horz_disp_off;
    wire        load_sr, load_sr_;
    wire        pullup_1 = 1'b1;
    h7474 g9a(.q(load_sr),
              .q_(load_sr_),
              .d(init_),
              .pre_(pullup_1),
              .clr_(B02B),
              .clk(B02A_)
           );

    jk h7b(.q(horz_disp_on),
           .q_(horz_disp_off),
           .j(h10_6),
           .k(h10_3),
           .c_(init_),
           .clk(load_sr_)
           );

    wire        horz_drive;
    jk h7a(.q(),
           .q_(horz_drive),
           .j(horz_disp_on),
           .k(horz_disp_off),
           .c_(init_),
           .clk(f1_8)
        );

    wire        video_latch = B02F_ && B02H;	// AND at G1 pin 8

    wire        h8_2, h8_3, h8_5, h8_6;
    wire        next, next_;			// from page 7
    jk h8a(.q(h8_3),
           .q_(h8_2),
           .j(h8_6),
           .k(h8_5),
           .c_(init_),
           .clk(next)
        );

    jk h8b(.q(h8_5),
           .q_(h8_6),
           .j(h8_3),
           .k(h8_2),
           .c_(init_),
           .clk(next)
        );

    wire        vert_drive = !(h8_6 && h8_2);	// NAND at G10 pin 11
    wire        video_on = h8_3 && h8_5;	// AND at H10 pin 11

    // Page 7
    wire        reload_;	// from page 8
    wire        h5_11 = !reload_ || !next_;	// NAND at H5
    wire        tv_sel = !BA[11] && sel8;	// AND at F1 pin 6
    wire        tp2 = 1'b1;
    wire        tv_read_ = !(tp2 && b_rw && tv_sel);	// NAND at AT pin 8
    wire        a5_12 = !(tv_sel && b_rw_ && phi2);	// NAND at A5 pin 12

    wire        g6_3;
    jk g6a(.q(g6_3),
           .q_(),
           .j(init_),
           .k(init_),
           .c_(horz_disp_on),
           .clk(RA1_)
        );

    wire        i1_6 = !video_on;	// Inverter I1 pin 6
    wire        pullup_2 = 1'b1;
    wire        f2_12, f2_2, f2_9, f2_5, f4_12, f4_2, f4_9, f4_5;
    wire        g3_12, g3_19, g3_15, g3_16, g3_5, g3_6, g3_2, g3_9;
    wire [9:0]  vidaddr = { f2_12, f2_2, f2_9, f2_5, f4_12,
                          f4_2, f4_9, f4_5, g6_3, RA1_ }; // not in schematic
    wire [9:0]  lineaddr = {g3_9, g3_2, g3_6, g3_5, g3_16,
                            g3_15, g3_19, g3_12, 2'b00}; // not in schematic
    wire        t20_lines_ = !(pullup_2 && f2_5 && i1_6 && RA9); // 4 NAND G2a
    wire        g2_8 = !(g3_9 && g3_2 && g3_6 && g3_5); // 4-input NAND at G2b
    wire        i1_8 = !g2_8;
    wire        t200_lines_ = !(i1_8 && g3_19);
    wire        h5_8 = !t20_lines_ || !t200_lines_;
    wire        g1_3 = h5_8 && horz_disp_off;

    c74373 g3(.q({g3_19, g3_16, g3_15, g3_12, g3_9, g3_6, g3_5, g3_2}),
              .d({f4_9, f4_12, f4_2, f4_5, f2_12, f2_9, f2_5, f2_2}),
              .oc_(1'b0),
              .g(h5_11)
           );

    c74177 f4(.qa(f4_5),
              .qb(f4_9),
              .qc(f4_2),
              .qd(f4_12),
              .a(g3_12),
              .b(g3_19),
              .c(g3_15),
              .d(g3_16),
              .load_(horz_disp_on),
              .clr_(next_),		// XXX: schematic calls this CLK (?)
              .clk1(g6_3),
              .clk2(f4_5)
          );

    c74177 f2(.qa(f2_5),
              .qb(f2_9),
              .qc(f2_2),
              .qd(f2_12),
              .a(g3_5),
              .b(g3_6),
              .c(g3_2),
              .d(g3_9),
              .load_(horz_disp_on),
              .clr_(next_),		// XXX: schematic calls this CLK (?)
              .clk1(f4_12),
              .clk2(f2_5)
           );

    wire        f6_9, tv_ram_rw;
    wire [9:0]  SA;
    c74157 f6(.Y({SA[0], f6_9, tv_ram_rw, SA[1]}),
              .A({RA1_, 1'b1, 1'b1, g6_3}),
              .B({BA[0], 1'b1, a5_12, BA[1]}),
              .S(clk1),
              .G_(1'b0)
           );

    c74157 f5(.Y({SA[4], SA[2], SA[3], SA[5]}),
              .A({f4_2, f4_5, f4_9, f4_12}),
              .B({BA[4], BA[2], BA[3], BA[5]}),
              .S(clk1),
              .G_(1'b0)
           );

    c74157 f3(.Y({SA[7], SA[9], SA[8], SA[6]}),
              .A({f2_9, f2_12, f2_2, f2_5}),
              .B({BA[7], BA[9], BA[8], BA[6]}),
              .S(clk1),
              .G_(1'b0)
           );

    h7474 g8b(.q(next),
              .q_(next_),
              .d(g1_3),
              .pre_(pullup_1),
              .clr_(B02H),
              .clk(video_latch)
           );

    // Page 8
    wire        h11_8;
    c7493 h11(.qa(),
              .qb(RA7),
              .qc(h11_8),
              .qd(RA9),
              .cka(1'b0),
              .ckb(horz_disp_on),
              .r01(next),
              .r02(next)
           );

    assign reload_ = !(horz_disp_on && RA7 && h11_8 && RA9); // NAND G11 pin 8

    // Inverse video register.
    wire        g9_9, g9_8;
    wire [7:0]  SD, LSD;
    h7474 g9b(.q(g9_9),
              .q_(g9_8),
              .d(LSD[7]),
              .pre_(pullup_1),
              .clr_(init_),
              .clk(load_sr)
           );

    // Video output shift register.
    wire        e11_9, e11_7;
    wire [7:0]  romdat;
    c74165 e11(.q(e11_9),
               .q_(e11_7),
               .D(romdat),
               .ld_(load_sr_),
               .clk_inh(1'b0),
               .ser(romdat[7]),
               .clk(clk8)
            );

    // Character ROM.
    c6316 f10(.D(romdat),
              .A({graphic, LSD[6:0], RA9, h11_8, RA7})
           );

    // Video data latch. XXX: not pin-for-pin with schematic.
    c74373 f9(.q(LSD),
              .d(SD),
              .oc_(1'b0),
              .g(video_latch)
           );

    // Video RAMs
    c6114 f8(.D(SD[3:0]),
             .A(SA),
             .RW_(tv_ram_rw),
             .CS_(1'b0)
          );

    c6114 f7(.D(SD[7:4]),
             .A(SA),
             .RW_(tv_ram_rw),
             .CS_(1'b0)
          );

    // Bi-directional buffers
    h74244 e8a(.Y(BD[3:0]),
               .A(SD[3:0]),
               .G_(tv_read_)
           );
    h74244 e8b(.Y(SD[3:0]),
               .A(BD[3:0]),
               .G_(tv_ram_rw)
           );
    h74244 e7a(.Y(BD[7:4]),
               .A(SD[7:4]),
               .G_(tv_read_)
           );
    h74244 e7b(.Y(SD[7:4]),
               .A(BD[7:4]),
               .G_(tv_ram_rw)
           );

    // Video output
    wire       g10_6 = !(g9_9 && e11_9);	// NAND at G9 pin 6
    wire       g10_8 = !(g9_8 && e11_7);	// NAND at G9 pin 8
    wire       h10_8 = g10_6 && g10_8;		// AND at H10 pin 8
    wire       video = !(h10_8 && video_on && horz_disp_on); // G11 pin 6

endmodule // dynamicpet
