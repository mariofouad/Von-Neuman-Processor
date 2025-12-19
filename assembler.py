import sys
import re

# --- ISA DEFINITION (Matched to Phase 1) ---
OPCODES = {
    'NOP':  '00000', 'HLT':  '00001', 'SETC': '00010', 'NOT':  '00011',
    'INC':  '00100', 'OUT':  '00101', 'IN':   '00110', 'MOV':  '00111',
    'SWAP': '01000', 'ADD':  '01001', 'SUB':  '01010', 'AND':  '01011',
    'IADD': '01100', 'PUSH': '01101', 'POP':  '01110', 'LDM':  '01111',
    'LDD':  '10000', 'STD':  '10001', 'JZ':   '10010', 'JN':   '10011',
    'JC':   '10100', 'JMP':  '10101', 'CALL': '10110', 'RET':  '10111',
    'INT':  '11000', 'RTI':  '11001'
}

def parse_reg(reg_str):
    reg_str = reg_str.upper().strip().replace(',', '')
    if reg_str.startswith('R') and reg_str[1:].isdigit():
        val = int(reg_str[1:])
        return f"{val:03b}"
    return "000"

def parse_imm(imm_str):
    imm_str = imm_str.strip().lower()
    if imm_str.startswith('0x'):
        val = int(imm_str[2:], 16)
    else:
        try:
            val = int(imm_str, 16) # Default to Hex as per requirements
        except ValueError:
            val = 0
    val &= 0xFFFF
    return f"{val:016b}"

def assemble_line(line):
    line = line.split('#')[0].split(';')[0].strip()
    if not line: return None
    line = line.replace(',', ' ')
    parts = re.split(r'\s+', line)
    mnemonic = parts[0].upper()
    
    # Handle .ORG directive separately or return it
    if mnemonic == '.ORG':
        return line # Special case handled in main
    
    # Check if the line is just a raw number (for vectors)
    is_raw_num = False
    try:
        # Check if it's hex (prefixed or raw hex) or decimal
        raw_val = int(parts[0].replace('0x', ''), 16)
        is_raw_num = True
    except ValueError:
        pass
        
    if is_raw_num and mnemonic not in OPCODES:
        # Return as a 32-bit hex word
        return f'x"{raw_val:08X}"'

    if mnemonic not in OPCODES:
        return f"ERROR: Unknown Opcode {mnemonic}"
        
    opcode_bin = OPCODES[mnemonic]
    
    # Default Fields
    rsrc1 = "000"
    rsrc2 = "000"
    rdst  = "000"
    imm   = "0000000000000000"
    
    # FORMAT PARSING
    # R-Type: Op Rdst, Rsrc1, Rsrc2  | Op Rdst, Rsrc | Op Rdst
    # I-Type: Op Rdst, Rsrc, Imm     | Op Rdst, Imm
    # J-Type: Op Imm
    
    args = parts[1:] if len(parts) > 1 else []
    
    # --- LOGIC PER INSTRUCTION TYPE ---
    if mnemonic in ['NOP', 'HLT', 'RET', 'RTI', 'SETC']:
        pass
        
    elif mnemonic in ['NOT', 'INC']:
        # Format: Op Rdst
        # These read from the register and write back to it.
        # So we put the register in both rsrc1 (source) and rdst (destination).
        if args:
            reg = parse_reg(args[0])
            rsrc1 = reg
            rdst  = reg
            
    elif mnemonic in ['PUSH', 'OUT']:
        # Format: Op Rsrc (Reads from register, no write-back)
        # We put the register in rsrc1 or rsrc2. Processor expects PUSH data in rsrc2.
        if args:
            reg = parse_reg(args[0])
            rsrc1 = reg # For security
            rsrc2 = reg # Processor uses ex_r_data2 for memory write data
            
    elif mnemonic in ['POP', 'IN']:
        # Format: Op Rdst (Writes to register, no source read)
        if args:
            rdst = parse_reg(args[0])
        
    elif mnemonic in ['MOV', 'SWAP']:
        if len(args) >= 2:
            rsrc1 = parse_reg(args[0])
            rdst  = parse_reg(args[1])
    elif mnemonic in ['ADD', 'SUB', 'AND']:
        if len(args) >= 3:
            rdst = parse_reg(args[0]); rsrc1 = parse_reg(args[1]); rsrc2 = parse_reg(args[2])
    elif mnemonic == 'IADD':
        if len(args) >= 3:
            rdst = parse_reg(args[0]); rsrc1 = parse_reg(args[1]); imm = parse_imm(args[2])
    elif mnemonic == 'LDM':
        if len(args) >= 2:
            rdst = parse_reg(args[0]); imm = parse_imm(args[1])
    elif mnemonic == 'LDD':
        if len(args) >= 3:
            rdst = parse_reg(args[0]); rsrc1 = parse_reg(args[1]); imm = parse_imm(args[2])
    elif mnemonic == 'STD':
        if len(args) >= 3:
            rsrc1 = parse_reg(args[0]); rsrc2 = parse_reg(args[1]); imm = parse_imm(args[2])
    elif mnemonic in ['JZ', 'JN', 'JC', 'JMP', 'CALL']:
        if len(args) >= 1: imm = parse_imm(args[0])
    elif mnemonic == 'INT':
        # Format: INT index (index is 0 or 1)
        if args:
            try:
                # We interpret index as hex as per requirement
                val = int(args[0].strip(), 16)
            except ValueError:
                val = 0
            imm = f"{val:016b}"

    # Construct 32-bit Binary
    # [31:27] Op
    # [26:24] Rsrc1
    # [23:21] Rsrc2
    # [20:18] Rdst
    # [17:16] Unused/OpExtension -> Using 01 for INT Pre-decode
    # [15:0]  Imm
    if mnemonic == 'INT':
        unused = "01"
    else:
        unused = "00"
    
    binary_str = f"{opcode_bin}{rsrc1}{rsrc2}{rdst}{unused}{imm}"
    hex_str = f"{int(binary_str, 2):08X}"
    
    return f'x"{hex_str}"'

def main():
    if len(sys.argv) < 2:
        print("Usage: python assembler.py <file.asm>")
        return

    filename = sys.argv[1]
    memory = {}
    current_addr = 0
    
    try:
        with open(filename, 'r') as f:
            for line in f:
                res = assemble_line(line)
                if res is None: continue
                if res.upper().startswith('.ORG'):
                    parts = re.split(r'\s+', res)
                    current_addr = int(parts[1], 16)
                    continue
                if "ERROR" in res:
                    print(res)
                    continue
                memory[current_addr] = res
                current_addr += 1
                
        # --- WRITE TO PROGRAM.MEM ---
        if not memory:
            print("No instructions assembled.")
            return

        max_addr = max(memory.keys())
        with open("program.mem", "w") as f:
            for addr in range(max_addr + 1):
                if addr in memory:
                    f.write(memory[addr] + "\n")
                else:
                    f.write("00000000\n") # Fill gaps (from .ORG) with NOPs
        
        print(f"Success! Generated program.mem with {len(memory)} instructions.")

    except Exception as e:
        print(f"File Error: {e}")

if __name__ == "__main__":
    main()