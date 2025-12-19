# all numbers in hex format
# we always start by reset signal
# this is a commented line
# You should ignore empty lines

# ---------- Don't forget to Reset before you start anything ---------- #

.ORG 0          #this means the the following line would be  at address  0 , and this is the reset address
10

.ORG 1          #this hw interrupt handler
900

.ORG 900 #this is hw int
LDM R7, 0x0005 # R7=5
AND R0,R0,R0     #N=0,Z=1
OUT R3
RTI              #POP PC and flags restored
IADD R1, R2, R3  # Try Hardware interrupt when fetching this (in a second run) - infinite loop?

.ORG 10
LDM R1, 0x000A            #R1=30
LDM R2, 0x0032            #R2=50
LDM R3, 0x0064            #R3=100
LDM R4, 0x012C            #R4=300
Push R4          #SP=FFE, M[FFF]=300
