# Mapeando a Memória:
    #define LEDR0TO7 256
    #define LEDR8 257
    #define LEDR9 258
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
    #define TIMER_SEG 357
    #define TIMER_SEG_RESET 506
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

        LDI R0 $9 # Limite de contagem inicial de 999.999
        STA R0 @LIM_UNIDADES
        STA R0 @LIM_DEZENAS
        STA R0 @LIM_CENTENAS
        STA R0 @LIM_UNI_MILHARES
        STA R0 @LIM_DEZ_MILHARES
        STA R0 @LIM_CEN_MILHARES

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
        LDI R0 $10
        STA R0 @10 
    # Fim do setup

# loop principal
loop:
    # Verifica se pediu para reiniciar
    LDA R0 @FPGA_RESET # verifica FPGA_RESET
    AND R0 @1
    CEQ R0 @1 # Não tem debouncing no FPGA_RESET, então o botão é 0 quando apertado
    JEQ @notRestart # Só reinicia a contagem se o FPGA_RESET for pressionado
    JSR @restart
    notRestart:

    # Verifica se pediu para configurar limite
    LDA R0 @KEY1 # verifica KEY1
    AND R0 @1
    CEQ R0 @0
    JEQ @notConfig # Só muda pro modo de configuração de limite se o KEY1 for pressionado
    JSR @config
    notConfig:

    # Verifica se pediu para incrementar
    LDA R0 @TIMER_SEG # verifica KEY0
    AND R0 @1
    CEQ R0 @0
    JEQ @notInc # Só incrementa de limite se o KEY0 for pressionado
    JSR @inc
    notInc:    

    JSR @updateHexas # exibe contagem atualizada
    JMP @loop # fim do loop principal


# Sub-rotinas

# Função para incrementar
inc:
    STA R0 @TIMER_SEG_RESET # limpa botão de incrementar
    
    LDA R0 @INC_DISABLE
    CEQ R0 @1 # verifica flag de limite de contagem / overflow (inibe incremento)
    JEQ @endInc # se flag hablitada, não incrementa (pula pro final da função)
    
    LDA R0 @UNIDADES
    ADD R0 @1 # incrementa
    STA R0 @UNIDADES

    JSR @update # atualiza valores para ficarem decimais
    JSR @checkLimit # checa se limite de contagem foi atingido

    endInc:
    RET

# Função para configurar limites
config:
    STA R0 @KEY1_RESET # limpa botão de configurar limites
    JSR @restart # reseta contagem

    LDI R0 $1 # indica que está setando limite da unidade (1 led acesos)
    STA R0 @LEDR0TO7

    configUnidades:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    STA R0 @HEX0 # exibe valor das chaves
    JEQ @configUnidades
    STA R0 @KEY1_RESET
    STA R0 @LIM_UNIDADES
    LDI R0 $9
    CLT R0 @LIM_UNIDADES # verifica se o limite é válido
    JLT @configUnidades
    # Se o limite é valido, passa pro próximo

    LDI R0 $3 # indica que está setando limite da dezena (2 leds acesos)
    STA R0 @LEDR0TO7

    configDezenas:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    STA R0 @HEX1 # exibe valor das chaves
    JEQ @configDezenas
    STA R0 @KEY1_RESET
    STA R0 @LIM_DEZENAS
    LDI R0 $9
    CLT R0 @LIM_DEZENAS # verifica se o limite é válido
    JLT @configDezenas
    # Se o limite é valido, passa pro próximo

    LDI R0 $7 # indica que está setando limite da centena (3 leds acesos)
    STA R0 @LEDR0TO7

    configCentenas:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    STA R0 @HEX2 # exibe valor das chaves
    JEQ @configCentenas
    STA R0 @KEY1_RESET
    STA R0 @LIM_CENTENAS
    LDI R0 $9
    CLT R0 @LIM_CENTENAS # verifica se o limite é válido
    JLT @configCentenas
    # Se o limite é valido, passa pro próximo

    LDI R0 $15 # indica que está setando limite da unidade de milhar (4 leds acesos)
    STA R0 @LEDR0TO7

    configUniMilhares:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    STA R0 @HEX3 # exibe valor das chaves
    JEQ @configUniMilhares
    STA R0 @KEY1_RESET
    STA R0 @LIM_UNI_MILHARES
    LDI R0 $9
    CLT R0 @LIM_UNI_MILHARES # verifica se o limite é válido
    JLT @configUniMilhares
    # Se o limite é valido, passa pro próximo

    LDI R0 $31 # indica que está setando limite da dezena de milhar (5 leds acesos)
    STA R0 @LEDR0TO7

    configDezMilhares:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    STA R0 @HEX4 # exibe valor das chaves
    JEQ @configDezMilhares
    STA R0 @KEY1_RESET
    STA R0 @LIM_DEZ_MILHARES
    LDI R0 $9
    CLT R0 @LIM_DEZ_MILHARES # verifica se o limite é válido
    JLT @configDezMilhares
    # Se o limite é valido, passa pro próximo

    LDI R0 $63 # indica que está setando limite da centena de milhar (6 leds acesos)
    STA R0 @LEDR0TO7

    configCenMilhares:
    LDA R0 @KEY1
    AND R0 @1
    CEQ R0 @0 # verifica se o botão de configurar foi apertado
    LDA R0 @SW0TO7
    STA R0 @HEX5 # exibe valor das chaves
    JEQ @configCenMilhares
    STA R0 @KEY1_RESET
    STA R0 @LIM_CEN_MILHARES
    LDI R0 $9
    CLT R0 @LIM_CEN_MILHARES # verifica se o limite é válido
    JLT @configCenMilhares
    # Se o limite é valido finaliza configuração

    LDI R0 $0 # apaga leds 
    STA R0 @LEDR0TO7
    
    JSR @restart # reseta valores do display e limpa botões
    JSR @checkLimit # checa se o limite de contagem foi atingido
    RET

# Função para reiniciar contagem
restart:
    LDI R0 $0

    # Limpa botões
    STA R0 @KEY0_RESET
    STA R0 @KEY1_RESET

    STA R0 @INC_DISABLE # Limpa flag que inibe incremento
    STA R0 @LEDR8 # Limpa aviso de overflow
    STA R0 @LEDR9 # Limpa aviso de limite de contagem

    # Limpa valores de contagem
    STA R0 @UNIDADES
    STA R0 @DEZENAS
    STA R0 @CENTENAS
    STA R0 @UNI_MILHARES
    STA R0 @DEZ_MILHARES
    STA R0 @CEN_MILHARES
    
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
    STA R0 @LEDR8 # Indica que teve overflow

    endUpdate:
    RET

# Função de checar limite de contagem
checkLimit:
    LDA R0 @UNIDADES 
    CLT R0 @LIM_UNIDADES # Checa limite da unidade
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    LDA R0 @DEZENAS
    CLT R0 @LIM_DEZENAS # Checa limite da dezena
    JLT @endCheckLimit # Se não chegou no limite, finaliza função
    
    LDA R0 @CENTENAS
    CLT R0 @LIM_CENTENAS # Checa limite da centena
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    LDA R0 @UNI_MILHARES
    CLT R0 @LIM_UNI_MILHARES # Checa limite da unidade de milhar
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    LDA R0 @DEZ_MILHARES
    CLT R0 @LIM_DEZ_MILHARES # Checa limite da dezena de milhar
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    LDA R0 @CEN_MILHARES
    CLT R0 @LIM_CEN_MILHARES # Checa limite da centena de milhar
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    # Se chegou aqui, chegou no limite de contagem
    LDI R0 $1
    STA R0 @INC_DISABLE # Seta flag de limite de contagem
    STA R0 @LEDR9 # indica que o limite de contagem foi atingido

    endCheckLimit:
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