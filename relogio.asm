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
    #define KEY0 352
    #define KEY1 353
    #define FPGA_RESET 356
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

    # Inicializando Variáveis
        LDI R0 $0 # contagem inciada em 0
        STA R0 @UNIDADES
        STA R0 @DEZENAS
        STA R0 @CENTENAS
        STA R0 @UNI_MILHARES
        STA R0 @DEZ_MILHARES
        STA R0 @CEN_MILHARES

    # Fim do setup

# loop principal
loop:
    # Verifica se pediu para resetar
    LDA R0 @FPGA_RESET # verifica FPGA_RESET
    ANDI R0 $1
    CEQI R0 $1 # Não tem debouncing no FPGA_RESET, então o botão é 0 enquanto apertado
    JEQ @notReset # Só reseta a contagem se o FPGA_RESET for pressionado
    JSR @reset
    notReset:

    # Verifica se pediu para configurar valor de início
    LDA R0 @KEY1 # verifica KEY1
    ANDI R0 $1
    CEQI R0 $0
    JEQ @notConfig # Só muda pro modo de configuração do valor de início se o KEY1 for pressionado
    JSR @config
    notConfig:    

    # Verifica se pediu para mudar a velocidade
    LDA R0 @KEY0 # verifica KEY0
    ANDI R0 $1
    CEQI R0 $0
    JEQ @notSpeed # Só muda a velocidade de incremento se o KEY0 for pressionado
    JSR @speed
    notSpeed: 
    
    JSR @update # atualiza valores para ficarem decimais
    JSR @updateHexas # exibe contagem atualizada
    JMP @loop # fim do loop principal

# Sub-rotinas

# Função para trocar velocidade do timer
speed:
    STA R2 @KEY0_RESET
    LDA R2 @SPEED_STATE
    ADDI R2 $1 # "inverte" o seletor de velocidade do timer
    STA R2 @SPEED_STATE
    STA R2 @SEL_TIMER
    STA R2 @LEDR9
    RET

# Função para incrementar
interrupt: # função de incremento chamada por interrupção
    LDA R1 @UNIDADES
    ADDI R1 $1 # incrementa
    STA R1 @UNIDADES
    RETI

# Função para configurar valor inicial
config:
    STA R2 @KEY1_RESET # limpa botão de configurar valor inicial
    JSR @reset # reseta contagem

    LDI R2 $7 # indica que está setando limite da centena (3 leds acesos)
    STA R2 @LEDR0TO7

    configCentenas:
    LDA R2 @KEY1
    ANDI R2 $1
    CEQ R2 @0 # verifica se o botão de configurar foi apertado
    LDA R2 @SW0TO7
    ANDI R2 $15
    STA R2 @HEX2 # exibe valor das chaves
    JEQ @configCentenas
    STA R2 @KEY1_RESET
    STA R2 @CENTENAS
    LDI R2 $9
    CLT R2 @CENTENAS # verifica se o limite é válido
    JLT @configCentenas
    # Se o limite é valido, passa pro próximo

    LDI R2 $15 # indica que está setando limite da unidade de milhar (4 leds acesos)
    STA R2 @LEDR0TO7

    configUniMilhares:
    LDA R2 @KEY1
    ANDI R2 $1
    CEQ R2 @0 # verifica se o botão de configurar foi apertado
    LDA R2 @SW0TO7
    ANDI R2 $7
    STA R2 @HEX3 # exibe valor das chaves
    JEQ @configUniMilhares
    STA R2 @KEY1_RESET
    STA R2 @UNI_MILHARES
    LDI R2 $5
    CLT R2 @UNI_MILHARES # verifica se o limite é válido
    JLT @configUniMilhares
    # Se o limite é valido, passa pro próximo

    LDI R2 $31 # indica que está setando limite da dezena de milhar (5 leds acesos)
    STA R2 @LEDR0TO7

    configDezMilhares:
    LDA R2 @KEY1
    ANDI R2 $1
    CEQ R2 @0 # verifica se o botão de configurar foi apertado
    LDA R2 @SW0TO7
    ANDI R2 $7
    STA R2 @HEX4 # exibe valor das chaves
    JEQ @configDezMilhares
    STA R2 @KEY1_RESET
    STA R2 @DEZ_MILHARES
    LDI R2 $3
    CLT R2 @DEZ_MILHARES # verifica se o limite é válido
    JLT @configDezMilhares
    # Se o limite é valido, passa pro próximo

    LDI R2 $63 # indica que está setando limite da centena de milhar (6 leds acesos)
    STA R2 @LEDR0TO7

    configCenMilhares:
    LDA R2 @KEY1
    ANDI R2 $1
    CEQ R2 @0 # verifica se o botão de configurar foi apertado
    LDA R2 @SW0TO7
    ANDI R2 $3
    STA R2 @HEX5 # exibe valor das chaves
    JEQ @configCenMilhares
    STA R2 @KEY1_RESET
    STA R2 @CEN_MILHARES
    LDI R2 $2
    CLT R2 @CEN_MILHARES # verifica se o limite é válido
    JLT @configCenMilhares
    # Se o limite é valido finaliza configuração

    LDI R2 $0 # apaga leds 
    STA R2 @LEDR0TO7
    
    JSR @restart # resaura configurações iniciais
    RET

# Função para resetar contagem
reset:
    LDI R2 $0

    # Limpa valores de contagem
    STA R2 @UNIDADES
    STA R2 @DEZENAS
    STA R2 @CENTENAS
    STA R2 @UNI_MILHARES
    STA R2 @DEZ_MILHARES
    STA R2 @CEN_MILHARES
    
    JSR @restart # reinicia configurações iniciais
    JSR @updateHexas # Atualiza displays
    RET

# Função para colocar os valores em decimal
update:
    LDA R2 @UNIDADES 
    CLTI R2 $10 # Verifica se precisa dar "carry out" na unidade
    JLT @endUpdate
    LDI R2 $0 
    STA R2 @UNIDADES

    LDA R2 @DEZENAS
    ADDI R2 $1
    STA R2 @DEZENAS
    CLTI R2 $6 # Verifica se precisa dar "carry out" na dezena
    JLT @endUpdate
    LDI R2 $0
    STA R2 @DEZENAS

    LDA R2 @CENTENAS
    ADDI R2 $1
    STA R2 @CENTENAS
    CLTI R2 $10 # Verifica se precisa dar "carry out" na centena
    JLT @endUpdate
    LDI R2 $0
    STA R2 @CENTENAS

    LDA R2 @UNI_MILHARES
    ADDI R2 $1
    STA R2 @UNI_MILHARES
    CLTI R2 $6 # Verifica se precisa dar "carry out" na unidade de milhar
    JLT @endUpdate
    LDI R2 $0
    STA R2 @UNI_MILHARES

    LDA R2 @DEZ_MILHARES
    ADDI R2 $1
    STA R2 @DEZ_MILHARES
    CLTI R2 $4 # Verifica se precisa dar "carry out" na dezena de milhar
    JLT @endUpdate
    LDI R2 $0
    STA R2 @DEZ_MILHARES

    LDA R2 @CEN_MILHARES
    ADDI R2 $1
    STA R2 @CEN_MILHARES
    CLTI R2 $3 # Verifica se precisa dar "carry out" na centena de milhar
    JLT @endUpdate
    LDI R2 $0
    STA R2 @CEN_MILHARES

    JSR @reset # Reseta caso tenha chegado em 24h
    endUpdate:
    RET

# Função para exibir valores da contagem no display
updateHexas:
    LDA R2 @UNIDADES 
    STA R2 @HEX0 # exibe valor da unidade
    LDA R2 @DEZENAS
    STA R2 @HEX1 # exibe valor da dezena
    LDA R2 @CENTENAS
    STA R2 @HEX2 # exibe valor da centena
    LDA R2 @UNI_MILHARES
    STA R2 @HEX3 # exibe valor da unidade de milhar
    LDA R2 @DEZ_MILHARES
    STA R2 @HEX4 # exibe valor da dezena de milhar
    LDA R2 @CEN_MILHARES
    STA R2 @HEX5 # exibe valor da centena de milhar
    RET

# Função para reiniciar configurações iniciais
restart:
    LDI R2 $0

    # Limpa botões
    STA R2 @KEY0_RESET
    STA R2 @KEY1_RESET

    # Limpa flags
    STA R2 @SPEED_STATE # Limpa flag de velocidade
    STA R2 @SEL_TIMER # Ajusta o timer para 1 segundo
    STA R2 @LEDR9 # Limpa aviso de aceleração
    RET