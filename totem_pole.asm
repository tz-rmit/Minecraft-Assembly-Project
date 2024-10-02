.ORIG x3000
; get pos
TRAP 0x31

; go to totem position
ADD R2, R2, #2
TRAP 0x35
ADD R1, R1, #1

; block ID to place
ADD R3, R3, #1

LD R4, HEIGHT

LOOP
    ; set block
    TRAP 0x34

    ; add to height and ID
    ADD R1, R1, #1
    ADD R3, R3, #1

    ; subtract next block height from max totem height
    NOT R5, R3
    ADD R5, R5, #1

    ADD R6, R4, R5

    BRzp LOOP    

HALT
HEIGHT .FILL #70 ; Note: Please do not change the name of this constant
.END