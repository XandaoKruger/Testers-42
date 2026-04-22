# libft_tester

Tester para o projecto Libft da 42. Testa estrutura, Norminette, compilação e todas as funções da Part 1, Part 2 e Part 3 (linked lists).

---

## Requisitos

- `cc` instalado
- `make` instalado
- `norminette` (opcional — se não estiver instalada, faz verificações manuais)
- `valgrind` (opcional — testa memory leaks)

---

## Como usar

```bash
bash libft_tester.sh /caminho/para/tua/libft
```

Se estiveres dentro da pasta da libft:

```bash
bash libft_tester.sh .
```

---

## O que testa

**Estrutura**
- Todos os ficheiros `ft_*.c` obrigatórios listados e numerados
- Regras do Makefile: `all`, `clean`, `fclean`, `re`, `NAME`
- Flags `-Wall -Wextra -Werror` e uso de `ar`

**Norminette**
- Se instalada, corre directamente e mostra ficheiro + linha de cada erro
- Se não instalada, verifica variáveis globais e linhas por função manualmente

**Compilação**
- `make` compila sem erros — mostra as linhas de erro relevantes se falhar
- `make clean` não apaga `libft.a`
- `make fclean` apaga `libft.a`

**Funções — Part 1**
`ft_isalpha` `ft_isdigit` `ft_isalnum` `ft_isascii` `ft_isprint`
`ft_strlen` `ft_toupper` `ft_tolower` `ft_strchr` `ft_strrchr`
`ft_strncmp` `ft_memset` `ft_bzero` `ft_memcpy` `ft_memmove`
`ft_strlcpy` `ft_strlcat` `ft_strnstr` `ft_atoi` `ft_memchr`
`ft_memcmp` `ft_calloc` `ft_strdup`

**Funções — Part 2**
`ft_putchar_fd` `ft_putstr_fd` `ft_putendl_fd` `ft_putnbr_fd`
`ft_substr` `ft_strjoin` `ft_strtrim` `ft_itoa` `ft_strmapi`
`ft_striteri` `ft_split`

**Funções — Part 3 (Linked Lists)**
`ft_lstnew` `ft_lstadd_front` `ft_lstsize` `ft_lstlast`
`ft_lstadd_back` `ft_lstdelone` `ft_lstclear` `ft_lstiter` `ft_lstmap`

Cada função de linked list tem múltiplos testes — casos normais, lista vazia, `NULL`, e comportamentos específicos como verificar se `del` é chamada o número certo de vezes.

**Memory leaks** (se Valgrind disponível)
- `ft_strdup`, `ft_split`, `ft_lstclear`, `ft_lstmap` sem leaks

---

## Output

```
[OK]    1. ft_isalpha.c
[KO]    2. ft_isdigit.c — ficheiro não encontrado
[OK]   ft_strlen
[KO]   ft_strncmp — linha 3 errada — esperado='1' obtido='0'
[WARN] Norminette — não instalada
```

---

## Erros explicados

| Mensagem | Causa | Como corrigir |
|---|---|---|
| `função não implementada ou não compilada: ft_X` | `ft_X.c` não está no Makefile ou o ficheiro não existe | Verifica o SRCS no Makefile |
| `função não declarada no header: ft_X` | Falta o protótipo de `ft_X` no `libft.h` | Adiciona o protótipo ao header |
| `TIMEOUT (>5s)` | Loop infinito — o programa não termina | Verifica condições de paragem dos loops |
| `SEGFAULT` | Acesso a ponteiro NULL ou fora dos limites | Verifica se NULL é tratado antes de desreferenciar |
| `ABORT` | Double free ou corrupção do heap | Verifica se estás a libertar memória mais do que uma vez |
| `linha N errada` | Output diferente do esperado nessa linha | A lógica da função está incorrecta nesse caso |
| `número de linhas errado` | A função imprime mais ou menos do que devia | Verifica loops e condições de saída |
| `memory leak detectado` | Malloc sem free correspondente | Usa valgrind directamente para ver qual alocação não foi libertada |

---

## Notas

- O tester não modifica nenhum ficheiro da tua libft
- Corre `make fclean` na tua libft antes se tiveres `.o` antigos
- Os testes da Part 3 requerem a `t_list` struct definida no `libft.h`
- Os testes de linked lists usam variáveis separadas para cada nó — nunca acedes a memória já libertada
