# all numbers in hex format
# we always start by reset signal
# this is a commented line
# You should ignore empty lines

# ---------- Don't forget to Reset before you start anything ---------- #

.ORG 0  #this means the the following line would be  at address  0 , and this is the reset address
300

.ORG 300

IN R2            #R2=19 add 19 in R2
CALL 100
IN R3 
IN R5
.ORG 100
IN R5            #R5=10
NOP
NOP
RET