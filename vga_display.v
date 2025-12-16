`timescale 1ns / 1ps
module vga_display(
    input clk,              // 100MHz
    input rst,
    output hsync,
    output vsync,
    output video_on,
    output [9:0] x,         // พิกัด X ส่งไปให้ Game Engine
    output [9:0] y,         // พิกัด Y ส่งไปให้ Game Engine
    output p_tick           // Pixel Tick 25MHz
    );

    // VGA Standard 640x480 Parameters
    parameter HD = 640, HF = 16, HB = 48, HR = 96;
    parameter VD = 480, VF = 10, VB = 33, VR = 2;
    
    // --- ส่วนที่แก้ไข (Clock Divider) ---
    // เพิ่ม Reset เพื่อให้ Simulation รู้จักค่าเริ่มต้น (แก้เส้นแดง)
    reg [1:0] clk_div;
    always @(posedge clk) begin
        if (rst)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1;
    end
    // --------------------------------

    assign p_tick = (clk_div == 0); // 25MHz Tick

    // Counters
    reg [9:0] h_count_reg, h_count_next;
    reg [9:0] v_count_reg, v_count_next;

    always @(posedge clk) begin
        if (rst) begin
            h_count_reg <= 0;
            v_count_reg <= 0;
        end else if (p_tick) begin
            h_count_reg <= h_count_next;
            v_count_reg <= v_count_next;
        end
    end

    // Next State Logic
    always @(*) begin
        h_count_next = h_count_reg;
        v_count_next = v_count_reg;
        if (h_count_reg == (HD+HF+HB+HR-1)) begin
            h_count_next = 0;
            if (v_count_reg == (VD+VF+VB+VR-1))
                v_count_next = 0;
            else
                v_count_next = v_count_reg + 1;
        end else begin
            h_count_next = h_count_reg + 1;
        end
    end

    // Outputs
    assign hsync = ~(h_count_reg >= (HD+HF) && h_count_reg < (HD+HF+HR));
    assign vsync = ~(v_count_reg >= (VD+VF) && v_count_reg < (VD+VF+VR));
    assign video_on = (h_count_reg < HD) && (v_count_reg < VD);
    assign x = h_count_reg;
    assign y = v_count_reg;

endmodule