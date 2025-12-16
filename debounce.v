`timescale 1ns / 1ps

module debounce(
    input clk,          // 100MHz clock
    input btn_in,       // ปุ่มกดจริง
    output reg btn_out  // สัญญาณที่กรองแล้ว (Pulse 1 ครั้ง)
    );

    reg [19:0] count;
    reg btn_prev;
    reg btn_stable;

    always @(posedge clk) begin
        // ถ้าสัญญาณเปลี่ยน ให้เริ่มนับใหม่
        if (btn_in != btn_stable) begin
            count <= count + 1;
            // ถ้านิ่งนานพอ (ประมาณ 10ms) ให้ยอมรับค่าใหม่
            if (count == 20'd1_000_000) begin
                btn_stable <= btn_in;
                count <= 0;
            end
        end else begin
            count <= 0;
        end
        
        // สร้างสัญญาณ Pulse เพียง 1 clock cycle เมื่อกดปุ่ม
        btn_prev <= btn_stable;
        btn_out <= (btn_stable == 1'b1 && btn_prev == 1'b0) ? 1'b1 : 1'b0;
    end
endmodule