# printf_tester

Tester para o projecto ft_printf da 42. Compara o output e valor de retorno do teu `ft_printf` contra o `printf` original em todos os especificadores obrigatórios.

---

## Requisitos

- `cc` instalado
- `make` instalado
- `norminette` (opcional)

---

## Como usar

```bash
bash printf_tester.sh /caminho/para/teu/ft_printf
```

Se estiveres dentro da pasta do projecto:

```bash
bash printf_tester.sh .
```

---

## O que testa

**Estrutura**
- `ft_printf.h` existe e contém o protótipo
- Makefile com regras `all`, `clean`, `fclean`, `re`, `NAME`
- Flags `-Wall -Wextra -Werror` e uso de `ar`
- `libftprintf.a` gerado correctamente

**Norminette**
- Se instalada, corre directamente e mostra erros com ficheiro e linha

**Compilação**
- `make` compila sem erros
- `make clean` não apaga `libftprintf.a`
- `make fclean` apaga `libftprintf.a`

**Especificadores — obrigatórios**

| Especificador | O que verifica |
|---|---|
| `%c` | caractere, múltiplos, valores ASCII |
| `%s` | string normal, vazia, NULL |
| `%%` | percent literal, múltiplos |
| `%d` | zero, positivo, negativo, INT_MAX, INT_MIN |
| `%i` | igual ao `%d` |
| `%u` | zero, max unsigned, cast de negativo |
| `%x` | hex minúsculas, zero, max, letras |
| `%X` | hex maiúsculas, zero, max, letras |
| `%p` | formato `0x` + hex, NULL como `(nil)` |

**Mixed** — vários especificadores juntos, sem especificadores, adjacentes

**Valor de retorno** — contagem exacta de caracteres impressos em todos os casos

**Edge cases** — INT_MIN, INT_MAX, UINT_MAX, strings longas, `%%` múltiplos, char ASCII 1 e 127

---

## Output

```
[OK]   d_basic
[KO]   d_int_min — linha 1 — esperado='-2147483648' obtido='-0'
[WARN] Norminette — não instalada
```

---

## Erros explicados

| Mensagem | Causa | Como corrigir |
|---|---|---|
| `não compilou — função não implementada: ft_X` | `ft_X` não existe ou não está no Makefile | Verifica SRCS no Makefile |
| `não compilou — função não declarada no header` | Falta protótipo em `ft_printf.h` | Adiciona o protótipo |
| `TIMEOUT (>5s)` | Loop infinito — provavelmente no loop principal da format string | Verifica condição de paragem do while |
| `SEGFAULT` | Acesso a NULL — `%s` ou `%p` com NULL sem verificação, ou `va_arg` com tipo errado | Verifica tratamento de NULL |
| `linha N errada` | Output diferente do `printf` real nessa linha | Ver tabela abaixo |
| `número de linhas errado` | Imprimes mais ou menos do que o esperado | Verifica `\n` desnecessários ou em falta |

**Causas específicas por especificador:**

| Especificador | Causa mais comum de falha |
|---|---|
| `%d` / `%i` | INT_MIN overflow — usa `long` antes de inverter o sinal |
| `%u` | Não fazes cast para `unsigned int` — resultado negativo |
| `%x` / `%X` | Dígitos com capitalização errada — `%x` é minúsculo, `%X` é maiúsculo |
| `%p` | Prefixo `0x` em maiúscula — deve ser sempre minúsculo |
| `%s` NULL | Não imprimes `(null)` — o printf real imprime isso |
| `%%` | Retornas 0 ou 2 em vez de 1 |
| `ret=N` | Contagem de caracteres errada — cada `write` conta todos os bytes escritos |

---

## Notas

- O tester não modifica nenhum ficheiro do teu projecto
- Os testes de `%p` verificam o **formato** (`0x` + hex), não o valor exacto — endereços mudam entre execuções
- Corre `make fclean` antes se tiveres `.o` antigos
- O tester requer que `libftprintf.a` esteja no directório indicado
