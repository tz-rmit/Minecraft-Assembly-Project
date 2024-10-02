.ORIG x3000
TRAP 0x31
ADD R1, R1, #-1
TRAP 0x33
AND R4, R3, 0x01
BRz EVEN
BRp ODD
HALT

EVEN
    LEA R0, EVEN_MSG
    TRAP 0x30
    HALT

ODD
    ADD R4, R3, #-10
    BRn ODD_LT_10
    BRzp ODD_GT_10
    HALT

ODD_LT_10
    LEA R0, LT_10_MSG
    TRAP 0x30
    HALT

ODD_GT_10
    LEA R0, GT_10_MSG
    TRAP 0x30
    HALT

HALT
EVEN_MSG .STRINGZ "The block beneath the player tile is even-numbered"
LT_10_MSG .STRINGZ "The block beneath the player tile is odd-numbered and less than 10"
GT_10_MSG .STRINGZ "The block beneath the player tile is odd-numbered and greater than 10"
.END