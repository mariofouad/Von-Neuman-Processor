import sys
import re

# --- ISA DEFINITION ---
OPCODES = {
    'NOP':  '00000',
    'HLT':  '00001',
    'SETC': '00010',
    'NOT':  '00011',
    'INC':  '00100',
    'OUT':  '00101',
    'IN':   '00110',
    'MOV':  '00111',
    'SWAP': '01000',
    'ADD':  '01001',
    'SUB':  '01010',
    'AND':  '01011',
    'IADD': '01100',
    'PUSH': '01101',
    'POP':  '01110',
    'LDM':  '01111',
    'LDD':  '10000',
    'STD':  '10001',
    'JZ':   '10010',
    'JN':   '10011', # Assumed
    'JC':   '10100',
    'JMP':  '10101',
    'CALL': '10110',
    'RET':  '10111',
    'INT':  '11000',
    'RTI':  '11001'
}

# Reverse mapping for Disassembler
BIN_TO_OP = {v: k for k, v in OPCODES.items()}

def parse_reg(reg_str):
    """Converts R0-R7 to 3-bit binary string."""
    reg_str = reg_str.upper().strip().replace(',', '')
    if reg_str.startswith('R') and reg_str[1:].isdigit():
        val = int(reg_str[1:])
        if 0 <= val <= 7:
            return f"{val:03b}"
    return "000"

def parse_imm(imm_str):
    """Converts hex immediate/offset to 16-bit binary string."""
    imm_str = imm_str.strip().lower()
    if imm_str.startswith('0x'):
        imm_str = imm_str[2:]
    
    try:
        # All numbers are hex format as per user requirement
        val = int(imm_str, 16)
    except ValueError:
        return "0000000000000000"
    
    # Handle negative if necessary (though usually hex is unsigned here)
    if val < 0:
        val = (1 << 16) + val
    
    # Ensure it fits in 16 bits
    val &= 0xFFFF
    
    return f"{val:016b}"

def assemble_line(line):
    """Assembles a single line of assembly to 32-bit binary/hex."""
    # Remove comments and whitespace
    line = line.split('#')[0].split(';')[0].strip()
    if not line:
        return None
        
    # Standardize comma removal
    line = line.replace(',', ' ')
    parts = re.split(r'\s+', line)
    mnemonic = parts[0].upper()
    
    # Handle .ORG directive separately or return it
    if mnemonic == '.ORG':
        return line # Special case handled in main
    
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
        
    elif mnemonic in ['NOT', 'INC', 'OUT', 'IN', 'POP', 'PUSH']:
        # Format: Op Rdst
        # Note: For PUSH, OUT, NOT, INC, the 'Rdst' field actually holds the Source for the operation,
        # but we parse it into the 'rdst' variable (bits 20-18) because that's where the VHDL Control/Mux expects it.
        if args: rdst = parse_reg(args[0])
        
    elif mnemonic in ['MOV', 'SWAP']:
        # Format: Op Rsrc, Rdst (Note: User ISA definition had specific order, assume Std: Dest, Src or Src, Dest?)
        # User Table: MOV Rsrc, Rdst. (Bits: Rsrc at 26:24, Rdst at 20:18).
        # Let's assume ASM syntax: MOV R1, R2 means R2 = R1? Or R1 = R2?
        # User Table: "MOV Rsrc, Rdst". Usually means Move FROM Src TO Dest.
        # But commonly ASM is "MOV Dest, Src".
        # Let's follow User Table Names strictly.
        if len(args) >= 2:
            rsrc1 = parse_reg(args[0]) # Rsrc
            rdst  = parse_reg(args[1]) # Rdst
            
    elif mnemonic in ['ADD', 'SUB', 'AND']:
        # Format: Op Rdst, Rsrc1, Rsrc2
        if len(args) >= 3:
            rdst  = parse_reg(args[0])
            rsrc1 = parse_reg(args[1])
            rsrc2 = parse_reg(args[2])
            
    elif mnemonic == 'IADD':
        # Format: Op Rdst, Rsrc, Imm
        if len(args) >= 3:
            rdst  = parse_reg(args[0])
            rsrc1 = parse_reg(args[1]) # Treated as Source 1
            imm   = parse_imm(args[2])
            
    elif mnemonic == 'LDM':
        # Format: LDM Rdst, Imm
        if len(args) >= 2:
            rdst = parse_reg(args[0])
            imm  = parse_imm(args[1])
            
    elif mnemonic == 'LDD':
        # Format: LDD Rdst, offset(Rsrc) -> tricky parse
        # or LDD Rdst, Rsrc, Offset
        if len(args) >= 3:
            rdst = parse_reg(args[0])
            rsrc1 = parse_reg(args[1])
            imm   = parse_imm(args[2])
            
    elif mnemonic == 'STD':
        # Format: STD Rsrc1, offset(Rsrc2) (Store Rsrc1 to Mem[Rsrc2+off])
        if len(args) >= 3:
            rsrc1 = parse_reg(args[0]) # Data to Store
            rsrc2 = parse_reg(args[1]) # Base Addr
            imm   = parse_imm(args[2]) # Offset
            
    elif mnemonic in ['JZ', 'JN', 'JC', 'JMP', 'CALL']:
        # Format: Op Imm
        if args:
            imm = parse_imm(args[0])

    elif mnemonic == 'INT':
        # INT index (bit 0)
        if args:
            val = int(args[0])
            # Assuming Index is put into bit 0 of Imm or unused bits?
            # User Table: "index(0 or 1)--> bit 0". Use Imm[0].
            imm = f"{val:016b}"

    # Construct 32-bit Binary
    # [31:27] Op
    # [26:24] Rsrc1
    # [23:21] Rsrc2
    # [20:18] Rdst
    # [17:16] Unused/OpExtension
    # [15:0]  Imm
    unused = "00"
    
    binary_str = f"{opcode_bin}{rsrc1}{rsrc2}{rdst}{unused}{imm}"
    hex_str = f"{int(binary_str, 2):08X}"
    
    return f'x"{hex_str}"'

def main():
    if len(sys.argv) < 2:
        print("Usage: python assembler.py <file.asm>")
        print("Runs interactive mode if no file.")
        print("Enter ASM line to Assemble, or HEX to Disassemble.")
        
        while True:
            line = input("> ")
            if line.lower() == 'exit': break
            
            # Simple heuristic: Hex if starts with x" or length is 8 hex chars
            clean = line.strip().replace('x"', '').replace('"', '')
            is_hex = all(c in '0123456789ABCDEFabcdef' for c in clean) and len(clean) == 8
            
            if is_hex:
                # Disassemble
                # TODO: Implement disassembly logic if needed
                print(f"Disassembling {clean}...") 
                val = int(clean, 16)
                b = f"{val:032b}"
                op = b[0:5]
                mnemonic = BIN_TO_OP.get(op, "UNKNOWN")
                print(f"Instruction: {mnemonic}")
            else:
                # Assemble
                res = assemble_line(line)
                print(f"VHDL: {res}")
        return

    # File Mode
    filename = sys.argv[1]
    memory = {}
    current_addr = 0
    
    try:
        with open(filename, 'r') as f:
            for line in f:
                res = assemble_line(line)
                if res is None:
                    continue
                
                if res.upper().startswith('.ORG'):
                    parts = re.split(r'\s+', res)
                    if len(parts) > 1:
                        # Address is in hex as per requirement
                        current_addr = int(parts[1], 16)
                    continue
                
                if "ERROR" in res:
                    print(f"-- {res} at {current_addr}")
                    continue
                
                memory[current_addr] = (res, line.strip())
                current_addr += 1
                
    except FileNotFoundError:
        print(f"Error: File {filename} not found.")
        return

    # Output VHDL INIT format
    print(f"-- Assembling {filename} to VHDL Init Format --")
    print("CONSTANT INIT_RAM : ram_type := (")
    
    # Sort addresses
    sorted_addrs = sorted(memory.keys())
    for addr in sorted_addrs:
        val, original = memory[addr]
        print(f"    {addr} => {val}, -- {original}")
        
    print("    OTHERS => (others => '0')")
    print(");")

if __name__ == "__main__":
    main()
