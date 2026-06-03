//////////////////////////////////////////////////////////////////////////////
// elevator_controller - four-floor elevator finite-state machine.
//
// The controller uses SCAN scheduling: the car continues in the active
// direction while requests remain ahead, serves matching requests at each
// floor, and reverses only after the current direction is exhausted.
//
// Request inputs are latched into pending registers until the associated floor
// is served:
//   cabRequest - in-car destination requests
//   hallUp     - hall requests for upward travel
//   hallDown   - hall requests for downward travel
//
// Floors are encoded as 0..3, where 0 is the ground floor.
//////////////////////////////////////////////////////////////////////////////

module elevator_controller(

    input clk, reset,

    input [3:0] cabRequest, hallUp, hallDown,
    input userDoorOpen, userDoorClose, emergencyStop, emergencyResetKey,

    output reg move_up, move_down, door_close, door_open,
    output reg [3:0] pendingCab, pendingUp, pendingDown,
    output reg [1:0] currentFloor,
    output inEmergency
);

// FSM state encoding and floor count.
parameter IDLE =        2'b00;
parameter MOVEUP =      2'b01;
parameter MOVEDOWN =    2'b10;
parameter EMERGENCY =   2'b11;
parameter MAXFLOOR = 4;

reg anyAbove, anyBelow;
reg [1:0] currentState;
integer i;

// Emergency status exported to the display renderer.
assign inEmergency = (currentState == EMERGENCY);

// Pending-request search used by the SCAN direction logic.
always@(*) begin
    anyAbove = 0;
    anyBelow = 0;
    for(i = 0; i < MAXFLOOR; i = i + 1) begin
        if((pendingCab[i] | pendingUp[i] | pendingDown[i]) && i < currentFloor) begin   // request below current floor
            anyBelow = 1;
        end
        else if((pendingCab[i] | pendingUp[i] | pendingDown[i]) && i > currentFloor) begin   // request above current floor
            anyAbove = 1;
        end
    end

end


// Main sequential FSM. Each clock latches new requests, advances at most one
// floor, and updates the movement and door outputs.
always @(posedge clk or posedge reset)
    begin
        if(reset) begin
            pendingUp <= 0;
            pendingCab <= 0;
            pendingDown <= 0;
            move_up <= 0;
            move_down <= 0;
            door_close <= 0;
            door_open <= 0;
            currentState <= IDLE;
            currentFloor <= 0;
        end

        // Emergency stop has priority over normal scheduling.
        else if(emergencyStop) begin
            currentState <= EMERGENCY;
            move_up <= 0;
            move_down <= 0;
        end

        else begin
            // Merge new requests into the pending registers.
            pendingUp <= pendingUp | hallUp;
            pendingDown <= pendingDown | hallDown;
            pendingCab <= pendingCab | cabRequest;
            move_up <= 0;
            move_down <= 0;
            door_close <= 0;
            door_open <= 0;

            case(currentState)
                // Idle state: respond to door controls, serve the current
                // floor, or choose the next sweep direction.
                IDLE: begin
                    if(userDoorOpen) begin
                        door_open <= 1;
                    end
                    else if(userDoorClose) begin
                        door_close <= 1;
                    end
                    else if(anyAbove) begin
                        currentState <= MOVEUP;
                    end
                    else if(anyBelow) begin
                        currentState <= MOVEDOWN;
                    end
                    else if((pendingCab[currentFloor] | pendingUp[currentFloor] | pendingDown[currentFloor])) begin
                        pendingUp[currentFloor] <= 0;
                        pendingDown[currentFloor] <= 0;
                        pendingCab[currentFloor] <= 0;
                        door_open <= 1;


                    end
                    else begin
                        currentState <= IDLE;
                    end
                end

                // Upward sweep: serve upward/cab requests at this floor, keep
                // moving while requests remain above, or reverse when needed.
                MOVEUP: begin
                    if(pendingCab[currentFloor] || pendingUp[currentFloor]) begin   // serve current floor
                        pendingUp[currentFloor] <= 0;
                        pendingDown[currentFloor] <= 0;
                        pendingCab[currentFloor] <= 0;
                        door_open <= 1;
                    end
                    else if(anyAbove) begin
                        move_up <=1;
                        currentFloor <= currentFloor + 1;
                    end
                    else if(anyBelow) begin
                        currentState <= MOVEDOWN;
                    end
                    else currentState <= IDLE;
                end

                // Downward sweep: serve downward/cab requests at this floor,
                // continue downward while possible, or reverse when needed.
                MOVEDOWN: begin
                    if(pendingCab[currentFloor] || pendingDown[currentFloor]) begin   // serve current floor
                        pendingUp[currentFloor] <= 0;
                        pendingDown[currentFloor] <= 0;
                        pendingCab[currentFloor] <= 0;
                        door_open <= 1;
                    end
                    else if(anyBelow) begin
                        currentState <= MOVEDOWN;
                        currentFloor <= currentFloor - 1;
                        move_down <= 1;
                    end
                    else if(anyAbove) begin
                        currentState <= MOVEUP;
                    end
                    else currentState <= IDLE;
                end

                // Emergency state: motors stay off; manual door controls still
                // work, and the reset key returns the FSM to idle.
                EMERGENCY: begin
                    if(userDoorOpen) door_open <= 1;
                    else if(userDoorClose) door_close <= 1;
                    if(emergencyResetKey) begin
                        currentState <= IDLE;
                    end
                    else currentState <= EMERGENCY;
                end
            endcase
        end


    end



endmodule
