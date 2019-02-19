;****************** main.s ***************
; Program written by: ***Your Names**update this***
; Date Created: 2/4/2017
; Last Modified: 1/18/2019
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE2 is Button input  (1 means pressed, 0 means not pressed)
;  PE3 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE3 an output and make PE2 and PF4 inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the button (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 70% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 2Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 30%.
;      TIP: debugging the breathing LED algorithm using the real board.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

       IMPORT  TExaS_Init
       THUMB
       AREA    DATA, ALIGN=2
;global variables go here
	
		
       AREA    |.text|, CODE, READONLY, ALIGN=2
;cycles DCD 190000,150000,100000,50000,10000,50000,100000,150000,190000
;value DCD 200000
cycles DCD 196000
value DCD 4000
amt DCD 200000
duty DCD 9000000,7000000,5000000,3000000,1000000
evalue DCD 10000000
subval DCD 1000000
	   THUMB
       EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
     BL  TExaS_Init ; voltmeter, scope on PD3
 ; Initialization goes here
	LDR R1,=SYSCTL_RCGCGPIO_R ;turning on the clock
	LDRB R0,[R1]
	ORR R0,#0X30
	STRB R0,[R1]
	NOP ;wait for stabilization bc 4 clock cycles to completely stabilize
	NOP
	NOP
	NOP
	LDR R1,=GPIO_PORTE_DIR_R ;set direction (which ones are input and which ones are output)
	LDRB R0,[R1]
	ORR R0, #0X08
	AND R0, #0XFB
	STRB R0,[R1]
	LDR R1, =GPIO_PORTE_DEN_R  ;set digital enable (we use 4 pins)
	LDRB R0,[R1]
	ORR R0, #0XFC
	STRB R0,[R1]
	LDR R1, =GPIO_PORTF_DIR_R
	LDRB R0,[R1]
	AND R0,#0X00
	AND R0, #0XFF
	STRB R0,[R1]
	LDR R1, =GPIO_PORTF_DEN_R  ;set digital enable (we use 4 pins)
	LDRB R0,[R1]
	ORR R0, #0X10
	STRB R0,[R1]
	LDR R0, =GPIO_PORTF_LOCK_R	;unlock port f
	LDR R1, =GPIO_LOCK_KEY
	STR R1,[R0]
	LDR R1, =GPIO_PORTF_PUR_R
	LDRB R0,[R1]
	ORR R0, #0X10
	STRB R0,[R1]
	
	LDR R1, =GPIO_PORTF_CR_R
	LDRB R0,[R1]
	ORR R0, #0XFF
	STRB R0,[R1]
	LDR R1, =GPIO_PORTF_AFSEL_R 
	LDRB R0,[R1]
	BIC R0,R0,#0X10
	STRB R0,[R1]
	
     CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  
; main engine goes here
	
	LDR R4,=duty					;load variables into registers
	LDR R6,[R4]
	LDR R8,[R4]
	LDR R7,=evalue
	LDR R7,[R7]

	
dloop
	LDR R2,=GPIO_PORTE_DATA_R		;check to see if pe2 has been set
	LDR R3,[R2]
	CMP R3,#0X04
	BNE dutyCycleLoop				;if it isnt pressed continue current cycle
	BEQ check						;if it is pressed, wait for button to be released
check
	LDR R3,[R2]
	CMP R3,#0X00					;check to see if button has been released
	BNE check						;keep polling till button has been released
	BEQ addloop						;once button is released, go to change duty cycle
	
addloop
	LDR R5, =subval					
	LDR R5,[R5]						;R5 stores the value to be subtracted from
	LDR R6,[R4]
	SUBS R10,R6,R5					
	BEQ loop						;Branch back to loop the array if at end
	ADD R4,R4,#4					;move to next value in array
	LDR R6,[R4]	
	LDR R8,[R4]
dutyCycleLoop
	
	LDR R9, =GPIO_PORTF_DATA_R	
	LDR R10,[R9]
	CMP R10,#0						;check to see if pf4 has been pressed
	BEQ floop						;branch to breathing
	LDR R6, [R4]	
delay								;run the duty cycle
	SUBS R6,#1
	BNE delay
	AND R1,R1,#0
	ORR R1,R1,#0X08
	STR R1,[R2]						;turn the light on
	SUBS R9,R7,R8
	SUBS R10,R7,R8
delay1								;delay for light on
	SUBS R9,#1
	BNE delay1
	AND R1,R1,#0				
	STR R1,[R2]						;turn light off

	LDR R2,=GPIO_PORTE_DATA_R
	LDR R3,[R2]
	CMP R3,#0X04					;check to see if pe2 has been pressed 
	BNE dutyCycleLoop				;if not, loop current duty cycle
	BEQ check						;if so, branch back to check if 0
	
floop
	LDR R12, =GPIO_PORTE_DATA_R
	LDR R3, =cycles					;R3 has 98% duty cycle
	LDR R2,[R3]
	LDR R3,[R3]
	LDR R5,=amt						;R5 has total cycles
	LDR R5,[R5]
	LDR R11,=value					;R11 has incrementing value (2%)
	LDR R11,[R11]
delay2
	SUBS R3, #1						;delay for light off
	BNE delay2
	AND R8,R8,#0
	ORR R8,R8,#0x08
	STR R8,[R12]
	SUBS R3,R5,R2					;R3 has duty cycle for light on
delay3
	SUBS R3,#1						;delay for light on
	BNE delay3
	SUBS R3,R2,R11
	SUBS R2,R2,R11					;R2 has 0 after all cycles are done
	BNE nzdelay						;if not 0 continue increasing cycle
debreathe	 						;if max duty cycle has been hit, decrease increment
	ADD R2,R2,R11
	ADD R3,R3,R2
delay4								;delay for light off decreasing duty cycle
	SUBS R3, #1
	BNE delay4
	AND R8,R8,#0
	ORR R8,R8,#0x08
	STR R8,[R12]
	SUBS R3,R5,R2					;duty cycle for on
delay5								;delay for light on
	SUBS R3,#1
	BNE delay5
	LDR R3, =cycles
	LDR R3,[R3]
	CMP R2,R3						;check if it has hit max
	AND R8,R8,#0
	STR R8,[R12]
	BNE debreathe					;branch to decrease brightness
nzdelay								
	AND R8,R8,#0						
	STR R8,[R12]					;turn led off
	LDR R9, =GPIO_PORTF_DATA_R		
	LDR R10,[R9]
	SUBS R10,R10,#0X10				;check portf is zero/released
	BEQ dloop 						;if yes, return to basic duty cycle
	B delay2						;if not, continue breathing
     B    loop

      
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file

