# Vectrex 3D Imager Triangle Demo

## Purpose

This is an early test program that I wrote while learning to control the 3D Imager. It is presented as a "Hello World!"-style
example of basic 3D Imager operation. 

The demo spins the 3D Imager at a stable rate of 30 Hz and draws a simple triangle on screen. The color and apparent depth of the triangle are
adjustable with the Controller.

Note that this program was developed using the Madtronix reproduction of the 3D Imager. I have not tested it with an official 3D Imager.

Binary assembled from source using sbasm: https://www.sbprojects.net/sbasm/


## Usage & Controls

A 3D Imager is expected to be plugged into Controller Port 2, and is expected to have the "Narrow Escape" color wheel loaded.

After an initial synchronization period, a blue triangle should appear on screen.

Holding down Button 1 allows the Red color intensity to be adjusted up or down with the joystick.

Holding down Buttons 2 and 3 do the same for Green and Blue intensities, respectively. 

Holding down Button 4 similarly allows the apparent depth of the triangle to be adjusted. This simply adjusts the
horizontal distance offset between the left-eye and right-eye images of the triangle. 


## Algorithm Outline

### Overview

The main program consists of a loop that waits for each of six "Color Phases" to begin, then
draws the triangle at the current position and intensity for the appropriate phase. In between each Color Phase,
a subroutine **Deflok** is called to renormalize the vector display hardware (the name for which
is borrowed from the Vectrex ROM's documented implementation). And also checks for user input.

The "Color Phases" are the periods of time during which exactly one eye can see the Vectrex screen
through a tint of exactly one color. In order of occurrence, they are Right-Eye Blue, then Green, then Red,
followed by Left-Eye Blue, then Green, then Red.

Note that two different segments of the color wheel may be simultaneously visible for a significant fraction of the
3D Imager's rotation period, and any vectors drawn during these times will have inconsistent appearance.
For this reason, the beginning and end of a Color Phase are considered to be only the *middle quarter* of the time
period during which a given segment of the color wheel is expected to be visible. 

Synchronization with the 3D Imager is maintained using an internal timer (Timer2), a sync signal from the 3D Imager,
an IRQ routine, and some math. 

Speed control of the 3D Imager is maintained by a Pulse Width Modulated (PWM) signal sent from the Vectrex
to the Imager and is primarily governed by the same IRQ routine.

Vector drawing is performed by the **Draw_Vector_X** subroutine using an internal timer (Timer1). 

### 3D Imager Speed Control

The 3D Imager expects a periodic signal to be sent from the Vectrex over the Controller port. The frequency
of this signal does not matter (so long as it falls within some tolerance range that I haven't checked the limits of),
but the duty cycle does. A higher duty cycle corresponds with more force applied by the motor, and faster spin. The
3D Imager sends the equivalent of a button tap to the Vectrex once per revolution of the color wheel.

First of all, this means the Controller port must function as both an *output* as well as an *input*, so as to
send out the periodic signal described above and also receive the 
player control inputs. The Programmable Sound Generator (PSG) chip is responsible for handling
Controller input. It is capable of either input or output from / to the Controller ports, but not both at once.
To send output, the PSG's configuration must be changed. To receive input, it must be changed back. Furthermore,
the CPU does not communicate directly with the PSG, but instead interfaces through the VIA 6522 chip.

All of this results in a somewhat convoluted "magic rain dance" to toggle between sending the PWM periodic signal to the 3D Imager and reading player inputs.
This is captured in the **config_PSG_output** and **config_PSG_input** subroutines.

To get the 3D Imager started spinning, a relatively simple loop (the **sync_fail** branch of the **Wait_Sync** subroutine)
sends a predetermined signal wave to the 3D Imager, and checks for receipt of signals from the 3D Imager indicating
full revolutions of the color wheel while a timer counts down. If a signal comes back before the timer counts down,
the timer is reset and a success is counted, else both the timer and success count are reset. After four successful
signals in a row, the 3D Imager control is handed off to the IRQ routine. 

The main design consideration for the IRQ routine is that the 3D Imager's speed is prone to constant disturbance even once achieved.
This requires adjustment and compensation with a fast response time in order to maintain a consistent speed. To do this, the IRQ routine
is divided into two "modes":
1. When triggered by the (expected) countdown of an internal timer (Timer2), the routine begins a new outgoing
Logic HIGH periodic signal to the 3D Imager, and updates state to expect the 3D Imager to trigger it next.
2. When triggered by an (expected) input from the 3D Imager indicating a complete revolution of the color wheel, 
the routine sets the outgoing PWM signal to Logic LOW, calculates the current rotation period by checking the
internal timer (Timer2), updates some bookkeeping, then sets Timer2 to a calculated delay and updates state to expect
the timer to trigger the IRQ next.

The key detail in the above is that the color wheel rotation will self-stabilize to a fixed speed so long as the
Timer2 delay in Step 2 is always the same. The more slowly the wheel spins, the longer the PWM signal remains HIGH,
and so the higher the duty cycle becomes and the more force is applied by the motor. And vice versa. 

The particular speed to which the 3D Imager self-stabilizes then becomes purely a function of the calculated delay applied to Timer2
in Step 2. This delay starts off as a hard-coded default value that is adjusted by the bookkeeping mentioned above. Here's how that works.

After every 16 color wheel revolutions, the shortest and longest time periods out of those 16 are compared. If the delta is too large,
the 3D Imager's speed is deemed "unstable" and no update is made to the current timer delay. If it is small enough on the other hand,
then the timer delay is adjusted (up or down) by *half* the difference between the current rotation period and the desired rotation period. 
The factor of one-half avoids overcompensation.

If the IRQ routine is triggered by a timer countdown when it was expecting a 3D Imager input, or vice versa, it sets a flag to resynchronize
the 3D Imager using the **sync_fail** loop as on startup. 
