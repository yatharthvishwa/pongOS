[org 0x7c00]
[bits 16]

section .data:
    ; coordinates and velocities are 16-bit words.
    paddle1_y dw 88
    paddle2_y dw 170

    ball_x    dw 160
    ball_y    dw 100
    ball_dx   dw 1
    ball_dy   dw 1

    score1    db 0
    score2    db 0

start:
    cli                     ;disable interrupts
    xor ax, ax              ;set ax to 0
    mov ds, ax              ;set others 0 too (data segment)
    mov es, ax              ;(extra segment)
    mov ss, ax              ;(stack segment)
    mov sp, 0x7c00          ;set stack pointer to top of boot sector
    sti                     ;re enable inturuupts
    cld                     ;rep stosb/stosw go forward

    mov ax, 0x0013          ; VGA mode 13h: 320x200, 256 colors
    int 0x10                ;swtich to VGA

    ; Paddle 1
    mov ax, 10              ; x
    mov bx, [paddle1_y]     ; y
    mov cx, 4               ; width
    mov dx, 24              ; height
    mov si, 15              ; color (white)
    ; call draw_rect          ;call :return here after jumping
    call game_loop

    ; rectangle (a paddle)
    mov ax, 310              ; x
    mov bx, [paddle2_y]      ; y
    mov cx, 4               ; width
    mov dx, 24              ; height
    mov si, 15              ; color (white)
    call draw_rect          ;call :return here after jumping

    ; Ball
    mov ax, [ball_x]              ; x
    mov bx, [ball_y]              ; y
    mov cx, 2               ; width
    mov dx, 2              ; height
    mov si, 15              ; color (white)
    call draw_rect          ;call :return here after jumping


halt:
    cli
    hlt
    jmp halt

; draw_rect
; in: ax = x, bx = y, cx = width, dx = height, si = color (low byte)
; di is the cursor : chooses where to write (memory off set of the pixel)
; rep stosb performs the actual memory store
; To write a pixel change the byte stored at the framebuffer address

draw_rect:
    pusha
    push es
    mov di, bx
    imul di, 320            ; di = y * 320 (converts the y coordinate into the number of bytes to move down the screen)
    ; If the screen were just 5 pixels wide, the memory layout would look like:
    ;row 0: 0..4
    ; row 1: 5..9
    ; row 2: 10..14
    add di, ax              ; di = y * 320 + x
    mov ax, 0xA000
    mov es, ax              ; es -> video memory
    mov ax, si              ; al = color
.row:
    push cx                 ;Saves the width value
    push di                 ;Saves the current memory position 
    rep stosb               ;Writes CX pixels in a row,writes byte AL to [ES:DI],increments DI,decrements CX,repeats until CX == 0
    pop di                  ;restore di
    add di, 320             ;move down one screen row
    pop cx
    dec dx
    jnz .row
    pop es
    popa
    ret

game_loop:
    ;read input
    ; update positions
    ; check collisions and scoring
    ; redraw the screen
    ; wait for the next frame
    
    ; cmp byte [paddle1_dir], 1
    jne move_paddle_up

    jmp game_loop

move_paddle_up:
    ; cmp word [paddle1_y], 0
    ; jbe reverse_paddle_down
    dec word [paddle1_y]
    jmp paddle_moved

paddle_moved:
    ; redraw the paddle here using [paddle1_y]
    call draw_rect
    jmp game_loop

times 510-($-$$) db 0
dw 0xaa55