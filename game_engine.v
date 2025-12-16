`timescale 1ns / 1ps
module game_engine(
    input clk,              
    input rst,              
    input jump_btn,         
    input start_btn,        
    input video_on,         
    input [9:0] pixel_x,    
    input [9:0] pixel_y,    
    output reg [11:0] rgb,  
    output reg [13:0] score 
    );

    // --- High Score Logic ---
    reg [13:0] current_score_reg; 
    reg [13:0] high_score;        
    
    // --- Bird Settings ---
    reg [9:0] bird_y;       
    reg signed [9:0] velocity; 
    parameter BIRD_X = 100;    
    parameter BIRD_SIZE = 20;
    
    // --- Pipe Settings ---
    parameter PIPE_WIDTH = 50;
    parameter PIPE_GAP_SIZE = 120;
    
    reg [11:0] pipe1_x;     
    reg [9:0] pipe1_gap_y;
    reg [11:0] pipe2_x;     
    reg [9:0] pipe2_gap_y;
    
    wire [10:0] real_pipe1_x = pipe1_x[11:2];
    wire [10:0] real_pipe2_x = pipe2_x[11:2];

    // --- Speed Control ---
    reg [4:0] current_speed;    
    reg [3:0] pipes_passed;     

    // --- Game State & Flags ---
    // State 0: Menu, 1: Countdown, 2: Play, 3: Dead
    reg [1:0] state; 
    reg [3:0] gravity_counter; 
    reg first_play; 

    // --- Countdown Variables ---
    reg [5:0] timer_frame_tick; 
    reg [2:0] countdown_val;    
    
    // --- Random Generator ---
    reg [15:0] random_lfsr;
    always @(posedge clk) begin
        if (rst) random_lfsr <= 16'hACE1; 
        else random_lfsr <= {random_lfsr[14:0], random_lfsr[15] ^ random_lfsr[13] ^ random_lfsr[12] ^ random_lfsr[10]};
    end

    // --- Frame Timer ---
    reg [19:0] frame_counter;
    wire frame_tick = (frame_counter == 833333); 

    // --- Input Latch ---
    reg jump_latched;
    always @(posedge clk) begin
        if (rst) jump_latched <= 0;
        else begin
            if (jump_btn) jump_latched <= 1;       
            else if (frame_tick) jump_latched <= 0; 
        end
    end
    
    reg start_latched;
    always @(posedge clk) begin
        if (rst) start_latched <= 0;
        else begin
            if (start_btn) start_latched <= 0;
            if (start_btn) start_latched <= 1;       
            else if (frame_tick) start_latched <= 0; 
        end
    end

    // Output Score -> 7-Segment
    always @(*) score = current_score_reg;

    // --- Game Logic ---
    always @(posedge clk) begin
        if(rst) begin
            state <= 0;
            bird_y <= 240;
            velocity <= 0;
            current_score_reg <= 0;
            high_score <= 0; 
            
            pipe1_x <= 320 * 4;            
            pipe1_gap_y <= 200;
            pipe2_x <= (320 + 340) * 4;     
            pipe2_gap_y <= 300;
            
            frame_counter <= 0;
            gravity_counter <= 0;
            
            current_speed <= 4; 
            pipes_passed <= 0;
            first_play <= 1; 
            
            timer_frame_tick <= 0;
            countdown_val <= 3;
        end else begin
            frame_counter <= (frame_counter >= 833333) ? 0 : frame_counter + 1;
            
            if (frame_tick) begin
                case (state)
                    // === STATE 0: MENU / RESTART ===
                    0: begin 
                        if (first_play) begin
                            // Live Background
                            if (pipe1_x < current_speed) begin 
                                pipe1_x <= 640 * 4; 
                                pipe1_gap_y <= (random_lfsr % 280) + 100; 
                            end else begin
                                pipe1_x <= pipe1_x - current_speed; 
                            end
                            if (pipe2_x < current_speed) begin 
                                pipe2_x <= 640 * 4; 
                                pipe2_gap_y <= (random_lfsr % 280) + 100; 
                            end else begin
                                pipe2_x <= pipe2_x - current_speed; 
                            end
                        end
                        
                        if (start_latched) begin 
                            state <= 1; // ไปนับถอยหลัง (State 1)
                            current_score_reg <= 0; 
                            first_play <= 0; 
                            bird_y <= 240;
                            velocity <= 0;
                            gravity_counter <= 0;
                            current_speed <= 4; 
                            pipes_passed <= 0;
                            pipe1_x <= 320 * 4; 
                            pipe2_x <= (320 + 340) * 4; 
                            pipe1_gap_y <= (random_lfsr[15:0] % 280) + 100;
                            pipe2_gap_y <= (random_lfsr[7:0] % 280) + 100; 
                            countdown_val <= 3;
                            timer_frame_tick <= 0;
                        end
                    end
                    
                    // === STATE 1: COUNTDOWN ===
                    1: begin 
                        if (timer_frame_tick >= 60) begin
                            timer_frame_tick <= 0;
                            if (countdown_val == 0) begin
                                state <= 2; // ไปเริ่มเกม (State 2)
                            end else begin
                                countdown_val <= countdown_val - 1;
                            end
                        end else begin
                            timer_frame_tick <= timer_frame_tick + 1;
                        end
                    end

                    // === STATE 2: PLAY ===
                    2: begin 
                        if (jump_latched) begin 
                            velocity <= -3; 
                            gravity_counter <= 0;
                        end
                        else begin
                            gravity_counter <= gravity_counter + 1;
                            if (gravity_counter == 8) begin 
                                if (velocity < 10) velocity <= velocity + 1;
                                gravity_counter <= 0;
                            end
                        end
                        bird_y <= bird_y + velocity;
                        
                        if (pipe1_x < current_speed) begin 
                            pipe1_x <= 640 * 4; 
                            pipe1_gap_y <= (random_lfsr % 280) + 100; 
                            current_score_reg <= current_score_reg + 1; 
                            pipes_passed <= pipes_passed + 1;
                            if (pipes_passed >= 1) begin 
                                pipes_passed <= 0;
                                if (current_speed < 24) current_speed <= current_speed + 1; 
                            end
                        end else begin
                            pipe1_x <= pipe1_x - current_speed; 
                        end

                        if (pipe2_x < current_speed) begin 
                            pipe2_x <= 640 * 4; 
                            pipe2_gap_y <= (random_lfsr % 280) + 100; 
                            current_score_reg <= current_score_reg + 1; 
                            pipes_passed <= pipes_passed + 1;
                            if (pipes_passed >= 1) begin
                                pipes_passed <= 0;
                                if (current_speed < 24) current_speed <= current_speed + 1;
                            end
                        end else begin
                            pipe2_x <= pipe2_x - current_speed; 
                        end
                        
                        if (bird_y < 0 || bird_y > 480 ||
                           ((BIRD_X + BIRD_SIZE > real_pipe1_x) && (BIRD_X < real_pipe1_x + PIPE_WIDTH) && ((bird_y < pipe1_gap_y) || (bird_y + BIRD_SIZE > pipe1_gap_y + PIPE_GAP_SIZE))) ||
                           ((BIRD_X + BIRD_SIZE > real_pipe2_x) && (BIRD_X < real_pipe2_x + PIPE_WIDTH) && ((bird_y < pipe2_gap_y) || (bird_y + BIRD_SIZE > pipe2_gap_y + PIPE_GAP_SIZE)))) 
                        begin
                            state <= 3; // ตาย (State 3)
                        end
                    end
                    
                    // === STATE 3: DEAD ===
                    3: begin 
                         if (current_score_reg > high_score) begin
                             high_score <= current_score_reg;
                         end
                         state <= 0; // กลับไป Menu (State 0)
                    end
                endcase
            end
        end
    end
    
    // Helper: Segments
    function [6:0] get_digit_seg(input [3:0] num);
        case(num)
            0: get_digit_seg = 7'b1111110; 1: get_digit_seg = 7'b0110000;
            2: get_digit_seg = 7'b1101101; 3: get_digit_seg = 7'b1111001;
            4: get_digit_seg = 7'b0110011; 5: get_digit_seg = 7'b1011011;
            6: get_digit_seg = 7'b1011111; 7: get_digit_seg = 7'b1110000;
            8: get_digit_seg = 7'b1111111; 9: get_digit_seg = 7'b1111011;
            default: get_digit_seg = 7'b0000000;
        endcase
    endfunction

    // ==========================================
    // --- DRAWING LOGIC ---
    // ==========================================
    
    // 1. Big Score
    wire [3:0] cur_tens = (current_score_reg / 10) % 10;
    wire [3:0] cur_ones = current_score_reg % 10;
    wire in_cur_tens = (pixel_x >= 280 && pixel_x < 320 && pixel_y >= 280 && pixel_y < 340);
    wire in_cur_ones = (pixel_x >= 330 && pixel_x < 370 && pixel_y >= 280 && pixel_y < 340);

    // 2. High Score Text (Top Left)
    wire in_high_text_y = (pixel_y >= 20 && pixel_y < 34); 
    
    reg is_highest_text;
    always @(*) begin
        is_highest_text = 0;
        if (in_high_text_y) begin
            // H (20-28)
            if (pixel_x>=20 && pixel_x<=28) begin
                if (pixel_x==20 || pixel_x==28 || pixel_y==27) is_highest_text = 1;
            end
            // I (32-34)
            else if (pixel_x>=32 && pixel_x<=34) begin
                if (pixel_x==33 || pixel_y==20 || pixel_y==33) is_highest_text = 1;
            end
            // G (38-46)
            else if (pixel_x>=38 && pixel_x<=46) begin
                if (pixel_y==20 || pixel_y==33 || pixel_x==38 || (pixel_x==46 && pixel_y>=27) || (pixel_y==27 && pixel_x>=42)) is_highest_text = 1;
            end
            // H (50-58)
            else if (pixel_x>=50 && pixel_x<=58) begin
                if (pixel_x==50 || pixel_x==58 || pixel_y==27) is_highest_text = 1;
            end
            // E (62-70)
            else if (pixel_x>=62 && pixel_x<=70) begin
                if (pixel_x==62 || pixel_y==20 || pixel_y==27 || pixel_y==33) is_highest_text = 1;
            end
            // S (74-82)
            else if (pixel_x>=74 && pixel_x<=82) begin
                if (pixel_y==20 || pixel_y==27 || pixel_y==33 || (pixel_x==74 && pixel_y<27) || (pixel_x==82 && pixel_y>27)) is_highest_text = 1;
            end
            // T (86-94)
            else if (pixel_x>=86 && pixel_x<=94) begin
                if (pixel_y==20 || pixel_x==90) is_highest_text = 1;
            end
            // : (98-100)
            else if (pixel_x>=98 && pixel_x<=100) begin
                if (pixel_y==24 || pixel_y==30) is_highest_text = 1;
            end
        end
    end

    // High Score Numbers
    wire [3:0] hi_tens = (high_score / 10) % 10;
    wire [3:0] hi_ones = high_score % 10;
    wire in_hi_tens = (pixel_x >= 110 && pixel_x < 120 && pixel_y >= 15 && pixel_y < 35); 
    wire in_hi_ones = (pixel_x >= 125 && pixel_x < 135 && pixel_y >= 15 && pixel_y < 35); 

    // Countdown Check -> ใช้ state == 1 แทน 3
    wire in_countdown = (state == 1) && (pixel_x >= 300 && pixel_x < 340 && pixel_y >= 210 && pixel_y < 270);
    
    reg pixel_is_big_score;
    reg pixel_is_small_score;
    reg [9:0] dx, dy;
    reg [6:0] current_segs;
    reg is_seg_draw; 
    
    always @(*) begin
        pixel_is_big_score = 0;
        pixel_is_small_score = 0;
        dx = 0; dy = 0; current_segs = 0;
        is_seg_draw = 0;
        
        // เช็ค state == 1 (Countdown)
        if (state == 1 && in_countdown) begin 
             dx = pixel_x - 300; dy = pixel_y - 210; 
             current_segs = get_digit_seg({1'b0, countdown_val}); 
        end 
        // เช็ค state != 1 (Not Countdown)
        else if (state != 1) begin
            // Big Score (Current)
            if (in_cur_tens) begin 
                 dx = pixel_x - 280; dy = pixel_y - 280; current_segs = get_digit_seg(cur_tens); 
            end
            else if (in_cur_ones) begin 
                 dx = pixel_x - 330; dy = pixel_y - 280; current_segs = get_digit_seg(cur_ones); 
            end
            
            // Small Score (Highest)
            if (state == 0 && !first_play) begin
                if (in_hi_tens) begin
                    dx = (pixel_x - 110) * 4; 
                    dy = (pixel_y - 15) * 3; 
                    current_segs = get_digit_seg(hi_tens);
                end
                else if (in_hi_ones) begin
                    dx = (pixel_x - 125) * 4;
                    dy = (pixel_y - 15) * 3; 
                    current_segs = get_digit_seg(hi_ones);
                end
            end
        end
        
        if (current_segs != 0) begin
            if (current_segs[6] && dy >= 0 && dy < 6 && dx >= 6 && dx <= 33) is_seg_draw = 1;
            if (current_segs[5] && dx >= 34 && dx <= 39 && dy >= 6 && dy <= 26) is_seg_draw = 1;
            if (current_segs[4] && dx >= 34 && dx <= 39 && dy >= 33 && dy <= 53) is_seg_draw = 1;
            if (current_segs[3] && dy >= 54 && dy <= 59 && dx >= 6 && dx <= 33) is_seg_draw = 1;
            if (current_segs[2] && dx >= 0 && dx <= 5 && dy >= 33 && dy <= 53) is_seg_draw = 1;
            if (current_segs[1] && dx >= 0 && dx <= 5 && dy >= 6 && dy <= 26) is_seg_draw = 1;
            if (current_segs[0] && dy >= 27 && dy <= 32 && dx >= 6 && dx <= 33) is_seg_draw = 1;
            
            if (is_seg_draw) begin
                if (in_hi_tens || in_hi_ones) pixel_is_small_score = 1;
                else pixel_is_big_score = 1;
            end
        end
    end

    // --- TEXT DRAWING LOGIC ---
    wire in_text_y = (pixel_y >= 200 && pixel_y <= 260);
    wire draw_M = in_text_y && ((pixel_x>=220 && pixel_x<=225) || (pixel_x>=255 && pixel_x<=260) || (pixel_x>=235 && pixel_x<=245 && pixel_y<=220));
    wire draw_E_menu = in_text_y && ((pixel_x>=270 && pixel_x<=275) || (pixel_x>=270 && pixel_x<=310 && (pixel_y<=205 || (pixel_y>=227 && pixel_y<=232) || pixel_y>=255)));
    wire draw_N = in_text_y && ((pixel_x>=320 && pixel_x<=325) || (pixel_x>=355 && pixel_x<=360) || (pixel_x>=320 && pixel_x<=360 && pixel_y<=205));
    wire draw_U = in_text_y && ((pixel_x>=370 && pixel_x<=375) || (pixel_x>=405 && pixel_x<=410) || (pixel_x>=370 && pixel_x<=410 && pixel_y>=255));
    wire text_MENU = (draw_M || draw_E_menu || draw_N || draw_U);

    wire draw_R1 = in_text_y && (pixel_x>=190 && pixel_x<=220) && ((pixel_x<=195) || (pixel_y<=205) || (pixel_y>=225 && pixel_y<=230) || (pixel_x>=215 && pixel_y<=230) || (pixel_x>=195 && pixel_y>=230 && (pixel_y - pixel_x >= 32) && (pixel_y - pixel_x <= 38)));
    wire draw_E_res = in_text_y && (pixel_x>=230 && pixel_x<=260) && ((pixel_x<=235) || (pixel_y<=205) || (pixel_y>=225 && pixel_y<=230) || (pixel_y>=255));
    wire draw_S  = in_text_y && (pixel_x>=270 && pixel_x<=300) && ((pixel_y<=205) || (pixel_y>=225 && pixel_y<=230) || (pixel_y>=255) || (pixel_x<=275 && pixel_y<=230) || (pixel_x>=295 && pixel_y>=230));
    wire draw_T1 = in_text_y && (pixel_x>=310 && pixel_x<=340) && ((pixel_y<=205) || (pixel_x>=322 && pixel_x<=327));
    wire draw_A  = in_text_y && (pixel_x>=350 && pixel_x<=380) && ((pixel_y<=205) || (pixel_x<=355) || (pixel_x>=375) || (pixel_y>=225 && pixel_y<=230));
    wire draw_R2 = in_text_y && (pixel_x>=390 && pixel_x<=420) && ((pixel_x<=395) || (pixel_y<=205) || (pixel_y>=225 && pixel_y<=230) || (pixel_x>=415 && pixel_y<=230) || (pixel_x>=395 && pixel_y>=230 && (pixel_y - pixel_x >= -168) && (pixel_y - pixel_x <= -162)));
    wire draw_T2 = in_text_y && (pixel_x>=430 && pixel_x<=460) && ((pixel_y<=205) || (pixel_x>=442 && pixel_x<=447));
    wire text_RESTART = (draw_R1 || draw_E_res || draw_S || draw_T1 || draw_A || draw_R2 || draw_T2);

    wire cloud1 = (pixel_x >= 60 && pixel_x <= 110 && pixel_y >= 60 && pixel_y <= 85) || (pixel_x >= 75 && pixel_x <= 100 && pixel_y >= 50 && pixel_y <= 60);
    wire cloud2 = (pixel_x >= 400 && pixel_x <= 460 && pixel_y >= 150 && pixel_y <= 175) || (pixel_x >= 415 && pixel_x <= 445 && pixel_y >= 140 && pixel_y <= 150);
    wire cloud3 = (pixel_x >= 250 && pixel_x <= 310 && pixel_y >= 350 && pixel_y <= 375) || (pixel_x >= 265 && pixel_x <= 295 && pixel_y >= 340 && pixel_y <= 350);
    wire is_cloud = (cloud1 || cloud2 || cloud3);

    // --- Final RGB Output ---
    always @(*) begin
        if (!video_on) rgb = 12'h000;
        else begin
            if (state == 0) begin // MENU / RESTART
                if (first_play) begin
                    if (text_MENU) rgb = 12'hFF0; 
                    else draw_background_with_pipes(); 
                end else begin
                    // RESTART SCREEN
                    if (text_RESTART) rgb = 12'hF00; 
                    else if (pixel_is_big_score) rgb = 12'hF00; 
                    else if (is_highest_text || pixel_is_small_score) rgb = 12'hF00;
                    else draw_frozen_crash_with_filter(); 
                end
            end
            // state == 1 คือ Countdown
            else if (state == 1) begin 
                 if (pixel_is_big_score) rgb = 12'hFF0; 
                 else draw_background_with_bird_pipes();
            end 
            else begin // PLAY (2) & DEAD (3) -> (ใน State 3 จริงๆ จะวนกลับไป 0 ทันที)
                draw_background_with_bird_pipes();
            end
        end
    end

    // --- Tasks ---
    task draw_background_with_pipes;
    begin
         if (pixel_x >= real_pipe1_x && pixel_x < real_pipe1_x+PIPE_WIDTH && (pixel_y < pipe1_gap_y || pixel_y > pipe1_gap_y+PIPE_GAP_SIZE)) rgb = 12'h444;
         else if (pixel_x >= real_pipe2_x && pixel_x < real_pipe2_x+PIPE_WIDTH && (pixel_y < pipe2_gap_y || pixel_y > pipe2_gap_y+PIPE_GAP_SIZE)) rgb = 12'h444;
         else begin
             if (is_cloud) rgb = 12'hFFF; 
             else rgb = 12'h8CE;          
         end
    end
    endtask

    task draw_background_with_bird_pipes;
    begin
        if (pixel_x >= BIRD_X && pixel_x < BIRD_X+BIRD_SIZE && pixel_y >= bird_y && pixel_y < bird_y+BIRD_SIZE) rgb = 12'hFF0;
        else if (pixel_x >= real_pipe1_x && pixel_x < real_pipe1_x+PIPE_WIDTH && (pixel_y < pipe1_gap_y || pixel_y > pipe1_gap_y+PIPE_GAP_SIZE)) rgb = 12'h444;
        else if (pixel_x >= real_pipe2_x && pixel_x < real_pipe2_x+PIPE_WIDTH && (pixel_y < pipe2_gap_y || pixel_y > pipe2_gap_y+PIPE_GAP_SIZE)) rgb = 12'h444;
        else begin
            if (is_cloud) rgb = 12'hFFF; 
            else rgb = 12'h8CE;          
        end
    end
    endtask

    task draw_frozen_crash_with_filter;
    begin
        if (pixel_x >= BIRD_X && pixel_x < BIRD_X+BIRD_SIZE && pixel_y >= bird_y && pixel_y < bird_y+BIRD_SIZE) rgb = 12'hF40;
        else if (pixel_x >= real_pipe1_x && pixel_x < real_pipe1_x+PIPE_WIDTH && (pixel_y < pipe1_gap_y || pixel_y > pipe1_gap_y+PIPE_GAP_SIZE)) rgb = 12'h622;
        else if (pixel_x >= real_pipe2_x && pixel_x < real_pipe2_x+PIPE_WIDTH && (pixel_y < pipe2_gap_y || pixel_y > pipe2_gap_y+PIPE_GAP_SIZE)) rgb = 12'h622;
        else begin
            if (is_cloud) rgb = 12'hFBB; 
            else rgb = 12'hD66;          
        end
    end
    endtask

endmodule