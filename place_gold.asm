.ORIG x3000
TRAP 0x31
ADD R0, R0, #4
TRAP 0x35
ADD R1, R1, #1
LD R3, COORD
TRAP 0x34
HALT
COORD .FILL #41
.END