$NOMOD51
;*****************************************************************************
;  Project
;
;  YOUR NAME   :  Austin Atteberry
;  FILE NAME   :  CatToy.asm
;  DATE        :  11/28/2017
;  TARGET MCU  :  C8051F340
;  DESCRIPTION :  This program generates a random number, which is used to
;              :  control actuators connected to Port 0. The speed of the
;              :  actuators is controlled by a keypad connected to Port 3.
;              :  The speed is displayed on an LCD display connected to Port
;              :  1.
;
; 	NOTES: 
;
;*****************************************************************************

$NOLIST
$include (c8051f340.inc)                    ; Include register definition file.
$LIST


;*****************************************************************************
;
; EQUATES
;
;*****************************************************************************

ENABLE           equ  P1.4                  ; Enable signal to LCD
RW               equ  P1.2                  ; R/W signal to LCD.
RS               equ  P1.3                  ; RS signal to LCD
LCD              equ  P2                    ; Output port to LCD.

keyport          equ P3                     ; Keypad port connected here
row1             equ P3.0                   ; Row 1 (pin 1)
row2             equ P3.1                   ; Row 2 (pin 2) 
row3             equ P3.2                   ; Row 3 (pin 3)
row4             equ P3.3                   ; Row 4 (pin 4)

col1             equ P3.4                   ; Column 1 (pin 5)
col2             equ P3.5                   ; Column 2 (pin 6)
col3             equ P3.6                   ; Column 3 (pin 7)
col4             equ P3.7                   ; Column 4 (pin 8)


;*****************************************************************************
;
; RESET and INTERRUPT VECTORS
;
;*****************************************************************************

         ; Reset Vector
                 org 0000H
                 ljmp Main                  ; Locate a jump to the start of
                                            ; code at the reset vector.


;*****************************************************************************
;
; MAIN CODE
;
;*****************************************************************************

Main:

                 anl PCA0MD,#NOT(040h)      ; Clear Watchdog Enable bit
                 mov P2MDOUT, #0FFH         ; Make P2 output push-pull
                 mov P1MDOUT, #0FFH         ; Make P1 output push-pull
                 mov P1MDIN, #0FFH          ; Make port pins input mode digital
                 mov P0MDOUT, #0FFH         ; Male P0 output push-pull
                 mov P3MDOUT, #0FH          ; Make P3 low nibble output push-pull
                 mov XBR1, #40H             ; Enable Crossbar
                 mov P0, #0                 ; Set Port 0 low
                 mov R0, #0                 ; Initialize R0
                 mov R1, #1FH               ; Initialize R1
                 mov R2, #0                 ; Clear mode select (R2)
                 mov R3, #0                 ; Clears LCD position counter
                 mov R4, #0                 ; Set initial speed to 1

                 call Init                  ; LCD Initialization proceedure
                 call Clear                 ; Clear LCD Display
                 call DisplayIntro          ; Call DisplayIntro subroutine
                 call AutoDisplay           ; Call AutoDisplay subroutine
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 call Autoroutine           ; Call Autoroutine subroutine

Start:           mov R0, #0                 ; clear R0 - the first key is key0

                 setb row4                  ; set row4
                 clr row1                   ; clear row1
                 call colScan               ; call column-scan subroutine
                 jb F0, finish              ; if F0 is set, jump to end of program
                 setb row1                  ; set row1
                 clr row2                   ; clear row2
                 call colScan               ; call column-scan subroutine
                 jb F0, finish              ; if F0 is set, jump to end of program
                 setb row2                  ; set row2
                 clr row3                   ; clear row3
                 call colScan               ; call column-scan subroutine
                 jb F0, finish              ; if F0 is set, jump to end of program
                 setb row3                  ; set row3
                 clr row4                   ; clear row4
                 call colScan               ; call column-scan subroutine
                 jb F0, finish              ; if F0 is set, jump to end of program

                 cjne R2, #0H, stagain      ; Jump to stagain if not in Auto mode
                 cjne R5, #0H, sdfasfda     ; Jump to sdfasfda if not 0
                 cjne R6, #0H, poaefbef     ; Jump to poaefbef if not 0
                 call Autoroutine           ; Call Autoroutine subroutine

finish:          mov DPTR, #Table1          ; Initialize Data Pointer
                 mov A, R0                  ; move keynumber to acc
                 movc A, @A + DPTR          ; Get key character
                 call control               ; Call control subroutine
                 clr F0                     ; clear flag
                 jmp start                  ; Continue looking for next key

sdfasfda:        dec R5                     ; Decrement R5
                 jmp start                  ; Continue looking for next key

poaefbef:        mov R5, #0FFH              ; Reset R5
                 dec R6                     ; Decrement R6
                 jmp start                  ; Continue looking for next key

stagain:         jmp start                  ; Continue looking for next key


;*****************************************************************************
;
;  colScan subroutine
;
;  The subroutine scans columns. It is called during each scan row event.
;  If a key in the current row being scaned has been pressed, the subroutine
;  will determine which column. when a key if found to be pressed, the
;  subroutine waits until the key has been released before continuing. This
;  method debounces the input keys.
;
;  GLOBAL REGESTERS USED: R0
;  GLOBAL BITS USED: F0(PSW.5)
;  INPUT: col1(P3.4), col2(P3.5), col3(P3.6), col4(P3.7)
;  OUTPUT: R0, F0
;
;*****************************************************************************

colScan:         jb col1, nextcol           ; check if col1 key is pressed
                 jnb col1, $                ; If yes, then wait for key release
                 jmp gotkey                 ; Have key, return
nextcol:         inc R0                     ; Increment keyvalue
                 jb col2, nextcol2          ; check if col2 key is pressed
                 jnb col2, $                ; If yes, then wait for key release
                 jmp gotkey                 ; Have key, return
nextcol2:        inc R0                     ; Increment keyvalue
                 jb col3, nextcol3          ; check if col3 key is pressed
                 jnb col3, $                ; If yes, then wait for key release
                 jmp gotkey                 ; Have key, return
nextcol3:        inc R0                     ; Increment keyvalue
                 jb col4, nokey             ; check if col4 key is pressed
                 jnb col4, $                ; If yes, then wait for key release
                 jmp gotkey                 ; Have key, return
nokey:           inc R0                     ; Increment keyvalue
                 ret                        ; finished scan, no key pressed
gotKey:          setb F0                    ; key found - set F0
                 ret                        ; and return from subroutine


;*****************************************************************************
;
;  Autoroutine subroutine
;
;  This subroutine sets pins 1-3 on P0.
;
;  LOCAL REGISTERS USED: none
;  INPUT: none
;  OUTPUT: P0
;
;*****************************************************************************

Autoroutine:     call Random                ; Call random subroutine
                 mov DPTR, #Table4          ; Initialize Data Pointer
                 movc A, @A + DPTR          ; Get port configuration
                 mov P0, A                  ; Set port output
                 call Speed                 ; Call Speed subroutine
                 ret                        ; Return


;*****************************************************************************
;
;  Random subroutine
;
;  This subroutine generates a pseudorandom 2-bit number by multiplying R1
;  with a prime seed and zeroing out the most significant six bits. 
;
;  LOCAL REGISTERS USED: none
;  INPUT: none
;  OUTPUT: ACC
;
;*****************************************************************************

Random:          mov A, R1                  ; Assign R1 to A
                 jnz random1                ; Jump if not zero
                 cpl A                      ; Complement A
                 mov R1, A                  ; Assign A to R1
random1:         anl a, #0B8H               ; And A with 184
                 mov C, P                   ; Move parity bit into C
                 mov A, R1                  ; Assign R1 to A
                 rlc A                      ; Rotate A left
                 mov R1, A                  ; Assign A to R1
                 clr ACC.7                  ; Zero first bit of A
                 clr ACC.6                  ; Zero second bit of A
                 clr ACC.5                  ; Zero third bit of A
                 clr ACC.4                  ; Zero fourth bit of A
                 clr ACC.3                  ; Zero fifth bit of A
                 clr ACC.2                  ; Zero sixth bit of A
                 ret                        ; Return


;*****************************************************************************
;
;  Speed subroutine
;
;  This subroutine calls the delay function a predetermined number of times
;  based on the speed setting.
;
;  LOCAL REGISTERS USED: none
;  INPUT: none
;  OUTPUT: none
;
;*****************************************************************************

Speed:           cjne R4, #9, speed8        ; Jump if (R4 != 9)
                 mov   R6, #01FH            ; Set register 6
                 mov   R5, #00H             ; Set register 5
                 jmp repeat                 ; Jump to repeat
speed8:          cjne R4, #8, speed7        ; Jump if (R4 != 8)
                 mov   R6, #01FH            ; Set register 6
                 mov   R5, #07H             ; Set register 5
                 jmp repeat                 ; Jump to repeat
speed7:          cjne R4, #7, speed6        ; Jump if (R4 != 7)
                 mov   R6, #01FH            ; Set register 6
                 mov   R5, #0FH             ; Set register 5
                 jmp repeat                 ; Jump to repeat
speed6:          cjne R4, #6, speed5        ; Jump if (R4 != 6)
                 mov   R6, #02FH            ; Set register 6
                 mov   R5, #17H             ; Set register 5
                 jmp repeat                 ; Jump to repeat
speed5:          cjne R4, #5, speed4        ; Jump if (R4 != 5)
                 mov   R6, #02FH            ; Set register 6
                 mov   R5, #1FH             ; Set register 5
                 jmp repeat                 ; Jump to repeat
speed4:          cjne R4, #4, speed3        ; Jump if (R4 != 4)
                 mov   R6, #02FH            ; Set register 6
                 mov   R5, #27H             ; Set register 5
                 jmp repeat                 ; Jump to repeat
speed3:          cjne R4, #3, speed2        ; Jump if (R4 != 3)
                 mov   R6, #03FH            ; Set register 6
                 mov   R5, #2FH             ; Set register 5
                 jmp repeat                 ; Jump to repeat
speed2:          cjne R4, #2, speed1        ; Jump if (R4 != 2)
                 mov   R6, #03FH            ; Set register 6
                 mov   R5, #37H             ; Set register 5
                 jmp repeat                 ; Jump to repeat
speed1:          mov   R6, #03FH            ; Set register 6
                 mov   R5, #3FH             ; Set register 5
                 jmp repeat                 ; Jump to repeat
repeat:          ret                        ; Return


;*****************************************************************************
;
;  init subroutine
;
;  The subroutine is used initialize the LCD during startup. 
;
;  LOCAL REGISTERS USED: None
;  INPUT: 
;  OUTPUT: LCD (P2), ENABLE (P1.4)
;
;*****************************************************************************

init:            clr RS                     ; Register Select
                 clr RW                     ; Read/Write ( 1 = Read  ; 0 = Write )
                 clr ENABLE                 ; High to Low Transition Stores the data
                 call delay                 ; Waits for LCD to stabilize
                 call reset                 ; Sends reset bytes to LCD
                 mov LCD, #38H              ; Function Set Word
                 call Busy                  ; Check Busy Flag
                 setb ENABLE                ; Latched the first byte.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets latch.
                 call busy                  ; Check Busy Flag
                 mov LCD, #08H              ; Display Off word
                 call Busy                  ; Check Busy Flag
                 setb ENABLE                ; Latched the first byte.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets latch.
                 call Busy                  ; Check Busy Flag
                 mov LCD, #0FH              ; Display On word.
                 call Busy                  ; Check Busy Flag
                 setb ENABLE                ; Latched the first byte.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets latch
                 call Busy                  ; Check Busy Flag
                 mov LCD, #06H              ; Entry Mode word
                 call Busy                  ; Check Busy Flag
                 setb ENABLE                ; Latched the first byte.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets latch.
                 call Busy                  ; Check Busy Flag
                 mov LCD, #02H              ; Display Home word
                 call Busy                  ; Check Busy Flag
                 setb ENABLE                ; Latched the first byte.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets latch.
                 call Busy                  ; Check Busy Flag
                 ret                        ; Return


;*****************************************************************************
;
;  clear subroutine
;
;  Clears the LCD.
;  Used one 8-bit data move to send the Clear Display Instruction command
;  (01H) to the LCD.  
;
;  The subroutine is used during initialization and when the display is full
;  to clear the display before it wraps back to DDRAM address 00.
;
;  INPUT: none
;  OUTPUT: Port 2 (LCD) and P1.4 (ENABLE)
;
;*****************************************************************************

clear:           mov LCD, #01H              ; Clear Display word
                 call Busy                  ; Check Busy Flag
                 setb ENABLE                ; Latched the first byte.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets latch
                 ret                        ; Return


;*****************************************************************************
;
;  DisplayIntro subroutine
;
;  Displays the message "Cat Toy" on the LCD screen for 5 seconds after
;  the device powers up.
;
;  LOCAL REGISTERS USED: R3
;  INPUT: none
;  OUTPUT: Port 2 (LCD) and P1.4 (ENABLE)
;
;*****************************************************************************

DisplayIntro:    clr RS                     ; Register Select ( 0 = Command )
                 clr RW                     ; Read/Write ( 1 = Read  ; 0 = Write )
                 mov R3, #0                 ; Clear R3
                 setb ENABLE                ; Latch the data
                 call delay                 ; Call delay subroutine
                 clr ENABLE                 ; Reset latch
DisplayIntro1:   mov DPTR, #Table5          ; Initialize Data Pointer
                 mov A, R3                  ; Move table index to acc
                 movc A, @A + DPTR          ; Get character
                 call display               ; call LCD Display proceedure
                 cjne R3, #7, DisplayIntro1 ; Repeat until R3=7
                 mov R3, #19H               ; Set R3=25
DisplayIntro2:   call delay                 ; Call delay subroutine
                 djnz R3, DisplayIntro2     ; Run delay subroutine 25 times
                 call clear                 ; Call clear subroutine
                 ret                        ; Return


;*****************************************************************************
;
;  control subroutine
;
;  This subroutine determines what action to take depending on which button
;  was pressed. 
;
;  LOCAL REGISTERS USED: R2,R3
;  INPUT: byte in the Accumulator
;  OUTPUT: P0
;
;*****************************************************************************

control:         cjne A, #45H, Next1        ; Jump to Next1 if * was not pressed
                 cjne R2, #1H, Manual       ; Jump to Manual if currently in Auto
                 mov R2, #0H                ; Switch to Auto mode
                 call AutoDisplay           ; Call AutoDisplay subroutine
                 ret                        ; Return

Manual:          mov R2, #1H                ; Switch to Manual mode
                 mov P0, #0H                ; Reset actuators
                 call ManualDisplay         ; Call ManualDisplay subroutine
                 ret                        ; Return

Next1:           cjne A, #41H, Next2        ; Jump to Next2 if A was not pressed
                 cjne R2, #01H, Next2       ; Jump to Next2 if not in Manual mode
                 mov P0, #80H               ; Activate Actuator A
                 call DisplayActive         ; Call DisplayActive subroutine
                 ret                        ; Return

Next2:           cjne A, #42H, Next3        ; Jump to Next3 if B was not pressed
                 cjne R2, #01H, Next3       ; Jump to Next3 if not in Manual mode
                 mov P0, #40H               ; Activate Actuator B
                 call DisplayActive         ; Call DisplayActive subroutine
                 ret                        ; Return

Next3:           cjne A, #43H, Next4        ; Jump to Next4 if C was not pressed
                 cjne R2, #01H, Next4       ; Jump to Next4 if not in Manual mode
                 mov P0, #10H               ; Activate Actuator C
                 call DisplayActive         ; Call DisplayActive subroutine
                 ret                        ; Return

Next4:           cjne R2, #0H, NextD        ; Jump to NextD if not in Auto mode
                 cjne A, #31H, Next5        ; Jump to Next5 if 1 was not pressed
                 cjne R4, #00H, setting1    ; Jump to setting1 if speed 1 is not set
                 ret                        ; Return

Next5:           cjne A, #32H, Next6        ; Jump to Next6 if 2 was not pressed
                 cjne R4, #01H, setting2    ; Jump to setting2 if speed 2 is not set
                 ret                        ; Return

Next6:           cjne A, #33H, Next7        ; Jump to Next7 if 3 was not pressed
                 cjne R4, #02H, setting3    ; Jump to setting3 if speed 3 is not set
                 ret                        ; Return

Next7:           cjne A, #34H, Next8        ; Jump to Next8 if 4 was not pressed
                 cjne R4, #04H, setting4    ; Jump to setting4 if speed 4 is not set
                 ret                        ; Return

Next8:           cjne A, #35H, Next9        ; Jump to Next9 if 5 was not pressed
                 cjne R4, #05H, setting5    ; Jump to setting5 if speed 5 is not set
                 ret                        ; Return

Next9:           cjne A, #36H, NextA        ; Jump to NextA if 6 was not pressed
                 cjne R4, #06H, setting6    ; Jump to setting6 if speed 6 is not set
                 ret                        ; Return

NextA:           cjne A, #37H, NextB        ; Jump to NextB if 7 was not pressed
                 cjne R4, #08H, setting7    ; Jump to setting7 if speed 7 is not set
                 ret                        ; Return

NextB:           cjne A, #38H, NextC        ; Jump to NextC if 8 was not pressed
                 cjne R4, #09H, setting8    ; Jump to setting8 if speed 8 is not set
                 ret                        ; Return

NextC:           cjne A, #39H, NextD        ; Jump to NextD if 9 was not pressed
                 cjne R4, #0AH, setting9    ; Jump to setting9 if speed 9 is not set
                 ret                        ; Return

NextD:           ret                        ; Return

setting1:        mov R4, #00H               ; Set R4
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 ret                        ; Return

setting2:        mov R4, #01H               ; Set R4
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 ret                        ; Return

setting3:        mov R4, #02H               ; Set R4
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 ret                        ; Return

setting4:        mov R4, #04H               ; Set R4
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 ret                        ; Return

setting5:        mov R4, #05H               ; Set R4
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 ret                        ; Return

setting6:        mov R4, #06H               ; Set R4
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 ret                        ; Return

setting7:        mov R4, #08H               ; Set R4
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 ret                        ; Return

setting8:        mov R4, #09H               ; Set R4
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 ret                        ; Return

setting9:        mov R4, #0AH               ; Set R4
                 call DisplaySpeed          ; Call DisplaySpeed subroutine
                 ret                        ; Return


;*****************************************************************************
;
;  AutoDisplay subroutine
;
;  This subroutine displays "Auto" on the LCD 
;
;  LOCAL REGISTERS USED: R3,R4
;  INPUT: byte in the Accumulator
;  OUTPUT: LCD
;
;*****************************************************************************

AutoDisplay:     call Clear                 ; Clear LCD Display
                 mov R3, #0                 ; Clear R3

AutoDisplay1:    mov DPTR, #Table2          ; Initialize Data Pointer
                 mov A, R3                  ; Move table index to acc
                 movc A, @A + DPTR          ; Get character
                 call display               ; call LCD Display proceedure
                 cjne R3, #4, AutoDisplay1  ; Repeat until R3=4
                 ret                        ; Return


;*****************************************************************************
;
;  ManualDisplay subroutine
;
;  This subroutine displays "Manual" on the LCD 
;
;  LOCAL REGISTERS USED: R3
;  INPUT: byte in the Accumulator
;  OUTPUT: LCD
;
;*****************************************************************************

ManualDisplay:   call Clear                 ; Clear LCD Display
                 mov R3, #0                 ; Clear R3

ManDisplay1:     mov DPTR, #Table3          ; Initialize Data Pointer
                 mov A, R3                  ; Move table index to acc
                 movc A, @A + DPTR          ; Get character
                 call display               ; call LCD Display proceedure
                 cjne R3, #6, ManDisplay1   ; Repeat until R3=6
                 ret                        ; Return


;*****************************************************************************
;
;  DisplayActive subroutine
;
;  This subroutine displays the letter of the active actuator on the second
;  line of the LCD when the program is in manual mode
;
;  LOCAL REGISTERS USED: none
;  INPUT: byte in the Accumulator
;  OUTPUT: LCD
;
;*****************************************************************************

DisplayActive:   clr RS                     ; Register Select ( 0 = Command )
                 clr RW                     ; Read/Write ( 1 = Read  ; 0 = Write )
                 mov LCD, #0C0H             ; Set cursor position
                 setb ENABLE                ; Latches the data.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets latch.
                 call display               ; call LCD Display proceedure
                 ret                        ; Return


;*****************************************************************************
;
;  DisplaySpeed subroutine
;
;  This subroutine displays the speed of the active actuator on the second
;  line of the LCD. 
;
;  LOCAL REGISTERS USED: R4
;  INPUT: none
;  OUTPUT: LCD
;
;*****************************************************************************

DisplaySpeed:    clr RS                     ; Register Select ( 0 = Command )
                 clr RW                     ; Read/Write ( 1 = Read  ; 0 = Write )
                 mov LCD, #0C0H             ; Set cursor position
                 setb ENABLE                ; Latches the data.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets latch.
                 mov DPTR, #Table1          ; Initialize Data Pointer
                 mov A, R4                  ; Move table index to acc
                 movc A, @A + DPTR          ; Get character
                 call display               ; call LCD Display proceedure
                 ret                        ; Return


;*****************************************************************************
;
;  display subroutine
;
;  Moves the control or ASCII byte in the accumulator into the LCD 8-bits at
;  a time. 
;
;  LOCAL REGISTERS USED: R3
;  INPUT: byte in the Accumulator
;  OUTPUT: One byte to the LCD. 
;
;*****************************************************************************

display:                               ; The data to be sent is in A.
                 setb RS               ; Register Select ( 1 = Data )                     
                 mov LCD, A            ; Sends data to LCD
                 setb ENABLE           ; Latches the data.
                 call delay            ; Waits.
                 clr ENABLE            ; Then resets the latch.

                 inc R3                ; R3 is used to keep track of LCD DDRAM.
                                       ; After an ASCII char is sent, R3 is
                                       ;  incremented.

                 ret                   ; Return


;*****************************************************************************
;
;  delay subroutine
;
;  This subroutine is a simple delay loop that is used to provide timing for
;  the LCD interface.
;
;  LOCAL REGISTERS USED: R5, R6
;  INPUT: none
;  OUTPUT: none
;  ACTION: Provides time delay for the LCD interface.
;
;*****************************************************************************

delay:           mov   R6, #00h             ; Set register 6 to 0
Loop0:           mov   R5, #00h             ; Set register 5 to 0
                 djnz  R5, $                ; Decrement register 5
                 djnz  R6, Loop0            ; Decrement register 6
                 ret                        ; Return


;*****************************************************************************
;
;  reset
;
;  Initialization by instruction
;  This subroutine sends a Function Set byte (30H) to the LCD three times so
;  that the LCD will reset correctly and communicate with the 8051.
;
;  INPUT: none
;  OUTPUT: LCD (P2), ENABLE (P1.4)
;
;*****************************************************************************

reset:           call delay
                 mov LCD, #30H              ; Writes Function Set.
                 setb ENABLE                ; Latches Instruction.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets latch.
                 call Busy                  ; Check Busy Flag delay
                 mov LCD, #30H              ; Writes Function Set.
                 setb ENABLE                ; Latches Instruction.
                 call delay                 ; Waits.
                 clr ENABLE                 ; Then resets the latch.
                 call Busy                  ; Check Busy Flagdelay
                 mov LCD, #30H              ; Writes Function Set.
                 setb ENABLE                ; Latches Instruction
                 call delay                 ; Waits
                 clr Enable                 ; Then resets the latch
                 call Busy                  ; Check Busy Flag
                 ret                        ; Return


;*****************************************************************************
;
;  Busy
;
;  This Subroutine checks the Busy Flag (DB7) to ensure the LCD is not busy
;
;  INPUT  P2.7
;
;*****************************************************************************

Busy:            clr RS                     ; Clear RS
                 setb RW                    ; Set RW
                 jb P2.7, $                 ; Wait while Pin 2.7 is active
                 clr RW                     ; Clear RW
                 ret                        ; Return


;*****************************************************************************
;
;  Tables
;
;*****************************************************************************

Table1:          db  31H,32H,33H,41H,34H,35H,36H,42H,37H,38H,39H,43H,45H,30H,46H,44H
Table2:          db  41H,75H,74H,6FH
Table3:          db  4DH,61H,6EH,75H,61H,6CH
Table4:          db  00H,80H,40H,10H
Table5:          db  43H,61H,74H,20H,54H,6FH,79H

                 end