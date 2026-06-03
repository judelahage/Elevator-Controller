`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// elevator_renderer - combinational VGA drawing logic for the elevator display.
//
// For each visible pixel, the renderer maps the current elevator state and
// pending requests to a 12-bit RGB color.
//
//   640x480 layout:                 columns:
//   +------------------------------+   cab calls  : far left
//   |  []        ___________   []  |   up calls   : left of shaft
//   |  []       |   CAR     |  []  |   down calls : right of shaft
//   |  []       |___________|  []  |   shaft+car  : center
//   |  ...  4 floor bands ...      |
//   +------------------------------+
//
// The car color encodes status: blue for idle or moving, green for doors open,
// and red for emergency. A white stripe marks the leading edge while the car is
// moving. Call boxes turn yellow when their matching request is pending.
//////////////////////////////////////////////////////////////////////////////

module elevator_renderer(
    input  [9:0]      x,
    input  [9:0]      y,
    input             videoon,        // active display region from VGA timing
    input  [1:0]      currentFloor,   // floor index, 0 = ground
    input             door_open,
    input             move_up,
    input             move_down,
    input             inEmergency,
    input  [3:0]      pendingCab,     // cab request bits by floor
    input  [3:0]      pendingUp,
    input  [3:0]      pendingDown,
    output reg [11:0] rgb             // packed RGB: {R[3:0], G[3:0], B[3:0]}
);

    // 12-bit RGB palette.
    localparam [11:0] BLACK  = 12'h000,
                      WHITE  = 12'hFFF,
                      BG     = 12'h666,   // background gray
                      SHAFTC = 12'h222,   // shaft interior
                      DIM    = 12'h333,   // inactive request box
                      BLUE   = 12'h00F,   // normal car color
                      GREEN  = 12'h0F0,   // doors-open car color
                      RED    = 12'hF00,   // emergency car color
                      YELLOW = 12'hFF0;   // active request box

    // Display geometry.
    localparam TOP      = 40,           // shaft top edge
               FLOOR_H  = 100,          // vertical space per floor
               BOT      = TOP + 4*FLOOR_H, // shaft bottom edge
               SHAFT_L  = 270,
               SHAFT_R  = 370,
               BW       = 2,            // border and divider thickness
               BOX      = 16;           // request box size

    // Floor band for the current pixel row.
    reg [1:0] rowFloor;
    always @(*) begin
        if      (y < TOP + 1*FLOOR_H) rowFloor = 2'd3;
        else if (y < TOP + 2*FLOOR_H) rowFloor = 2'd2;
        else if (y < TOP + 3*FLOOR_H) rowFloor = 2'd1;
        else                          rowFloor = 2'd0;
    end
    wire [9:0] bandTop = TOP + (3 - rowFloor)*FLOOR_H;

    // Car rectangle positioned from the current floor.
    wire [9:0] car_top = TOP + (3 - currentFloor)*FLOOR_H + 10;
    wire [9:0] car_bot = car_top + 80;
    wire [9:0] car_l   = SHAFT_L + 14;
    wire [9:0] car_r   = SHAFT_R - 14;
    wire in_car = (x >= car_l && x <= car_r) && (y >= car_top && y <= car_bot);

    reg [11:0] car_color;
    always @(*) begin
        if      (inEmergency) car_color = RED;
        else if (door_open)   car_color = GREEN;
        else                  car_color = BLUE;
    end

    // Shaft walls and floor divider lines.
    wire in_shaft   = (x >= SHAFT_L && x <= SHAFT_R) && (y >= TOP && y <= BOT);
    wire on_border  = in_shaft && (x <  SHAFT_L+BW || x >  SHAFT_R-BW ||
                                   y <  TOP+BW     || y >  BOT-BW);
    wire on_floorln = (x >= SHAFT_L && x <= SHAFT_R) &&
                      ((y >= TOP+1*FLOOR_H && y < TOP+1*FLOOR_H+BW) ||
                       (y >= TOP+2*FLOOR_H && y < TOP+2*FLOOR_H+BW) ||
                       (y >= TOP+3*FLOOR_H && y < TOP+3*FLOOR_H+BW));

    // Request boxes centered within the current floor band.
    wire in_box_y    = (y >= bandTop + (FLOOR_H-BOX)/2) &&
                       (y <  bandTop + (FLOOR_H+BOX)/2);
    wire in_cab_box  = in_box_y && (x >= 60          && x < 60+BOX);
    wire in_up_box   = in_box_y && (x >= SHAFT_L-36  && x < SHAFT_L-36+BOX);
    wire in_down_box = in_box_y && (x >= SHAFT_R+20  && x < SHAFT_R+20+BOX);

    // Pixel compositing order. Later assignments draw over earlier layers.
    always @(*) begin
        if (!videoon) begin
            rgb = BLACK;
        end else begin
            rgb = BG;
            if (in_cab_box)               rgb = pendingCab[rowFloor]  ? YELLOW : DIM;
            if (in_up_box)                rgb = pendingUp[rowFloor]   ? YELLOW : DIM;
            if (in_down_box)              rgb = pendingDown[rowFloor] ? YELLOW : DIM;
            if (in_shaft)                 rgb = SHAFTC;
            if (on_border || on_floorln)  rgb = WHITE;
            if (in_car) begin
                rgb = car_color;
                if (move_up   && y <  car_top + 8) rgb = WHITE;  // upward leading edge
                if (move_down && y >  car_bot - 8) rgb = WHITE;  // downward leading edge
            end
        end
    end

endmodule
