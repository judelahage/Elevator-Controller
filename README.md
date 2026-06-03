# Elevator Controller (Verilog)

A four-floor elevator controller written in Verilog, implementing the **SCAN
("elevator") scheduling algorithm** with directional hall calls, a latching
emergency stop, and manual door control. Targets the **Digilent Basys 3**
(Xilinx Artix-7) FPGA.

## Overview

The project is two modules:

| File | Role |
|------|------|
| [`elevatorcontrollerfsm.v`](sources_1/elevatorcontrollerfsm.v) | Core finite-state machine — request latching, scheduling, doors, emergency |
| [`elevatorcontrollerfsmtest.v`](sources_1/elevatorcontrollerfsmtest.v) | Synthesizable top wrapper mapping the FSM to Basys 3 switches, buttons, and LEDs |
| [`Basys3_elevator.xdc`](constrs_1/Basys3_elevator.xdc) | Basys 3 pin constraints for the top wrapper |

## How it works

### Scheduling — SCAN

Rather than serving calls in arrival order, the car sweeps in one direction,
stopping at **every** requested floor along the way, and only reverses when
nothing remains ahead of it. This is the classic "elevator algorithm" and keeps
the car from bouncing back and forth.

Two combinational flags drive the decision each cycle:

- `anyAbove` — a request exists on a floor above the current one
- `anyBelow` — a request exists on a floor below

While moving up the car keeps climbing as long as `anyAbove` holds; only when it
runs out of upward calls does it consider reversing. Moving down is the mirror.

### Requests

Three independent sources, one bit per floor, are **latched** into sticky
`pending` registers and held until that floor is served:

- **Cabin buttons** (`cabRequest`) — destinations chosen from inside the car
- **Hall up-calls** (`hallUp`) — a rider on a floor wanting to go *up*
- **Hall down-calls** (`hallDown`) — a rider wanting to go *down*

Because hall calls are **directional**, the car only picks up an up-call while
ascending and a down-call while descending — a down-bound rider is caught on the
return trip, exactly like a real elevator.

### States

| State | Behavior |
|-------|----------|
| `IDLE` | Parked, motor off. Picks an initial direction, serves its own floor, and honors the manual door buttons. |
| `MOVEUP` | Climbing. Serves cabin/up calls at each floor, reverses or idles when nothing is left above. |
| `MOVEDOWN` | Descending. Mirror of `MOVEUP`. |
| `EMERGENCY` | Latched safe state — motors off, holds until cleared. |

### Emergency stop

Asserting `emergencyStop` cuts the motors and forces the `EMERGENCY` state. It
**latches** — releasing the button does *not* resume service. The car stays put
until `emergencyResetKey` is pressed, then returns to `IDLE`.

### Doors

`door_open` / `door_close` pulse automatically when the car serves a floor, and
can be driven manually with the door-open / door-close buttons while idle.

## FSM interface

**Inputs**

| Signal | Width | Description |
|--------|-------|-------------|
| `clk`, `reset` | 1 | Clock and synchronous-async reset |
| `cabRequest` | 4 | Cabin destination buttons, one bit per floor |
| `hallUp` | 4 | Hall up-call buttons |
| `hallDown` | 4 | Hall down-call buttons |
| `userDoorOpen` / `userDoorClose` | 1 | Manual door control |
| `emergencyStop` | 1 | Latching emergency stop |
| `emergencyResetKey` | 1 | Clears the latched emergency |

**Outputs**

| Signal | Description |
|--------|-------------|
| `move_up` / `move_down` | Motor direction |
| `door_open` / `door_close` | Door actuators |

Floors are represented 0-indexed internally (`0`–`3` → floors 1–4).

## Basys 3 mapping

The top wrapper divides the 100 MHz board clock down to **~1 Hz** so floor moves
are visible, and edge-detects the request switches so each flip issues exactly
one call.

| Board control | Maps to |
|---------------|---------|
| `sw[3:0]` | Cabin buttons (floors 1–4) |
| `sw[7:4]` | Hall up-calls |
| `sw[11:8]` | Hall down-calls |
| `btnD` | Reset |
| `btnC` | Emergency stop |
| `btnU` | Emergency reset key |
| `btnL` / `btnR` | Door open / close |
| `led[0..3]` | `move_up`, `move_down`, `door_open`, `door_close` |

## Build & run (Vivado)

1. Create a Vivado project targeting the Basys 3 (`xc7a35tcpg236-1`).
2. Add both files from [`sources_1/`](sources_1) and set `elevatorcontrollerfsmtest` as the top module.
3. Add the included [`Basys3_elevator.xdc`](constrs_1/Basys3_elevator.xdc) as a constraints file.
4. Run Synthesis → Implementation → Generate Bitstream.
5. Program the device.

### Operating it

- **Request a floor:** flip a switch **up, then back down** — the rising edge
  registers one call. Watch the car sweep with the direction LEDs.
- **Emergency:** press `btnC` to halt; press `btnU` to release.
- **Doors:** `btnL` / `btnR` while the car is idle.

> Buttons are sampled on the slow (~1 Hz) clock, so hold each press for about a
> second.

## Possible extensions

- Drive `currentFloor` to a 7-segment digit (1–4) or extra LEDs.
- Add a door-dwell timer so the door holds open for several seconds.
- Fire-service recall (send the car to the ground floor on emergency).
