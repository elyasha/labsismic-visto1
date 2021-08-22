;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
EXP1: 		MOV 	#MSG,R5 ; Ponteiro da mensagem em claro
			MOV 	#GSM,R6 ; Ponteiro da mensagem cifrada
			CALL 	#ENIGMA1
			JMP 	$
			NOP
;
; Sua rotina ENIGMA (Exp 1)
ENIGMA1:	TST.B	0(R5)
			JNZ		CALCULAR
			RET
CALCULAR:	MOV.B	@R5+,0(R6)
			SUB.B	#'A',0(R6)
			MOV.B	@R6,R7 				; Salvar index num registrador auxiliar
			MOV.B	RT1(R7),0(R6)
			ADD.B	#'A',0(R6)
			INC		R6
			JMP		ENIGMA1
			NOP

;
; Dados para o enigma
		.data
MSG: 	.byte 	"CABECAFEFACAFAD",0 ;Mensagem em claro
GSM: 	.byte 	"XXXXXXXXXXXXXXX",0 ;Mensagem cifrada
RT1: 	.byte 	2, 4, 1, 5, 3, 0 ;Trama do Rotor 1
                                            

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
