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
    #define UNIDADE_SEGUNDOS 16
    #define DEZENA_SEGUNDOS 17
    #define UNIDADE_MINUTOS 18
    #define DEZENA_MINUTOS 19
    #define UNIDADE_HORAS 20
    #define DEZENA_HORAS 21

    #define LIM_UNIDADE_SEGUNDOS 22
    #define LIM_DEZENA_SEGUNDOS 23
    #define LIM_UNIDADE_MINUTOS 24
    #define LIM_DEZENA_MINUTOS 25
    #define LIM_UNIDADE_HORAS 26
    #define LIM_DEZENA_HORAS 27

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

    # Limpando FlipFlop dos botões
        STA R0 @KEY0_RESET
        STA R0 @KEY1_RESET

    # Inicializando Variáveis
        LDI R0 $0 # contagem iniciada em 0
        STA R0 @UNIDADE_SEGUNDOS
        STA R0 @DEZENA_SEGUNDOS
        STA R0 @UNIDADE_MINUTOS
        STA R0 @DEZENA_MINUTOS
        STA R0 @UNIDADE_HORAS
        STA R0 @DEZENA_HORAS

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
    
    JSR @update # atualiza valores para ficarem decimais e dentro do padrão 23:59:59
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
    LDA R1 @UNIDADE_SEGUNDOS
    ADDI R1 $1 # incrementa
    STA R1 @UNIDADE_SEGUNDOS
    RETI

# Função para configurar valor inicial
config:
    STA R2 @KEY1_RESET # limpa botão de configurar valor inicial
    JSR @reset # reseta contagem

    LDI R2 $7 # indica que está setando o início da unidade dos minutos (3 leds acesos)
    STA R2 @LEDR0TO7

    configUnidadeMinutos:
    LDA R2 @KEY1
    ANDI R2 $1
    CEQ R2 @0 # verifica se o botão de configurar foi apertado
    LDA R2 @SW0TO7
    ANDI R2 $15
    STA R2 @HEX2 # exibe valor das chaves
    JEQ @configUnidadeMinutos
    STA R2 @KEY1_RESET
    STA R2 @UNIDADE_MINUTOS
    LDI R2 $9
    CLT R2 @UNIDADE_MINUTOS # verifica se o limite é válido
    JLT @configUnidadeMinutos
    # Se o limite é valido, passa para o próximo

    LDI R2 $15 # indica que está setando o início da dezena dos minutos (4 leds acesos)
    STA R2 @LEDR0TO7

    configDezenaMinutos:
    LDA R2 @KEY1
    ANDI R2 $1
    CEQ R2 @0 # verifica se o botão de configurar foi apertado
    LDA R2 @SW0TO7
    ANDI R2 $7
    STA R2 @HEX3 # exibe valor das chaves
    JEQ @configDezenaMinutos
    STA R2 @KEY1_RESET
    STA R2 @DEZENA_MINUTOS
    LDI R2 $5
    CLT R2 @DEZENA_MINUTOS # verifica se o limite é válido
    JLT @configDezenaMinutos
    # Se o limite é valido, passa para o próximo

    LDI R2 $31 # indica que está setando o início da unidade das horas (5 leds acesos)
    STA R2 @LEDR0TO7

    configUnidadeHoras:
    LDA R2 @KEY1
    ANDI R2 $1
    CEQ R2 @0 # verifica se o botão de configurar foi apertado
    LDA R2 @SW0TO7
    ANDI R2 $15
    STA R2 @HEX4 # exibe valor das chaves
    JEQ @configUnidadeHoras
    STA R2 @KEY1_RESET
    STA R2 @UNIDADE_HORAS
    LDI R2 $9
    CLT R2 @UNIDADE_HORAS # verifica se o limite é válido
    JLT @configUnidadeHoras
    # Se o limite é valido, passa para o próximo

    LDI R2 $63 # indica que está setando o início da dezena das horas (6 leds acesos)
    STA R2 @LEDR0TO7

    configDezenaHoras:
    LDA R2 @KEY1
    ANDI R2 $1
    CEQ R2 @0 # verifica se o botão de configurar foi apertado
    LDA R2 @SW0TO7
    ANDI R2 $3
    STA R2 @HEX5 # exibe valor das chaves
    JEQ @configDezenaHoras
    STA R2 @KEY1_RESET
    STA R2 @DEZENA_HORAS
    LDA R2 @UNIDADE_HORAS
    CLTI R2 $4 # Confere se a unidade das horas é menor que 4
    JLT @ConfigMais20Horas # Se a unidade é menor do que 4, confere se dezena de hora é 0,1 ou 2
    LDI R2 $1
    CLT R2 @DEZENA_HORAS # dezena de hora só poderá ser 0 ou 1
    JLT @configDezenaHoras

    ConfigMais20Horas: # dezena de hora pode ser 0,1 ou 2
    LDI R2 $2
    CLT R2 @DEZENA_HORAS # verifica se o limite é válido
    JLT @configDezenaHoras
    # Se o limite é valido finaliza configuração

    LDI R2 $0 # apaga leds 
    STA R2 @LEDR0TO7

    # Limpa unidade, já que ela continuou incrementando pela interrupção
    STA R2 @UNIDADE_SEGUNDOS

    JSR @restart # restaura configurações iniciais
    RET

# Função para resetar contagem
reset:
    LDI R2 $0

    # Limpa valores de contagem
    STA R2 @UNIDADE_SEGUNDOS
    STA R2 @DEZENA_SEGUNDOS
    STA R2 @UNIDADE_MINUTOS
    STA R2 @DEZENA_MINUTOS
    STA R2 @UNIDADE_HORAS
    STA R2 @DEZENA_HORAS
    
    JSR @restart # reinicia configurações iniciais
    JSR @updateHexas # Atualiza displays
    RET

# Função para colocar os valores em decimal
update:
    LDA R2 @UNIDADE_SEGUNDOS 
    CLTI R2 $10 # Verifica se precisa dar "carry out" na unidade dos segundos (vai de 0 a 9)
    JLT @endUpdate
    LDI R2 $0 
    STA R2 @UNIDADE_SEGUNDOS

    LDA R2 @DEZENA_SEGUNDOS
    ADDI R2 $1
    STA R2 @DEZENA_SEGUNDOS
    CLTI R2 $6 # Verifica se precisa dar "carry out" na dezena dos segundos (vai de 0 a 5)
    JLT @endUpdate
    LDI R2 $0
    STA R2 @DEZENA_SEGUNDOS

    LDA R2 @UNIDADE_MINUTOS
    ADDI R2 $1
    STA R2 @UNIDADE_MINUTOS
    CLTI R2 $10 # Verifica se precisa dar "carry out" na unidade dos minutos (vai de 0 a 9)
    JLT @endUpdate
    LDI R2 $0
    STA R2 @UNIDADE_MINUTOS

    LDA R2 @DEZENA_MINUTOS
    ADDI R2 $1
    STA R2 @DEZENA_MINUTOS
    CLTI R2 $6 # Verifica se precisa dar "carry out" na dezena dos minutos (vai de 0 a 5)
    JLT @endUpdate
    LDI R2 $0
    STA R2 @DEZENA_MINUTOS

#   Se houver “carry out” para a hora, além de serem chegados os limites dos algarismos, é checado se a hora chegou em 24
    LDA R2 @UNIDADE_HORAS
    ADDI R2 $1
    STA R2 @UNIDADE_HORAS
    CEQI R2 $4 # se é 4, verifica o valor da dezena da hora
    JEQ @check24HR
    JMP @updadeDezenaHoras # verifica se precisa da “carry out” na unidade de hora

    check24HR:
    LDA R2 @DEZENA_HORAS
    CEQI R2 $2 # se é 2, é porque a hora chegou em 24 horas
    JEQ @BackTo0 # reseta contagem se chegou em 24 horas
    JMP @updadeDezenaHoras # se não chegou em 24 horas, verifica se tem “carry out” na unidade de hora
    BackTo0:
    JSR @reset
    JMP @endUpdate

    updadeDezenaHoras:
    LDA R2 @UNIDADE_HORAS
    CLTI R2 $10 # Verifica se tem “carry out” na unidade de hora
    JLT @endUpdate
    LDI R2 $0
    STA R2 @UNIDADE_HORAS
    LDA R2 @DEZENA_HORAS
    ADDI R2 $1
    STA R2 @DEZENA_HORAS
    
    endUpdate:
    RET

# Função para exibir valores da contagem no display
updateHexas:
    LDA R2 @UNIDADE_SEGUNDOS 
    STA R2 @HEX0 # exibe valor da unidade
    LDA R2 @DEZENA_SEGUNDOS
    STA R2 @HEX1 # exibe valor da dezena
    LDA R2 @UNIDADE_MINUTOS
    STA R2 @HEX2 # exibe valor da centena
    LDA R2 @DEZENA_MINUTOS
    STA R2 @HEX3 # exibe valor da unidade de milhar
    LDA R2 @UNIDADE_HORAS
    STA R2 @HEX4 # exibe valor da dezena de milhar
    LDA R2 @DEZENA_HORAS
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