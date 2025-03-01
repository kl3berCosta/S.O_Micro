#include <stdio.h>
#include <stdlib.h>

int main() {
    char filename[100], ch;
    FILE *file;

    printf("Digite o nome do arquivo: ");
    scanf("%s", filename);

    file = fopen(filename, "w"); // Abre o arquivo para escrita
    if (!file) {
        printf("Erro ao abrir o arquivo!\n");
        return 1;
    }

    printf("Digite o texto (CTRL+D para salvar e sair):\n");

    getchar(); // Limpa buffer do teclado
    while ((ch = getchar()) != EOF) {
        fputc(ch, file);
    }

    fclose(file);
    printf("\nArquivo salvo como %s\n", filename);
    return 0;
}
