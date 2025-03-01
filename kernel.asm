
BITS 16
ORG 0x0000  ; O kernel será carregado neste endereço

jmp start  ; Pula a seção de dados

; ==== Dados ====
msg        db "Welcome to micro-os!", 0Dh, 0Ah, 0
cmd_size   equ 10  ; Tamanho máximo do comando
command_buffer db cmd_size dup(0)
prompt     db ">", 0

chelp      db "help", 0
ccls       db "cls", 0
clist      db "ls", 0
cload      db "load", 0
creboot    db "reboot", 0

help_msg   db "Comandos: help, cls, ls, load, reboot", 0Dh, 0Ah, 0
unknown    db "Comando desconhecido: ", 0
file_msg   db "Arquivos:", 0Dh, 0Ah, 0
load_msg   db "Carregando arquivo...", 0Dh, 0Ah, 0

; ==== Código ====
start:
    cli
    mov ax, 0x0800
    mov ds, ax
    mov es, ax
    sti

    ; Configura o modo de vídeo 80x25
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Exibe mensagem de boas-vindas
    call clear_screen
    lea si, msg
    call print_string

main_loop:
    call get_command
    call process_cmd
    jmp main_loop

; ==== Lê comando do usuário ====
get_command:
    lea si, [prompt]
    call print_string
    mov di, command_buffer
    mov cx, cmd_size
    call get_string
    ret

; ==== Processa o comando ====
process_cmd:
    lea si, [command_buffer]
    lea di, [chelp]
    call strcmp
    jz print_help

    lea si, [command_buffer]
    lea di, [ccls]
    call strcmp
    jz clear_screen

    lea si, [command_buffer]
    lea di, [clist]
    call strcmp
    jz list_files

    lea si, [command_buffer]
    lea di, [cload]
    call strcmp
    jz load_file

    lea si, [command_buffer]
    lea si, unknown
    call print_string
    lea si, [command_buffer]
    call print_string
    ret

print_help:
    lea si, [help_msg]
    call print_string
    ret

; ==== Lista arquivos do sistema ====
list_files:
    lea si, [file_msg]
    call print_string
    call 0x0900:0x0100  ; Chama a função de listar arquivos do FS
    ret

; ==== Carrega um arquivo ====
load_file:
    lea si, [load_msg]
    call print_string
    call 0x0900:0x0200  ; Chama a função de carregar um arquivo do FS
    ret

; ==== Compara duas strings ====
strcmp:
    mov cx, 0xFFFF
.loop:
    lodsb
    scasb
    jne .neq
    test al, al
    jnz .loop
    xor ax, ax
    ret
.neq:
    mov ax, 1
    ret

; ==== Limpa a tela ====
clear_screen:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    ret

; ==== Reinicia o sistema ====
reboot:
    mov ax, 0x0040
    mov ds, ax
    mov word [0x0072], 0x0000
    jmp 0FFFFh:0000h

; ==== Lê uma string do teclado ====
get_string:
    xor cx, cx
.read:
    mov ah, 0
    int 0x16
    cmp al, 0x0D
    je .done
    stosb
    loop .read
.done:
    mov byte [di], 0
    ret

; ==== Imprime string ====
print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

; Preenche até 512 bytes
times 512-($-$$) db 0

