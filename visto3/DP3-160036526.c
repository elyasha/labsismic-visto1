/*
 * Visto 03
 * Matheus Elyasha Lopes
 * 21 Outubro 2021
 *
 * Uma aplicação embarcada que transforme a LaunchPad num voltímetro de dois canais (A0 e A1) ou num display XY.
 * Use como referência positiva o 3,3V e o terra como referência negativa.
 * Para cada canal, o valor apresentado deve ser o resultado a média de 8 conversões realizadas durante o período de 1 segundo.
 * Isto significa que a cada segundo o voltímetro atualiza os valores dos dois canais.
 * Para facilitar a conferência da taxa de conversão, o estado do led vermelho (L1) deve ser invertido a cada atualização do LCD.
 */
#include <msp430.h> 




#define LED1_ON (P1OUT |= BIT0)
#define LED1_OFF (P1OUT &= ~BIT0)
#define LED1_TOGGLE (P1OUT ^= BIT0)

#define LED2_ON (P4OUT |= BIT7)
#define LED2_OFF (P4OUT &= ~BIT7)
#define LED2_TOGGLE    (P4OUT ^= BIT7

#define SMCLK 1048576L // frequencia do SMCLK
#define ACLK 32768     // frequencia do ACLK

#define BR100K 11 //(SMCLK) 1.048.576/11 ~= 100kHz
#define BR10K 105 //(SMCLK) 1.048.576/105 ~= 10kHz

#define TAXA_ATUALIZACAO_LCD 1 // Hertz
#define NUMERO_CONVERSOES 16 // metade para canal A0 e metade para canal A1


/*
 * PCF8574AT -> 0x3F
 * PCF8574A -> 0x27
 */
#define LCD_ADDRESS 0x3F;

// Assinatura das funções
void configurar_timer(void);
void atualizar_lcd(void);
void configurar_led(void);
void configurar_i2c(void);
void configurar_joysticker(void);
void configurar_adc(void);


// Definição de variaveis globais

/*
 * A sincronização entre as duas rotinas é conseguida com uma flag.
 */
volatile int flag = 0;

/*
 * O programa inicia no modo 0.
 * Cada acionamento de SW avança de forma circular pelos 3 modos.
 * Por acionamento de SW, entende-se sua passagem do estado de aberta para fechada.
 * Cuide para remover os rebotes.
 * Modo 0: Medidas do canal A0 apresentando tensão em Volts, código do ADC em decimal e indicação das tensões mínima e máxima das 10 últimas conversões.
 * Modo 1: Medidas do canal A1 apresentando tensão em Volts, código do ADC em decimal e indicação das tensões mínima e máxima e das 10 últimas conversões.
 * Modo 2: Plano cartesiano XY
 */
volatile int modo_operacao = 0;


/**
 * main.c: Solução do visto 03
 * Esta rotina é o programa principal que faz as inicializações e fica escrevendo no LCD e monitorando a chave SW
 * A rotina principal percebe flag = 1, zera essa flag e atualiza o LCD com as novas medidas.
 *
 */
int main(void)
{
	WDTCTL = WDTPW | WDTHOLD;	// stop watchdog timer
	
	configurar_led();
	configurar_timer();
	configurar_i2c();
	configurar_joysticker();
	configurar_adc();
    __enable_interrupt(); //Habilitacao de interrupcao geral (GIE = 1)

    while(1) {
        if (flag == 1) {
              atualizar_lcd();
              flag = 0;
          }
    }
	return 0;
}

void atualizar_lcd(void) {
    // verificar se deve mudar de modo

    // atualizar o lcd de acordo com o joysticker
}

/*
 * Timer na taxa de 16Hz
 *
 * Note que a cada segundo são 16 conversões, sendo 8 para o canal A0 e 8 para o canal A1.
 * Elas devem ser alternadas.
 * Sugestão: Usar o modo Autoscan repetido e disparar as conversões usando um timer na taxa de 16 Hz.
 */
void configurar_timer(void) {
    TA0CTL  = TASSEL__ACLK | MC_1;
    TA0CCR0 = 2048 - 1;      //16 Hz
    TA0CCR1 = TA0CCR0 >> 1;  //carga=50%
    TA0CCTL1 = OUTMOD_7;
}

void configurar_i2c(void) {
    // Configurar MSP com mestre no I2C (Usando UCB0)
    UCB0CTL1 |= UCSWRST;    // UCSI B0 em ressete
    UCB0CTL0  = UCSYNC |     //Síncrono
                UCMODE_3 |   //Modo I2C
                UCMST;       //Mestre
    UCB0BRW  =  BR100K;      //100 kbps
    P3SEL   |=  BIT1 | BIT0;  // Use dedicated module
    UCB0CTL1 =  UCSSEL_2;    //SMCLK e remove ressete

    P3SEL |= BIT1 | BIT0; // Funcoes alternativas
    P3REN |= BIT1 | BIT0; // Habilitar resistor
    P3OUT |= BIT1 | BIT0; // Pullup



    // Configurar o LCD como escravo no I2C
}

void configurar_joysticker(void) {
    // Configurar o Joysticker



    // VRX



    // VRY



    // SW
    P6DIR &= ~BIT2;  // P6.2 = entrada (SW)
    P6REN |=  BIT2;  // Habilita resistor
    P6OUT |=  BIT2;  // de pull-up
}

void configurar_led(void) {

    P1DIR |=  BIT0;  // P1.0 = saída (vermelho)
    P1OUT &= ~BIT0;

}

void configurar_adc(void) {

}



/*
 * A rotina que atende a interrupcao do ADC apenas lê os resultados das conversões e calcula as médias
 * A rotina de interrupção, cada vez que calcula uma nova média, faz flag = 1.
 */
#pragma vector = ADC12_VECTOR
__interrupt void isr_adc12(){
//    eixo_x = ADC12MEM0 + ADC12MEM2 + ADC12MEM4 + ADC12MEM6 + ADC12MEM8 + ADC12MEM10 + ADC12MEM12 + ADC12MEM14;                //Ler resultado
//    eixo_y = ADC12MEM1 + ADC12MEM3 + ADC12MEM5 + ADC12MEM7 + ADC12MEM9 + ADC12MEM11 + ADC12MEM13 + ADC12MEM15;                //Ler resultado
//    eixo_x /= 8;
//    eixo_y /= 8;
//    hexa_x = eixo_x ;    // Valor que ser� convertido para hexadecimal
//    hexa_y = eixo_y ;    // Valor que ser� convertido para hexadecimal
//
//    eixo_x *= (3.3/4.096);     // Converte os passos para 0V at� 3,3V
//    eixo_y *= (3.3/4.096);     // Converte os passos para 0V at� 3,3V
//    flag = 1;
//
//    // Ultimas 3 convers�es
//    cx2 = cx1;
//    cx1 = cx0;
//    cx0 = eixo_x;
//
//    cy2 = cy1;
//    cy1 = cy0;
//    cy0 = eixo_y;
}
