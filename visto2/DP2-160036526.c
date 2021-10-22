/*
 *  Matheus Elyasha Lopes - 160036526
 *  Data de cricao : 19 Setembro 2021
 *  Link do repositorio para acesso posterior
 *  https://github.com/elyasha/labsismic-vistos
*/

#include <msp430.h>

// Assinatura das funcoes
void gpio_config();
void TA0_config();
void TA1_config();
void TA2_config();
void calcular_distancia();
void acender_leds();
void calcular_frequencia_a_ser_gerada();
void debounce(int valor);
int monitoraS1(void);
int monitoraS2(void);

// Definicao de variaveis globais (optei por usar variaveis globais para nao mexer com parametros de funcoes/ponteiros)
unsigned const int BREAKPOINT1 = 10;
unsigned const int BREAKPOINT2 = 30;
unsigned const int BREAKPOINT3 = 50;
unsigned int captura_subida = 0;
unsigned int captura_descida = 0;
unsigned int ruido = 0;
long distancia_em_cm;
long diff;
long clock = 0;
long diff_anterior;
long frequencia;

/*
 * main: Solucao do problema individual para o problema 2 (Theremim R2D2)
 */
void main()
{
    WDTCTL = WDTPW | WDTHOLD; // stop watchdog timer

    // Configuracao GPIO e Timers
    gpio_config();
    TA0_config();
    TA1_config();

    __enable_interrupt(); // Interrupcao habilitada

    while (1)
    {
        calcular_distancia();
        acender_leds();
        calcular_frequencia_a_ser_gerada();
        TA2_config(); // Programar TA2 de acordo com a frequencia, o que deve ser feito a cada medida
    }
}

// Interrupcao do timer
#pragma vector = TIMER1_A1_VECTOR
__interrupt void ta1_ccifg()
{
    switch (TA1IV)
    {
    case 2: // CCR1
        if (TA1CCTL1 & CCI)
        {
            captura_subida = TA1CCR1;
        }
        else
        {
            captura_descida = TA1CCR1;
        }
        break;
    }
}

void calcular_distancia()
{
    diff = captura_descida - captura_subida;
    if (diff < 0)
    {
        diff = -diff;
    }
    if (diff >= 1.3 * diff_anterior && ruido > 0)
    {
        diff = diff_anterior;
        ruido = 0;
    }
    else
    {
        ruido++;
    }
    diff_anterior = diff;
    distancia_em_cm = (17000 * diff) / 1048576;
}

void acender_leds()
{
    if (distancia_em_cm > BREAKPOINT3)
    {
        P1OUT &= ~BIT0;
        P4OUT &= ~BIT7;
    }
    else if ((distancia_em_cm <= BREAKPOINT3) && (distancia_em_cm > BREAKPOINT2))
    {
        P1OUT &= ~BIT0;
        P4OUT |= BIT7;
    }
    else if ((distancia_em_cm <= BREAKPOINT2) && (distancia_em_cm > BREAKPOINT1))
    {
        P1OUT |= BIT0;
        P4OUT &= ~BIT7;
    }
    else
    {
        P1OUT |= BIT0;
        P4OUT |= BIT7;
    }
}

void calcular_frequencia_a_ser_gerada()
{
    if (distancia_em_cm > 50)
    {
        frequencia = 0;
        if (monitoraS1() == 1 || monitoraS2() == 1) {
            frequencia = 5 * 1000;
        }
    }
    else if ((distancia_em_cm <= 50) && (distancia_em_cm > 25))
    {
        frequencia = (5 - 0.1 * distancia_em_cm) * 1000;
        if (monitoraS1() == 1 || monitoraS2() == 1) {
            frequencia = 0.1 * distancia_em_cm * 1000;
        }

    }
    else if ((distancia_em_cm <= 25) && (distancia_em_cm > 5))
    {
        frequencia = (2.5 + 0.125 * (25 - distancia_em_cm)) * 1000;
        if (monitoraS1() == 1 || monitoraS2() == 1) {
            frequencia = (2.5 - 0.125 * (25 - distancia_em_cm)) * 1000;
        }
    }
    else
    {
        frequencia = 5 * 1000;
        if (monitoraS1() == 1 || monitoraS2() == 1) {
            frequencia = 0.01; // Valor proximo de zero (evitar zero para nao dar ZeroDivisionError)
        }
    }

    // frequencia = (5 - 0.1 * distancia_em_cm) * 1000;

    clock = 524288 / frequencia;
    if (clock < 0)
    {
        clock = 0;
    }
}

void gpio_config()
{

    // DIR nos LEDS
    P1DIR |= BIT0; // P1.0 = output   (vermelho)
    P4DIR |= BIT7; // P4.7 = output   (verde)

    // Setup inicial dos leds
    P1OUT &= ~BIT0;
    P4OUT &= ~BIT7;

    //Chave S1 em P2.1
    P2DIR &= ~BIT1; // Defino o P2.1 como entrada
    P2REN |= BIT1;  // Habilito o resistor de pull-(up ou down)
    P2OUT |= BIT1;  // Configuro com pull-up

    //Chave S2 em P1.1
    P1DIR &= ~BIT1; // Defino o P1.1 como entrada
    P1REN |= BIT1;  // Habilito o resistor de pull-(up ou down)
    P1OUT |= BIT1;  // Configuro com pull-up

    // TA0.4 Trigger
    P1DIR |= BIT5; // Trigger = output (P1.5)
    P1SEL |= BIT5; // P1.5 = output do timer

    // TA1.1 Echo
    P2DIR &= ~BIT0; // Echo = input (P2.0)
    P2SEL |= BIT0;  // Modo de captura

    // TA2.2 Buzzer
    P2DIR |= BIT5; // Buzzer = output (P2.5)
    P2SEL |= BIT5; // P2.5 = input do timer
}

void TA0_config()
{
    TA0CTL = TASSEL__SMCLK | MC__UP | ID_1;
    TA0CCR0 = 26214; // (2 ^ 20) * (1 / 2) * (1 / 20)
    TA0CCR4 = 10;

    TA0CCTL4 = OUTMOD_7;
}

void TA1_config()
{
    TA1CTL = TASSEL_2 | MC_2 | TACLR;
    TA1CCTL1 = CAP | SCS | CCIS_0 | CM_3 | CCIE;
}

void TA2_config()
{
    TA2CTL = TASSEL__SMCLK | MC__UP | ID_1;
    TA2CCR0 = clock;
    TA2CCR2 = TA2CCR0 >> 1; // 50% DUTY CYCLE

    TA2CCTL2 = OUTMOD_7;
}
int monitoraS1(void)
{
    static int passadoS1 = 1;

    if ((P2IN & BIT1) == 0) // pressionei o botão S1
    {
        if (passadoS1 == 1)
        {
            debounce(1000);
            passadoS1 = 0;
            return 1;
        }
    }
    else
    {
        debounce(1000);
        passadoS1 = 1;
        return 0;
    }

    return 0;
}

int monitoraS2(void)
{
    static int passadoS2 = 1;

    if ((P1IN & BIT1) == 0) // pressionei o botão S1
    {
        if (passadoS2 == 1)
        {
            debounce(1000);
            passadoS2 = 0;
            return 1;
        }
    }
    else
    {
        debounce(1000);
        passadoS2 = 1;
        return 0;
    }

    return 0;
}

void debounce(int valor)
{
    volatile int x;
    for (x = 0; x < valor; x++);
}
