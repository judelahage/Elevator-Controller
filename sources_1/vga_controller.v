`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// vga_controller - 640x480 VGA timing generator.
//
// The module divides the 100 MHz Basys 3 clock into a 25 MHz pixel tick,
// advances horizontal and vertical scan counters, and produces sync pulses
// plus the active-display flag used by the renderer.
//////////////////////////////////////////////////////////////////////////////////


module vga_controller(
        input clk100mhz,
        input reset,
        output videoon,
        output hsync,
        output vsync,
        output ptick,
        output [9:0] x,
        output [9:0] y
        );
        
    // Signal summary:
    //   videoon marks pixels inside the 640x480 visible region.
    //   reset clears the timing counters and sync registers.
    //   hsync and vsync are the VGA synchronization pulses.
    //   ptick is the 25 MHz pixel-enable pulse.
    
    // Standard 640x480 VGA timing. Ten-bit counters cover the full 800x525
    // scan area, including visible pixels and blanking intervals.
    parameter HD = 640; // horizontal visible pixels
    parameter HF = 48; // horizontal front porch
    parameter HB = 16; // horizontal back porch
    parameter HR = 96; // horizontal sync pulse
    parameter HMAX = HD+HF+HB+HR-1; // maximum horizontal counter value
    parameter VD = 480; // vertical visible rows
    parameter VF = 10; // vertical front porch
    parameter VB = 33; // vertical back porch
    parameter VR = 2; // vertical sync pulse
    parameter VMAX = VD+VF+VB+VR-1; // maximum vertical counter value
    
    reg [1:0] r25mhz;
    wire w25mhz;
    
    always @(posedge clk100mhz or posedge reset) // divide-by-four pixel tick counter
        if(reset)
            r25mhz <= 0;
        else
            r25mhz <= r25mhz + 1;
        
    assign w25mhz = (r25mhz == 0) ? 1 : 0; // one-cycle tick every four input clocks
    
    reg [9:0] hcountreg, hcountnext;
    reg [9:0] vcountreg, vcountnext;
    reg vsyncreg, hsyncreg;
    wire vsyncnext, hsyncnext;
    
    // Registered scan position and sync outputs.
    always @(posedge clk100mhz or posedge reset)
        if(reset) begin
        vcountreg <= 0;
        hcountreg <= 0;
        vsyncreg <= 1'b0;
        hsyncreg <= 1'b0;
    end
    else begin
        vcountreg <= vcountnext;
        hcountreg <= hcountnext;
        vsyncreg <= vsyncnext;
        hsyncreg <= hsyncnext;
    end
    
    // Horizontal scan counter.
    always @(posedge w25mhz or posedge reset)
        if(reset)
            hcountnext <= 0;
        else
            if(hcountreg == HMAX) // wrap at the end of a scan line
                hcountnext <= 0;
            else // advance within the current scan line
                hcountnext <= hcountreg + 1;
    // Vertical scan counter.
    always @(posedge w25mhz or posedge reset)
        if(reset)
            vcountnext <= 0;
        else
            if(hcountreg == HMAX)
                if((vcountreg == VMAX))
                    vcountnext <= 0;
                else
                    vcountnext <= vcountreg + 1;
                    
    assign hsyncnext = (hcountreg >= (HD+HB) && hcountreg <= (HD+HB+HR-1));
    assign vsyncnext = (vcountreg >= (VD+VF) && vcountreg <= (VD+VF+VR-1));
    assign videoon = (hcountreg < HD) && (vcountreg < VD); // visible 640x480 region
    
    // Output assignments.
    assign hsync = hsyncreg;
    assign vsync = vsyncreg;
    assign x = hcountreg;
    assign y = vcountreg;
    assign ptick = w25mhz;
endmodule
