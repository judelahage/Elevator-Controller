`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// elevator_top - Basys 3 top-level integration for the elevator controller.
//
// This module connects the board clock, switches, buttons, LEDs, and VGA port
// to the elevator control FSM and display renderer. The FSM runs from a divided
// clock so floor changes are visible on the board instead of occurring at full
// 100 MHz speed.
//
// Switch layout:
//   sw[3:0]   cab floor requests
//   sw[7:4]   hall up requests
//   sw[11:8]  hall down requests
//
// Button layout:
//   btnD reset, btnC emergency stop, btnU emergency reset,
//   btnL manual door open, btnR manual door close.
//////////////////////////////////////////////////////////////////////////////

module elevator_top(
    input         clk100mhz,   // Basys 3 100 MHz clock, pin W5
    input  [11:0] sw,          // floor request switches
    input         btnC,        // emergency stop button
    input         btnU,        // emergency reset button
    input         btnD,        // system reset button
    input         btnL,        // manual door-open button
    input         btnR,        // manual door-close button
    output [3:0]  led,          // movement and door status indicators
    output hsync, vsync,
    output [11:0] rgb
);

    // VGA timing and elevator image generation.
    wire[9:0] x, y;
    wire videoon;
    wire [1:0] currentFloor;
    wire inEmergency;
    wire [3:0] pendingCab, pendingUp, pendingDown;
    
    vga_controller vga_c(.clk100mhz(clk100mhz), .x(x), .y(y), .videoon(videoon), .hsync(hsync), .vsync(vsync), .ptick(), .reset(btnD));
    elevator_renderer render(.x(x), .y(y), .videoon(videoon), .currentFloor(currentFloor), .door_open(door_open), .move_up(move_up), .move_down(move_down), .inEmergency(inEmergency), .pendingCab(pendingCab), .pendingUp(pendingUp), .pendingDown(pendingDown), .rgb(rgb));



    // Control clock divider: 100 MHz board clock to about 1 Hz.
    // The divider toggles every 50,000,000 ticks, creating a 1 s half-period.
    localparam integer DIV = 50_000_000;
    reg [25:0] divcount = 0;
    reg        slowclk  = 0;
    always @(posedge clk100mhz) begin
        if (divcount == DIV-1) begin
            divcount <= 0;
            slowclk  <= ~slowclk;
        end else begin
            divcount <= divcount + 1;
        end
    end

    // Switch edge detection in the slow-clock domain.
    // A rising switch edge becomes a single-cycle request pulse.
    reg [11:0] sw_sync0, sw_sync1, sw_prev;
    always @(posedge slowclk) begin
        sw_sync0 <= sw;
        sw_sync1 <= sw_sync0;
        sw_prev  <= sw_sync1;
    end
    wire [11:0] sw_rise = sw_sync1 & ~sw_prev;

    // Elevator control FSM.
    wire move_up, move_down, door_open, door_close;

    elevator_controller elevator (
        .clk              (slowclk),
        .reset            (btnD),
        .cabRequest       (sw_rise[3:0]),
        .hallUp           (sw_rise[7:4]),
        .hallDown         (sw_rise[11:8]),
        .userDoorOpen     (btnL),
        .userDoorClose    (btnR),
        .emergencyStop    (btnC),
        .emergencyResetKey(btnU),
        .move_up          (move_up),
        .move_down        (move_down),
        .door_close       (door_close),
        .door_open        (door_open),
        .currentFloor     (currentFloor),
        .inEmergency      (inEmergency),
        .pendingCab(pendingCab),
        .pendingDown(pendingDown),
        .pendingUp(pendingUp)
    );

    // LED status mirrors the controller outputs.
    assign led[0] = move_up;
    assign led[1] = move_down;
    assign led[2] = door_open;
    assign led[3] = door_close;



endmodule
