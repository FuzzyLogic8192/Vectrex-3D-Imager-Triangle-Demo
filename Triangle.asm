	.CR     6809
	.TF	Triangle.bin,BIN
    ; Copyright (C) FuzzyLogic8192
    ;***************************************************************************
    ; DEFINE SECTION
    ;***************************************************************************
    ; BIOS Rooutines
Intensity_7F	.EQ	$F2A9
Intensity_5F    .EQ     $F2A5                   ; BIOS Intensity routine
Print_Str_d     .EQ     $F37A                   ; BIOS print routine
Wait_Recal      .EQ     $F192                   ; BIOS recalibration
music1          .EQ     $FD0D                   ; address of a (BIOS ROM) music
Reset_Pen	.EQ	$F35B			; zero beam
Reset0Ref	.EQ	$F354			; zero integrators & beam
Read_Btns	.EQ	$F1BA
Joy_Digital	.EQ	$F1F8

    ; VIA register addresses
VIA_MUX		.EQ	$D000	; MUX Control - $00 = Y, $04 = Z, $01 = X, $06 = sound
				; $09 = PSG READ, $11 = PSG WRITE, $19 = PSG LATCH ADDR
VIA_DAC		.EQ	$D001	; DAC register
Port_B_Ctrl	.EQ	$D002	;
DAC_Ctrl	.EQ	$D003
T1_Count_L	.EQ	$D004
T1_Count_H	.EQ	$D005
T1_Latch_L	.EQ	$D006
T1_Latch_H	.EQ	$D007
T2_Count_L	.EQ	$D008	; Also used as T2 Latch
T2_Count_H	.EQ	$D009
Shift_Reg	.EQ	$D00A
VIA_Aux_Ctrl	.EQ	$D00B
VIA_Per_Ctrl	.EQ	$D00C	; /blank h/l = $E0/$C0 /zero h/l = $0E/$0C
				; 
Int_Flags	.EQ	$D00D
Int_Enable	.EQ	$D00E

    ; Useful Memory Locations
Vec_Button_Tgl	.EQ	$C811
Vec_Buttons	.EQ	$C80F
Vec_Prev_Btns	.EQ	$C810
Vec_Joy_1	.EQ	$C81B
Vec_Joy_1_X	.EQ	$C81B
Vec_Joy_1_Y	.EQ	$C81C
Vec_joy_2	.EQ	$C81D
Vec_Joy_2_X	.EQ	$C81D
Vec_joy_2_Y	.EQ	$C81E
    ; Joystick enable registers
Vec_Joy_Mux_1_X	.EQ	$C81F
Vec_Joy_Mux_1_Y	.EQ	$C820
Vec_joy_Mux_2_X	.EQ	$C821
Vec_Joy_Mux_2_Y	.EQ	$C822


   ; Defined Values
MUX_X		.EQ	$01
MUX_Y		.EQ	$00
MUX_Z		.EQ	$04
MUX_snd		.EQ	$06
Zero_Blank	.EQ	$CD
Move_Blank	.EQ	$CF
Enable_Joy_1	.EQ	$0103
Enable_Joy_2	.EQ	$0507


RIGHT_BLUE_BIT	.EQ	$01
RIGHT_GREEN_BIT	.EQ	$02
RIGHT_RED_BIT	.EQ	$04
LEFT_BLUE_BIT	.EQ	$08
LEFT_GREEN_BIT	.EQ	$10
LEFT_RED_BIT	.EQ	$20

BLUE_BITS	.EQ	$09
GREEN_BITS	.EQ	$12
RED_BITS	.EQ	$24
LEFT_BITS	.EQ	$38
RIGHT_BITS	.EQ	$07



     	; Game Header

	.OR $0000
	.DB "g GCE 0000",$80
	.DW      music1                 	 ; music from the rom
	.DB      $F8,$50,$20,-$56    		 ; height, width, rel y, rel x
                                  		 ; (from 0,0)
	.DB      "TRIANGLE",$80			; some game information,
                                                ; ending with $80
	.DB      0                      	 ; end of game header
	.DP $D0

    	; Variables
Pulse_Time	.EQ	$C890			; pulse width in clock cycles
Sync_Fail_Flag	.EQ	$C892			; wavelength in clock cycles
Sync_Count	.EQ	$C894			; 3D Imager rotation counter
Color_Delta	.EQ	$C896
Color_Delay	.EQ	$C897
Wait_To_Inc	.EQ	$C898

Intensity_Red	.EQ	$C950
Intensity_Green	.EQ	$C951
Intensity_Blue	.EQ	$C952
Color_Phase	.EQ	$C953
Debug_Color_Delay	.EQ	$C954


Imager_Sync_Flag	.EQ	$CA20
Imager_Time	.EQ	$CA22
Imager_Time_L	.EQ	$CA23
Imager_Time_Echo	.EQ	$CA24
Color_Flags	.EQ	$CA26
Sync_Fail_Mode	.EQ	$CA28
Sybc_Fail_Flag	.EQ	$CA29
Success_Count	.EQ	$CA2A
Pulse_Delay	.EQ	$CA2C
Waiting_For_Timer	.EQ	$CA2E
Sample_Count	.EQ	$CA30
Fastest_Time	.EQ	$CA32
Slowest_Time	.EQ	$CA34
Left_Triangle_Pos	.EQ	$CA36
Right_Triangle_Pos	.EQ	$CA38

    	; Initialization
	ORCC #$50				; disable interrupts

	LDA #$40				; setup Timer 1
	STA T1_Latch_L				;


	CLR Vec_Buttons				; clear button status
	CLR Vec_Prev_Btns			;



	CLR Imager_Time		; clear Imager sync time
	CLR Imager_Time_Echo	; clear previous sync time
	CLR Imager_Sync_Flag	; init flag to no-signal
	CLR Sync_Fail_Flag	;
	CLR Sync_Fail_Mode	;
	CLR Waiting_For_Timer	;


	LDD #$0000		; init triangle position to center
	STD Right_Triangle_Pos	;
	STD Left_Triangle_Pos	;


	LDA #$3F		; draw triangle in blue
	STA Intensity_Blue	;
	CLR Intensity_Green	;
	CLR Intensity_Red	;



	LDD #Enable_Joy_1
	STD Vec_Joy_Mux_1_X	; enable joystick 1

	LDD #$0000
	STD Vec_Joy_Mux_2_X	; disable joystick 2



	LDA #$FF		; set DAC to output
	STA DAC_Ctrl		;


   	; setup IRQ handler
	LDA #$7E		; Long JMP instruction
	STA $CBF8		; IRQ interrupt vector
	LDD #IRQ_Handler	; address of sync routine
	STD $CBF9		;



    	; setup PSG to Read REG14

	
	LDA #$0E		; PSG register 14
	STA VIA_DAC		; write to DAC
	LDB #$19		; set PSG to latch addr
	STB VIA_MUX		;
	LDB #$01		; set PSG inactive
	STB VIA_MUX		;


	LDA #$7F		; disable interrupts
	STA Int_Enable		;
	ORCC #$50		;
	LDA #$A2		;
	STA Int_Enable		; enable CA1 and T2 interrupts

	LDA #$CD		; set trigger to positive edge
	STA VIA_Per_Ctrl	;

	ANDCC #$EF		; enable IRQ



main:


	JSR Process_Buttons		; select colors and move triangle

	JSR Wait_Sync			; sync with Imager




     	; right blue

	JSR Deflok			;

	LDA Color_Delta			; get color phase width

	LDB #$55			; divide by 3
	MUL				;
	BITB #$80			;
	BEQ debug_add_right_delay	;
	INCA				;
debug_add_right_delay:

	ADDA Color_Delay		;
	STA Debug_Color_Delay		; store delay

	
	

debug_wait_right_blue:
	LDA T2_Count_H			; get timer count
	SUBA Pulse_Delay		; subtract pulse delay (high byte)
	NEGA				; negate to find difference
	CMPA Debug_Color_Delay		; compare with initial delay
	BLO debug_wait_right_blue	; if less, keep waiting

	LDD Right_Triangle_Pos		; get right-eye triangle position
	JSR Draw_Triangle		;



	JSR Wait_Color_Phase		; wait for next color phase


    	; right green

	JSR Deflok			;
	LDD Right_Triangle_Pos		; get right-eye triangle position
	JSR Draw_Triangle		;


	JSR Wait_Color_Phase		; wait for next color phase

     	; right red

	JSR Deflok			;
	LDD Right_Triangle_Pos		; get right-eye triangle position
	JSR Draw_Triangle		;


	JSR Wait_Color_Phase		; wait for next color phase


    	; left blue

	JSR Deflok			;

	LDA Color_Delta			; get color phase width

	LDB #$55			; divide by 3
	MUL				;
	BITB #$80			;
	BEQ debug_add_left_delay	;
	INCA				;
debug_add_left_delay:

	ADDA Color_Delay		;
	STA Debug_Color_Delay		; store delay

	
	

debug_wait_left_blue:
	LDA T2_Count_H			; get timer count
	SUBA Pulse_Delay		; subtract pulse delay (high byte)
	NEGA				; negate to find difference
	CMPA Debug_Color_Delay		; compare with initial delay
	BLO debug_wait_left_blue	; if less, keep waiting

	LDD Left_Triangle_Pos		; get left-eye triangle position
	JSR Draw_Triangle		;





	JSR Wait_Color_Phase		; wait for next color phase


     	; left green

	JSR Deflok			;
	LDD Left_Triangle_Pos		; get left-eye triangle position
	JSR Draw_Triangle		;



	JSR Wait_Color_Phase		; wait for next color phase


    	; left red

	JSR Deflok			;
	LDD Left_Triangle_Pos		; get left-eye triangle position
	JSR Draw_Triangle		;

	LBRA main			; loop





Draw_Triangle:


	STB VIA_DAC			; write Y offset to DAC
	CLR VIA_MUX			; strobe mux
	NOP				;
	NOP				;
	LDB #$01			; 
	STB VIA_MUX			;
	STA VIA_DAC			; write X offset to DAC

	LDA #Move_Blank			; free beam
	STA VIA_Per_Ctrl		;

	CLR T1_Count_H			; MOVE

pos_beam_wait:
	LDA Int_Flags			;
	BITA #$40			; beam done yet?
	BEQ pos_beam_wait		; if not, wait


	LDX #The_Triangle		; point X at triangle vector definition
	JSR Draw_Vector_X		; 
	JSR Draw_Vector_X		; draw the triangle
	JSR Draw_Vector_X		;

    	; zero beam
	CLR VIA_DAC			;
	CLR VIA_MUX			;
	LDA #$01			;
	NOP				;
	NOP				;
	STA VIA_MUX			;

	LDA #Zero_Blank			; zero beam
	STA VIA_Per_Ctrl		;

	RTS				;







	
   	; Vector Draw Routine
Draw_Vector_X:

	LDA Color_Phase			; load color parameter
	BITA #RED_BITS			; use red intensity?
	BEQ check_draw_green		; if not, check green
	LDB Intensity_Red		; else, load red intensity
	BRA draw_color_vector		;
check_draw_green:
	BITA #GREEN_BITS		; use green intensity?
	BEQ draw_blue			; if not, must be blue
	LDB Intensity_Green		; else, load green intensity
	BRA draw_color_vector		;
draw_blue:
	LDB Intensity_Blue		; load blue intensity
draw_color_vector:


	ORCC #$10		; disable IRQ while we load parameters

	STB VIA_DAC		; write to DAC

    	; strobe mux
    	;
	LDB #MUX_Z		; set mux to brightness
	STB VIA_MUX		;
	LDA ,X+			; get current Y vel (and prolong mux strobe)
	LDB #MUX_X		; switch mux off
	STB VIA_MUX		;


	STA VIA_DAC		; write Y vel to DAC

    	; strobe mux
    	;
	LDB #MUX_Y		; set mux to Y integrator
	STB VIA_MUX		;
	LDA ,X+			; get current time / scale factor (and prolong mux strobe)
	LDB #MUX_X		; switch mux off
	STB VIA_MUX		;



	CLR VIA_DAC		; re-zero X integrator


	STA T1_Latch_L		; write to Timer 1 latch

	LDA ,X+			; get current X vel
	STA VIA_DAC		; write to DAC (integrator ought to be re-zeroed by now)


    	; **DRAW**
	
	DEC Shift_Reg		; switch on beam
	CLR T1_Count_H		; start timer / beam motion

	ANDCC #$EF		; re-enable IRQ

wait_for_vec:
	LDA Int_Flags		; wait for vector to finish drawing
	BITA #$40		;
	BEQ wait_for_vec	;

	CLR Shift_Reg		; switch off beam

	RTS








Update_Position:



	TST Vec_Joy_1_Y				; move triangle?
	BEQ update_position_exit		; if zero, do not update 
	BGT move_deeper				; if positive (up), move into screen

    	; else, move out of screen
	
	LDD Right_Triangle_Pos			; get current position
	CMPA #$90				; check boundary
	BLE update_position_exit		; if at boundary, skip update
	DECA					; else, update
	STD Right_Triangle_Pos			;

	LDD Left_Triangle_Pos			; get current position
	CMPA #$6F				; check boundary
	BGE update_position_exit		; if at boundary, skip update
	INCA					; else, update
	STD Left_Triangle_Pos			;

	BRA update_position_exit		;

move_deeper:

	LDD Right_Triangle_Pos			; get current position
	CMPA #$6F				; check boundary
	BGE update_position_exit		; if at boundary, skip update
	INCA					; else, update
	STD Right_Triangle_Pos			;

	LDD Left_Triangle_Pos			; get current position
	CMPA #$90				; check boundary
	BLE update_position_exit		; if at boundary, skip update
	DECA					; else, update
	STD Left_Triangle_Pos			;


update_position_exit:

	LDA Vec_Buttons				; 
	STA Vec_Prev_Btns			; update previous button state

	RTS					; return







Process_Buttons:

	LDA Vec_Buttons			; get current button state
	TSTA				;




	BITA #01			; is button 1 pressed?
	BEQ check_button_2		; if not, skip to check button 2


	LDA #RED_BITS			; update red intensity
	JSR Change_Color		;


check_button_2:

	LDA Vec_Buttons			; get current button state
	BITA #02			; is button 2 pressed?
	BEQ check_button_3		; if not, skip to check button 3

	LDA #GREEN_BITS			; update green intensity
	JSR Change_Color		;

check_button_3:

	LDA Vec_Buttons			; get current button state
	BITA #04			; is button 3 pressed?
	BEQ check_button_4		; if not, skip to check button 4

	LDA #BLUE_BITS			; update blue intensity
	JSR Change_Color		;

check_button_4:
    	LDA Vec_Buttons			; get current button state
	BITA #$08			; is button 4 pressed?
	BNE Update_Position		; if so, update triangle position

	LDA Vec_Buttons			; 
	STA Vec_Prev_Btns		; update previous button state

	RTS				; return




Change_Color:
	CMPA #RED_BITS			; adjust red?
	BNE check_load_green		; if not, check green
	LDB Intensity_Red		; else, load red intensity
	BRA adjust_color_intensity	;
check_load_green:
	CMPA #GREEN_BITS		; adjust green?
	BNE load_blue			; if not, must be blue
	LDB Intensity_Green		; else, load green intensity
	BRA adjust_color_intensity	;
load_blue:
	LDB Intensity_Blue		; load blue intensity
adjust_color_intensity:
	
	TST Vec_Joy_1_Y			;
	BEQ change_color_exit		; if joystick centered, perform no adjustment
	BGT inc_color			;

    	; else, dec color
	TSTB				; skip adjustment if already at min
	BEQ change_color_exit		;

	DECB				;
	BRA save_color			;

inc_color:

	CMPB #$3F			; skip adjustment if already at max
	BHS change_color_exit		;
	
	INCB				;

save_color:
	CMPA #RED_BITS			; adjust red?
	BNE check_save_green		; if not, check green
	STB Intensity_Red		;
	BRA change_color_exit		;
check_save_green:
	CMPA #GREEN_BITS		; adjust green?
	BNE save_blue			; if not, must be blue
	STB Intensity_Green		;
	BRA change_color_exit		;
save_blue:
	STB Intensity_Blue		;

change_color_exit:
	RTS				; return


    	; Get Button State Routine
Get_Buttons:
	CLR VIA_DAC		; clear DAC and set DDAC to input
	CLR DAC_Ctrl		;
	LDA #$09		; read button state from PSG
	STA VIA_MUX		;
	LDB #$01		; prep to set PSG inactive (and prolong mux strobe)
	LDA VIA_DAC		; get button state
	STB VIA_MUX		; finish setting PSG inactive
	COMA			; invert
	STA Vec_Buttons		;
	DEC DAC_Ctrl		; set DDAC to output
	RTS			; return




   	; *******************
   	; Sync 30 Hz Routines
   	; *******************




sync_fail:

	JSR config_PSG_output		; reconfigure PSG to output (prep for next pulse)

	INC Sync_Fail_Mode		; set sync fail mode flag for IRQ routine
	CLR Waiting_For_Timer		; set IRQ to wait for sync signal

sync_fail_loop_reset:
	CLR Success_Count		; init success counter to zero

sync_fail_loop:
	LDA #$C3			;
	STA T2_Count_H			; restart T2
	CLR Imager_Sync_Flag		; clear sync flag

sync_fail_pulse_loop:
   	;pulse
	LDA #$80			;
	STA VIA_DAC			;
	LDB #$11			; PSG Write
	STB VIA_MUX			;
	NOP				;
	NOP				;
	LDB #$01			; PSG inactive
	STB VIA_MUX			;

    	; delay
	LDA #$6C			;
sync_fail_wait:
	DECA				;
	BNE sync_fail_wait		;

   	; cease pulse
	LDA #$FF			;
	STA VIA_DAC			;
	LDB #$11			; PSG Write
	STB VIA_MUX			;
	NOP				;
	NOP				;
	LDB #$01			; PSG inactive
	STB VIA_MUX			;

    	; delay
	LDA #$54			;
sync_fail_pulse_wait:
	DECA				;
	BNE sync_fail_pulse_wait	;

	LDA T2_Count_H			; check T2
	CMPA #$C3			;
	BLS sync_fail_pulse_loop	; if still running, loop and pulse again

	TST Imager_Sync_Flag		; else, check for sync signal
	BEQ sync_fail_loop_reset	; if none, clear success count, restart T2, and pulse again

	LDA Success_Count		;
	INCA				; inc success counter
	STA Success_Count		;
	CMPA #$04			; compare to 4
	BLT sync_fail_loop		; if less, restart T2 and check again


	LDD #$6000			; restore default pulse delay
	STD Pulse_Delay			;
	CLR Sample_Count		; reset IRQ sample counter
	LDD #$0000			;
	STD Fastest_Time		; reset IRQ counter variables
	LDD #$FFFF			;
	STD Slowest_Time		;
	STD T2_Count_L			; restart T2	
	CLR Imager_Sync_Flag		; clear sync flag
	CLR Sync_Fail_Flag		; clear sync fail flag for Wait_Sync
	CLR Sync_Fail_Mode		; clear sync fail mode flag for IRQ handler


					; re-enter Wait_Sync routine
	

					;	BRA Wait_Sync			; re-sync


Wait_ReSync:
	CLR Success_Count		; clear success counter


   	; Wait Sync Routine
   	; called periodically to sync vectors to Imager

Wait_Sync:




   	; Zero Beam
	LDB #Zero_Blank			; zero & blank beam
	STB VIA_Per_Ctrl		;


	TST Imager_Sync_Flag		; check that signal has not come in yet
	BEQ wait_for_Imager		; if not, wait for it

    	; else, we're late, drop frame
	CLR Imager_Sync_Flag		; clear signal, then wait for next one


wait_for_Imager:
	TST Sync_Fail_Flag		; check sync fail flag
	LBNE sync_fail			; if set, spin up the Imager

	TST Imager_Sync_Flag		; else, check if signal received
	BNE prep_exit			; if so, prepare to exit



   	; else, do something intelligent here while we wait	
	NOP
	NOP
	NOP
	NOP


	BRA wait_for_Imager		; loop and wait



prep_exit:
	ORCC #$10			; disable IRQ while we gather user input

	JSR config_PSG_input		;
	JSR Get_Buttons			; get user input (while we can)
	JSR Joy_Digital			; call BIOS rotuine (for now...)
	JSR config_PSG_output		;

	ANDCC #$EF			; re-enable IRQ

	CLR Imager_Sync_Flag		; clear sync flag

    	; calculate phase delta

	LDD Imager_Time			; get timestamp
	COMD				; convert to time delta
	ADDD Pulse_Delay		; add last pulse delay to get total period
	

	LDB #$55			;
	MUL				; divide high byte by 6
	BITB #$80			;
	BEQ wait_sync_divide_two	;
	INCA				;
wait_sync_divide_two:
	LSRA				;


wait_sync_check_delta:

    	; safety check
	CMPA #$1C			; compare color delta to minimum
	BLT Wait_Resync			; if less, we're out of sync
	CMPA #$28			; compare color delta to maximum
	BGT Wait_Resync			; if more, we're out of sync

	STA Color_Delta			; else, save new phase delta


	LDA Success_Count		; check that we have seen
	CMPA #$20			; 32 consecutive on-time frames
	BHI wait_sync_exit		; before returning to caller
	INC Success_Count		; if less, keep waiting for more
	BRA Wait_Sync			;

wait_sync_exit:


    	; zero beam, integrators, offset, and set ground
	CLR VIA_DAC			;
	LDA #$04			;
	STA VIA_MUX			; clear brightness
	LDA #$02			;
	STA VIA_MUX			; zero X,Y offset
	CLR Shift_Reg			;
	CLR VIA_MUX			; zero X, Y integrators
	CLR Shift_Reg			;
	INC VIA_MUX			; disable mux


	CLR Color_Delay			; init color phase delay



	LDA Color_Delta			;
	LSRA				; divide color phase by 4
	LSRA				;

	STA Color_Delay			; init color phase delay

	LDA #$01			;
	STA Color_Phase			; init color phase to right-blue

wait_right_blue:
	LDA T2_Count_H			; get timer count
	SUBA Pulse_Delay		; subtract pulse delay (high byte)
	NEGA				; negate to find difference
	CMPA Color_Delay		; compare with initial delay
	BLO wait_right_blue		; if less, keep waiting




	RTS				; return

   	; ****END OF WAIT SYNC ROUTINE****
	




     	; Wait for Color Phase routine
     	; Sync vectors to color phases
     	; returns when next color phase begins
Wait_Color_Phase:

	LDB Color_Delta			; get color phase length
	ADDB Color_Delay		; add to current color delay time
	STB Color_Delay			; update color delay time

	LSL Color_Phase			; update phase counter

wait_color:
	LDA T2_Count_H			; get timer count
	SUBA Pulse_Delay		; subtract pulse delay (high byte)
	NEGA				; negate to find difference
	CMPA Color_Delay		; compare with color delay
	BLO wait_color			; if less, keep waiting


	RTS				; else, return



     	; "Deflok" routine
     	; Prevents scan collapse
     	; to be called at the start of every color phase
Deflok:
    	; free beam, draw 7F, 7F vector at scale FF
	ORCC #$10			; disable IRQ
	LDA #Move_Blank			; free vector beam
	STA VIA_Per_Ctrl		;
	LDA #$7F			;
	STA VIA_DAC			; set X and Y integrators to max
	CLR VIA_MUX			;
	LDA #$FF			; setup T1
	STA T1_Latch_L			;
	CLR T1_Count_H			; DRAW

wait_deflok_1:
	LDA Int_Flags			;
	BITA #$40			; is beam finished?
	BEQ wait_deflok_1		; if not, check again


    	; zero beam
	CLR VIA_DAC			;
	LDA #Zero_Blank			;
	STA VIA_Per_Ctrl		;

    	; free beam, draw 80,80 vector at scale FF
	LDA #Move_Blank			; free vector beam
	STA VIA_Per_Ctrl		;
	LDA #$80			;
	ORCC #$10			; disable IRQ
	STA VIA_DAC			; set X and Y integrators to max
	CLR VIA_MUX			;
	LDA #$FF			; setup T1
	STA T1_Latch_L			;
	CLR T1_Count_H			; DRAW

wait_deflok_2:
	LDA Int_Flags			;
	BITA #$40			; is beam finished?
	BEQ wait_deflok_2		; if not, check again

    	; zero beam
	LDB #Zero_Blank			; zero & blank beam
	STB VIA_Per_Ctrl		;

	ANDCC #$EF			; re-enable IRQ

	RTS				; return



    	; *** IRQ ROUTINE ***

IRQ_sync_fail:

	TST Sync_Fail_Mode		; sync fail?
	BNE IRQ_sync_fail_exit		; if so, exit

	INC Sync_Fail_Flag		; else, signal main program to re-sync Imager

IRQ_sync_fail_exit:
	LDA #$20			; clear interrupt flag
	STA Int_Flags			;

	RTI				; return




IRQ_T2:
	TST Waiting_For_Timer		; were we waiting for T2 to expire?
	BEQ IRQ_sync_fail		; if not, we're out of sync


   	; else, initiate new pulse
	LDA #$80			;
	STA VIA_DAC			;
	LDB #$11			; PSG Write
	STB VIA_MUX			;
	LDD #$FFFF			; restart T2
	STD T2_Count_L			;
	LDB #$01			; PSG inactive
	STB VIA_MUX			;	

 	CLR Waiting_For_Timer		; clear flag, we're now waiting for sync signal

	RTI				; return





   	; IRQ Handler
   	; Triggered by Imager sync signal or T2 countdown
IRQ_Handler:	

	LDB Int_Flags			; get interrupt flag register
	LDX T2_Count_L			; get timestamp

    	; if vector is being drawn, wait for it to finish
IRQ_wait_vector:
	LDA Int_Flags			; fetch interrupt flags again
	BITA #$40			; check if T1 has counted down
					;	BNE IRQ_done_vector		; if not, wait for it
					;	LDA T1_Count_H			; else, check T1
	BEQ IRQ_wait_vector		; if not, keep waiting

IRQ_done_vector:
	CLR Shift_Reg			; blank beam output


	LDA #$01			; ensure MUX is disabled
	STA VIA_MUX			;
	
    	; find out what triggered routine
	BITB #$02			; got sync?
	BEQ IRQ_T2			; if not, branch to timeout handler


   	; else, sync signal triggered IRQ.
	TST Waiting_for_Timer		; were we waiting for sync?
	BNE IRQ_sync_fail		; if not, we're out of sync

   	; else, we were expecting this sync signal

	INC Imager_Sync_Flag		; set flag / counter


	TST Sync_Fail_Mode		; sync fail?
	LBNE IRQ_exit			; if so, simply exit

    	; cease pulse
	LDA #$FF			;
	STA VIA_DAC			;
	LDB #$11			; PSG Write
	STB VIA_MUX			;
	LDD Pulse_Delay			; load pulse delay
	EXG A,B				; byteswap
	STD T2_Count_L			; start T2
	LDB #$01			; PSG inactive
	STB VIA_MUX			;
	

	TFR X,D				; get timer value
	EXG A,B				; byteswap
	STD Imager_Time			; store as timestamp




    	; calculate pulse delay

   	; check sample count
	LDA Sample_Count		;
	CMPA #$10			; have we collected 16 samples yet?
	BLT add_sample			; if not, count this one

    	; else, check stability
	
	LDD Fastest_Time		;
	SUBD Slowest_Time		;
	CMPD #$0400			; delta = 1K cycles or less?
	BHI reset_samples		; if not, skip update of delay

   	; if stable, perform final check on current sync signal...
	
	LDD Imager_Time			; get current timestamp
	CMPD Fastest_Time		; ensure it falls within established bounds
	BHI reset_samples		; too fast, collect another 16 samples
	CMPD Slowest_Time		; 
	BLO reset_samples		; too slow, collect another 16 samples

    	; update delay

	COMD				; convert timestamp to time delta
	ADDD Pulse_Delay		; add current delay to get total period
	SUBD #$C2AD			; subtract desired period to find error
	COMD				; negate to turn error into correction factor
	ASRD				; divide by two to avoid over-compensation
	ADDD Pulse_Delay		; add correction to current delay
	STD Pulse_Delay			; save new delay



reset_samples:
	LDD #$0000			;
	STD Fastest_Time		; reset variables
	LDD #$FFFF			;
	STD Slowest_Time		;

	CLR Sample_Count		; reset sample counter

add_sample:
	LDD Imager_Time			; get timestamp
	CMPD Fastest_Time		;
	BLS not_fastest			; fastest seen so far?
	STD Fastest_Time		; if so, save it
not_fastest:
	CMPD Slowest_Time		; slowest seen so far?
	BHS not_slowest			;
	STD Slowest_Time		; if so, save it
not_slowest:

	INC Sample_Count		; inc sample counter	


	INC Waiting_For_Timer		; set flag indicating wait for T2 timeout




IRQ_exit:


	LDA #$02			; clear IRQ flag
	STA Int_Flags			;

	RTI				; return

   	; ****END OF IRQ HANDLER****




   	; Config PSG Input Routine
   	; sets PSG to read input from controllers
config_PSG_input:


   	; Latch Reg 7 addr
	LDA #$07		; PSG Register 7
	LDB #$19		; PSG latch addr
	STA VIA_DAC		;
	STB VIA_MUX		;
	LDA #$01		; PSG inactive
	STA VIA_MUX		;

   	; get current Reg 7 state
	CLR VIA_DAC		;
	CLR DAC_Ctrl		; set DAC to input
	LDA #$09		; PSG Read
	STA VIA_MUX		;
	LDB #$01		; prep for PSG inactive
	LDA VIA_DAC		; get current PSG reg 7 state

	STB VIA_MUX		; PSG inactive

   	; set output bit and write back Reg 7
	ANDA #$BF		; clear bit 6 (output enable bit)
	DEC DAC_Ctrl		; set DAC to output
	LDB #$11		; PSG write
	STA VIA_DAC		; write PSG register 7
	STB VIA_MUX		;
	LDA #$01		; PSG inactive
	STA VIA_MUX		;

   	; latch Reg 14 addr
	LDA #$0E		; PSG register 14
	STA VIA_DAC		; write to DAC
	LDB #$19		; set PSG to latch addr
	STB VIA_MUX		;
	LDB #$01		; set PSG inactive
	STB VIA_MUX		;

	RTS			; return




   	; Config PSG Output Routine
   	; Sets PSG to output signal to Imager
config_PSG_output:


   	; Latch Reg 7 addr
	LDA #$07		; PSG Register 7
	LDB #$19		; PSG latch addr
	STA VIA_DAC		;
	STB VIA_MUX		;
	LDA #$01		; PSG inactive
	STA VIA_MUX		;

   	; get current Reg 7 state
	CLR VIA_DAC		;
	CLR DAC_Ctrl		; set DAC to input
	LDA #$09		; PSG Read
	STA VIA_MUX		;
	LDB #$01		; prep for PSG inactive
	LDA VIA_DAC		; get current PSG reg 7 state
	STB VIA_MUX		; PSG inactive

   	; set output bit and write back Reg 7
	ORA #$40		; set bit 6 (output enable bit)
	DEC DAC_Ctrl		; set DAC to output
	LDB #$11		; PSG write
	STA VIA_DAC		; write PSG register 7
	STB VIA_MUX		;
	LDA #$01		; PSG inactive
	STA VIA_MUX		;

   	; latch Reg 14 addr
	LDA #$0E		; PSG register 14
	STA VIA_DAC		; write to DAC
	LDB #$19		; set PSG to latch addr
	STB VIA_MUX		;
	LDB #$01		; set PSG inactive
	STB VIA_MUX		;

	RTS			; return




The_Triangle:			; { Y, scale, X, }, ...
	.DB $C0,$40,$20,$00,$40,$C0,$40,$40,$20

		
