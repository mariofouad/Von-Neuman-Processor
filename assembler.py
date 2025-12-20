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
    
    if mnemonic == '.ORG': return line
    
    # Handle raw hex data (for reset vectors, interrupt vectors, etc.)
    if mnemonic not in OPCODES:
        # Check if it's a valid hex number (raw data)
        try:
            val = int(mnemonic, 16)
            return f"{val:08X}"  # Return as 32-bit hex value
        except ValueError:
            return f"ERROR: {mnemonic}"
        
    opcode_bin = OPCODES[mnemonic]
    rsrc1, rsrc2, rdst = "000", "000", "000"
    imm15 = "000000000000000"  # 15-bit immediate (bits 14:0)
    fast_bits = "00"           # Default fast bits (bits 16:15)
    args = parts[1:]

    # Formatting based on Instruction Type
    if mnemonic in ['NOT', 'INC', 'OUT', 'IN', 'POP', 'PUSH']:
        if len(args) >= 1: rdst = parse_reg(args[0])
    elif mnemonic in ['MOV', 'SWAP']:
        if len(args) >= 2:
            rsrc1 = parse_reg(args[0])  # First arg -> source (Rsrc)
            rdst  = parse_reg(args[1])  # Second arg -> destination (Rdst)
    elif mnemonic in ['ADD', 'SUB', 'AND']:
        if len(args) >= 3:
            rdst = parse_reg(args[0]); rsrc1 = parse_reg(args[1]); rsrc2 = parse_reg(args[2])
    elif mnemonic == 'IADD':
        if len(args) >= 3:
            rdst = parse_reg(args[0]); rsrc1 = parse_reg(args[1])
            imm16 = parse_imm(args[2])
            imm15 = imm16[1:]  # Take lower 15 bits
    elif mnemonic == 'LDM':
        if len(args) >= 2:
            rdst = parse_reg(args[0])
            imm16 = parse_imm(args[1])
            imm15 = imm16[1:]  # Take lower 15 bits
    elif mnemonic == 'LDD':
        if len(args) >= 3:
            rdst = parse_reg(args[0]); rsrc1 = parse_reg(args[1])
            imm16 = parse_imm(args[2])
            imm15 = imm16[1:]  # Take lower 15 bits
    elif mnemonic == 'STD':
        if len(args) >= 3:
            rsrc1 = parse_reg(args[0]); rsrc2 = parse_reg(args[1])
            imm16 = parse_imm(args[2])
            imm15 = imm16[1:]  # Take lower 15 bits
    elif mnemonic in ['JZ', 'JN', 'JC', 'JMP']:
        if len(args) >= 1:
            imm16 = parse_imm(args[0])
            imm15 = imm16[1:]  # Take lower 15 bits
    
    # ========== CONTROL FLOW WITH FAST BITS ==========
    # Fast Bits (16:15): 11=CALL, 10=RET/RTI, 01=INT
    elif mnemonic == 'CALL':
        fast_bits = "11"  # CALL fast bits
        if len(args) >= 1:
            imm16 = parse_imm(args[0])
            imm15 = imm16[1:]  # Target address in bits 14:0
    elif mnemonic == 'RET':
        fast_bits = "10"  # RET fast bits
        # No immediate needed
    elif mnemonic == 'RTI':
        fast_bits = "10"  # RTI fast bits (same as RET for hazard detection)
        # No immediate needed
    elif mnemonic == 'INT':
        fast_bits = "01"  # INT fast bits
        if len(args) >= 1:
            index = int(args[0]) & 0x1  # Index is 0 or 1, goes in bit 0
            imm15 = f"{'0'*14}{index}"
    
    # Instruction format: opcode(5) | rsrc1(3) | rsrc2(3) | rdst(3) | 0 | fast(2) | imm(15)
    binary_str = f"{opcode_bin}{rsrc1}{rsrc2}{rdst}0{fast_bits}{imm15}"
    return f"{int(binary_str, 2):08X}"

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