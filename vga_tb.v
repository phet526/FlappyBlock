`timescale 1ns / 1ps

module vga_tb;

    // ==========================================
    // 1. ประกาศตัวแปร
    // ==========================================
    reg clk;
    reg rst;

    // Outputs จาก Module VGA
    wire hsync;
    wire vsync;
    wire video_on;
    wire [9:0] x;
    wire [9:0] y;
    wire p_tick;

    // ==========================================
    // 2. เชื่อมต่อกับ vga_display (Instantiate)
    // ==========================================
    vga_display uut (
        .clk(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .x(x),
        .y(y),
        .p_tick(p_tick)
    );

    // ==========================================
    // 3. สร้าง Clock 100MHz (สำคัญมาก!)
    // ==========================================
    initial begin
        clk = 0;
        // สลับค่าทุก 5ns -> คาบ 10ns -> 100MHz
        forever #5 clk = ~clk; 
    end

    // ==========================================
    // 4. ส่วนตรวจสอบผล (Monitor) [NEW!]
    // ==========================================
    // ส่วนนี้จะช่วยพิมพ์ข้อความบอกเมื่อเจอ V-Sync ตกลงมา
    initial begin
        // รอให้พ้นช่วง Reset ก่อน
        #200; 
        
        // วนลูปรอจับสัญญาณ V-Sync ขาลง (negedge)
        forever begin
            @(negedge vsync); 
            $display("Time: %t | V-Sync Detected! (Frame End)", $time);
        end
    end

    // ==========================================
    // 5. ลำดับการทดสอบ (Stimulus)
    // ==========================================
    initial begin
        // เริ่มต้น: ตั้งค่าเริ่มต้น และกด Reset
        $display("Simulation Start...");
        rst = 1; 
        
        // รอ 100ns แล้วปล่อย Reset
        #100;
        rst = 0;
        $display("Reset Released. VGA Running...");

        // รันยาวๆ ประมาณ 35ms (เพื่อให้เห็น V-Sync อย่างน้อย 2 รอบ)
        // 1 ms = 1,000,000 ns
        #35000000; 

        $display("Simulation Timeout. Finishing...");
        $finish;
    end

endmodule