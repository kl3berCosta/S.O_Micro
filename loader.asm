BITS 16
ORG 0x7C00  ; Define que o código será carregado no endereço 0x7C00

    ; Inicializa a pilha
    mov ax, 0x07C0
    mov ss, ax
    mov sp, 0x03FE  ; Topo da pilha

    ; Define segmento de dados
    xor ax, ax
    mov ds, ax

    ; Configura modo de vídeo 80x25
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; Exibe mensagem de carregamento
    mov si, msg_loading
    call print_string

    ; ===================================
    ; Carrega o filesystem na memória (0x0900:0000)
    mov ah, 0x02  ; Função de leitura do disco
    mov al, 1     ; Número de setores para ler
    mov ch, 0     ; Cilindro 0
    mov cl, 3     ; Setor 3 (onde o FS está gravado)
    mov dh, 0     ; Cabeça 0

    mov ax, 0x0900
    mov es, ax
    xor bx, bx  ; Posição 0 dentro do segmento

    int 0x13
    jc disk_error  ; Se falhar, exibe erro

    mov si, msg_after_fs_load
    call print_string  ; Mensagem para depuração

    ; Executa o filesystem
    call 0x0900:0x0000

    ; ===================================
    ; Carrega o kernel no endereço 0x1000:0000
    mov ah, 0x02  ; Função de leitura do disco
    mov al, 10    ; Número de setores para ler
    mov ch, 0     ; Cilindro 0
    mov cl, 5     ; Setor 5 (onde o Kernel está gravado)
    mov dh, 0     ; Cabeça 0

    mov ax, 0x1000
    mov es, ax
    xor bx, bx  ; Posição 0 dentro do segmento

    int 0x13
    jc disk_error  ; Se falhar, exibe erro

    mov si, msg_after_kernel_load
    call print_string  ; Mensagem para depuração

    ; ===================================
    ; Verificação de integridade do kernel
    cmp byte [es:0x0000], 0xE9
    je integrity_check_ok
    cmp byte [es:0x0000], 0xEB  ; Também aceita JMP curto
    je integrity_check_ok

disk_error:
    mov si, msg_error
    call print_string
    jmp reboot

integrity_check_ok:
    ; Configura segmentos para o kernel
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Depuração: imprime o primeiro byte do kernel
    mov si, 0x0000
    mov al, [es:si]
    call print_hex

    ; Passa controle para o kernel
    jmp 0x1000:0x0000

; ==== Função para imprimir um valor hexadecimal ====
print_hex:
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 2  ; Número de dígitos a exibir

.next_digit:
    rol al, 4  ; Obtém o próximo dígito
    mov bl, al
    and bl, 0x0F
    add bl, '0'
    cmp bl, '9'
    jbe .print
    add bl, 7

.print:
    mov ah, 0x0E
    mov al, bl
    int 0x10
    loop .next_digit

    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ==== Outras funções de impressão ====
print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

; Reinicia o sistema
reboot:
    mov ax, 0x0040
    mov ds, ax
    mov word [0x0072], 0x0000
    jmp 0xFFFF:0x0000  ; Reinicia o sistema

; ==== Dados ====
msg_loading db "Loading Filesystem and Kernel...", 0x0D, 0x0A, 0
msg_after_fs_load db "Filesystem read OK!", 0x0D, 0x0A, 0
msg_after_kernel_load db "Kernel read OK!", 0x0D, 0x0A, 0
msg_error   db "Erro de leitura!", 0x0D, 0x0A, "Reiniciando...", 0

; Preenche até 512 bytes
times (510 - ($ - $$)) db 0
dw 0xAA55  ; Assinatura de boot

