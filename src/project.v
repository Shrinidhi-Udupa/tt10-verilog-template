/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  //wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule

`timescale 1ns/1ps
// `include "dco_model.v"

module tt_um_dco(
    input        clk,
    input        reset,
    input        en,
    input  [7:0] dco_code,
    output       dco_out
);
  
  wire [15:0] coarse;  
  assign coarse = (dco_code[3:0] < 16) ? (((16'b1 << dco_code[3:0]) - 1'b1) << dco_code[7:4]) : 16'b0;

  
  dco_mode K1(
      .clk(clk),
      .rst_n(~reset),
      .en(en),
      .coarse(coarse),
      .dco_out(dco_out)
  );
endmodule


module dco_mode (
    input wire clk,
    input wire rst_n,
    input wire en,
    //input wire coarse_0, coarse_1, coarse_2, coarse_3, coarse_4, coarse_5, coarse_6, coarse_7, coarse_8, coarse_9, coarse_10, coarse_11, coarse_12, coarse_13, coarse_14, coarse_15,
    output reg dco_out,
    input wire [15:0] coarse
);

    reg [7:0] period;
    reg [7:0] counter;
    reg [7:0] prev_period;
    
    // Compute period based on coarse control bits (example mapping)
    always @(*)   
        
        begin
	
	casez (coarse)
            16'b1???????????????: period = 8'd100;
            16'b01??????????????: period = 8'd94;
            16'b001?????????????: period = 8'd90;
            16'b0001????????????: period = 8'd84;
            16'b00001???????????: period = 8'd80;
            16'b000001??????????: period = 8'd74;
            16'b0000001?????????: period = 8'd70;
            16'b00000001????????: period = 8'd64;
            16'b000000001???????: period = 8'd60;
            16'b0000000001??????: period = 8'd54;
            16'b00000000001?????: period = 8'd50;
            16'b000000000001????: period = 8'd44;
            16'b0000000000001???: period = 8'd40;
            16'b00000000000001??: period = 8'd34;
            16'b000000000000001?: period = 8'd30;
            16'b0000000000000001: period = 8'd10;
            default: period = 8'd50;
        endcase
        end
        
        wire [7:0] period2;
        assign period2 = period;
        
        reg fast_clk;  // Internal fast clock (1ns)
        reg [3:0] fast_clk_div; // Divider for generating fast clock

        always @(posedge clk or negedge rst_n) begin
            if (~rst_n) begin
        fast_clk_div <= 4'd0;
        fast_clk <= 1'b0;
             end else begin
        fast_clk_div <= fast_clk_div + 1;
        if (fast_clk_div == 4'd4) begin  // Toggle at every 5 counts (10ns / 2)
            fast_clk <= ~fast_clk;
            fast_clk_div <= 4'd0;
        end
    end
end

always @(posedge clk or negedge rst_n)
 begin
    if (~rst_n) begin
        counter <= 8'd0;
        dco_out <= 1'b0;
        //prev_period <= 8'd50; // Default period
    end else if (en) begin
        if (counter >= prev_period) begin
            dco_out <= ~dco_out;
            counter <= 8'd0;
        end else begin
            counter <= counter + 1;
        end        
         // Update previous period at each clock cycle
    end
end
always@(posedge fast_clk) begin 
     prev_period <= period;
end
endmodule

