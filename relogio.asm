# Mapeando a Memória:
    #define LEDR0TO7 256
    #define LEDR8 257
    #define LEDR9 258
    #define SEL_TIMER 259
    #define HEX0 288
    #define HEX1 289
    #define HEX2 290
    #define HEX3 291
    #define HEX4 292
    #define HEX5 293
    #define SW0TO7 320
    #define TIMER 323
    #define KEY0 352
    #define KEY1 353
    #define FPGA_RESET 356
    #define TIMER_RESET 506
    #define KEY1_RESET 510
    #define KEY0_RESET 511

# Setup:
    #define UNIDADES 16
    #define DEZENAS 17
    #define CENTENAS 18
    #define UNI_MILHARES 19
    #define DEZ_MILHARES 20
    #define CEN_MILHARES 21

    #define LIM_UNIDADES 22
    #define LIM_DEZENAS 23
    #define LIM_CENTENAS 24
    #define LIM_UNI_MILHARES 25
    #define LIM_DEZ_MILHARES 26
    #define LIM_CEN_MILHARES 27

    #define SPEED_STATE 48

    #define INC_DISABLE 32 # flag que desabilita o incremento

    # Zerando Hexas e Apagando Leds
        LDI R0 $0
        STA R0 @HEX0
        STA R0 @HEX1
        STA R0 @HEX2
        STA R0 @HEX3
        STA R0 @HEX4
        STA R0 @HEX5
        STA R0 @LEDR0TO7
        STA R0 @LEDR8
        STA R0 @LEDR9
    
    # Configurando timer para 1 segundo
        STA R0 @SEL_TIMER
        STA R0 @SPEED_STATE

    # Limpando FlipFlop dos botôes
        STA R0 @KEY0_RESET
        STA R0 @KEY1_RESET
        STA R0 @TIMER_RESET

    # Inicializando Variáveis
        LDI R0 $0 # contagem inciada em 0
        STA R0 @UNIDADES
        STA R0 @DEZENAS
        STA R0 @CENTENAS
        STA R0 @UNI_MILHARES
        STA R0 @DEZ_MILHARES
        STA R0 @CEN_MILHARES

    # Variaveis utilizadas em operações
        LDI R0 $0
        STA R0 @0
        LDI R0 $1
        STA R0 @1
        LDI R0 $3
        STA R0 @3
        LDI R0 $4
        STA R0 @4
        LDI R0 $6
        STA R0 @6
        LDI R0 $7
        STA R0 @7
        LDI R0 $10
        STA R0 @10 
        LDI R0 $15
        STA R0 @15
    # Fim do setup

# loop principal
loop:
    # Verifica se pediu para resetar
    LDA R0 @FPGA_RESET # verifica FPGA_RESET
    AND R0 @1
    CEQ R0 @1 # Não tem debouncing no FPGA_RESET, então o botão é 0 enquanto apertado
    JEQ @notReset # Só reseta a contagem se o FPGA_RESET for pressionado
    JSR @reset
    notReset:

    # Verifica se pediu para configurar valor de início
    LDA R0 @KEY1 # verifica KEY1
    AND R0 @1
    CEQ R0 @0
    JEQ @notConfig # Só muda pro modo de configuração do valor de início se o KEY1 for pressionado
    JSR @config
    notConfig:

    # Verifica se pediu para incrementar
    LDA R0 @TIMER # verifica timer
    AND R0 @1
    CEQ R0 @0
    JEQ @notInc # Só incrementa se o timer tiver "estourado"
    JSR @inc
    notInc:    

    # Verifica se pediu para mudar a velocidade
    LDA R0 @KEY0 # verifica KEY0
    AND R0 @1
    CEQ R0 @0
    JEQ @notSpeed # Só muda a velocidade de incremento se o KEY0 for pressionado
    JSR @speed
    notSpeed: 

    JSR @updateHexas # exibe contagem atualizada
    JMP @loop # fim do loop principal


# Sub-rotinas

# Função para trocar velocidade do timer
speed:
    STA R0 @KEY0_RESET
    LDA R0 @SPEED_STATE
    ADD R0 @1 # "inverte" o seletor de velocidade do timer
    STA R0 @SPEED_STATE
    STA R0 @SEL_TIMER
    STA R0 @LEDR9
    RET

# Função para incrementar
inc:
    STA R0 @TIMER_RESET # limpa botão de incrementar
    
    LDA R0 @INC_DISABLE
    CEQ R0 @1 # verifica flag de limite de contagem / overflow (inibe incremento)
    JEQ @endInc # se flag hablitada, não incrementa (pula pro final da função)
    
    LDA R0 @UNIDADES
    ADD R0 @1 # incrementa
    STA R0 @UNIDADES

    JSR @update # atualiza valores para ficarem decimais

    endInc:
    RET

# Função para configurar valor inicial
config:
    STA R0 @KEY1_RESET # limpa botão de configurar valor inicial
    JSR @reset # reseta contagem

    LDI R0 $7 # indica que está setando limite da centena (3 leds acesos)
    STA R0 @LEDR0TO7

    configCentenas:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    AND R0 @15
    STA R0 @HEX2 # exibe valor das chaves
    JEQ @configCentenas
    STA R0 @KEY1_RESET
    STA R0 @CENTENAS
    LDI R0 $9
    CLT R0 @CENTENAS # verifica se o limite é válido
    JLT @configCentenas
    # Se o limite é valido, passa pro próximo

    LDI R0 $15 # indica que está setando limite da unidade de milhar (4 leds acesos)
    STA R0 @LEDR0TO7

    configUniMilhares:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    AND R0 @7
    STA R0 @HEX3 # exibe valor das chaves
    JEQ @configUniMilhares
    STA R0 @KEY1_RESET
    STA R0 @UNI_MILHARES
    LDI R0 $5
    CLT R0 @UNI_MILHARES # verifica se o limite é válido
    JLT @configUniMilhares
    # Se o limite é valido, passa pro próximo

    LDI R0 $31 # indica que está setando limite da dezena de milhar (5 leds acesos)
    STA R0 @LEDR0TO7

    configDezMilhares:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    AND R0 @7
    STA R0 @HEX4 # exibe valor das chaves
    JEQ @configDezMilhares
    STA R0 @KEY1_RESET
    STA R0 @DEZ_MILHARES
    LDI R0 $3
    CLT R0 @DEZ_MILHARES # verifica se o limite é válido
    JLT @configDezMilhares
    # Se o limite é valido, passa pro próximo

    LDI R0 $63 # indica que está setando limite da centena de milhar (6 leds acesos)
    STA R0 @LEDR0TO7

    configCenMilhares:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    AND R0 @3
    STA R0 @HEX5 # exibe valor das chaves
    JEQ @configCenMilhares
    STA R0 @KEY1_RESET
    STA R0 @CEN_MILHARES
    LDI R0 $2
    CLT R0 @CEN_MILHARES # verifica se o limite é válido
    JLT @configCenMilhares
    # Se o limite é valido finaliza configuração

    LDI R0 $0 # apaga leds 
    STA R0 @LEDR0TO7
    
    JSR @restart # resaura configurações iniciais
    RET

# Função para resetar contagem
reset:
    LDI R0 $0

    # Limpa valores de contagem
    STA R0 @UNIDADES
    STA R0 @DEZENAS
    STA R0 @CENTENAS
    STA R0 @UNI_MILHARES
    STA R0 @DEZ_MILHARES
    STA R0 @CEN_MILHARES
    
    JSR @restart # reinicia configurações iniciais
    JSR @updateHexas # Atualiza displays
    RET

# Função para colocar os valores em decimal
update:
    LDA R0 @UNIDADES 
    CLT R0 @10 # Verifica se precisa dar "carry out" na unidade
    JLT @endUpdate
    LDI R0 $0 
    STA R0 @UNIDADES

    LDA R0 @DEZENAS
    ADD R0 @1
    STA R0 @DEZENAS
    CLT R0 @6 # Verifica se precisa dar "carry out" na dezena
    JLT @endUpdate
    LDI R0 $0
    STA R0 @DEZENAS

    LDA R0 @CENTENAS
    ADD R0 @1
    STA R0 @CENTENAS
    CLT R0 @10 # Verifica se precisa dar "carry out" na centena
    JLT @endUpdate
    LDI R0 $0
    STA R0 @CENTENAS

    LDA R0 @UNI_MILHARES
    ADD R0 @1
    STA R0 @UNI_MILHARES
    CLT R0 @6 # Verifica se precisa dar "carry out" na unidade de milhar
    JLT @endUpdate
    LDI R0 $0
    STA R0 @UNI_MILHARES

    LDA R0 @DEZ_MILHARES
    ADD R0 @1
    STA R0 @DEZ_MILHARES
    CLT R0 @4 # Verifica se precisa dar "carry out" na dezena de milhar
    JLT @endUpdate
    LDI R0 $0
    STA R0 @DEZ_MILHARES

    LDA R0 @CEN_MILHARES
    ADD R0 @1
    STA R0 @CEN_MILHARES
    CLT R0 @3 # Verifica se precisa dar "carry out" na centena de milhar
    JLT @endUpdate
    LDI R0 $0
    STA R0 @CEN_MILHARES

    LDI R0 $1
    STA R0 @INC_DISABLE # Seta flag que inibe incremento
    STA R0 @LEDR8 # Indica que chegou no limite de contagem de 24h

    endUpdate:
    RET

# Função para exibir valores da contagem no display
updateHexas:
    LDA R0 @UNIDADES 
    STA R0 @HEX0 # exibe valor da unidade
    LDA R0 @DEZENAS
    STA R0 @HEX1 # exibe valor da dezena
    LDA R0 @CENTENAS
    STA R0 @HEX2 # exibe valor da centena
    LDA R0 @UNI_MILHARES
    STA R0 @HEX3 # exibe valor da unidade de milhar
    LDA R0 @DEZ_MILHARES
    STA R0 @HEX4 # exibe valor da dezena de milhar
    LDA R0 @CEN_MILHARES
    STA R0 @HEX5 # exibe valor da centena de milhar
    RET

# Função para reiniciar configurações iniciais
restart:
    LDI R0 $0

    # Limpa botões
    STA R0 @KEY0_RESET
    STA R0 @KEY1_RESET
    STA R0 @TIMER_RESET # Limpa flag do timer

    # Limpa flags
    STA R0 @SPEED_STATE # Limpa flag de velocidade
    STA R0 @SEL_TIMER # Ajusta o timer para 1 segundo
    STA R0 @INC_DISABLE # Limpa flag que inibe incremento
    STA R0 @LEDR8 # Limpa aviso de limite de contagem
    STA R0 @LEDR9 # Limpa aviso de aceleração

    RET