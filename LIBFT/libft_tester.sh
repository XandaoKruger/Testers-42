#!/bin/bash

# ============================================================
# LIBFT TESTER — Fiel à Moulinette da 42
# Testa Part 1, Part 2 e Norminette
# Uso: bash libft_tester.sh [caminho_para_libft]
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

LIBFT_PATH="${1:-.}"
LIBFT_H="$LIBFT_PATH/libft.h"
LIBFT_A="$LIBFT_PATH/libft.a"
TMP_DIR="/tmp/libft_tester_$$"

mkdir -p "$TMP_DIR"

print_header() {
	echo ""
	echo -e "${BOLD}${BLUE}============================================================${NC}"
	echo -e "${BOLD}${BLUE}  $1${NC}"
	echo -e "${BOLD}${BLUE}============================================================${NC}"
}

print_test() {
	local name="$1"
	local result="$2"
	local detail="$3"
	if [ "$result" = "OK" ]; then
		echo -e "  ${GREEN}[OK]${NC}   $name"
		((PASS++))
	elif [ "$result" = "WARN" ]; then
		echo -e "  ${YELLOW}[WARN]${NC} $name — $detail"
		((WARN++))
	else
		echo -e "  ${RED}[KO]${NC}   $name — $detail"
		((FAIL++))
	fi
}

# ============================================================
# 1. VERIFICAÇÕES DE ESTRUTURA
# ============================================================
print_header "ESTRUTURA DO PROJECTO"

# Verifica libft.h
if [ -f "$LIBFT_H" ]; then
	print_test "libft.h existe" "OK"
else
	print_test "libft.h existe" "KO" "ficheiro não encontrado em $LIBFT_PATH"
fi

# Verifica Makefile
if [ -f "$LIBFT_PATH/Makefile" ]; then
	print_test "Makefile existe" "OK"
	# Verifica regras obrigatórias
	for rule in "all" "clean" "fclean" "re" "NAME"; do
		if grep -q "$rule" "$LIBFT_PATH/Makefile"; then
			print_test "Makefile tem regra: $rule" "OK"
		else
			print_test "Makefile tem regra: $rule" "KO" "regra '$rule' não encontrada"
		fi
	done
	# Verifica ar
	if grep -q "ar" "$LIBFT_PATH/Makefile"; then
		print_test "Makefile usa ar (não libtool)" "OK"
	else
		print_test "Makefile usa ar (não libtool)" "WARN" "ar não encontrado no Makefile"
	fi
	# Verifica -Wall -Wextra -Werror
	if grep -q "\-Wall" "$LIBFT_PATH/Makefile" && grep -q "\-Wextra" "$LIBFT_PATH/Makefile" && grep -q "\-Werror" "$LIBFT_PATH/Makefile"; then
		print_test "Makefile tem flags -Wall -Wextra -Werror" "OK"
	else
		print_test "Makefile tem flags -Wall -Wextra -Werror" "KO" "flags em falta"
	fi
else
	print_test "Makefile existe" "KO" "não encontrado"
fi

# Verifica ficheiros ft_*.c obrigatórios
MANDATORY_FUNCS="ft_isalpha ft_isdigit ft_isalnum ft_isascii ft_isprint \
ft_strlen ft_memset ft_bzero ft_memcpy ft_memmove ft_strlcpy ft_strlcat \
ft_toupper ft_tolower ft_strchr ft_strrchr ft_strncmp ft_memchr ft_memcmp \
ft_strnstr ft_atoi ft_calloc ft_strdup \
ft_substr ft_strjoin ft_strtrim ft_split ft_itoa ft_strmapi ft_striteri \
ft_putchar_fd ft_putstr_fd ft_putendl_fd ft_putnbr_fd \
ft_lstnew ft_lstadd_front ft_lstsize ft_lstlast ft_lstadd_back \
ft_lstdelone ft_lstclear ft_lstiter ft_lstmap"

print_header "FICHEIROS OBRIGATÓRIOS"
file_num=1
for func in $MANDATORY_FUNCS; do
	if [ -f "$LIBFT_PATH/${func}.c" ]; then
		printf "  ${GREEN}[OK]${NC}   %2d. %s.c\n" "$file_num" "$func"
		((PASS++))
	else
		printf "  ${RED}[KO]${NC}   %2d. %s.c — ficheiro não encontrado\n" "$file_num" "$func"
		((FAIL++))
	fi
	((file_num++))
done

# ============================================================
# 2. NORMINETTE
# ============================================================
print_header "NORMINETTE"

if command -v norminette &> /dev/null; then
	NORM_OUTPUT=$(norminette "$LIBFT_PATH"/*.c "$LIBFT_PATH"/*.h 2>&1)
	NORM_ERRORS=$(echo "$NORM_OUTPUT" | grep -c "Error")
	if [ "$NORM_ERRORS" -eq 0 ]; then
		print_test "Norminette — sem erros" "OK"
	else
		print_test "Norminette — $NORM_ERRORS erro(s) encontrado(s)" "KO" "detalhes abaixo"
		echo ""
		echo "$NORM_OUTPUT" | grep -A1 "Error" | grep -v "^--$" | sed 's/^/    /'
		echo ""
	fi
else
	print_test "Norminette" "WARN" "norminette não instalada — a verificar manualmente"
	# Verificações manuais da norma
	for file in "$LIBFT_PATH"/ft_*.c; do
		fname=$(basename "$file")
		# Verifica variáveis globais
		if grep -n "^[a-zA-Z].*=.*;" "$file" | grep -v "^[0-9]*:.*(/\*\|//\|static\|typedef)" > /dev/null 2>&1; then
			print_test "Sem variáveis globais: $fname" "WARN" "possível variável global detectada"
		fi
		# Conta linhas por função (aproximado)
		MAX_LINES=$(awk '/^{/{count=0} /^}$/{if(count>25) print count} {count++}' "$file" | sort -n | tail -1)
		if [ -n "$MAX_LINES" ] && [ "$MAX_LINES" -gt 25 ]; then
			print_test "Linhas por função (<= 25): $fname" "KO" "função com ~$MAX_LINES linhas"
		fi
	done
fi

# ============================================================
# 3. COMPILAÇÃO
# ============================================================
print_header "COMPILAÇÃO"

cd "$LIBFT_PATH" || exit 1

# Limpa e compila
make fclean > /dev/null 2>&1
MAKE_OUTPUT=$(make 2>&1)
MAKE_EXIT=$?

if [ $MAKE_EXIT -eq 0 ]; then
	print_test "make — compila sem erros" "OK"
else
	print_test "make — compila sem erros" "KO" "erro de compilação no make"
	echo ""
	echo -e "${RED}  Detalhes do erro:${NC}"
	echo "$MAKE_OUTPUT" | grep -E "error:|undefined|warning:" | head -10 | sed 's/^/    /'
	echo ""
	echo -e "${RED}  Não é possível continuar — corrige os erros de compilação primeiro.${NC}"
	exit 1
fi

if [ -f "libft.a" ]; then
	print_test "libft.a gerado" "OK"
else
	print_test "libft.a gerado" "KO" "libft.a não encontrado após make"
	exit 1
fi

# make clean não apaga libft.a
make clean > /dev/null 2>&1
if [ -f "libft.a" ]; then
	print_test "make clean não apaga libft.a" "OK"
else
	print_test "make clean não apaga libft.a" "KO" "libft.a foi apagado pelo clean"
fi

# make fclean apaga libft.a
make fclean > /dev/null 2>&1
if [ ! -f "libft.a" ]; then
	print_test "make fclean apaga libft.a" "OK"
else
	print_test "make fclean apaga libft.a" "KO" "libft.a não foi apagado pelo fclean"
fi

# Recompila para os testes
make > /dev/null 2>&1

cd - > /dev/null || exit 1

# ============================================================
# 4. TESTES FUNCIONAIS
# ============================================================

LIBFT_A="$LIBFT_PATH/libft.a"
CC="cc"
CFLAGS="-Wall -Wextra -Werror"

compile_test() {
	local name="$1"
	local src="$2"
	local out="$TMP_DIR/$name"
	echo "$src" > "$TMP_DIR/${name}.c"
	$CC $CFLAGS "$TMP_DIR/${name}.c" "$LIBFT_A" -I"$LIBFT_PATH" -o "$out" 2>"$TMP_DIR/${name}.err"
	local exit_code=$?
	if [ $exit_code -ne 0 ]; then
		# Tenta perceber o motivo do erro de compilação
		local err_output
		err_output=$(cat "$TMP_DIR/${name}.err")
		local reason=""
		if echo "$err_output" | grep -q "undefined reference"; then
			local missing
			missing=$(echo "$err_output" | grep "undefined reference" | sed "s/.*\`\(.*\)'.*/\1/" | sort -u | tr '\n' ' ')
			reason="função não implementada ou não compilada: $missing"
		elif echo "$err_output" | grep -q "implicit declaration"; then
			local missing
			missing=$(echo "$err_output" | grep "implicit declaration" | sed "s/.*'\(.*\)'.*/\1/" | sort -u | tr '\n' ' ')
			reason="função não declarada no header: $missing"
		elif echo "$err_output" | grep -q "error:"; then
			reason=$(echo "$err_output" | grep "error:" | head -1 | sed 's/.*error: //')
		else
			reason="erro de compilação desconhecido"
		fi
		print_test "$name" "KO" "não compilou — $reason"
		((FAIL++))
		return 1
	fi
	return 0
}

run_test() {
	local name="$1"
	local expected="$2"
	local out="$TMP_DIR/$name"

	# Verifica se o binário existe (compilação falhou antes)
	if [ ! -f "$out" ]; then
		return
	fi

	local result
	result=$(timeout 5 "$out" 2>/tmp/run_stderr_$$)
	local exit_code=$?

	if [ $exit_code -eq 124 ]; then
		print_test "$name" "KO" "TIMEOUT (>5s) — possível loop infinito ou deadlock"
	elif [ $exit_code -eq 139 ]; then
		print_test "$name" "KO" "SEGFAULT — acesso inválido à memória (ponteiro NULL? buffer overflow?)"
	elif [ $exit_code -eq 134 ]; then
		print_test "$name" "KO" "ABORT — double free ou heap corruption detectado"
	elif [ "$result" = "$expected" ]; then
		print_test "$name" "OK"
	else
		# Dá detalhe sobre a diferença
		local exp_lines
		local got_lines
		exp_lines=$(echo "$expected" | wc -l)
		got_lines=$(echo "$result" | wc -l)
		if [ "$exp_lines" != "$got_lines" ]; then
			print_test "$name" "KO" "número de linhas errado — esperado $exp_lines linha(s), obtido $got_lines"
		else
			# Mostra a primeira linha diferente
			local line_num=1
			while IFS= read -r exp_line; do
				got_line=$(echo "$result" | sed -n "${line_num}p")
				if [ "$exp_line" != "$got_line" ]; then
					print_test "$name" "KO" "linha $line_num errada — esperado='$exp_line' obtido='$got_line'"
					break
				fi
				((line_num++))
			done <<< "$expected"
		fi
	fi
	rm -f /tmp/run_stderr_$$
}

# ============================================================
# PART 1 — LIBC FUNCTIONS
# ============================================================
print_header "PART 1 — ft_isalpha"

compile_test "isalpha_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%d\n%d\n%d\n%d\n%d\n%d\n",
		ft_isalpha('"'"'a'"'"') != 0,
		ft_isalpha('"'"'Z'"'"') != 0,
		ft_isalpha('"'"'0'"'"') == 0,
		ft_isalpha('"'"' '"'"') == 0,
		ft_isalpha(0) == 0,
		ft_isalpha(127) == 0);
}'
run_test "isalpha_basic" "1
1
1
1
1
1"

compile_test "isalpha_bounds" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%d\n%d\n%d\n%d\n",
		ft_isalpha('"'"'A'"'"') != 0,
		ft_isalpha('"'"'z'"'"') != 0,
		ft_isalpha('"'"'9'"'"') == 0,
		ft_isalpha('"'"'/'"'"') == 0);
}'
run_test "isalpha_bounds" "1
1
1
1"

print_header "PART 1 — ft_isdigit"

compile_test "isdigit_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%d\n%d\n%d\n%d\n",
		ft_isdigit('"'"'0'"'"') != 0,
		ft_isdigit('"'"'9'"'"') != 0,
		ft_isdigit('"'"'a'"'"') == 0,
		ft_isdigit('"'"' '"'"') == 0);
}'
run_test "isdigit_basic" "1
1
1
1"

print_header "PART 1 — ft_isalnum"

compile_test "isalnum_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%d\n%d\n%d\n%d\n%d\n",
		ft_isalnum('"'"'a'"'"') != 0,
		ft_isalnum('"'"'Z'"'"') != 0,
		ft_isalnum('"'"'5'"'"') != 0,
		ft_isalnum('"'"' '"'"') == 0,
		ft_isalnum('"'"'\0'"'"') == 0);
}'
run_test "isalnum_basic" "1
1
1
1
1"

print_header "PART 1 — ft_isascii"

compile_test "isascii_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%d\n%d\n%d\n%d\n%d\n",
		ft_isascii(0) != 0,
		ft_isascii(127) != 0,
		ft_isascii(128) == 0,
		ft_isascii(-1) == 0,
		ft_isascii('"'"'A'"'"') != 0);
}'
run_test "isascii_basic" "1
1
1
1
1"

print_header "PART 1 — ft_isprint"

compile_test "isprint_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%d\n%d\n%d\n%d\n%d\n",
		ft_isprint('"'"' '"'"') != 0,
		ft_isprint('"'"'~'"'"') != 0,
		ft_isprint(31) == 0,
		ft_isprint(127) == 0,
		ft_isprint('"'"'A'"'"') != 0);
}'
run_test "isprint_basic" "1
1
1
1
1"

print_header "PART 1 — ft_strlen"

compile_test "strlen_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%zu\n%zu\n%zu\n",
		ft_strlen("hello"),
		ft_strlen(""),
		ft_strlen("42Lisboa"));
}'
run_test "strlen_basic" "5
0
8"

print_header "PART 1 — ft_toupper / ft_tolower"

compile_test "toupper_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%c\n%c\n%c\n%c\n",
		ft_toupper('"'"'a'"'"'),
		ft_toupper('"'"'z'"'"'),
		ft_toupper('"'"'A'"'"'),
		ft_toupper('"'"'1'"'"'));
}'
run_test "toupper_basic" "A
Z
A
1"

compile_test "tolower_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%c\n%c\n%c\n%c\n",
		ft_tolower('"'"'A'"'"'),
		ft_tolower('"'"'Z'"'"'),
		ft_tolower('"'"'a'"'"'),
		ft_tolower('"'"'1'"'"'));
}'
run_test "tolower_basic" "a
z
a
1"

print_header "PART 1 — ft_strchr / ft_strrchr"

compile_test "strchr_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char *s = "banana";
	char *r;
	r = ft_strchr(s, '"'"'a'"'"');
	printf("%s\n", r ? r : "NULL");
	r = ft_strchr(s, '"'"'b'"'"');
	printf("%s\n", r ? r : "NULL");
	r = ft_strchr(s, '"'"'x'"'"');
	printf("%s\n", r ? r : "NULL");
	r = ft_strchr(s, '"'"'\0'"'"');
	printf("%d\n", r != NULL);
}'
run_test "strchr_basic" "anana
banana
NULL
1"

compile_test "strrchr_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char *s = "banana";
	char *r;
	r = ft_strrchr(s, '"'"'a'"'"');
	printf("%s\n", r ? r : "NULL");
	r = ft_strrchr(s, '"'"'b'"'"');
	printf("%s\n", r ? r : "NULL");
	r = ft_strrchr(s, '"'"'x'"'"');
	printf("%s\n", r ? r : "NULL");
}'
run_test "strrchr_basic" "a
banana
NULL"

print_header "PART 1 — ft_strncmp"

compile_test "strncmp_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%d\n", ft_strncmp("abc", "abc", 3) == 0);
	printf("%d\n", ft_strncmp("abc", "abd", 3) < 0);
	printf("%d\n", ft_strncmp("abd", "abc", 3) > 0);
	printf("%d\n", ft_strncmp("abc", "abd", 2) == 0);
	printf("%d\n", ft_strncmp("abc", "abc", 0) == 0);
}'
run_test "strncmp_basic" "1
1
1
1
1"

print_header "PART 1 — ft_memset / ft_bzero"

compile_test "memset_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char buf[6] = "hello";
	ft_memset(buf, '"'"'x'"'"', 3);
	printf("%s\n", buf);
	ft_memset(buf, 0, 5);
	printf("%d\n", buf[0] == 0);
}'
run_test "memset_basic" "xxxlo
1"

compile_test "bzero_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char buf[5] = "test";
	ft_bzero(buf, 4);
	printf("%d\n%d\n%d\n%d\n",
		buf[0] == 0, buf[1] == 0, buf[2] == 0, buf[3] == 0);
}'
run_test "bzero_basic" "1
1
1
1"

print_header "PART 1 — ft_memcpy / ft_memmove"

compile_test "memcpy_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char src[] = "hello";
	char dst[6];
	ft_memcpy(dst, src, 6);
	printf("%s\n", dst);
	ft_memcpy(dst, src, 0);
	printf("%s\n", dst);
}'
run_test "memcpy_basic" "hello
hello"

compile_test "memmove_overlap" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char buf[] = "memmove";
	ft_memmove(buf + 2, buf, 5);
	printf("%s\n", buf);
}'
run_test "memmove_overlap" "mememmo"

print_header "PART 1 — ft_strlcpy / ft_strlcat"

compile_test "strlcpy_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char dst[10];
	size_t r;
	r = ft_strlcpy(dst, "hello", 10);
	printf("%s\n%zu\n", dst, r);
	r = ft_strlcpy(dst, "hello", 3);
	printf("%s\n%zu\n", dst, r);
	r = ft_strlcpy(dst, "hello", 0);
	printf("%zu\n", r);
}'
run_test "strlcpy_basic" "hello
5
he
5
5"

compile_test "strlcat_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char dst[20] = "hello";
	size_t r;
	r = ft_strlcat(dst, " world", 20);
	printf("%s\n%zu\n", dst, r);
}'
run_test "strlcat_basic" "hello world
11"

print_header "PART 1 — ft_strnstr"

compile_test "strnstr_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char *r;
	r = ft_strnstr("banana", "nan", 6);
	printf("%s\n", r ? r : "NULL");
	r = ft_strnstr("banana", "xyz", 6);
	printf("%s\n", r ? r : "NULL");
	r = ft_strnstr("banana", "", 6);
	printf("%s\n", r ? r : "NULL");
	r = ft_strnstr("banana", "nan", 2);
	printf("%s\n", r ? r : "NULL");
}'
run_test "strnstr_basic" "nana
NULL
banana
NULL"

print_header "PART 1 — ft_atoi"

compile_test "atoi_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%d\n", ft_atoi("42"));
	printf("%d\n", ft_atoi("-42"));
	printf("%d\n", ft_atoi("   42"));
	printf("%d\n", ft_atoi("+42"));
	printf("%d\n", ft_atoi("0"));
	printf("%d\n", ft_atoi("42abc"));
	printf("%d\n", ft_atoi("2147483647"));
	printf("%d\n", ft_atoi("-2147483648"));
}'
run_test "atoi_basic" "42
-42
42
42
0
42
2147483647
-2147483648"

print_header "PART 1 — ft_memchr / ft_memcmp"

compile_test "memchr_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	char s[] = "hello\0world";
	char *r;
	r = ft_memchr(s, '"'"'l'"'"', 5);
	printf("%d\n", r != NULL);
	r = ft_memchr(s, '"'"'\0'"'"', 6);
	printf("%d\n", r != NULL);
	r = ft_memchr(s, '"'"'x'"'"', 5);
	printf("%d\n", r == NULL);
}'
run_test "memchr_basic" "1
1
1"

compile_test "memcmp_basic" '#include "libft.h"
#include <stdio.h>
int main(void) {
	printf("%d\n", ft_memcmp("abc", "abc", 3) == 0);
	printf("%d\n", ft_memcmp("abc", "abd", 3) < 0);
	printf("%d\n", ft_memcmp("abc", "abc", 0) == 0);
	printf("%d\n", ft_memcmp("abc\0x", "abc\0y", 5) < 0);
}'
run_test "memcmp_basic" "1
1
1
1"

print_header "PART 1 — ft_calloc / ft_strdup"

compile_test "calloc_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	int *p = ft_calloc(5, sizeof(int));
	if (!p) { printf("NULL\n"); return 0; }
	printf("%d\n%d\n%d\n", p[0] == 0, p[4] == 0, 1);
	free(p);
	void *z = ft_calloc(0, 0);
	printf("%d\n", z != NULL);
	free(z);
}'
run_test "calloc_basic" "1
1
1
1"

compile_test "strdup_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	char *s = ft_strdup("hello");
	printf("%s\n", s);
	printf("%d\n", s != NULL);
	free(s);
	char *e = ft_strdup("");
	printf("%zu\n", ft_strlen(e));
	free(e);
}'
run_test "strdup_basic" "hello
1
0"

# ============================================================
# PART 2
# ============================================================
print_header "PART 2 — ft_putchar_fd / ft_putstr_fd / ft_putendl_fd"

compile_test "putchar_fd" '#include "libft.h"
int main(void) {
	ft_putchar_fd('"'"'A'"'"', 1);
	ft_putchar_fd('"'"'\n'"'"', 1);
}'
run_test "putchar_fd" "A"

compile_test "putstr_fd" '#include "libft.h"
int main(void) {
	ft_putstr_fd("hello", 1);
	ft_putchar_fd('"'"'\n'"'"', 1);
}'
run_test "putstr_fd" "hello"

compile_test "putendl_fd" '#include "libft.h"
int main(void) {
	ft_putendl_fd("hello", 1);
}'
run_test "putendl_fd" "hello"

print_header "PART 2 — ft_putnbr_fd"

compile_test "putnbr_fd" '#include "libft.h"
int main(void) {
	ft_putnbr_fd(42, 1);
	ft_putchar_fd('"'"'\n'"'"', 1);
	ft_putnbr_fd(-42, 1);
	ft_putchar_fd('"'"'\n'"'"', 1);
	ft_putnbr_fd(0, 1);
	ft_putchar_fd('"'"'\n'"'"', 1);
	ft_putnbr_fd(2147483647, 1);
	ft_putchar_fd('"'"'\n'"'"', 1);
	ft_putnbr_fd(-2147483648, 1);
	ft_putchar_fd('"'"'\n'"'"', 1);
}'
run_test "putnbr_fd" "42
-42
0
2147483647
-2147483648"

print_header "PART 2 — ft_substr"

compile_test "substr_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	char *s;
	s = ft_substr("banana", 0, 3);
	printf("%s\n", s); free(s);
	s = ft_substr("banana", 2, 3);
	printf("%s\n", s); free(s);
	s = ft_substr("banana", 10, 3);
	printf("[%s]\n", s); free(s);
	s = ft_substr("banana", 0, 0);
	printf("[%s]\n", s); free(s);
	s = ft_substr("banana", 0, 100);
	printf("%s\n", s); free(s);
}'
run_test "substr_basic" "ban
nan
[]
[]
banana"

print_header "PART 2 — ft_strjoin"

compile_test "strjoin_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	char *s;
	s = ft_strjoin("hello", " world");
	printf("%s\n", s); free(s);
	s = ft_strjoin("", "hello");
	printf("%s\n", s); free(s);
	s = ft_strjoin("hello", "");
	printf("%s\n", s); free(s);
	s = ft_strjoin("", "");
	printf("[%s]\n", s); free(s);
}'
run_test "strjoin_basic" "hello world
hello
hello
[]"

print_header "PART 2 — ft_strtrim"

compile_test "strtrim_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	char *s;
	s = ft_strtrim("  hello  ", " ");
	printf("%s\n", s); free(s);
	s = ft_strtrim("xxhelloxx", "x");
	printf("%s\n", s); free(s);
	s = ft_strtrim("hello", "x");
	printf("%s\n", s); free(s);
	s = ft_strtrim("", " ");
	printf("[%s]\n", s); free(s);
	s = ft_strtrim("xxxxx", "x");
	printf("[%s]\n", s); free(s);
	s = ft_strtrim("xyhelloyx", "xy");
	printf("%s\n", s); free(s);
}'
run_test "strtrim_basic" "hello
hello
hello
[]
[]
hello"

print_header "PART 2 — ft_itoa"

compile_test "itoa_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	char *s;
	s = ft_itoa(0); printf("%s\n", s); free(s);
	s = ft_itoa(42); printf("%s\n", s); free(s);
	s = ft_itoa(-42); printf("%s\n", s); free(s);
	s = ft_itoa(2147483647); printf("%s\n", s); free(s);
	s = ft_itoa(-2147483648); printf("%s\n", s); free(s);
}'
run_test "itoa_basic" "0
42
-42
2147483647
-2147483648"

print_header "PART 2 — ft_strmapi"

compile_test "strmapi_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static char to_upper(unsigned int i, char c) {
	(void)i;
	if (c >= '"'"'a'"'"' && c <= '"'"'z'"'"') return c - 32;
	return c;
}
int main(void) {
	char *s = ft_strmapi("hello", to_upper);
	printf("%s\n", s); free(s);
	s = ft_strmapi("", to_upper);
	printf("[%s]\n", s); free(s);
}'
run_test "strmapi_basic" "HELLO
[]"

print_header "PART 2 — ft_striteri"

compile_test "striteri_basic" '#include "libft.h"
#include <stdio.h>
static void to_upper_i(unsigned int i, char *c) {
	(void)i;
	if (*c >= '"'"'a'"'"' && *c <= '"'"'z'"'"') *c -= 32;
}
int main(void) {
	char s[] = "hello";
	ft_striteri(s, to_upper_i);
	printf("%s\n", s);
}'
run_test "striteri_basic" "HELLO"

print_header "PART 2 — ft_split"

compile_test "split_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	char **r;
	int i;
	r = ft_split("hello world foo", '"'"' '"'"');
	i = 0;
	while (r[i]) { printf("%s\n", r[i]); free(r[i]); i++; }
	free(r);
	r = ft_split("  hello  world  ", '"'"' '"'"');
	i = 0;
	while (r[i]) { printf("%s\n", r[i]); free(r[i]); i++; }
	free(r);
	r = ft_split("", '"'"' '"'"');
	printf("%d\n", r[0] == NULL);
	free(r);
	r = ft_split("hello", '"'"'x'"'"');
	printf("%s\n", r[0]); free(r[0]);
	free(r);
}'
run_test "split_basic" "hello
world
foo
hello
world
1
hello"

# ============================================================
# PART 3 — LINKED LISTS
# ============================================================
print_header "PART 3 — ft_lstnew"

compile_test "lstnew_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	t_list *node;
	node = ft_lstnew("hello");
	if (!node) { printf("NULL\n"); return 1; }
	printf("%s\n", (char *)node->content);
	printf("%d\n", node->next == NULL);
	free(node);
	node = ft_lstnew(NULL);
	if (!node) { printf("NULL\n"); return 1; }
	printf("%d\n", node->content == NULL);
	printf("%d\n", node->next == NULL);
	free(node);
	node = ft_lstnew("");
	if (!node) { printf("NULL\n"); return 1; }
	printf("%d\n", node->content != NULL);
	free(node);
}'
run_test "lstnew_basic" "hello
1
1
1
1"

print_header "PART 3 — ft_lstadd_front"

compile_test "lstadd_front_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	t_list *second;
	t_list *first;
	t_list *lst;
	second = ft_lstnew("second");
	first = ft_lstnew("first");
	lst = second;
	ft_lstadd_front(&lst, first);
	printf("%s\n", (char *)lst->content);
	printf("%s\n", (char *)lst->next->content);
	printf("%d\n", lst->next->next == NULL);
	free(first);
	free(second);
}'
run_test "lstadd_front_basic" "first
second
1"

compile_test "lstadd_front_null" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	t_list *lst;
	t_list *node;
	lst = NULL;
	node = ft_lstnew("only");
	ft_lstadd_front(&lst, node);
	printf("%s\n", (char *)lst->content);
	printf("%d\n", lst->next == NULL);
	free(node);
}'
run_test "lstadd_front_null" "only
1"

compile_test "lstadd_front_multiple" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	t_list *lst;
	t_list *a;
	t_list *b;
	t_list *c;
	lst = NULL;
	a = ft_lstnew("a");
	b = ft_lstnew("b");
	c = ft_lstnew("c");
	ft_lstadd_front(&lst, a);
	ft_lstadd_front(&lst, b);
	ft_lstadd_front(&lst, c);
	printf("%s\n", (char *)lst->content);
	printf("%s\n", (char *)lst->next->content);
	printf("%s\n", (char *)lst->next->next->content);
	printf("%d\n", lst->next->next->next == NULL);
	free(a); free(b); free(c);
}'
run_test "lstadd_front_multiple" "c
b
a
1"

print_header "PART 3 — ft_lstsize"

compile_test "lstsize_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	t_list *a;
	t_list *b;
	t_list *c;
	a = ft_lstnew("a");
	b = ft_lstnew("b");
	c = ft_lstnew("c");
	a->next = b;
	b->next = c;
	printf("%d\n", ft_lstsize(a));
	printf("%d\n", ft_lstsize(NULL));
	printf("%d\n", ft_lstsize(b));
	printf("%d\n", ft_lstsize(c));
	free(a); free(b); free(c);
}'
run_test "lstsize_basic" "3
0
2
1"

print_header "PART 3 — ft_lstlast"

compile_test "lstlast_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	t_list *a;
	t_list *b;
	t_list *c;
	t_list *last;
	a = ft_lstnew("a");
	b = ft_lstnew("b");
	c = ft_lstnew("c");
	a->next = b;
	b->next = c;
	last = ft_lstlast(a);
	printf("%s\n", (char *)last->content);
	printf("%d\n", last->next == NULL);
	last = ft_lstlast(c);
	printf("%s\n", (char *)last->content);
	last = ft_lstlast(a->next);
	printf("%s\n", (char *)last->content);
	free(a); free(b); free(c);
}'
run_test "lstlast_basic" "c
1
c
c"

print_header "PART 3 — ft_lstadd_back"

compile_test "lstadd_back_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	t_list *lst;
	t_list *b;
	t_list *c;
	lst = ft_lstnew("first");
	b = ft_lstnew("second");
	c = ft_lstnew("third");
	ft_lstadd_back(&lst, b);
	ft_lstadd_back(&lst, c);
	printf("%s\n", (char *)lst->content);
	printf("%s\n", (char *)lst->next->content);
	printf("%s\n", (char *)lst->next->next->content);
	printf("%d\n", lst->next->next->next == NULL);
	free(lst); free(b); free(c);
}'
run_test "lstadd_back_basic" "first
second
third
1"

compile_test "lstadd_back_null" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
	t_list *lst;
	t_list *node;
	lst = NULL;
	node = ft_lstnew("only");
	ft_lstadd_back(&lst, node);
	printf("%s\n", (char *)lst->content);
	printf("%d\n", lst->next == NULL);
	free(node);
}'
run_test "lstadd_back_null" "only
1"

print_header "PART 3 — ft_lstdelone"

compile_test "lstdelone_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static void del(void *content) { (void)content; }
int main(void) {
	t_list *a;
	t_list *b;
	a = ft_lstnew("a");
	b = ft_lstnew("b");
	a->next = b;
	ft_lstdelone(a, del);
	printf("%s\n", (char *)b->content);
	printf("%d\n", b->next == NULL);
	free(b);
}'
run_test "lstdelone_basic" "b
1"

compile_test "lstdelone_del_called" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static int del_count = 0;
static void del(void *content) { (void)content; del_count++; }
int main(void) {
	t_list *a;
	a = ft_lstnew("x");
	ft_lstdelone(a, del);
	printf("%d\n", del_count);
}'
run_test "lstdelone_del_called" "1"

print_header "PART 3 — ft_lstclear"

compile_test "lstclear_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static void del(void *content) { (void)content; }
int main(void) {
	t_list *a;
	t_list *b;
	t_list *c;
	a = ft_lstnew("a");
	b = ft_lstnew("b");
	c = ft_lstnew("c");
	a->next = b;
	b->next = c;
	ft_lstclear(&a, del);
	printf("%d\n", a == NULL);
}'
run_test "lstclear_basic" "1"

compile_test "lstclear_null" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static void del(void *content) { (void)content; }
int main(void) {
	t_list *lst;
	lst = NULL;
	ft_lstclear(&lst, del);
	printf("%d\n", lst == NULL);
}'
run_test "lstclear_null" "1"

compile_test "lstclear_del_all" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static int del_count = 0;
static void del(void *content) { (void)content; del_count++; }
int main(void) {
	t_list *a;
	t_list *b;
	t_list *c;
	a = ft_lstnew("a");
	b = ft_lstnew("b");
	c = ft_lstnew("c");
	a->next = b;
	b->next = c;
	ft_lstclear(&a, del);
	printf("%d\n", del_count);
}'
run_test "lstclear_del_all" "3"

print_header "PART 3 — ft_lstiter"

compile_test "lstiter_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static void print_content(void *content) {
	printf("%s\n", (char *)content);
}
int main(void) {
	t_list *a;
	t_list *b;
	t_list *c;
	a = ft_lstnew("hello");
	b = ft_lstnew("world");
	c = ft_lstnew("42");
	a->next = b;
	b->next = c;
	ft_lstiter(a, print_content);
	free(a); free(b); free(c);
}'
run_test "lstiter_basic" "hello
world
42"

compile_test "lstiter_null" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static int count = 0;
static void counter(void *content) { (void)content; count++; }
int main(void) {
	ft_lstiter(NULL, counter);
	printf("%d\n", count);
}'
run_test "lstiter_null" "0"

print_header "PART 3 — ft_lstmap"

compile_test "lstmap_basic" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static void *dup_content(void *content) {
	return ft_strdup((char *)content);
}
static void del(void *content) { free(content); }
int main(void) {
	t_list *a;
	t_list *b;
	t_list *mapped;
	a = ft_lstnew("hello");
	b = ft_lstnew("world");
	a->next = b;
	mapped = ft_lstmap(a, dup_content, del);
	if (!mapped) { printf("NULL\n"); free(a); free(b); return 1; }
	printf("%s\n", (char *)mapped->content);
	printf("%s\n", (char *)mapped->next->content);
	printf("%d\n", mapped->next->next == NULL);
	printf("%d\n", mapped->content != a->content);
	ft_lstclear(&mapped, del);
	free(a); free(b);
}'
run_test "lstmap_basic" "hello
world
1
1"

compile_test "lstmap_null" '#include "libft.h"
#include <stdio.h>
#include <stdlib.h>
static void *dup_content(void *content) {
	return ft_strdup((char *)content);
}
static void del(void *content) { free(content); }
int main(void) {
	t_list *mapped;
	mapped = ft_lstmap(NULL, dup_content, del);
	printf("%d\n", mapped == NULL);
}'
run_test "lstmap_null" "1"

# Valgrind linked lists
if command -v valgrind &> /dev/null; then
	print_header "MEMORY LEAKS — Linked Lists"

	compile_test "valgrind_lstclear" '#include "libft.h"
#include <stdlib.h>
static void del(void *c) { (void)c; }
int main(void) {
	t_list *a = ft_lstnew("a");
	t_list *b = ft_lstnew("b");
	t_list *c = ft_lstnew("c");
	a->next = b; b->next = c;
	ft_lstclear(&a, del);
	return 0;
}'

	VALGRIND_OUT=$(valgrind --leak-check=full --error-exitcode=1 "$TMP_DIR/valgrind_lstclear" 2>&1)
	if [ $? -eq 0 ]; then
		print_test "ft_lstclear — sem leaks" "OK"
	else
		print_test "ft_lstclear — sem leaks" "KO" "memory leak — não estás a libertar todos os nós"
	fi

	compile_test "valgrind_lstmap" '#include "libft.h"
#include <stdlib.h>
static void *dup(void *c) { return ft_strdup((char *)c); }
static void del(void *c) { free(c); }
int main(void) {
	t_list *a = ft_lstnew("a");
	t_list *b = ft_lstnew("b");
	a->next = b;
	t_list *new = ft_lstmap(a, dup, del);
	ft_lstclear(&new, del);
	free(a); free(b);
	return 0;
}'

	VALGRIND_OUT=$(valgrind --leak-check=full --error-exitcode=1 "$TMP_DIR/valgrind_lstmap" 2>&1)
	if [ $? -eq 0 ]; then
		print_test "ft_lstmap — sem leaks" "OK"
	else
		print_test "ft_lstmap — sem leaks" "KO" "memory leak — verifica ft_lstmap e ft_lstclear"
	fi
fi

# ============================================================
# VALGRIND (se disponível)
# ============================================================
print_header "MEMORY LEAKS (Valgrind)"

if command -v valgrind &> /dev/null; then
	compile_test "valgrind_strdup" '#include "libft.h"
#include <stdlib.h>
int main(void) {
	char *s = ft_strdup("test");
	free(s);
	return 0;
}'

	VALGRIND_OUT=$(valgrind --leak-check=full --error-exitcode=1 "$TMP_DIR/valgrind_strdup" 2>&1)
	if [ $? -eq 0 ]; then
		print_test "ft_strdup — sem leaks" "OK"
	else
		print_test "ft_strdup — sem leaks" "KO" "memory leak detectado"
	fi

	compile_test "valgrind_split" '#include "libft.h"
#include <stdlib.h>
int main(void) {
	char **r = ft_split("hello world", '"'"' '"'"');
	int i = 0;
	while (r[i]) { free(r[i]); i++; }
	free(r);
	return 0;
}'

	VALGRIND_OUT=$(valgrind --leak-check=full --error-exitcode=1 "$TMP_DIR/valgrind_split" 2>&1)
	if [ $? -eq 0 ]; then
		print_test "ft_split — sem leaks" "OK"
	else
		print_test "ft_split — sem leaks" "KO" "memory leak detectado"
	fi
else
	print_test "Valgrind" "WARN" "valgrind não instalado — testa leaks manualmente"
fi

# ============================================================
# RESUMO FINAL
# ============================================================
echo ""
echo -e "${BOLD}${BLUE}============================================================${NC}"
echo -e "${BOLD}  RESUMO FINAL${NC}"
echo -e "${BOLD}${BLUE}============================================================${NC}"
echo -e "  ${GREEN}Passou:  $PASS${NC}"
echo -e "  ${RED}Falhou:  $FAIL${NC}"
echo -e "  ${YELLOW}Avisos:  $WARN${NC}"
TOTAL=$((PASS + FAIL))
echo -e "  Total:   $TOTAL testes"
echo ""
if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
	echo -e "${GREEN}${BOLD}  Tudo OK! Podes entregar com confiança.${NC}"
elif [ $FAIL -eq 0 ]; then
	echo -e "${YELLOW}${BOLD}  Sem falhas, mas há $WARN aviso(s) para verificar.${NC}"
else
	echo -e "${RED}${BOLD}  Há $FAIL teste(s) a falhar. Corrige antes de entregar.${NC}"
	echo ""
	echo -e "${BOLD}  Causas mais comuns de falha:${NC}"
	echo -e "  • Função não implementada → erro de compilação 'undefined reference'"
	echo -e "  • Função não declarada no header → 'implicit declaration'"
	echo -e "  • Lógica errada → output diferente do esperado"
	echo -e "  • Loop infinito → TIMEOUT"
	echo -e "  • Acesso a ponteiro NULL → SEGFAULT"
fi
echo ""

# Limpeza
rm -rf "$TMP_DIR"
