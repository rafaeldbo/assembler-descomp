import traceback, os, sys, re

# Função de coloração de texto
def colorize(text:str, color:str) -> str:
    COLORS = {'red': '\033[91m', 'green': '\033[92m', 'dark green': '\033[38;2;0;100;0m', 'yellow': '\033[93m', 'reset': '\033[0m', 'cyan': '\033[96m'}
    return f'{COLORS[color.lower()]}{text}{COLORS["reset"]}'

# Funções de log
def info(message:str) -> None:
    print(colorize(f'[INFO] {message}', 'green'))

class ArgParserError(Exception):
    def __init__(self, message:str):
        super().__init__(message)

# ASMfile = Arquivo de entrada de contém o assembly
if len(sys.argv) > 1: # Fazendo leitura do argumento de arquivo .asm
    file = sys.argv[1] if '.asm' in sys.argv[1] else sys.argv[1] + '.asm'
    if not os.path.isfile(file):
        raise ArgParserError(f'Arquivo .asm "{file}" não encontrado')
    ASMfile = file
elif os.path.isfile('./code.asm'):
    ASMfile = './code.asm' 
    info('Compilando arquivo "code.asm" encontrado no diretório atual')
else:
    raise FileNotFoundError('Arquivo "code.asm" não encontrado e nenhum arquivo foi fornecido na entrada')
    
# initROM.mif = Arquivo de saída que countém o binário formatado para VHDL
if os.path.isfile('./initROM.mif'):
    MIFfile = './initROM.mif'
    info('Arquivo initROM.mif encontrado no diretório atual')
elif os.path.isfile('../initROM.mif'):
    MIFfile = '../initROM.mif'
    info('Arquivo initROM.mif encontrado no diretório anterior')
else:
    raise FileNotFoundError('Arquivo "initROM.mif" não encontrado')

ROMfile = './ROM.txt' # Arquivo de saída que countém o binário formatado para VHDL

# limpando arquivos .vhd.bak do diretório
dirpath = MIFfile.replace('initROM.mif', '') 
for path, *content in os.walk(dirpath):
    folders, files = content
    if path == dirpath:
        for file in files:
            if '.vhd.bak' in file:
                os.remove(os.path.join(dirpath, file))

OPCODE_SIZE = 5
BANKREG_SIZE = 2
IMMEDIATE_SIZE = 9

MNEMONICS =	 {
    'NOP':  0,
    'LDA':  1,
    'SUM':  2, 'SOMA': 2, 'ADD': 2,
    'SUB':  3,
    'LDI':  4,
    'STA':  5,
    'JMP':  6,
    'JEQ':  7,
    'CEQ':  8,
    'JSR':  9,
    'RET':  10,
    'AND':  11,
    'CLT':  12,
    'JLT':  13,
}

INST_EMPTY_PATTERN = r'\b(?P<OPCODE>\w{3,5})\b$'
INST_EMPTY_MOEMONICS = ['NOP', 'RET']
INST_EMPTY_STRUCTURE = '<OPCODE>'

INST_IMMEDIATE_PATTERN = r'\b(?P<OPCODE>\w{3,5})\b R(?P<REGISTER>[0-9])\b \$(?P<IMMEDIATE>\S+)$'
INST_IMMEDIATE_MOEMONICS = ['LDI']
INST_IMMEDIATE_STRUCTURE = '<OPCODE> R<REGISTER> $<IMMEDIATE>'

INST_REG_MEM_PATTERN = r'\b(?P<OPCODE>\w{3,5})\b R(?P<REGISTER>[0-9])\b @(?P<IMMEDIATE>\S+)$'
INST_REG_MEM_MOEMONICS = ['LDA', 'STA', *('SUM', 'SOMA', 'ADD'), 'SUB', 'AND', 'CEQ', 'CLT']
INST_REG_MEM_STRUCTURE = '<OPCODE> R<REGISTER> @<MEM>'

INST_JUMP_PATTERN = r'\b(?P<OPCODE>\w{3,5})\b @(?P<IMMEDIATE>\S+)$'
INST_JUMP_MOEMONICS = ['JMP', 'JSR', 'JEQ', 'JLT']
INST_JUMP_STRUCTURE = '<OPCODE> @<LINE>'

INSTRUCTION_DATA_PARSER = {
    'empty':     (INST_EMPTY_MOEMONICS,     INST_EMPTY_STRUCTURE),
    'immediate': (INST_IMMEDIATE_MOEMONICS, INST_IMMEDIATE_STRUCTURE),
    'reg_mem':   (INST_REG_MEM_MOEMONICS,   INST_REG_MEM_STRUCTURE),
    'jump':      (INST_JUMP_MOEMONICS,      INST_JUMP_STRUCTURE)
}
        
DEFINE_PATTERN = r'#define \b(?P<ALIAS>\S+) \b(?P<VALUE>\d+)$'
LABEL_PATTERN = r'^(?P<LABEL>\S+):$'

MIFheader = """-- Copyright (C) 2017  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions
-- and other software and tools, and its AMPP partner logic
-- functions, and any output files from any of the foregoing
-- (including device programming or simulation files), and any
-- associated documentation or information are expressly subject
-- to the terms and conditions of the Intel Program License
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details.

WIDTH={width};
DEPTH={depth};
ADDRESS_RADIX=DEC;
DATA_RADIX=BIN;

CONTENT BEGIN
--address : data;\n""".format(width=OPCODE_SIZE+BANKREG_SIZE+IMMEDIATE_SIZE, depth=512)

global FILE_LINE

# Funções de alerta de sintaxe
def warning(message:str) -> None:
    print(colorize(f'[WARNING] {message} (file line: {FILE_LINE})', 'yellow'))

class ASMError(Exception):
    def __init__(self, message:str):
        super().__init__(message)

# Funções auxiliares
def b(value:str|int, size:int) -> str: # Converte um valor para binário com 'size' bits
    value = 0 if value == '' else int(value)
    if value > 2**size-1:
        raise ASMError(f'Valor "{value}" é maior que o limite de {2**size-1}. Não é possível representar em {size} bits')
    return f'"{bin(value)[2:].zfill(size)}"' if size > 1 else f"'{bin(value)[2:].zfill(size)}'"

def toMIF(instrction:str) -> str: #  Transforma o formato do .mif no formato binário
    return ''.join(instrction.replace('"', '').split(' & '))

# Classe que define a tabela de símbolos
class SymbolTable:
    def __init__(self) -> None:
        self.table = {}
    
    def add_label(self, label:str, line:int) -> None:
        if label.upper() in self.table.keys():
            raise ASMError(f'Label "{label.upper()}" não pôde ser declarada pois já é um alias')
        if label.lower() not in self.table.keys():
            self.table[label.lower()] = line
            info(f'Label "{label.lower()}" declarada na linha {line}')
            return
        raise ASMError(f'Label "{label.upper()}" já foi declarada')
    
    def add_alias(self, alias:str, position:int) -> None:
        if alias.lower() in self.table.keys():
            raise ASMError(f'Alias "{alias.upper()}" não pôde ser declarado pois já é uma label')
        if alias.upper() not in self.table.keys():
            self.table[alias.upper()] = position
            info(f'Alias "{alias.upper()}" declarado para a posição {position} da memória')
            return
        raise ASMError(f'Alias "{alias.upper()}" já foi declarado')
    
    def get(self, symbol:str) -> bool:
        if symbol.lower() in self.table.keys(): 
            return self.table[symbol.lower()]
        if symbol.upper() in self.table.keys():
            return self.table[symbol.upper()]
        raise ASMError(f'Símbolo "{symbol}" não foi declarado nem como label nem como alias')

# Funções de tratamento de linha
def defineComment(line: str) -> str: # Cria a versão da linha com comentário
    if '# ' in line:
        line = line.split('# ')
        line = line[0] + '\t#' + line[1]
    return line

def defineInstruction(line: str) -> str: # Cria a versão da linha sem comentário
    if '# ' in line:
        line = line.split('# ')[0]
    elif '#' in line and not line.startswith('#define'):
        raise ASMError(f'Comentário não está no formato correto. Só utilize o simpulo # para fazer comentários. \nRecebido: "{line}" \nEsperado: <INSTRUÇÃO> # <COMENTÁRIO>')
    return line.strip()

def parseInstruction(line: str) -> str: # converte a instrução para o formato binário
    # Identificando a estrutura da instrução
    # Instrução sem argumentos
    if (match := re.match(INST_EMPTY_PATTERN, line)) is not None: 
        opcode, register, immediate = match.group('OPCODE'), '', ''
        mnemonics, structure = INSTRUCTION_DATA_PARSER['empty']
    # Instrução com imediato
    elif (match := re.match(INST_IMMEDIATE_PATTERN, line)) is not None: 
        opcode, register, immediate = match.group('OPCODE'), match.group('REGISTER'), match.group('IMMEDIATE')
        mnemonics, structure = INSTRUCTION_DATA_PARSER['immediate']
    # Instrução com acesso a memória
    elif (match := re.match(INST_REG_MEM_PATTERN, line)) is not None: 
        opcode, register, immediate = match.group('OPCODE'), match.group('REGISTER'), match.group('IMMEDIATE')
        mnemonics, structure = INSTRUCTION_DATA_PARSER['reg_mem']
    # Instrução de pulo
    elif (match := re.match(INST_JUMP_PATTERN, line)) is not None: 
        opcode, register, immediate = match.group('OPCODE'), '', match.group('IMMEDIATE')
        mnemonics, structure = INSTRUCTION_DATA_PARSER['jump']
    else:
        opcode, mnemonics = 'ERROR', MNEMONICS
        
    # Tratando erros de estrutura
    if opcode not in mnemonics:
        if opcode == '':
            raise ASMError(f'A estrutura dessa instrução está invalida. \nRecebido: "{line}" ')
        raise ASMError(f'A estrutura dessa instrução não corresponde com a estrutura da instrução "{opcode}" \nRecebido: {line} \nEsperado: {structure}')
    
    # Tratamento do mnemônico
    if opcode != opcode.upper():
        warning(f'Mnemônico "{opcode}" não está em caixa alta')
        opcode = opcode.upper()
    if opcode not in MNEMONICS.keys():
        raise ASMError(f'Mnemônico "{opcode}" não foi definido')
    
    # Tratamento do registrador
    if register != '' and int(register) > 2**BANKREG_SIZE-1:
        raise ASMError(f'Número do registrador "{register}" é maior que {2**BANKREG_SIZE-1}')
    
    # Tratamento do imediato
    if immediate != '':
        # Substituição de labels/alias
        if not immediate.isdigit():
            immediate = table.get(immediate)
        
        # Validação do valor do imediato
        if int(immediate) > 2**IMMEDIATE_SIZE-1:
            raise ASMError(f'Valor imediato "{immediate}" é maior que o limite de {2**IMMEDIATE_SIZE-1}')
    
    return f'{b(MNEMONICS[opcode], OPCODE_SIZE)} & {b(register, BANKREG_SIZE)} & {b(immediate, IMMEDIATE_SIZE)}'


# Leitura dos arquivos
with open(ASMfile, 'r', encoding='utf8') as f:
    lines = f.readlines() # faz aquisição do código do .asm

# Escrita dos arquivos
with open(ROMfile, 'w+') as f1, open(MIFfile, 'w') as f2:
    
    table = SymbolTable()
    f2.write(MIFheader) # Escreve o header no arquivo initROM.mif
    try:
        # Registrando labels e defines
        preprocessed_lines = []
        FILE_LINE = 1
        count = 0
        for line in lines:
            line = line.replace('\n', '').replace('\t', '').strip() # Remove o caracter de quebra de linha e tabulacao
            
            preprocessed_line = None
            if line not in ['', ' '] and not line.startswith('# '):
                instructionLine = defineInstruction(line)
                
                if instructionLine.startswith('#define '): # Define um alias
                    if (match := re.match(DEFINE_PATTERN, instructionLine)) is None:
                        raise ASMError(f'Estrutura do #define está incorreta. \nRecebido: {instructionLine} \nEsperado: #define <ALIAS> <VALUE>')
                    alias, value = match.group('ALIAS'), match.group('VALUE')
                    if (value := int(value)) > 2**IMMEDIATE_SIZE-1:
                        raise ASMError(f'Valor do #define "{value}" é maior que o limite de {2**IMMEDIATE_SIZE-1}')
                    table.add_alias(alias, int(value))
                    
                elif ':' in instructionLine: # Define um label
                    if (match := re.match(LABEL_PATTERN, instructionLine)) is None:
                        raise ASMError(f'Estrutura da label está incorreta. \nRecebido: {instructionLine} \nEsperado: <LABEL>:')
                    label = match.group('LABEL')
                    table.add_label(label, count)
                else: 
                    preprocessed_line = line
                    count += 1
            preprocessed_lines.append(preprocessed_line)
            FILE_LINE += 1
        
        # Escrevendo instruções  
        FILE_LINE = 1
        count = 0          
        for i, line in enumerate(preprocessed_lines): 
            if line is not None:
                # Exemplo de linha => 1. JSR @14 #comentario1
                commentLine = defineComment(line)         # Define o comentário da linha. Ex: #comentario1
                instructionLine = defineInstruction(line) # Define a instrução. Ex: JSR @14
                
                instructionLine = parseInstruction(instructionLine) # Converte imediato. Ex(JSR @14): x"9" & '0' & x"0E"
                
                f1.write(f'tmp({count}) := {instructionLine};\t-- {commentLine}\n') #Escreve no arquivo ROM.txt
                                                                                    #Entrada => 1. JSR @14 #comentario1
                                                                                    #Saída =>   1. tmp(0) := x"9" & '0' x"0E";	-- JSR @14 	#comentario1
                f2.write(f'{count} : {toMIF(instructionLine)};\n') #Escreve no arquivo initROM.mif
                print(f'tmp({count}) := {colorize(instructionLine, "cyan")};' + colorize(f"\t-- {commentLine}", "dark green"))
                                                                                    
                count += 1
            FILE_LINE += 1
        info(f'{count} instruções escritas')
        f2.write('END;') 
                
    # Tratamento de exceções
    except ASMError as error:
        print(colorize(f'[ERROR]: {error} (file line: {FILE_LINE})', 'red'))
    except Exception as error:
        print(traceback.format_exc())
        print(colorize(f'[BUG]: {error} (file line: {FILE_LINE})', 'red'))
    