org 0x7C00

; Entry point: BIOS loads this at 0x7C00 and jumps here
start:
    ; Set video mode to 13h: 320x200 pixels, 256 colors
    mov ax, 0x0013
    int 0x10

    ; ES = 0xA000 is the segment for VGA memory
    push 0xA000
    pop es

    ; Clear AX and set Data Segment to 0
    xor ax, ax
    mov ds, ax

    ; Initialize game variables
    mov word [player_x], 155
    mov word [enemy_x], 100
    mov word [enemy_y], 0
    mov byte [bullet_active], 0
    mov word [score], 0

game_loop:
    ; Use BIOS timer (ticks at 18.2Hz) for consistent game speed
    mov ah, 0x00
    int 0x1A
    mov bx, dx

timer_wait:
    int 0x1A
    cmp dx, bx
    je timer_wait

    ; Wait for vertical retrace to prevent screen flickering
    mov dx, 0x3DA

retrace_wait:
    in al, dx
    test al, 8
    jz retrace_wait

    ; Clear the entire screen (64000 pixels) with color 0 (black)
    xor di, di
    xor al, al
    mov cx, 64000
    rep stosb

    ; Move cursor to (0,0) and print the current score
    xor dx, dx
    mov ah, 0x02
    xor bh, bh
    int 0x10
    mov ax, [score]
    call print_num

    ; Check if a key is waiting in the keyboard buffer
    mov ah, 0x01
    int 0x16
    jz update_physics

    ; Get the actual key pressed
    mov ah, 0x00
    int 0x16

    ; Handle Arrow keys (scan codes) and Space bar
    cmp ah, 0x4B        ; Left Arrow
    je move_left
    cmp ah, 0x4D        ; Right Arrow
    je move_right
    cmp ah, 0x39        ; Space Bar
    je fire_bullet
    jmp update_physics

move_left: 
    sub word [player_x], 10
    jnc update_physics
    mov word [player_x], 0
    jmp update_physics

move_right: 
    add word [player_x], 10
    cmp word [player_x], 310
    jbe update_physics
    mov word [player_x], 310
    jmp update_physics

fire_bullet:
    ; Allow only one bullet on screen at a time
    cmp byte [bullet_active], 0
    jnz update_physics
    mov byte [bullet_active], 1
    mov ax, [player_x]
    add ax, 4           ; Center bullet relative to player ship
    mov [bullet_x], ax
    mov word [bullet_y], 175

update_physics:
    ; Process bullet movement if active
    cmp byte [bullet_active], 0
    jz update_enemy
    sub word [bullet_y], 10
    jnc bullet_in_bounds
    mov byte [bullet_active], 0
    jmp update_enemy

bullet_in_bounds:
    ; Collision check: Bullet vs Enemy (Bounding box)
    mov ax, [bullet_y]
    sub ax, [enemy_y]
    add ax, 4
    cmp ax, 19
    ja update_enemy
    mov ax, [bullet_x]
    sub ax, [enemy_x]
    add ax, 2
    cmp ax, 17
    ja update_enemy

    ; If hit: Kill bullet, increase score, and respawn enemy
    mov byte [bullet_active], 0
    inc word [score]
    jmp respawn_enemy

update_enemy:
    ; Move enemy down by 2 pixels
    add word [enemy_y], 2
    cmp word [enemy_y], 200
    jae respawn_enemy

    ; Collision check: Player vs Enemy
    mov ax, [enemy_y]
    add ax, 15          ; Enemy height
    cmp ax, 185         ; Player Y start
    jb draw_game

    ; Bounding box check for X axis
    mov ax, [player_x]
    sub ax, [enemy_x]
    add ax, 10
    cmp ax, 25
    jbe game_over

respawn_enemy:
    ; Reset enemy to top at a "random" X position based on system clock
    mov word [enemy_y], 0
    xor ax, ax
    int 0x1A
    mov ax, dx
    xor dx, dx
    mov bx, 305
    div bx              ; Divide clock ticks by 305 to get X in screen range
    mov [enemy_x], dx

draw_game:
    ; Render Player (10x5 Blue rectangle)
    mov ax, 185
    mov bx, [player_x]
    mov si, 10
    mov dx, 5
    mov cl, 1           ; Color Blue
    call rect

    ; Render Bullet (2x4 Yellow rectangle) if active
    cmp byte [bullet_active], 0
    jz skip_bullet_draw
    mov ax, [bullet_y]
    mov bx, [bullet_x]
    mov si, 2
    mov dx, 4
    mov cl, 14          ; Color Yellow
    call rect

skip_bullet_draw:
    ; Render Enemy (15x15 Red rectangle)
    mov ax, [enemy_y]
    mov bx, [enemy_x]
    mov si, 15
    mov dx, 15
    mov cl, 4           ; Color Red
    call rect
    jmp game_loop

game_over:
    ; Display Game Over message in middle of screen
    mov dx, 0x0C0E      ; Position: Row 12, Column 14
    mov ah, 0x02
    xor bh, bh
    int 0x10
    mov si, msg_gameover

print_msg:
    lodsb
    test al, al
    jz wait_key
    mov ah, 0x0E
    int 0x10
    jmp print_msg

wait_key:
    ; Wait for any key press to restart the game
    mov ah, 0x00
    int 0x16
    jmp start

; Subroutine: Convert number in AX to decimal and print to screen
print_num:
    mov bx, 10
    xor cx, cx

digit_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz digit_loop

char_loop:
    pop ax
    add al, '0'
    mov ah, 0x0E
    int 0x10
    loop char_loop
    ret

; Subroutine: Draw a rectangle
; Inputs: AX=Y, BX=X, SI=Width, DX=Height, CL=Color
rect:
    mov bp, dx
    mov dx, 320
    mul dx
    add ax, bx
    mov di, ax          ; Destination offset in VGA memory
    mov al, cl

draw_rect_loop:
    push di
    mov cx, si
    rep stosb           ; Fill row with color
    pop di
    add di, 320         ; Move to next pixel row
    dec bp
    jnz draw_rect_loop
    ret

; Game variables and strings
player_x      dw 0
enemy_x       dw 0
enemy_y       dw 0
bullet_active db 0
bullet_x      dw 0
bullet_y      dw 0
score         dw 0
msg_gameover  db 'GAME OVER', 0

; Pad file to 510 bytes and add the 0xAA55 boot signature
times 510-($-$$) db 0
dw 0xAA55
