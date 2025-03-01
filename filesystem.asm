BITS 16
ORG 0x0900  ; O código do FS será carregado no segmento 0x0900

jmp start  ; Pula a seção de dados

;Tabela de Arquivos
file_table:
    db "file1.bin",  2,  5  ; Nome, setor inicial, tamanho (setores)
    db "file2.bin",  7,  3
    db "file3.bin", 10,  4
    db  0  ; Marca de fim da tabela

start:
    lea si, msg_fs_loaded
    call print_string  ; Exibe "Filesystem Loaded!"
    call list_files    ; Lista arquivos disponíveis
    call load_file     ; Solicita arquivo para carregar
    ret  ; Retorna ao kernel

; Rotina para listar arquivos
list_files:
    pusha
    lea si, file_table

.next_entry:
    cmp byte [si], 0
    je .done  ; Se for fim da tabela, sair

    ; Imprime o nome do arquivo
    call print_string
    mov al, ' '
    call print_char

    ; Pula nome (11 bytes)
    add si, 11
    jmp .next_entry

.done:
    popa
    ret

;Rotina para carregar um arquivo
load_file:
    pusha
    lea si, file_table
    mov di, buffer

.get_input:
    ; Pergunta o nome do arquivo
    lea si, load_msg
    call print_string
    mov di, buffer
    call get_string

.search:
    cmp byte [si], 0
    je .not_found  ; Se fim da tabela, não encontrou

    ; Compara nome do arquivo
    push si
    push di
    call strcmp
    pop di
    pop si
    jz .found  ; Se igual, carregar

    ; Avança para próximo arquivo na tabela
    add si, 11
    jmp .search

.found:
    ; Pega setor inicial e tamanho
    mov cl, [si+9]   ; Setor inicial
    mov ch, [si+10]  ; Tamanho em setores

    ; Lê arquivo do disco
    mov ah, 0x02
    mov al, ch
    mov dh, 0  ; Cabeça 0
    mov bx, 0x1000
    mov es, bx
    xor bx, bx
    int 0x13

    jc .disk_error  ; Se erro, mostrar mensagem
    lea si, success_msg
    call print_string
    jmp .done

.disk_error:
    lea si, err_msg
    call print_string
    jmp .done

.not_found:
    lea si, nf_msg
    call print_string

.done:
    popa
    ret

;Função de comparação de strings
strcmp:
    mov cx, 11
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

;Entrada de dados
get_string:
    xor cx, cx
.read:
    mov ah, 0
    int 0x16
    cmp al, 0x0D
    je .done
    stosb
    jmp .read
.done:
    mov byte [di], 0
    ret

;Imprime string
print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

;Imprime caractere 
print_char:
    mov ah, 0x0E
    int 0x10
    ret

msg_fs_loaded db "Filesystem Loaded!", 0Dh, 0Ah, 0
load_msg db "Nome do arquivo: ", 0
nf_msg   db "Arquivo nao encontrado!", 0Dh, 0Ah, 0
err_msg  db "Erro ao ler do disco!", 0Dh, 0Ah, 0
success_msg db "Arquivo carregado com sucesso!", 0Dh, 0Ah, 0
buffer   times 11 db 0

; Preenchendo até 512 bytes
times 512-($-$$) db 0

