# libft_tester

Tester para o projecto Libft da 42. Testa estrutura, Norminette, compilação e todas as funções da Part 1 e Part 2.

---

## Requisitos

- `cc` instalado
- `make` instalado
- `norminette` (opcional — se não estiver instalada, faz verificações manuais)
- `valgrind` (opcional — testa memory leaks)

---

## Como usar

Copia o ficheiro `libft_tester.sh` para qualquer lugar e corre:

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
- Existência de `libft.h`, `Makefile` e todos os `ft_*.c` obrigatórios
- Regras do Makefile: `all`, `clean`, `fclean`, `re`, `NAME`
- Flags `-Wall -Wextra -Werror` e uso de `ar`

**Norminette**
- Se instalada, corre directamente e reporta erros
- Se não instalada, verifica variáveis globais e linhas por função

**Compilação**
- `make` compila sem erros
- `make clean` não apaga `libft.a`
- `make fclean` apaga `libft.a`
- `libft.a` é gerado correctamente

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

**Memory leaks** (se Valgrind disponível)
- `ft_strdup` e `ft_split` sem leaks

---

## Output

```
[OK]   ft_strlen — compila e passa
[KO]   ft_strncmp — esperado='1' obtido='0'
[WARN] Norminette — não instalada
```

No final mostra o total de testes passados, falhados e avisos.

---

## Notas

- O tester não modifica nenhum ficheiro da tua libft
- Funções não implementadas causam erro de compilação e saltam o teste
- Corre `make fclean` na tua libft antes se tiveres `.o` antigos
