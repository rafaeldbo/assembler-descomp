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
    #define SW8 321
    #define SW9 322
    #define KEY0 352
    #define KEY1 353
    #define KEY2 354
    #define KEY3 355
    #define KEY_RST 356
    #define KEY_RST_RESET 507
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

    #define INC_DISABLE 32

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

    # Limpando FF dos botôes
        STA @KEY_RST_RESET
        STA @KEY0_RESET
        STA @KEY1_RESET

    # Inicializando Variáveis
        LDI $0
        STA @UNIDADES
        STA @DEZENAS
        STA @CENTENAS
        STA @UNI_MILHARES
        STA @DEZ_MILHARES
        STA @CEN_MILHARES

        LDI $9
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
        LDI $9
        STA @9 
        LDI $10
        STA @10 # fim do setup

# loop principal
loop:
    # Verifica se pediu para reiniciar
    LDA @KEY_RST # verifica FPGA_RESET
    # AND @1
    CEQ @0
    JEQ @notRestart
    JSR @restart
    notRestart:

    # Verifica se pediu para configurar limite
    LDA @KEY1 # verifica KEY1
    # AND @1
    CEQ @0
    JEQ @notConfig
    JSR @config
    notConfig:

    # Verifica se pediu para incrementar
    LDA @KEY0 # verifica KEY0
    # AND @1
    CEQ @0
    JEQ @notInc
    JSR @inc
    notInc:    

    # Fim do loop
    JSR @updateHexas
    JMP @loop # fim do loop principal


# Sub-rotinas
inc:
    LDI $1
    STA @LEDR0TO7 # Aviso de que está incrementando

    STA @KEY0_RESET # increment
    LDA @INC_DISABLE
    CEQ @1
    JEQ @endInc

    LDA @UNIDADES
    ADD @1
    STA @UNIDADES

    JSR @update # atualiza valores para ficarem decimais
    JSR @checkLimit # checka limite de contagem

    endInc:
    RET

config:
    LDI $2
    STA @LEDR0TO7 # Aviso de que está configurando

    STA @KEY1_RESET # config
    JSR @restart 

    configUnidades:
    LDA @SW0TO7
    STA @LIM_UNIDADES
    LDA @9
    CLT @LIM_UNIDADES
    JLT @configUnidades
    LDA @LIM_UNIDADES
    STA @HEX0
    LDA @KEY1
    STA @KEY1_RESET
    # AND @1
    CEQ @0
    JEQ @configUnidades

    configDezenas:
    LDA @SW0TO7
    STA @LIM_DEZENAS
    LDA @9
    CLT @LIM_DEZENAS
    JLT @configUnidades
    LDA @LIM_DEZENAS
    STA @HEX1
    LDA @KEY1
    STA @KEY1_RESET
    # AND @1
    CEQ @0
    JEQ @configDezenas

    configCentenas:
    LDA @SW0TO7
    STA @LIM_CENTENAS
    LDA @9
    CLT @LIM_CENTENAS
    JLT @configUnidades
    LDA @LIM_CENTENAS
    STA @HEX2
    LDA @KEY1
    STA @KEY1_RESET
    # AND @1
    CEQ @0
    JEQ @configCentenas

    configUniMilhares:
    LDA @SW0TO7
    STA @LIM_UNI_MILHARES
    LDA @9
    CLT @LIM_UNI_MILHARES
    JLT @configUnidades
    LDA @LIM_UNI_MILHARES
    STA @HEX3
    LDA @KEY1
    STA @KEY1_RESET
    # AND @1
    CEQ @0
    JEQ @configUniMilhares

    configDezMilhares:
    LDA @SW0TO7
    STA @LIM_DEZ_MILHARES
    LDA @9
    CLT @LIM_DEZ_MILHARES
    JLT @configUnidades
    LDA @LIM_DEZ_MILHARES
    STA @HEX4
    LDA @KEY1
    STA @KEY1_RESET
    # AND @1
    CEQ @0
    JEQ @configDezMilhares

    configCenMilhares:
    LDA @SW0TO7
    STA @LIM_CEN_MILHARES
    LDA @9
    CLT @LIM_CEN_MILHARES
    JLT @configUnidades
    LDA @LIM_CEN_MILHARES
    STA @HEX5
    LDA @KEY1
    STA @KEY1_RESET
    # AND @1
    CEQ @0
    JEQ @configCenMilhares

    RET

restart:
    STA @KEY_RST_RESET # restart
    LDI $0

    STA @INC_DISABLE
    STA @LEDR8
    STA @LEDR9

    STA @UNIDADES
    STA @DEZENAS
    STA @CENTENAS
    STA @UNI_MILHARES
    STA @DEZ_MILHARES
    STA @CEN_MILHARES

    JSR @updateHexas
    RET

update:
    LDA @UNIDADES 
    CLT @10
    JLT @endUpdate
    LDI $0
    STA @UNIDADES

    LDA @DEZENAS
    ADD @1
    STA @DEZENAS
    CLT @10
    JLT @endUpdate
    LDI $0
    STA @DEZENAS

    LDA @CENTENAS
    ADD @1
    STA @CENTENAS
    CLT @10
    JLT @endUpdate
    LDI $0
    STA @CENTENAS

    LDA @UNI_MILHARES
    ADD @1
    STA @UNI_MILHARES
    CLT @10
    JLT @endUpdate
    LDI $0
    STA @UNI_MILHARES

    LDA @DEZ_MILHARES
    ADD @1
    STA @DEZ_MILHARES
    CLT @10
    JLT @endUpdate
    LDI $0
    STA @DEZ_MILHARES

    LDA @CEN_MILHARES
    ADD @1
    STA @CEN_MILHARES
    CLT @10
    JLT @endUpdate
    LDI $0
    STA @CEN_MILHARES

    LDI $1
    STA @INC_DISABLE
    STA @LEDR8

    endUpdate:
    RET

checkLimit:
    LDA @UNIDADES  # checkLimit
    CLT @LIM_UNIDADES
    JLT @endCheckLimit

    LDA @DEZENAS
    CLT @LIM_DEZENAS
    JLT @endCheckLimit
    
    LDA @CENTENAS
    CLT @LIM_CENTENAS
    JLT @endCheckLimit

    LDA @UNI_MILHARES
    CLT @LIM_UNI_MILHARES
    JLT @endCheckLimit

    LDA @DEZ_MILHARES
    CLT @LIM_DEZ_MILHARES
    JLT @endCheckLimit

    LDA @CEN_MILHARES
    CLT @LIM_CEN_MILHARES
    JLT @endCheckLimit

    LDI $1
    STA @INC_DISABLE
    STA @LEDR9

    endCheckLimit:
    RET

updateHexas:
    LDA @UNIDADES # updateHexas
    STA @HEX0
    LDA @DEZENAS
    STA @HEX1
    LDA @CENTENAS
    STA @HEX2
    LDA @UNI_MILHARES
    STA @HEX3
    LDA @DEZ_MILHARES
    STA @HEX4
    LDA @CEN_MILHARES
    STA @HEX5
    RET