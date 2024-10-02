.ORIG x3000

TRAP 0x31
ADD R0, R0, #1
ADD R2, R2, #1
ADD R3, R3, #1

; store start coords
ST R0, X_START
ST R2, Z_START

LD R4, STAIRS_WIDTH
LD R5, STAIRS_HEIGHT
LD R6, STAIRS_LENGTH

; add dimensions to coords
ADD R4, R4, R0
ADD R5, R5, R1
ADD R6, R6, R2

; negate dims for subtracting
NOT R4, R4
ADD R4, R4, #1

NOT R5, R5
ADD R5, R5, #1

NOT R6, R6
ADD R6, R6, #1

ST R4, X_STOP
ST R5, Y_STOP
ST R6, Z_STOP

JSR PLACE_STAIRS

HALT

PLACE_STAIRS
    ST R7, SUB_POINTER_TWO
    JSR PLACE_LAYER
    LD R7, SUB_POINTER_TWO
    ; reset z after layer
    LD R2, Z_START
    ; add the z offset
    LD R4, Z_OFFSET
    ADD R2, R2, R4
    ADD R4, R4, #1
    ST R4, Z_OFFSET
    LD R4, Y_STOP
    ; increment y
    ADD R1, R1, #1
    ADD R5, R4, R1
    BRn PLACE_STAIRS
    RET
HALT

; 
PLACE_LAYER
    ST R7, SUB_POINTER
    JSR PLACE_ROW
    LD R7, SUB_POINTER
    ; reset x after row
    LD R0, X_START
    LD R4, Z_STOP
    ; increment z
    ADD R2, R2, #1
    ADD R5, R4, R2
    BRn PLACE_LAYER
    RET
HALT

; inputs: R0, R1, R2 = x, y, z 
;         R3 = block ID
;         save R4, R5 beforehand
PLACE_ROW
    LD R4, X_STOP
    TRAP 0x34
    ; increment x
    ADD R0, R0, #1
    ADD R5, R4, R0
    BRn PLACE_ROW
    RET
HALT
; Note: Please do not change the names of the constants below
STAIRS_WIDTH .FILL #2
STAIRS_LENGTH .FILL #4
STAIRS_HEIGHT .FILL #3
TEMP_LENGTH .BLKW	1
SUB_POINTER .BLKW	1
SUB_POINTER_TWO .BLKW	1
X_STOP .BLKW	1
Y_STOP .BLKW	1
Z_STOP .BLKW	1
X_START .BLKW	1
Z_START .BLKW	1
Z_OFFSET .FILL #1
.END