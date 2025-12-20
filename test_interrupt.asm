# Test program for CALL/RET/INT/RTI
# Memory Map:
# M[0] = Reset vector (jump to main)
# M[1] = HW Interrupt handler address
# M[2] = INT 0 handler address
# M[3] = INT 1 handler address

.ORG 0
10          # Reset vector: jump to address 0x10 (main)
30          # HW Interrupt handler at address 0x30
20          # INT 0 handler at address 0x20
25          # INT 1 handler at address 0x25

# INT 0 Handler (at address 0x20)
.ORG 20
LDM R0, 0AA     # Load marker value
OUT R0          # Output to show we're in INT 0 handler
RTI             # Return from interrupt

# INT 1 Handler (at address 0x25)
.ORG 25
LDM R0, 0BB     # Load marker value  
OUT R0          # Output to show we're in INT 1 handler
RTI             # Return from interrupt

# HW Interrupt Handler (at address 0x30)
.ORG 30
LDM R0, 0CC     # Load marker value
OUT R0          # Output to show we're in HW interrupt handler
RTI             # Return from interrupt

# Subroutine (at address 0x40)
.ORG 40
LDM R1, 55      # Load value
OUT R1          # Output
RET             # Return to caller

# Main Program (at address 0x10)
.ORG 10
LDM R0, 01      # Load initial value
OUT R0          # Output it
CALL 40         # Call subroutine at 0x40
LDM R0, 02      # After call returns
OUT R0          # Output it
INT 0           # Software interrupt 0
LDM R0, 03      # After INT 0 returns
OUT R0          # Output it
INT 1           # Software interrupt 1
LDM R0, 04      # After INT 1 returns
OUT R0          # Output it
HLT             # Halt
