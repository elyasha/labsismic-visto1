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
; Matheus Elyasha Lopes - 160036526
; Data de criação : 22 Agosto 2021
; Link do repositório para acesso posterior
; https://github.com/elyasha/labsismic-vistos
;
RT_TAMANHO_MENSAGEM 	.equ 32								; Tamanho dos rotores (32 simbolos)

INICIO_CONFIGURACAO:
			MOV		#CHAVE,R15								; Ler chave em R15

			CALL	#RESETAR_ROTOR

			CLR		R6										; Número do rotor - Rotor A

SELECIONAR_ROTOR_A:
			INC		R6
			CMP.B	R6,0(R15)
			JZ		CONFIGURAR_ROTOR_A
			ADD		#32,R4
			JMP		SELECIONAR_ROTOR_A

CONFIGURAR_ROTOR_A:											; Gira o rotor para esquerda de acordo com a configuração
			INC		R15
			MOV.B	@R15+,R11								; R11 recebe configuração do rotor A
			CALL	#CONFIGURAR_ROTORES
			CALL 	#RESETAR_ROTOR 							; Restaurar posição original de RT1

			CLR		R6										; Limpar o número do rotor para encontrar Rotor B

SELECIONAR_ROTOR_B:
			INC		R6
			CMP.B	R6,0(R15)
			JZ		CONFIGURAR_ROTOR_B
			ADD		#32,R4
			JMP		SELECIONAR_ROTOR_B

CONFIGURAR_ROTOR_B:											; Gira o rotor para esquerda de acordo com a configuração
			INC		R15
			MOV.B	@R15+,R11								; R11 recebe configuração do rotor B
			CALL	#CONFIGURAR_ROTORES
			CALL 	#RESETAR_ROTOR

			CLR		R6										; Limpar o número do rotor para encontrar Rotor C

SELECIONAR_ROTOR_C:
			INC		R6										; Número do rotor
			CMP.B	R6,0(R15)
			JZ		CONFIGURAR_ROTOR_C
			ADD		#32,R4
			JMP		SELECIONAR_ROTOR_C

CONFIGURAR_ROTOR_C:											; Gira o rotor para esquerda de acordo com a configuração
			INC		R15
			MOV.B	@R15+,R11								; R11 recebe configuração do rotor C
			CALL	#CONFIGURAR_ROTORES

;Tamanho de MSG, considerando apenas letras (caracteres válidos no alfabeto de ; até Z na tabela ASCII)
TAMANHO_MENSAGEM:
			MOV		#MSG,R15								; Endereço de MSG
			CLR		R4										; Tamanho de MSG
TAMANHO_MENSAGEM1:
			CMP.B	#0,0(R15)
			JZ		VISTO1
			INC		R15
			CMP.B	#';',-1(R15)
			JLO		TAMANHO_MENSAGEM1
			CMP.B	#'Z',-1(R15)
			JEQ		TAMANHO_MENSAGEM2
			JHS		TAMANHO_MENSAGEM1
TAMANHO_MENSAGEM2:
			INC		R4
			JMP		TAMANHO_MENSAGEM1

VISTO1:
			MOV 	#MSG,R5
			MOV 	#GSM,R6
			CLR		R15										; Número de giros do Rotor A
			CLR		R14										; Número de giros do Rotor B
			CALL 	#ENIGMA									; Cifrar
			CLR		R14
			CLR		R15

VISTO1_AUX:
			CMP		#0,R4									; Número de de voltas do rotor A
			JNZ		VOLTA_ROTOR_A
			MOV 	#GSM,R5
			MOV		#DCF,R6
			CLR		R15										; Número de giros do Rotor A
			CLR		R14										; Número de giros do Rotor B
			CALL	#ENIGMA									; Decifrar (Como é criptografia simétrica, a chave é a mesma !)
			JMP		$
			NOP

CONFIGURAR_ROTORES:
			MOV		R4,R10									; Endereço do rotor
			MOV		#RT_TAMANHO_MENSAGEM,R12				; Tamanho do rotor
			MOV.B	@R10+,R13								; Guarda o primeiro número do Rotor ATUAL
			DEC		R12
			MOV.B	@R10,R14								; Auxilia na troca de números do Rotor
			DEC		R10

CONFIGURAR_ROTORES2:
			MOV.B	R14,0(R10)
			INCD	R10
			MOV.B	@R10,R14
			DEC		R10
			DEC		R12
			CMP		#0,R12
			JNZ		CONFIGURAR_ROTORES2
			MOV.B	R13,0(R10)
			DEC		R11
			CMP		#0,R11
			JZ		FIM
			JMP		CONFIGURAR_ROTORES

ENIGMA:
			CMP.B	#0,0(R5)
			JZ		FIM
			MOV.B	@R5,R7

			; Verificar se o caracter atual é uma letra (se está no alfabeto de ; até Z)
			CMP		#';',R7
			JLO		CHARACTER_ESPECIAL
			CMP		#'Z',R7
			JEQ		ENIGMA_AUX
			JHS		CHARACTER_ESPECIAL

ENIGMA_AUX:
			SUB		#';',R7									; Indice do Rotor

			; Rotor A (Rotor da esquerda)
			MOV.B	#1,R8									; Número do Rotor
			MOV		#RT1,R9									; Posição do Rotor
			MOV		#CHAVE,R10

ROTOR_A:
			CMP.B	@R10,R8
			JZ		ROTOR_A2
			ADD		#32,R9
			INC		R8
			JMP		ROTOR_A

ROTOR_A2:
			MOV		R9,R11									; R11 recebe posição do Rotor A
			CALL	#CALC_VALOR_ROTOR_REFLETOR				; Valor do Rotor em R7
			INCD	R10
			MOV.B	@R9,R7									; R7 = Número no Rotor A

			; Rotor B (Rotor do meio)
			MOV.B	#1,R8									; R8 = Número do Rotor
			MOV		#RT1,R9									; R9 = Posição do Rotor

ROTOR_B:
			CMP.B	@R10,R8
			JZ		ROTOR_B2
			ADD		#32,R9
			INC		R8
			JMP		ROTOR_B

ROTOR_B2:
			MOV		R9,R12									; R12 = Posição do Rotor B
			CALL	#CALC_VALOR_ROTOR_REFLETOR				; Valor do Rotor em R7
			INCD	R10
			MOV.B	@R9,R7									; R7 = Número no Rotor B

			; Rotor C (Rotor da direita)
			MOV.B	#1,R8									; R8 = Número do Rotor
			MOV		#RT1,R9									; R9 = Posição do Rotor

ROTOR_C:
			CMP.B	@R10,R8
			JZ		ROTOR_C2
			ADD		#32,R9
			INC		R8
			JMP		ROTOR_C

ROTOR_C2:
			MOV		R9,R13									; R13 = Posição do Rotor C
			CALL	#CALC_VALOR_ROTOR_REFLETOR				; Valor do Rotor em R7
			INCD	R10
			MOV.B	@R9,R7									; R7 = Número no Rotor C

			; REFLETOR
			MOV.B	#1,R8									; R8 = Número do Refletor
			MOV		#RF1,R9									; R9 = Posição do Refletor

REFLETOR:
			CMP.B	@R10,R8
			JZ		REFLETOR2
			ADD		#32,R9
			INC		R8
			JMP		REFLETOR

REFLETOR2:
			CALL	#CALC_VALOR_ROTOR_REFLETOR				; Valor do Refletor em R7
			MOV.B	@R9,R7									; R7 = Número no Refletor

			;Volta para o Rotor C
			MOV		R13,R8									; R8 recebe posição do Rotor C
			CLR		R9										; R9 = Contador
			CALL	#REFLETE_VALOR_INVERSO
			;Volta para o Rotor B
			MOV		R12,R8									; R8 recebe posição do Rotor B
			MOV.B	R9,R7									; R7 = Número que será procurado no rotor
			CLR		R9
			CALL	#REFLETE_VALOR_INVERSO
			;Volta para o Rotor A
			MOV		R11,R8									; R8 recebe posição do rotor A
			MOV.B	R9,R7									; R7 = Número que será procurado no rotor
			CLR		R9
			CALL	#REFLETE_VALOR_INVERSO

			ADD.B	#';',R9
			MOV.B	R9,0(R6)
			INC		R5
			INC		R6
			CALL	#GIRAR_ROTOR_A
			CMP.B	#32,R15									; R15 = Número de Voltas do Rotor A
			JZ		GIRAR_ROTOR_B

ENIGMA_AUX2:
			CMP.B	#32,R14									; R14 = Número de Voltas do Rotor B
			JZ		GIRAR_ROTOR_C
			JMP		ENIGMA

REFLETE_VALOR_INVERSO:
			CMP.B	@R8+,R7
			JZ		FIM
			INC		R9
			JMP		REFLETE_VALOR_INVERSO

CALC_VALOR_ROTOR_REFLETOR:
			CMP		#0,R7
			JZ		FIM
			DEC		R7
			INC		R9
			JMP		CALC_VALOR_ROTOR_REFLETOR

; Mantêm characteres especiais (não cifra os caracteres)
CHARACTER_ESPECIAL:
			MOV.B	R7,0(R6)
			INC		R5
			INC		R6
			JMP		ENIGMA

; Gira o Rotor A (Esquerda)
GIRAR_ROTOR_A:
			MOV		R11,R10
			MOV		#RT_TAMANHO_MENSAGEM,R7					; R7 recebe tamanho do Rotor
			ADD		#31,R10									; R10 aponta para o final do Rotor A (Esquerda)
			MOV.B	@R10,R8									; R8 recebe primeiro número do Rotor girado
			DEC		R7
			DEC		R10
			MOV.B	@R10+,R9								; R9 recebe último número do Rotor girado

GIRAR_ROTOR_A2:
			MOV.B	R9,0(R10)
			DECD	R10
			MOV.B	@R10+,R9
			DEC		R7
			CMP		#0,R7
			JNZ		GIRAR_ROTOR_A2
			MOV.B	R8,0(R10)
			INC		R15
			JMP		FIM

; Gira o Rotor B (Meio)
GIRAR_ROTOR_B:
			MOV		R12,R10
			MOV		#RT_TAMANHO_MENSAGEM,R7					; R7 recebe tamanho do Rotor
			ADD		#31,R10									; R10 aponta para o final do Rotor B (Meio)
			MOV.B	@R10,R8									; R8 recebe primeiro número do Rotor girado
			DEC		R7
			DEC		R10
			MOV.B	@R10+,R9								; R9 recebe último número do Rotor girado

GIRAR_ROTOR_B2:
			MOV.B	R9,0(R10)
			DECD	R10
			MOV.B	@R10+,R9
			DEC		R7
			CMP		#0,R7
			JNZ		GIRAR_ROTOR_B2
			MOV.B	R8,0(R10)
			CLR		R15
			INC		R14
			JMP		ENIGMA_AUX2

;Gira o Rotor C (Direita)
GIRAR_ROTOR_C:
			MOV		R13,R10
			MOV		#RT_TAMANHO_MENSAGEM,R7					; R7 recebe tamanho do Rotor
			ADD		#31,R10									; R10 aponta para o final do Rotor C
			MOV.B	@R10,R8									; R8 recebe primeiro número do Rotor girado
			DEC		R7
			DEC		R10
			MOV.B	@R10+,R9								; R9 recebe último número do Rotor girado

GIRAR_ROTOR_C2:
			MOV.B	R9,0(R10)
			DECD	R10
			MOV.B	@R10+,R9
			DEC		R7
			CMP		#0,R7
			JNZ		GIRAR_ROTOR_C2
			MOV.B	R8,0(R10)
			CLR		R14
			JMP		ENIGMA

; Volta o Rotor A
VOLTA_ROTOR_A:
			DEC		R4										; Número de Voltas a retornar no Rotor A
			MOV		R11,R10
			MOV		#RT_TAMANHO_MENSAGEM,R7					; R7 recebe o tamanho do Rotor
			MOV.B	@R10+,R8								; R8 será o ultimo número do Rotor
			DEC		R7
			MOV.B	@R10,R9									; R9 será o primeiro número do Rotor
			DEC		R10

VOLTA_ROTOR_A2:		MOV.B	R9,0(R10)
			INCD	R10
			MOV.B	@R10,R9
			DEC		R10
			DEC		R7
			CMP		#0,R7
			JNZ		VOLTA_ROTOR_A2
			MOV.B	R8,0(R10)
			INC		R15
			CMP.B	#32,R15									; R15 recebe número de giros do Rotor A
			JZ		VOLTA_ROTOR_B
			JMP		VISTO1_AUX

; Volta o Rotor B
VOLTA_ROTOR_B:	MOV		R12,R10
			MOV		#RT_TAMANHO_MENSAGEM,R7					; R7 recebe tamanho do Rotor
			MOV.B	@R10+,R8								; R8 será o ultimo número do Rotor
			DEC		R7
			MOV.B	@R10,R9									; R9 será o primeiro número do Rotor
			DEC		R10

VOLTA_ROTOR_B2:	MOV.B	R9,0(R10)
			INCD	R10
			MOV.B	@R10,R9
			DEC		R10
			DEC		R7
			CMP		#0,R7
			JNZ		VOLTA_ROTOR_B2
			MOV.B	R8,0(R10)
			CLR		R15
			INC		R14
			CMP.B	#32,R14									; R14 recebe número de giros do Rotor B
			JZ		VOLTA_ROTOR_C
			JMP		VISTO1_AUX
;
; Volta o Rotor C
VOLTA_ROTOR_C:	MOV		R13,R10
			MOV		#RT_TAMANHO_MENSAGEM,R7					; R7 recebe tamanho do Rotor
			MOV.B	@R10+,R8								; R8 será o ultimo número do Rotor
			DEC		R7
			MOV.B	@R10,R9									; R9 será o primeiro número do Rotor
			DEC		R10

VOLTA_ROTOR_C2:	MOV.B	R9,0(R10)
			INCD	R10
			MOV.B	@R10,R9
			DEC		R10
			DEC		R7
			CMP		#0,R7
			JNZ		VOLTA_ROTOR_C2
			MOV.B	R8,0(R10)
			CLR		R14
			JMP		VISTO1_AUX

RESETAR_ROTOR:
			MOV		#RT1,R4

;
FIM:		RET
;
CHAVE: 		.byte 2, 6, 3, 10, 5, 12, 2
;
; Área de dados
			.data
MSG: 		.byte "UMA NOITE DESTAS, VINDO DA CIDADE PARA O ENGENHO NOVO,"
			.byte " ENCONTREI NO TREM DA CENTRAL UM RAPAZ AQUI DO BAIRRO,"
			.byte " QUE EU CONHECO DE VISTA E DE CHAPEU.",0 				; Dom Casmurro

GSM: 		.byte "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
			.byte "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
			.byte "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",0

DCF: 		.byte "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
			.byte "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
			.byte "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",0

;Rotores com 32 posições
ROTORES:
RT1: 	 .byte 13, 23, 0, 9, 4, 2, 5, 11, 12, 17, 21, 6, 28, 25, 30, 10
	  	 .byte 22, 1, 3, 26, 24, 31, 8, 14, 29, 15, 18, 16, 19, 7, 27, 20

RT2: 	 .byte 6, 24, 2, 8, 25, 20, 16, 29, 23, 0, 7, 19, 30, 17, 12, 15
		 .byte 5, 4, 26, 10, 11, 18, 28, 27, 14, 9, 13, 1, 21, 31, 22, 3

RT3:	 .byte 6, 15, 23, 7, 27, 13, 19, 3, 16, 4, 17, 20, 24, 25, 0, 10
		 .byte 30, 26, 22, 1, 8, 11, 14, 31, 9, 28, 5, 18, 12, 2, 29, 21

RT4: 	 .byte 15, 16, 5, 18, 31, 26, 19, 28, 1, 2, 14, 12, 24, 20, 21, 0
		 .byte 11, 23, 4, 10, 7, 3, 25, 29, 27, 8, 17, 6, 9, 13, 22, 30

RT5: 	 .byte 13, 25, 1, 26, 6, 12, 9, 2, 28, 11, 16, 15, 4, 8, 3, 31
		 	.byte 5, 18, 23, 17, 24, 27, 0, 22, 29, 19, 7, 10, 14, 21, 20, 30

;Refletores com 32 posições
REFLETORES:
RF1:	 .byte 26, 23, 31, 9, 29, 20, 16, 11, 27, 3, 14, 7, 21, 28, 10, 25
		 .byte 6, 22, 24, 30, 5, 12, 17, 1, 18, 15, 0, 8, 13, 4, 19, 2

RF2: 	 .byte 20, 29, 8, 9, 23, 27, 21, 11, 2, 3, 25, 7, 13, 12, 22, 16
		 .byte 15, 28, 30, 26, 0, 6, 14, 4, 31, 10, 19, 5, 17, 1, 18, 24

RF3: 	 .byte 14, 30, 7, 5, 15, 3, 18, 2, 23, 17, 29, 28, 25, 27, 0, 4
		 .byte 19, 9, 6, 16, 26, 22, 21, 8, 31, 12, 20, 13, 11, 10, 1, 24


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
