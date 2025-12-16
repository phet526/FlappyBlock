`timescale 1ns / 1ps
module top(
    input clk,          // Clock 100MHz
    input btnC,         // ปุ่มกลาง = กระโดด (Jump)
    input btnL,         // [NEW] ปุ่มซ้าย = เริ่มเกม/รีสตาร์ท (Start)
    input sw0,          // สวิตช์ 0 = รีเซ็ตบอร์ด (Reset)
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output Hsync,
    output Vsync,
    output [6:0] seg,   // 7-segment cathodes
    output [3:0] an     // 7-segment anodes
    );

    wire clean_jump;    // สัญญาณกระโดดที่ Debounce แล้ว
    wire clean_start;   // [NEW] สัญญาณเริ่มเกมที่ Debounce แล้ว
    
    wire video_on;
    wire [9:0] x, y;
    wire [11:0] rgb_out;
    wire [13:0] score;
    wire p_tick;

    // 1. Instantiate Debouncers
    // ตัวที่ 1: สำหรับปุ่มกระโดด (btnC)
    debounce db_jump (
        .clk(clk),
        .btn_in(btnC),
        .btn_out(clean_jump)
    );
    
    // [NEW] ตัวที่ 2: สำหรับปุ่มเริ่มเกม (btnL)
    debounce db_start (
        .clk(clk),
        .btn_in(btnL),
        .btn_out(clean_start)
    );

    // 2. Instantiate VGA Controller
    vga_display vga_inst (
        .clk(clk),
        .rst(sw0),
        .hsync(Hsync),
        .vsync(Vsync),
        .video_on(video_on),
        .x(x),
        .y(y),
        .p_tick(p_tick)
    );

    // 3. Instantiate Game Engine
    game_engine game_inst (
        .clk(clk),          
        .rst(sw0),
        .jump_btn(clean_jump),   // เชื่อมปุ่มกระโดด
        .start_btn(clean_start), // [NEW] เชื่อมปุ่มเริ่มเกม
        .video_on(video_on),
        .pixel_x(x),
        .pixel_y(y),
        .rgb(rgb_out),
        .score(score)
    );

    // 4. Instantiate 7-Segment Display
    seg7_control seg_inst (
        .clk(clk),
        .number(score),
        .an(an),
        .seg(seg)
    );

    // เชื่อมสัญญาณสีออก VGA Port
    assign vgaRed   = rgb_out[11:8];
    assign vgaGreen = rgb_out[7:4];
    assign vgaBlue  = rgb_out[3:0];

endmodule