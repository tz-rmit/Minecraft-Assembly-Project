.ORIG x3000
TRAP 0x31
ADD R4, R4, R1
ST R4, GOAL_HEIGHT
; shift to bottom left corner
ADD R0, R0, #-1
ST R0, START_X
ADD R2, R2, #-1

ADD R6, R0, #3
NOT R6, R6
ADD R6, R6, #1

ADD R7, R2, #3
NOT R7, R7
ADD R7, R7, #1
ST R7, MAX_Z

LOOP
    JSR FLATTEN_ROW
    ; reset x
    LD R0, START_X
    ; increment z
    ADD R2, R2, #1
    ; check pos.z is in range
    LD R7, MAX_Z
    ST R7, MAX_Z
    ADD R7, R7, R2
    BRn LOOP
HALT

; flattens 3x1 line with smallest corner at R0, R1, R2
; R6 must be -(pos.x+3)
FLATTEN_ROW
    ST R7, SUB_POINTER
    JSR FLATTEN_COL
    LD R7, SUB_POINTER
    ; increment x
    ADD R0, R0, #1
    ; check pos.x is in range
    ADD R5, R6, R0
    BRn FLATTEN_ROW
    RET
HALT

; flatten column at (R0, R2) to h=R4
FLATTEN_COL
    TRAP 0x35
    ; R5 = terrain height - player height
    LD R4, GOAL_HEIGHT
    NOT R4, R4
    ADD R4, R4, #1
    ADD R5, R4, R1
    ; if the terrain is higher
    BRzp AIR
    ; else add grass below
    LD R3, GRASS_ID
    ADD R1, R1, #1
    ADD R5, R4, R1
    BRz CONT
    FILL_LOOP
        TRAP 0x34
        ADD R1, R1, #1
        ADD R5, R4, R1
        BRn FILL_LOOP
    CONT
    RET
HALT
    

AIR
    LD R3, AIR_ID
    ADD R4, R4, #1
    FLAT_LOOP
        TRAP 0x34
        ADD R1, R1, #-1
        ADD R5, R4, R1
        BRp FLAT_LOOP
    BR CONT
HALT
AIR_ID .FILL #0
GRASS_ID .FILL #2
SUB_POINTER .BLKW	1
GOAL_HEIGHT .BLKW	1
MAX_Z .BLKW	1
START_X .BLKW	1
.END