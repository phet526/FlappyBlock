`timescale 1ns / 1ps
module seg7_control(
    input clk,
    input [13:0] number, // คะแนน
    output reg [3:0] an, // เลือกหลัก (Active Low)
    output reg [6:0] seg // ไฟแต่ละขีด (Active Low)
    );

    reg [3:0] digit_val;
    reg [19:0] refresh_counter;
    wire [1:0] digit_sel = refresh_counter[19:18]; // ตัวนับจังหวะสลับหลอดไฟ

    always @(posedge clk) refresh_counter <= refresh_counter + 1;

    // --- ส่วนเลือกหลักที่จะแสดงผล ---
    integer val;
    always @(*) begin
        case(digit_sel)
            // หลักหน่วย (ขวาสุด) -> เปิดไฟ (1110)
            2'b00: begin an = 4'b1110; val = number % 10; end      
            
            // หลักสิบ (รองขวา) -> เปิดไฟ (1101)
            2'b01: begin an = 4'b1101; val = (number / 10) % 10; end 
            
            // หลักร้อย และ หลักพัน -> ปิดไฟทิ้งเลย (1111)
            // (1 คือดับ, 0 คือติด สำหรับ Common Anode)
            default: begin an = 4'b1111; val = 0; end 
        endcase
    end

    // --- ส่วนแปลงเลข 0-9 เป็นไฟ a-g ---
    always @(*) begin
        case(val)
            0: seg = 7'b1000000; // 0
            1: seg = 7'b1111001; // 1
            2: seg = 7'b0100100; // 2
            3: seg = 7'b0110000; // 3
            4: seg = 7'b0011001; // 4
            5: seg = 7'b0010010; // 5
            6: seg = 7'b0000010; // 6
            7: seg = 7'b1111000; // 7
            8: seg = 7'b0000000; // 8
            9: seg = 7'b0010000; // 9
            default: seg = 7'b1111111; // ดับหมด
        endcase
    end
endmodule