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
        LDI $0
        STA @HEX0
        STA @HEX1
        STA @HEX2
        STA @HEX3
        STA @HEX4
        STA @HEX5
        STA @LEDR0TO7
        STA @LEDR8
        STA @LEDR9

    # Limpando FlipFlop dos botôes
        STA @KEY0_RESET
        STA @KEY1_RESET

    # Inicializando Variáveis
        LDI $0 # contagem inciada em 0
        STA @UNIDADES
        STA @DEZENAS
        STA @CENTENAS
        STA @UNI_MILHARES
        STA @DEZ_MILHARES
        STA @CEN_MILHARES

        LDI $9 # Limite de contagem inicial de 999.999
        STA @LIM_UNIDADES
        STA @LIM_DEZENAS
        STA @LIM_CENTENAS
        STA @LIM_UNI_MILHARES
        STA @LIM_DEZ_MILHARES
        STA @LIM_CEN_MILHARES

    # Variaveis utilizadas em operações
        LDI $0
        STA @0
        LDI $1
        STA @1
        LDI $10
        STA @10 
    # Fim do setup

# loop principal
loop:
    # Verifica se pediu para reiniciar
    LDA @FPGA_RESET # verifica FPGA_RESET
    AND @1
    CEQ @1 # Não tem debouncing no FPGA_RESET, então o botão é 0 quando apertado
    JEQ @notRestart # Só reinicia a contagem se o FPGA_RESET for pressionado
    JSR @restart
    notRestart:

    # Verifica se pediu para configurar limite
    LDA @KEY1 # verifica KEY1
    AND @1
    CEQ @0
    JEQ @notConfig # Só muda pro modo de configuração de limite se o KEY1 for pressionado
    JSR @config
    notConfig:

    # Verifica se pediu para incrementar
    LDA @KEY0 # verifica KEY0
    AND @1
    CEQ @0
    JEQ @notInc # Só incrementa de limite se o KEY0 for pressionado
    JSR @inc
    notInc:    

    JSR @updateHexas # exibe contagem atualizada
    JMP @loop # fim do loop principal


# Sub-rotinas

# Função para incrementar
inc:
    STA @KEY0_RESET # limpa botão de incrementar
    
    LDA @INC_DISABLE
    CEQ @1 # verifica flag de limite de contagem / overflow (inibe incremento)
    JEQ @endInc # se flag hablitada, não incrementa (pula pro final da função)
    
    LDA @UNIDADES
    ADD @1 # incrementa
    STA @UNIDADES

    JSR @update # atualiza valores para ficarem decimais
    JSR @checkLimit # checa se limite de contagem foi atingido

    endInc:
    RET

# Função para configurar limites
config:
    STA @KEY1_RESET # limpa botão de configurar limites
    JSR @restart # reseta contagem

    LDI $1 # indica que está setando limite da unidade (1 led acesos)
    STA @LEDR0TO7

    configUnidades:
    LDA @KEY1
    AND @1
    CEQ @0 # verifica se o botão de configurar foi apertado
    LDA @SW0TO7
    STA @HEX0 # exibe valor das chaves
    JEQ @configUnidades
    STA @KEY1_RESET
    STA @LIM_UNIDADES
    LDI $9
    CLT @LIM_UNIDADES # verifica se o limite é válido
    JLT @configUnidades
    # Se o limite é valido, passa pro próximo

    LDI $3 # indica que está setando limite da dezena (2 leds acesos)
    STA @LEDR0TO7

    configDezenas:
    LDA @KEY1
    AND @1
    CEQ @0 # verifica se o botão de configurar foi apertado
    LDA @SW0TO7
    STA @HEX1 # exibe valor das chaves
    JEQ @configDezenas
    STA @KEY1_RESET
    STA @LIM_DEZENAS
    LDI $9
    CLT @LIM_DEZENAS # verifica se o limite é válido
    JLT @configDezenas
    # Se o limite é valido, passa pro próximo

    LDI $7 # indica que está setando limite da centena (3 leds acesos)
    STA @LEDR0TO7

    configCentenas:
    LDA @KEY1
    AND @1
    CEQ @0 # verifica se o botão de configurar foi apertado
    LDA @SW0TO7
    STA @HEX2 # exibe valor das chaves
    JEQ @configCentenas
    STA @KEY1_RESET
    STA @LIM_CENTENAS
    LDI $9
    CLT @LIM_CENTENAS # verifica se o limite é válido
    JLT @configCentenas
    # Se o limite é valido, passa pro próximo

    LDI $15 # indica que está setando limite da unidade de milhar (4 leds acesos)
    STA @LEDR0TO7

    configUniMilhares:
    LDA @KEY1
    AND @1
    CEQ @0 # verifica se o botão de configurar foi apertado
    LDA @SW0TO7
    STA @HEX3 # exibe valor das chaves
    JEQ @configUniMilhares
    STA @KEY1_RESET
    STA @LIM_UNI_MILHARES
    LDI $9
    CLT @LIM_UNI_MILHARES # verifica se o limite é válido
    JLT @configUniMilhares
    # Se o limite é valido, passa pro próximo

    LDI $31 # indica que está setando limite da dezena de milhar (5 leds acesos)
    STA @LEDR0TO7

    configDezMilhares:
    LDA @KEY1
    AND @1
    CEQ @0 # verifica se o botão de configurar foi apertado
    LDA @SW0TO7
    STA @HEX4 # exibe valor das chaves
    JEQ @configDezMilhares
    STA @KEY1_RESET
    STA @LIM_DEZ_MILHARES
    LDI $9
    CLT @LIM_DEZ_MILHARES # verifica se o limite é válido
    JLT @configDezMilhares
    # Se o limite é valido, passa pro próximo

    LDI $63 # indica que está setando limite da centena de milhar (6 leds acesos)
    STA @LEDR0TO7

    configCenMilhares:
    LDA @KEY1
    AND @1
    CEQ @0 # verifica se o botão de configurar foi apertado
    LDA @SW0TO7
    STA @HEX5 # exibe valor das chaves
    JEQ @configCenMilhares
    STA @KEY1_RESET
    STA @LIM_CEN_MILHARES
    LDI $9
    CLT @LIM_CEN_MILHARES # verifica se o limite é válido
    JLT @configCenMilhares
    # Se o limite é valido finaliza configuração

    LDI $0 # apaga leds 
    STA @LEDR0TO7
    
    JSR @restart # reseta valores do display e limpa botões
    JSR @checkLimit # checa se o limite de contagem foi atingido
    RET

# Função para reiniciar contagem
restart:
    LDI $0

    # Limpa botões
    STA @KEY0_RESET
    STA @KEY1_RESET

    STA @INC_DISABLE # Limpa flag que inibe incremento
    STA @LEDR8 # Limpa aviso de overflow
    STA @LEDR9 # Limpa aviso de limite de contagem

    # Limpa valores de contagem
    STA @UNIDADES
    STA @DEZENAS
    STA @CENTENAS
    STA @UNI_MILHARES
    STA @DEZ_MILHARES
    STA @CEN_MILHARES
    
    JSR @updateHexas # Atualiza displays
    RET

# Função para colocar os valores em decimal
update:
    LDA @UNIDADES 
    CLT @10 # Verifica se precisa dar "carry out" na unidade
    JLT @endUpdate
    LDI $0 
    STA @UNIDADES

    LDA @DEZENAS
    ADD @1
    STA @DEZENAS
    CLT @10 # Verifica se precisa dar "carry out" na dezena
    JLT @endUpdate
    LDI $0
    STA @DEZENAS

    LDA @CENTENAS
    ADD @1
    STA @CENTENAS
    CLT @10 # Verifica se precisa dar "carry out" na centena
    JLT @endUpdate
    LDI $0
    STA @CENTENAS

    LDA @UNI_MILHARES
    ADD @1
    STA @UNI_MILHARES
    CLT @10 # Verifica se precisa dar "carry out" na unidade de milhar
    JLT @endUpdate
    LDI $0
    STA @UNI_MILHARES

    LDA @DEZ_MILHARES
    ADD @1
    STA @DEZ_MILHARES
    CLT @10 # Verifica se precisa dar "carry out" na dezena de milhar
    JLT @endUpdate
    LDI $0
    STA @DEZ_MILHARES

    LDA @CEN_MILHARES
    ADD @1
    STA @CEN_MILHARES
    CLT @10 # Verifica se precisa dar "carry out" na centena de milhar
    JLT @endUpdate
    LDI $0
    STA @CEN_MILHARES

    LDI $1
    STA @INC_DISABLE # Seta flag que inibe incremento
    STA @LEDR8 # Indica que teve overflow

    endUpdate:
    RET

# Função de checar limite de contagem
checkLimit:
    LDA @UNIDADES 
    CLT @LIM_UNIDADES # Checa limite da unidade
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    LDA @DEZENAS
    CLT @LIM_DEZENAS # Checa limite da dezena
    JLT @endCheckLimit # Se não chegou no limite, finaliza função
    
    LDA @CENTENAS
    CLT @LIM_CENTENAS # Checa limite da centena
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    LDA @UNI_MILHARES
    CLT @LIM_UNI_MILHARES # Checa limite da unidade de milhar
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    LDA @DEZ_MILHARES
    CLT @LIM_DEZ_MILHARES # Checa limite da dezena de milhar
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    LDA @CEN_MILHARES
    CLT @LIM_CEN_MILHARES # Checa limite da centena de milhar
    JLT @endCheckLimit # Se não chegou no limite, finaliza função

    # Se chegou aqui, chegou no limite de contagem
    LDI $1
    STA @INC_DISABLE # Seta flag de limite de contagem
    STA @LEDR9 # indica que o limite de contagem foi atingido

    endCheckLimit:
    RET

# Função para exibir valores da contagem no display
updateHexas:
    LDA @UNIDADES 
    STA @HEX0 # exibe valor da unidade
    LDA @DEZENAS
    STA @HEX1 # exibe valor da dezena
    LDA @CENTENAS
    STA @HEX2 # exibe valor da centena
    LDA @UNI_MILHARES
    STA @HEX3 # exibe valor da unidade de milhar
    LDA @DEZ_MILHARES
    STA @HEX4 # exibe valor da dezena de milhar
    LDA @CEN_MILHARES
    STA @HEX5 # exibe valor da centena de milhar
    RET