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
    lea si, msg
    call print_string

    ; ===================================
    ; Carrega o kernel no endereço 0x0800:0000
    mov ah, 0x02  ; Função de leitura do disco
    mov al, 10    ; Número de setores para ler
    mov ch, 0     ; Cilindro 0
    mov cl, 2     ; Setor 2
    mov dh, 0     ; Cabeça 0

    ; Define o endereço de destino para o kernel
    mov bx, 0x0800
    mov es, bx
    xor bx, bx  ; Posição 0 dentro do segmento

    ; Chama a interrupção do BIOS para ler o disco
    int 0x13
    jc disk_error  ; Se falhar, exibe erro

    ; ===================================
    ; Verificação de integridade do kernel
    cmp byte [es:0x0000], 0xE9
    je integrity_check_ok
    cmp byte [es:0x0000], 0xEB  ; Também aceita JMP curto
    je integrity_check_ok

disk_error:
    lea si, err
    call print_string
    jmp reboot

integrity_check_ok:
    ; Configura segmentos para o kernel
    mov ax, 0x0800
    mov ds, ax
    mov es, ax

    jmp 0x0800:0x0000  ; Passa controle para o kernel

; ===========================================
; Rotina para exibir strings na tela
print_string:
    push ax
    push si
next_char:
    lodsb
    test al, al
    jz printed
    mov ah, 0x0E
    int 0x10
    jmp next_char
printed:
    pop si
    pop ax
    ret

; Reinicia o sistema
reboot:
    mov ax, 0x0040
    mov ds, ax
    mov word [0x0072], 0x0000
    jmp 0xFFFF:0x0000  ; Reinicia o sistema

; ==== Dados ====
msg db "Loading...", 0x0D, 0x0A, 0
err db "Erro de leitura do kernel!", 0x0D, 0x0A, "Reiniciando...", 0

; Preenche até 512 bytes
times 510-($-$$) db 0
dw 0xAA55  ; Assinatura de boot

