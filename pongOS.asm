[org 0x7c00]
[bits 16]

jmp start


; coordinates and velocities are 16-bit words.
paddle1_y dw 88
paddle2_y dw 170

ball_x    dw 160
ball_y    dw 100
ball_dx   dw 1
ball_dy   dw 1

score1    db 0
score2    db 0

paddle1_dir db 1       ; 1 = down, 0 = up
last_tick   dw 0


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
    call draw_rect          ;call :return here after jumping

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
    call draw_rect          ;call :return here after jumping\

    mov ah, 00h
    int 1Ah
    mov [last_tick], dx

    jmp game_loop

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

    ; check for key
    mov ah, 01h
    int 16h
    jz .no_key        ; no key pressed

    mov ah, 00h
    int 16h           ; AL = ASCII key, AH = scan code

    cmp al, 'w'
    je move_up
    cmp al, 's'
    je move_down
    jmp .no_key

.after_input:
    ; redraw paddle
    jmp draw_paddle
    ; continue game logic

.no_key:
    ; no keyboard input

    ; continue loop

    ; update positions
    ; check collisions and scoring
    ; redraw the screen
    ; wait for the next frame
    

    ; Erase paddle 1 at its current position
    mov ax, 10
    mov bx, [paddle1_y]
    mov cx, 4
    mov dx, 24
    xor si, si              ; color 0: black
    call draw_rect

    ; Move down until reaching the bottom limit
.move_down:
    cmp byte [paddle1_dir], 1
    jne move_up

    cmp word [paddle1_y], 176 ; 200 screen pixels - 24 paddle pixels
    jae start_moving_up
    inc word [paddle1_y]
    jmp draw_paddle

start_moving_up:
    mov byte [paddle1_dir], 0
    jmp draw_paddle

move_up:
    ;check the upper limit, upper limit of y = 0
    cmp word [paddle1_y], 0
    jbe start_moving_down   ; start moving down when reached up, start_moving_down reverse the direction
    ;if not reached up
    dec word [paddle1_y]    ; -1 from the y coordinate to move the paddle up
    jmp draw_paddle

start_moving_down:   ;reverse the direction at the top
    mov byte [paddle1_dir], 1        ;1 = down

draw_paddle:
    ; Draw paddle 1 at its updated position
    mov ax, 10
    mov bx, [paddle1_y]
    mov cx, 4
    mov dx, 24
    mov si, 15
    call draw_rect

    ; Wait for the BIOS timer to advance before moving again
.wait:
    mov ah, 00h
    int 1Ah
    cmp dx, [last_tick]
    je .wait
    mov [last_tick], dx

    jmp game_loop
times 510-($-$$) db 0
dw 0xaa55