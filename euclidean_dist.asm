.ORIG x3000
TRAP 0x31
; X preprocessing
LD R3, G_X
JSR PREPROCESS
ST R5, X_DIFF_SQR

; Y preprocessing
LD R3, G_Y
ADD R0, R1, #0
JSR PREPROCESS
ST R5, Y_DIFF_SQR

; Z preprocessing
LD R3, G_Z
ADD R0, R2, #0
JSR PREPROCESS
ST R5, Z_DIFF_SQR

; square goal distance
LD R3, GOAL_DIST
LD R4, GOAL_DIST
AND R5, R5, #0
JSR SQUARE

; negate gd^2
NOT R5, R5
ADD R5, R5, #1

; calculate sum of squares
AND R4, R4, #0
AND R0, R0, #0
LD R1, X_DIFF_SQR
LD R2, Y_DIFF_SQR
LD R3, Z_DIFF_SQR

ADD R0, R0, R1
ADD R0, R0, R2
ADD R0, R0, R3

; add -(gd^2)(R5) to sum(R0)
ADD R6, R0, R5
BRn WITHIN
BR OUTSIDE
HALT

WITHIN
    LEA R0, IN_MSG
    TRAP 0x30
    HALT

OUTSIDE
    LEA R0, OUT_MSG
    TRAP 0x30
    HALT

HALT
; finds the difference between R3 AND R0 and squares it
PREPROCESS

    ; negate G_?
    NOT R3, R3
    ADD R3, R3, #1


    ; R3 = ? - g_?
    ADD R3, R3, R0
    

    ; if negative, negate before squaring
    BRn NEGATE
    CONT


    ; square the difference
    ADD R4, R3, #0
    ST R7, SUB_POINTER
    AND R5, R5, #0
    JSR SQUARE
    LD R7, SUB_POINTER
    RET

NEGATE
    NOT R3, R3
    ADD R3, R3, #1
    BR CONT

HALT
; R3 ^ R4 -> R5
SQUARE
    ADD R5, R5, R4
    ADD R3, R3, #-1
    BRp SQUARE
    RET

HALT
; Note: Please do not change the names of the constants below
G_X .FILL #7
G_Y .FILL #-8
G_Z .FILL #5
GOAL_DIST .FILL #10
IN_MSG .STRINGZ "The player is within distance of the goal"
OUT_MSG .STRINGZ "The player is outside the goal bounds"
X_DIFF_SQR .BLKW #1
Y_DIFF_SQR .BLKW #1
Z_DIFF_SQR .BLKW #1
SUB_POINTER .BLKW #1
.END