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

EXP2:		MOV 	#MSG,R5
			MOV 	#GSM,R6
			CALL 	#ENIGMA2
			;
			MOV 	#GSM,R5
			MOV 	#DCF,R6
			CALL 	#ENIGMA2 ;Decifrar
			JMP $
			NOP
;
; Sua rotina ENIGMA (Exp 2)
; R5 = claro
; R6 = cifrado
; R7 = auxiliar
ENIGMA2:	TST.B	0(R5)
			JNZ		CALCULAR
			RET
CALCULAR:	MOV.B	@R5+,R7
			SUB.B	#'A',R7
			MOV.B	RT1(R7),R7	;RT1
;
			MOV.B	RF1(R7),R7	;RF1
;
			MOV		#RT1,R10
			CALL	#C_INV
			ADD.B	#'A',R7
			MOV.B	R7,0(R6);
			INC		R6
			JMP		ENIGMA2
;
; Consulta inversa
; Recebe:	R10=endereço do rotor
;			R7 =elemento a ser buscado
; Retorna:	R7 =índice do elemento
; Usa:		R11=contador (0, 1, ...)
C_INV:		CLR			R11
CI0:		CMP.B		@R10+,R7
			JNZ			CI1
			MOV.B		R11,R7
			RET
CI1:		INC			R11
			JMP			CI0
			NOP

;
; Dados para o enigma
	 		.data
MSG: 		.byte "CABECAFEFACAFAD",0 ;Mensagem em claro
GSM: 		.byte "XXXXXXXXXXXXXXX",0 ;Mensagem cifrada
DCF: 		.byte "XXXXXXXXXXXXXXX",0 ;Mensagem decifrada
RT1: 		.byte 2, 4, 1, 5, 3, 0 ;Trama do Rotor 1
RF1: 		.byte 3, 5, 4, 0, 2, 1 ;Tabela do Refletor
        	     ;A  B  C  D  E  F
          	     ;0  1  2  3  4  5
                                            

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
            
