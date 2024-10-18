import traceback, os, sys

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

# ASMfile =  Arquivo de entrada de contém o assembly
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

IMMEDIATE_SIZE = 9
MNEMONICS =	{ 
    'NOP':  '0',
    'LDA':  '1',
    'SUM':  '2', 'SOMA': '2', 'ADD': '2',
    'SUB':  '3',
    'LDI':  '4',
    'STA':  '5',
    'JMP':  '6',
    'JEQ':  '7',
    'CEQ':  '8',
    'JSR':  '9',
    'RET':  'A',
    'AND':  'B',
    'CLT':  'C',
    'JLT':  'D',
}
global FILE_LINE

# Funções de alerta de sintaxe
def warning(message:str) -> None:
    print(colorize(f'[WARNING] {message} (file line: {FILE_LINE})', 'yellow'))

class ASMError(Exception):
    def __init__(self, message:str):
        super().__init__(message)

# Funções auxiliares
def b(value:str) -> str: # Coloca a "aspas" certa no valor binário
    if value == '': return value
    return f"'{value}'" if len(value) == 1 else f'"{value}"'

def x(value:str) -> str: # Coloca o valor hexadecimal no formato x""
    if value == '': return value
    return f'x"{value}"'

def toMIF(instrction:str) -> str: #  Transforma o formato da RAM no formato binário
    opcode, binary, hex = instrction.replace('x', '').replace('"', '').replace("'", '').replace('& ', '').split(' ')
    return bin(int(opcode, 16))[2:].zfill(4) + binary + bin(int(hex, 16))[2:].zfill(8)

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
    if '#' in line:
        line = line.split('#')
        line = line[0] + '\t#' + line[1]
    return line

def defineInstruction(line: str) -> str: # Cria a versão da linha sem comentário
    if line.startswith('#define') and '# ' in line:
        line = line.split('# ')[0]
    elif not line.startswith('#define') and '#' in line:
        line = line.split('#')[0]
    return line.strip()

def parseInstruction(line: str) -> str: # converte a instrução para o formato binário
    if line.count(' ') == 1:
        opcode, value = line.split(' ')
    elif line.count(' ') == 0:
        opcode, value = line, ''
    else:
        raise ASMError('A estrutura do Argumento não é válida, deve ser {Mnemônico} {@ ou $}{valor}')
    
    # Tratamento do mnemônico
    if opcode != opcode.upper():
        warning(f'Mnemônico "{opcode}" não está em caixa alta')
        opcode = opcode.upper()
        
    if opcode not in MNEMONICS.keys():
        raise ASMError(f'Mnemônico "{opcode}" não foi definido')
    
    # Tratamento do imediato
    if   '$' in value: # Valor
        if opcode not in ['LDI']:
            warning(f'Uso incorreto do "$" com o Mnemônico "{opcode}"')
        value = value[1:]
    elif '@' in value: # Acesso a memória ou label
        if opcode in ['LDI']:
            warning(f'Uso incorreto do "@" com o Mnemônico "{opcode}"')
        value = value[1:]
    elif value == '': # Se não houver valor imediato
        if opcode not in ['RET', 'NOP']:
            raise ASMError(f'A intrução "{opcode}" deve ter um imediato')
        value = '0'
    else:
        raise ASMError(f'Imediato "{value}" não foi definido corretamente')
    
    # Substituição de labels
    if not value.isdigit():
        value = table.get(value)
    
    # Validação do valor do imediato
    if int(value) > 2**IMMEDIATE_SIZE-1:
        raise ASMError(f'Valor imediato "{value}" é maior que o limite de {2**IMMEDIATE_SIZE-1}')
    
    # Conversão do valor do imediato para o formato hexadecimal+binário, limitado ao número de bits do imediato
    value = hex(int(value))[2:].upper().zfill(IMMEDIATE_SIZE//4)
    bin_part = b(value[:max(0, len(value)-IMMEDIATE_SIZE//4)].zfill(IMMEDIATE_SIZE%4))
    hex_part = f'x"{value[max(0, len(value)-IMMEDIATE_SIZE//4):]}"'
    
    if bin_part == '':
        return f'{MNEMONICS[opcode]} & {hex_part}'
    return f'{x(MNEMONICS[opcode])} & {bin_part} & {hex_part}'


# Leitura dos arquivos
with open(ASMfile, 'r', encoding='utf8') as f1, open(MIFfile, 'r') as f2:
    lines = f1.readlines() # faz aquisição do código do .asm
    HEADER_MIF = ''.join([f2.readline() for _ in range(21)]) # faz aquisição do header do arquivo .mif

# Escrita dos arquivos
with open(ROMfile, 'w+') as f1, open(MIFfile, 'w+') as f2:
    
    table = SymbolTable()
    f2.write(HEADER_MIF) # Escreve o header no arquivo initROM.mif
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
                    if instructionLine.count(' ') != 2:
                        raise ASMError('O #define deve ter 2 argumentos, o nome e o valor')
                    _, alias, value = instructionLine.split(' ')
                    if int(value) > 2**IMMEDIATE_SIZE-1:
                        raise ASMError(f'Valor do #define "{value}" é maior que o limite de {2**IMMEDIATE_SIZE-1}')
                    table.add_alias(alias, int(value))
                    
                elif ':' in instructionLine: # Define um label
                    label = instructionLine[:instructionLine.index(':')]
                    scrap = instructionLine[instructionLine.index(':'):]
                    if ' ' in label or '#' in label:
                        raise ASMError('Há caracteres incorretos nessa label')
                    if scrap != ':':
                        raise ASMError('Há algo de depois da label')
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
    