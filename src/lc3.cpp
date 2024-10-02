#include <stdio.h>
#include <stdint.h>
#include <signal.h>
/* unix only */
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/termios.h>
#include <sys/mman.h>

/* for MCPI */
#include <iostream>
#include <mcpp/mcpp.h>
#include <mcpp/util.h>

mcpp::MinecraftConnection *mc_conn;

enum
{
    R_R0 = 0,
    R_R1,
    R_R2,
    R_R3,
    R_R4,
    R_R5,
    R_R6,
    R_R7,
    R_PC, /* program counter */
    R_COND,
    R_COUNT
};
enum
{
    FL_POS = 1 << 0, /* P */
    FL_ZRO = 1 << 1, /* Z */
    FL_NEG = 1 << 2, /* N */
};
enum
{
    OP_BR = 0, /* branch */
    OP_ADD,    /* add  */
    OP_LD,     /* load */
    OP_ST,     /* store */
    OP_JSR,    /* jump register */
    OP_AND,    /* bitwise and */
    OP_LDR,    /* load register */
    OP_STR,    /* store register */
    OP_RTI,    /* unused */
    OP_NOT,    /* bitwise not */
    OP_LDI,    /* load indirect */
    OP_STI,    /* store indirect */
    OP_JMP,    /* jump */
    OP_RES,    /* reserved (unused) */
    OP_LEA,    /* load effective address */
    OP_TRAP    /* execute trap */
};

enum
{
    MR_KBSR = 0xFE00, /* keyboard status */
    MR_KBDR = 0xFE02  /* keyboard data */
};
enum
{
    TRAP_GETC = 0x20,            /* get character from keyboard, not echoed onto the terminal */
    TRAP_OUT = 0x21,             /* output a character */
    TRAP_PUTS = 0x22,            /* output a word string */
    TRAP_IN = 0x23,              /* get character from keyboard, echoed onto the terminal */
    TRAP_PUTSP = 0x24,           /* output a byte string */
    TRAP_HALT = 0x25,            /* halt the program */
    TRAP_CHAT_POST = 0x30,
    TRAP_GET_PLAYER_TILE = 0x31,
    TRAP_SET_PLAYER_TILE = 0x32,
    TRAP_GET_BLOCK = 0x33,
    TRAP_SET_BLOCK = 0x34,
    TRAP_GET_HEIGHT = 0x35,
    TRAP_PRINT_REGISTERS = 0x36,
};

#define MEMORY_MAX (1 << 16)
uint16_t memory[MEMORY_MAX];  /* 65536 locations */
uint16_t reg[R_COUNT];

struct termios original_tio;

void disable_input_buffering()
{
    tcgetattr(STDIN_FILENO, &original_tio);
    struct termios new_tio = original_tio;
    new_tio.c_lflag &= ~ICANON & ~ECHO;
    tcsetattr(STDIN_FILENO, TCSANOW, &new_tio);
}

void restore_input_buffering()
{
    tcsetattr(STDIN_FILENO, TCSANOW, &original_tio);
}

uint16_t check_key()
{
    fd_set readfds;
    FD_ZERO(&readfds);
    FD_SET(STDIN_FILENO, &readfds);

    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 0;
    return select(1, &readfds, NULL, NULL, &timeout) != 0;
}
void handle_interrupt(int signal)
{
    restore_input_buffering();
    printf("\n");
    exit(-2);
}
uint16_t sign_extend(uint16_t x, int bit_count)
{
    if ((x >> (bit_count - 1)) & 1) {
        x |= (0xFFFF << bit_count);
    }
    return x;
}
uint16_t swap16(uint16_t x)
{
    return (x << 8) | (x >> 8);
}
void update_flags(uint16_t r)
{
    if (reg[r] == 0)
    {
        reg[R_COND] = FL_ZRO;
    }
    else if (reg[r] >> 15) /* a 1 in the left-most bit indicates negative */
    {
        reg[R_COND] = FL_NEG;
    }
    else
    {
        reg[R_COND] = FL_POS;
    }
}
void read_image_file(FILE* file)
{
    /* the origin tells us where in memory to place the image */
    uint16_t origin;
    fread(&origin, sizeof(origin), 1, file);
    origin = swap16(origin);

    /* we know the maximum file size so we only need one fread */
    uint16_t max_read = MEMORY_MAX - origin;
    uint16_t* p = memory + origin;
    size_t read = fread(p, sizeof(uint16_t), max_read, file);

    /* swap to little endian */
    while (read-- > 0)
    {
        *p = swap16(*p);
        ++p;
    }
}
int read_image(const char* image_path)
{
    FILE* file = fopen(image_path, "rb");
    if (!file) { return 0; };
    read_image_file(file);
    fclose(file);
    return 1;
}
void mem_write(uint16_t address, uint16_t val)
{
    memory[address] = val;
}
int unsigned_to_signed(uint16_t u)
{
    return (u + 32768) % 65536 - 32768;
}
uint16_t mem_read(uint16_t address)
{
    if (address == MR_KBSR)
    {
        if (check_key())
        {
            memory[MR_KBSR] = (1 << 15);
            memory[MR_KBDR] = getchar();
        }
        else
        {
            memory[MR_KBSR] = 0;
        }
    }
    return memory[address];
}

int running = 1;
template <unsigned op>
void ins(uint16_t instr)
{
    uint16_t r0, r1, r2, imm5, imm_flag;
    uint16_t pc_plus_off, base_plus_off;

    constexpr uint16_t opbit = (1 << op);
    if (0x4EEE & opbit) { r0 = (instr >> 9) & 0x7; }
    if (0x12F3 & opbit) { r1 = (instr >> 6) & 0x7; }
    if (0x0022 & opbit)
    {
        imm_flag = (instr >> 5) & 0x1;

        if (imm_flag)
        {
            imm5 = sign_extend(instr & 0x1F, 5);
        }
        else
        {
            r2 = instr & 0x7;
        }
    }
    if (0x00C0 & opbit)
    {   // Base + offset
        base_plus_off = reg[r1] + sign_extend(instr & 0x3F, 6);
    }
    if (0x4C0D & opbit)
    {
        // Indirect address
        pc_plus_off = reg[R_PC] + sign_extend(instr & 0x1FF, 9);
    }
    if (0x0001 & opbit)
    {
        // BR
        uint16_t cond = (instr >> 9) & 0x7;
        if (cond & reg[R_COND]) { reg[R_PC] = pc_plus_off; }
    }
    if (0x0002 & opbit)  // ADD
    {
        if (imm_flag)
        {
            reg[r0] = reg[r1] + imm5;
        }
        else
        {
            reg[r0] = reg[r1] + reg[r2];
        }
    }
    if (0x0020 & opbit)  // AND
    {
        if (imm_flag)
        {
            reg[r0] = reg[r1] & imm5;
        }
        else
        {
            reg[r0] = reg[r1] & reg[r2];
        }
    }
    if (0x0200 & opbit) { reg[r0] = ~reg[r1]; } // NOT
    if (0x1000 & opbit) { reg[R_PC] = reg[r1]; } // JMP
    if (0x0010 & opbit)  // JSR
    {
        uint16_t long_flag = (instr >> 11) & 1;
        reg[R_R7] = reg[R_PC];
        if (long_flag)
        {
            pc_plus_off = reg[R_PC] + sign_extend(instr & 0x7FF, 11);
            reg[R_PC] = pc_plus_off;
        }
        else
        {
            reg[R_PC] = reg[r1];
        }
    }

    if (0x0004 & opbit) { reg[r0] = mem_read(pc_plus_off); } // LD
    if (0x0400 & opbit) { reg[r0] = mem_read(mem_read(pc_plus_off)); } // LDI
    if (0x0040 & opbit) { reg[r0] = mem_read(base_plus_off); }  // LDR
    if (0x4000 & opbit) { reg[r0] = pc_plus_off; } // LEA
    if (0x0008 & opbit) { mem_write(pc_plus_off, reg[r0]); } // ST
    if (0x0800 & opbit) { mem_write(mem_read(pc_plus_off), reg[r0]); } // STI
    if (0x0080 & opbit) { mem_write(base_plus_off, reg[r0]); } // STR
    if (0x8000 & opbit)  // TRAP
    {
        int trapvect = instr & 0xFF;

        if (trapvect == TRAP_GETC)
        {
            /* read a single ASCII char */
            reg[R_R0] = (uint16_t)getchar();
            update_flags(R_R0);
        }
        else if (trapvect == TRAP_OUT)
        {
            putc((char)reg[R_R0], stdout);
            fflush(stdout);
        }
        else if (trapvect == TRAP_PUTS)
        {
            /* one char per word */
            uint16_t* c = memory + reg[R_R0];
            while (*c)
            {
                putc((char)*c, stdout);
                ++c;
            }
            fflush(stdout);
        }
        else if (trapvect == TRAP_IN)
        {
            printf("Enter a character: ");
            char c = getchar();
            putc(c, stdout);
            fflush(stdout);
            reg[R_R0] = (uint16_t)c;
            update_flags(R_R0);
        }
        else if (trapvect == TRAP_PUTSP)
        {
            /* one char per byte (two bytes per word)
            here we need to swap back to
            big endian format */
            uint16_t* c = memory + reg[R_R0];
            while (*c)
            {
                char char1 = (*c) & 0xFF;
                putc(char1, stdout);
                char char2 = (*c) >> 8;
                if (char2) putc(char2, stdout);
                ++c;
            }
            fflush(stdout);
        }
        else if (trapvect == TRAP_HALT)
        {
            puts("HALT");
            fflush(stdout);
            running = 0;
        }
        else
        {
            /* Minecraft TRAPs */
            if (mc_conn == NULL)
            {
                mc_conn = new mcpp::MinecraftConnection("0.0.0.0", 4711);
            }

            if (trapvect == TRAP_CHAT_POST)
            {
                std::string chat_str("");
                
                /* one char per word */
                uint16_t* c = memory + reg[R_R0];
                while (*c)
                {
                    chat_str += (char)*c;
                    ++c;
                }
                (*mc_conn).postToChat(chat_str);
            }
            else if (trapvect == TRAP_GET_PLAYER_TILE)
            {
                mcpp::Coordinate pos = (*mc_conn).getPlayerPosition();
                reg[0] = pos.x;
                reg[1] = pos.y;
                reg[2] = pos.z;
            }
            else if (trapvect == TRAP_SET_PLAYER_TILE)
            {
                mcpp::Coordinate pos(
                    unsigned_to_signed(reg[0]),
                    unsigned_to_signed(reg[1]),
                    unsigned_to_signed(reg[2])
                );
                (*mc_conn).setPlayerPosition(pos);
            }
            else if (trapvect == TRAP_GET_BLOCK)
            {
                mcpp::Coordinate pos(
                    unsigned_to_signed(reg[0]),
                    unsigned_to_signed(reg[1]),
                    unsigned_to_signed(reg[2])
                );
                reg[3] = (*mc_conn).getBlock(pos).id;
            }
            else if (trapvect == TRAP_SET_BLOCK)
            {
                mcpp::Coordinate pos(
                    unsigned_to_signed(reg[0]),
                    unsigned_to_signed(reg[1]),
                    unsigned_to_signed(reg[2])
                );
                (*mc_conn).setBlock(pos, reg[3]);
            }
            else if (trapvect == TRAP_GET_HEIGHT)
            {
                reg[1] = (*mc_conn).getHeight(
                    unsigned_to_signed(reg[0]),
                    unsigned_to_signed(reg[2])
                );
            }
            else if (trapvect == TRAP_PRINT_REGISTERS)
            {
                printf("R0: %u\n", reg[0]);
                printf("R1: %u\n", reg[1]);
                printf("R2: %u\n", reg[2]);
                printf("R3: %u\n", reg[3]);
                printf("R4: %u\n", reg[4]);
                printf("R5: %u\n", reg[5]);
                printf("R6: %u\n", reg[6]);
                printf("R7: %u\n", reg[7]);
            }
        }
    }
    //if (0x0100 & opbit) { } // RTI
    if (0x4666 & opbit) { update_flags(r0); }
}
static void (*op_table[16])(uint16_t) = {
    ins<0>, ins<1>, ins<2>, ins<3>,
    ins<4>, ins<5>, ins<6>, ins<7>,
    NULL, ins<9>, ins<10>, ins<11>,
    ins<12>, NULL, ins<14>, ins<15>
};

int main(int argc, const char* argv[])
{
    if (argc < 2)
    {
        /* show usage string */
        printf("lc3 [image-file1] ...\n");
        exit(2);
    }
    
    for (int j = 1; j < argc; ++j)
    {
        if (!read_image(argv[j]))
        {
            printf("failed to load image: %s\n", argv[j]);
            exit(1);
        }
    }
    signal(SIGINT, handle_interrupt);
    disable_input_buffering();

    reg[R_COND] = FL_ZRO;

    enum { PC_START = 0x3000 };
    reg[R_PC] = PC_START;

    while (running)
    {
        uint16_t instr = mem_read(reg[R_PC]++);
        uint16_t op = instr >> 12;
        op_table[op](instr);
    }
    restore_input_buffering();

    if (mc_conn != NULL)
    {
        delete mc_conn;
    }
}