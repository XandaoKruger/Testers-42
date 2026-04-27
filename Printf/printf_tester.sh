#!/bin/bash

# ============================================================
# FT_PRINTF TESTER — Fiel à Moulinette da 42
# Compara ft_printf com o printf original em todos os casos
# Uso: bash printf_tester.sh [caminho_para_ft_printf]
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

PASS=0
FAIL=0
WARN=0

PRINTF_PATH="${1:-.}"
PRINTF_H="$PRINTF_PATH/ft_printf.h"
PRINTF_A="$PRINTF_PATH/libftprintf.a"
TMP_DIR="/tmp/printf_tester_$$"

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

# Compila um teste com printf real e ft_printf e compara output + retorno
run_comparison() {
	local name="$1"
	local code="$2"

	# Versão com printf real
	cat > "$TMP_DIR/${name}_real.c" << EOF
#include <stdio.h>
#include <limits.h>
int main(void) {
	int ret;
	$code
	return 0;
}
EOF

	# Versão com ft_printf
	cat > "$TMP_DIR/${name}_ft.c" << EOF
#include "ft_printf.h"
#include <limits.h>
int main(void) {
	int ret;
	$(echo "$code" | sed 's/\bprintf\b/ft_printf/g')
	return 0;
}
EOF

	cc -o "$TMP_DIR/${name}_real" "$TMP_DIR/${name}_real.c" 2>"$TMP_DIR/${name}_real.err"
	if [ $? -ne 0 ]; then
		print_test "$name" "WARN" "erro a compilar o teste de referência"
		return
	fi

	cc -o "$TMP_DIR/${name}_ft" "$TMP_DIR/${name}_ft.c" "$PRINTF_A" -I"$PRINTF_PATH" 2>"$TMP_DIR/${name}_ft.err"
	if [ $? -ne 0 ]; then
		local err
		err=$(cat "$TMP_DIR/${name}_ft.err")
		local reason=""
		if echo "$err" | grep -q "undefined reference"; then
			local missing
			missing=$(echo "$err" | grep "undefined reference" | sed "s/.*\`\(.*\)'.*/\1/" | sort -u | tr '\n' ' ')
			reason="função não implementada: $missing"
		elif echo "$err" | grep -q "implicit declaration"; then
			reason="função não declarada no header ft_printf.h"
		else
			reason=$(echo "$err" | grep "error:" | head -1 | sed 's/.*error: //')
		fi
		print_test "$name" "KO" "não compilou — $reason"
		return
	fi

	local out_real out_ft
	out_real=$(timeout 5 "$TMP_DIR/${name}_real" 2>/dev/null)
	local exit_real=$?
	out_ft=$(timeout 5 "$TMP_DIR/${name}_ft" 2>/dev/null)
	local exit_ft=$?

	if [ $exit_real -eq 124 ] || [ $exit_ft -eq 124 ]; then
		print_test "$name" "KO" "TIMEOUT — loop infinito?"
		return
	fi
	if [ $exit_ft -eq 139 ]; then
		print_test "$name" "KO" "SEGFAULT — acesso inválido à memória"
		return
	fi
	if [ $exit_ft -eq 134 ]; then
		print_test "$name" "KO" "ABORT — double free ou heap corruption"
		return
	fi

	if [ "$out_real" = "$out_ft" ]; then
		print_test "$name" "OK"
	else
		# Mostra a primeira diferença
		local line_num=1
		local found=0
		while IFS= read -r exp_line; do
			got_line=$(echo "$out_ft" | sed -n "${line_num}p")
			if [ "$exp_line" != "$got_line" ]; then
				print_test "$name" "KO" "linha $line_num — esperado='$exp_line' obtido='$got_line'"
				found=1
				break
			fi
			((line_num++))
		done <<< "$out_real"
		if [ $found -eq 0 ]; then
			local exp_lines got_lines
			exp_lines=$(echo "$out_real" | wc -l)
			got_lines=$(echo "$out_ft" | wc -l)
			print_test "$name" "KO" "número de linhas diferente — esperado $exp_lines obtido $got_lines"
		fi
	fi
}

# ============================================================
# 1. ESTRUTURA DO PROJECTO
# ============================================================
print_header "ESTRUTURA DO PROJECTO"

if [ -f "$PRINTF_H" ]; then
	print_test "ft_printf.h existe" "OK"
else
	print_test "ft_printf.h existe" "KO" "ficheiro não encontrado"
fi

if grep -q "ft_printf" "$PRINTF_H" 2>/dev/null; then
	print_test "ft_printf.h contém protótipo" "OK"
else
	print_test "ft_printf.h contém protótipo" "KO" "protótipo de ft_printf não encontrado no header"
fi

if [ -f "$PRINTF_PATH/Makefile" ]; then
	print_test "Makefile existe" "OK"
	for rule in "all" "clean" "fclean" "re" "NAME"; do
		if grep -q "$rule" "$PRINTF_PATH/Makefile"; then
			print_test "Makefile tem regra: $rule" "OK"
		else
			print_test "Makefile tem regra: $rule" "KO" "regra '$rule' não encontrada"
		fi
	done
	if grep -q "ar" "$PRINTF_PATH/Makefile"; then
		print_test "Makefile usa ar (não libtool)" "OK"
	else
		print_test "Makefile usa ar (não libtool)" "KO" "ar não encontrado"
	fi
	if grep -q "\-Wall" "$PRINTF_PATH/Makefile" && grep -q "\-Wextra" "$PRINTF_PATH/Makefile" && grep -q "\-Werror" "$PRINTF_PATH/Makefile"; then
		print_test "Makefile tem flags -Wall -Wextra -Werror" "OK"
	else
		print_test "Makefile tem flags -Wall -Wextra -Werror" "KO" "flags em falta"
	fi
else
	print_test "Makefile existe" "KO" "não encontrado"
fi

# ============================================================
# 2. NORMINETTE
# ============================================================
print_header "NORMINETTE"

if command -v norminette &> /dev/null; then
	NORM_OUTPUT=$(norminette "$PRINTF_PATH"/*.c "$PRINTF_PATH"/*.h 2>&1)
	NORM_ERRORS=$(echo "$NORM_OUTPUT" | grep -c "Error")
	if [ "$NORM_ERRORS" -eq 0 ]; then
		print_test "Norminette — sem erros" "OK"
	else
		print_test "Norminette — $NORM_ERRORS erro(s)" "KO" "detalhes abaixo"
		echo ""
		echo "$NORM_OUTPUT" | grep -A1 "Error" | grep -v "^--$" | sed 's/^/    /'
		echo ""
	fi
else
	print_test "Norminette" "WARN" "não instalada — verifica manualmente"
fi

# ============================================================
# 3. COMPILAÇÃO
# ============================================================
print_header "COMPILAÇÃO"

cd "$PRINTF_PATH" || exit 1
make fclean > /dev/null 2>&1
MAKE_OUTPUT=$(make 2>&1)
MAKE_EXIT=$?

if [ $MAKE_EXIT -eq 0 ]; then
	print_test "make — compila sem erros" "OK"
else
	print_test "make — compila sem erros" "KO" "erro de compilação"
	echo ""
	echo -e "${RED}  Detalhes:${NC}"
	echo "$MAKE_OUTPUT" | grep -E "error:|undefined" | head -10 | sed 's/^/    /'
	echo ""
	echo -e "${RED}  Não é possível continuar sem compilar.${NC}"
	exit 1
fi

if [ -f "libftprintf.a" ]; then
	print_test "libftprintf.a gerado" "OK"
else
	print_test "libftprintf.a gerado" "KO" "libftprintf.a não encontrado — o NAME no Makefile está correcto?"
	exit 1
fi

make clean > /dev/null 2>&1
if [ -f "libftprintf.a" ]; then
	print_test "make clean não apaga libftprintf.a" "OK"
else
	print_test "make clean não apaga libftprintf.a" "KO" "a biblioteca foi apagada pelo clean"
fi

make fclean > /dev/null 2>&1
if [ ! -f "libftprintf.a" ]; then
	print_test "make fclean apaga libftprintf.a" "OK"
else
	print_test "make fclean apaga libftprintf.a" "KO" "a biblioteca não foi apagada pelo fclean"
fi

make > /dev/null 2>&1
cd - > /dev/null || exit 1

# ============================================================
# 4. TESTES %c
# ============================================================
print_header "CONVERSÃO %c"

run_comparison "c_basic" \
	'ret = printf("%c\n", '"'"'A'"'"'); printf("ret=%d\n", ret);'

run_comparison "c_lowercase" \
	'ret = printf("%c\n", '"'"'z'"'"'); printf("ret=%d\n", ret);'

run_comparison "c_digit" \
	'ret = printf("%c\n", '"'"'5'"'"'); printf("ret=%d\n", ret);'

run_comparison "c_space" \
	'ret = printf("%c\n", '"'"' '"'"'); printf("ret=%d\n", ret);'

run_comparison "c_newline" \
	'ret = printf("%c", '"'"'\n'"'"'); printf("ret=%d\n", ret);'

run_comparison "c_multiple" \
	'ret = printf("%c%c%c\n", '"'"'4'"'"', '"'"'2'"'"', '"'"'!'"'"'); printf("ret=%d\n", ret);'

run_comparison "c_zero" \
	'ret = printf("%c\n", 65); printf("ret=%d\n", ret);'

# ============================================================
# 5. TESTES %s
# ============================================================
print_header "CONVERSÃO %s"

run_comparison "s_basic" \
	'ret = printf("%s\n", "hello"); printf("ret=%d\n", ret);'

run_comparison "s_empty" \
	'ret = printf("%s\n", ""); printf("ret=%d\n", ret);'

run_comparison "s_null" \
	'ret = printf("%s\n", (char *)NULL); printf("ret=%d\n", ret);'

run_comparison "s_multiple" \
	'ret = printf("%s %s\n", "hello", "world"); printf("ret=%d\n", ret);'

run_comparison "s_long" \
	'ret = printf("%s\n", "abcdefghijklmnopqrstuvwxyz"); printf("ret=%d\n", ret);'

run_comparison "s_special_chars" \
	'ret = printf("%s\n", "hello\tworld"); printf("ret=%d\n", ret);'

# ============================================================
# 6. TESTES %%
# ============================================================
print_header "CONVERSÃO %%"

run_comparison "percent_basic" \
	'ret = printf("%%\n"); printf("ret=%d\n", ret);'

run_comparison "percent_between" \
	'ret = printf("100%%\n"); printf("ret=%d\n", ret);'

run_comparison "percent_multiple" \
	'ret = printf("%%%% \n"); printf("ret=%d\n", ret);'

# ============================================================
# 7. TESTES %d e %i
# ============================================================
print_header "CONVERSÃO %d e %i"

run_comparison "d_zero" \
	'ret = printf("%d\n", 0); printf("ret=%d\n", ret);'

run_comparison "d_positive" \
	'ret = printf("%d\n", 42); printf("ret=%d\n", ret);'

run_comparison "d_negative" \
	'ret = printf("%d\n", -42); printf("ret=%d\n", ret);'

run_comparison "d_int_max" \
	'ret = printf("%d\n", INT_MAX); printf("ret=%d\n", ret);'

run_comparison "d_int_min" \
	'ret = printf("%d\n", INT_MIN); printf("ret=%d\n", ret);'

run_comparison "d_multiple" \
	'ret = printf("%d %d %d\n", 1, -2, 3); printf("ret=%d\n", ret);'

run_comparison "i_zero" \
	'ret = printf("%i\n", 0); printf("ret=%d\n", ret);'

run_comparison "i_positive" \
	'ret = printf("%i\n", 42); printf("ret=%d\n", ret);'

run_comparison "i_negative" \
	'ret = printf("%i\n", -42); printf("ret=%d\n", ret);'

run_comparison "i_int_min" \
	'ret = printf("%i\n", INT_MIN); printf("ret=%d\n", ret);'

run_comparison "d_and_i_mixed" \
	'ret = printf("%d %i\n", -100, 100); printf("ret=%d\n", ret);'

# ============================================================
# 8. TESTES %u
# ============================================================
print_header "CONVERSÃO %u"

run_comparison "u_zero" \
	'ret = printf("%u\n", 0); printf("ret=%d\n", ret);'

run_comparison "u_basic" \
	'ret = printf("%u\n", 42); printf("ret=%d\n", ret);'

run_comparison "u_large" \
	'ret = printf("%u\n", 4294967295U); printf("ret=%d\n", ret);'

run_comparison "u_int_max" \
	'ret = printf("%u\n", (unsigned int)INT_MAX); printf("ret=%d\n", ret);'

run_comparison "u_negative_cast" \
	'ret = printf("%u\n", (unsigned int)-1); printf("ret=%d\n", ret);'

run_comparison "u_multiple" \
	'ret = printf("%u %u\n", 0, 4294967295U); printf("ret=%d\n", ret);'

# ============================================================
# 9. TESTES %x e %X
# ============================================================
print_header "CONVERSÃO %x e %X"

run_comparison "x_zero" \
	'ret = printf("%x\n", 0); printf("ret=%d\n", ret);'

run_comparison "x_basic" \
	'ret = printf("%x\n", 255); printf("ret=%d\n", ret);'

run_comparison "x_large" \
	'ret = printf("%x\n", 4294967295U); printf("ret=%d\n", ret);'

run_comparison "x_letters" \
	'ret = printf("%x\n", 0xdeadbeef); printf("ret=%d\n", ret);'

run_comparison "x_int_max" \
	'ret = printf("%x\n", INT_MAX); printf("ret=%d\n", ret);'

run_comparison "X_zero" \
	'ret = printf("%X\n", 0); printf("ret=%d\n", ret);'

run_comparison "X_basic" \
	'ret = printf("%X\n", 255); printf("ret=%d\n", ret);'

run_comparison "X_letters" \
	'ret = printf("%X\n", 0xdeadbeef); printf("ret=%d\n", ret);'

run_comparison "X_large" \
	'ret = printf("%X\n", 4294967295U); printf("ret=%d\n", ret);'

run_comparison "x_X_mixed" \
	'ret = printf("%x %X\n", 255, 255); printf("ret=%d\n", ret);'

run_comparison "x_negative_cast" \
	'ret = printf("%x\n", (unsigned int)-1); printf("ret=%d\n", ret);'

# Testa só o formato de %p — endereços mudam entre processos
run_ptr_test() {
	local name="$1"
	local code="$2"

	cat > "$TMP_DIR/${name}_ft.c" << EOF
#include "ft_printf.h"
#include <limits.h>
int main(void) {
	int ret;
	$code
	return 0;
}
EOF

	cc -o "$TMP_DIR/${name}_ft" "$TMP_DIR/${name}_ft.c" "$PRINTF_A" -I"$PRINTF_PATH" 2>"$TMP_DIR/${name}_ft.err"
	if [ $? -ne 0 ]; then
		local err reason
		err=$(cat "$TMP_DIR/${name}_ft.err")
		if echo "$err" | grep -q "undefined reference"; then
			local missing
			missing=$(echo "$err" | grep "undefined reference" | sed "s/.*\`\(.*\)'.*/\1/" | sort -u | tr '\n' ' ')
			reason="função não implementada: $missing"
		else
			reason=$(echo "$err" | grep "error:" | head -1 | sed 's/.*error: //')
		fi
		print_test "$name" "KO" "não compilou — $reason"
		return
	fi

	local out_ft
	out_ft=$(timeout 5 "$TMP_DIR/${name}_ft" 2>/dev/null)
	local exit_ft=$?

	if [ $exit_ft -eq 124 ]; then
		print_test "$name" "KO" "TIMEOUT"
		return
	fi
	if [ $exit_ft -eq 139 ]; then
		print_test "$name" "KO" "SEGFAULT"
		return
	fi

	# Verifica formato: cada linha com ponteiro deve começar com 0x seguido de hex
	local bad=0
	local detail=""
	while IFS= read -r line; do
		# Extrai cada token que deveria ser um ponteiro (começa com 0x ou é (nil))
		for token in $line; do
			if echo "$token" | grep -qE "^0x[0-9a-f]+$"; then
				: # formato correcto
			elif [ "$token" = "(nil)" ]; then
				: # nil correcto
			elif echo "$token" | grep -qE "^ret=[0-9]+$"; then
				: # linha de retorno, ignorar
			elif echo "$token" | grep -qE "^[0-9]+$"; then
				: # número puro, ignorar
			else
				# Verifica se parece um ponteiro mal formatado
				if echo "$token" | grep -qiE "^(0X|[0-9a-fA-F]+)"; then
					bad=1
					detail="formato errado: '$token' — deve ser '0x' minúsculo seguido de hex"
				fi
			fi
		done
	done <<< "$out_ft"

	if [ $bad -eq 0 ]; then
		print_test "$name" "OK"
	else
		print_test "$name" "KO" "$detail"
	fi
}

# ============================================================
# 10. TESTES %p
# ============================================================
print_header "CONVERSÃO %p"

run_comparison "p_null" \
	'ret = printf("%p\n", (void *)NULL); printf("ret=%d\n", ret);'

run_ptr_test "p_basic" \
	'int x = 42; ret = ft_printf("%p\n", (void *)&x); ft_printf("ret=%d\n", ret);'

run_ptr_test "p_string" \
	'char *s = "hello"; ret = ft_printf("%p\n", (void *)s); ft_printf("ret=%d\n", ret);'

run_ptr_test "p_multiple" \
	'int a = 1; int b = 2; ret = ft_printf("%p %p\n", (void *)&a, (void *)&b); ft_printf("ret=%d\n", ret);'

run_ptr_test "p_format_0x_prefix" \
	'int x = 1; ft_printf("%p\n", (void *)&x);'

run_ptr_test "p_format_lowercase_hex" \
	'void *p = (void *)0xABCDEF; ft_printf("%p\n", p);'

# ============================================================
# 11. TESTES MIXED — vários especificadores juntos
# ============================================================
print_header "TESTES MIXED"

run_comparison "mixed_all" \
	'ret = printf("%c %s %d %i %u %x %X %%\n", '"'"'A'"'"', "hello", 42, -42, 100U, 255, 255); printf("ret=%d\n", ret);'

run_comparison "mixed_no_specifier" \
	'ret = printf("hello world\n"); printf("ret=%d\n", ret);'

run_comparison "mixed_only_newline" \
	'ret = printf("\n"); printf("ret=%d\n", ret);'

run_comparison "mixed_numbers" \
	'ret = printf("%d + %d = %d\n", 21, 21, 42); printf("ret=%d\n", ret);'

run_comparison "mixed_adjacent_specifiers" \
	'ret = printf("%d%d%d\n", 1, 2, 3); printf("ret=%d\n", ret);'

run_comparison "mixed_percent_in_string" \
	'ret = printf("100%% done: %d items\n", 42); printf("ret=%d\n", ret);'

run_comparison "mixed_zero_values" \
	'ret = printf("%d %u %x %X\n", 0, 0, 0, 0); printf("ret=%d\n", ret);'

run_comparison "mixed_extremes" \
	'ret = printf("%d %d %u\n", INT_MAX, INT_MIN, 4294967295U); printf("ret=%d\n", ret);'

# ============================================================
# 12. TESTES DE RETORNO
# ============================================================
print_header "VALOR DE RETORNO"

run_comparison "ret_char" \
	'ret = printf("%c", '"'"'A'"'"'); printf("\n%d\n", ret);'

run_comparison "ret_string" \
	'ret = printf("%s", "hello"); printf("\n%d\n", ret);'

run_comparison "ret_int" \
	'ret = printf("%d", 42); printf("\n%d\n", ret);'

run_comparison "ret_negative" \
	'ret = printf("%d", -42); printf("\n%d\n", ret);'

run_comparison "ret_mixed" \
	'ret = printf("hello %d world", 42); printf("\n%d\n", ret);'

run_comparison "ret_percent" \
	'ret = printf("%%"); printf("\n%d\n", ret);'

run_comparison "ret_empty_string" \
	'ret = printf("%s", ""); printf("%d\n", ret);'

run_comparison "ret_hex" \
	'ret = printf("%x", 255); printf("\n%d\n", ret);'

run_comparison "ret_pointer" \
	'void *p = (void*)0x1; printf("%p", p); ret = printf("%p", p); printf("\n%d\n", ret);'

# ============================================================
# 13. EDGE CASES
# ============================================================
print_header "EDGE CASES"

run_comparison "edge_int_min_d" \
	'ret = printf("%d\n", -2147483648); printf("ret=%d\n", ret);'

run_comparison "edge_int_min_i" \
	'ret = printf("%i\n", -2147483648); printf("ret=%d\n", ret);'

run_comparison "edge_uint_max" \
	'ret = printf("%u\n", 4294967295U); printf("ret=%d\n", ret);'

run_comparison "edge_hex_max" \
	'ret = printf("%x\n", 4294967295U); printf("ret=%d\n", ret);'

run_comparison "edge_HEX_max" \
	'ret = printf("%X\n", 4294967295U); printf("ret=%d\n", ret);'

run_comparison "edge_multiple_percent" \
	'ret = printf("%%%%\n"); printf("ret=%d\n", ret);'

run_comparison "edge_char_127" \
	'ret = printf("%c\n", 127); printf("ret=%d\n", ret);'

run_comparison "edge_char_1" \
	'ret = printf("%c\n", 1); printf("ret=%d\n", ret);'

run_comparison "edge_zero_hex" \
	'ret = printf("%x %X\n", 0, 0); printf("ret=%d\n", ret);'

run_comparison "edge_long_string" \
	'ret = printf("%s\n", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"); printf("ret=%d\n", ret);'

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
	echo -e "${GREEN}${BOLD}  Tudo OK! ${NC}"
elif [ $FAIL -eq 0 ]; then
	echo -e "${YELLOW}${BOLD}  Sem falhas mas há $WARN aviso(s) a verificar.${NC}"
else
	echo -e "${RED}${BOLD}  Há $FAIL teste(s) a falhar. Corrige antes de entregar.${NC}"
	echo ""
	echo -e "${BOLD}  Guia de erros:${NC}"
	echo -e "  ${RED}não compilou — função não implementada${NC}"
	echo -e "    → o ficheiro .c existe mas a função não está no Makefile"
	echo -e "    → ou a função simplesmente não foi implementada ainda"
	echo ""
	echo -e "  ${RED}não compilou — função não declarada no header${NC}"
	echo -e "    → falta o protótipo em ft_printf.h"
	echo ""
	echo -e "  ${RED}TIMEOUT (>5s)${NC}"
	echo -e "    → loop infinito — verifica o loop principal que percorre a format string"
	echo ""
	echo -e "  ${RED}SEGFAULT${NC}"
	echo -e "    → acesso a NULL — verifica se tratas %s e %p com NULL"
	echo -e "    → ou va_arg com tipo errado"
	echo ""
	echo -e "  ${RED}linha N errada — esperado='X' obtido='Y'${NC}"
	echo -e "    → output diferente do printf real — causas comuns:"
	echo -e "      %d/%i → não tratas INT_MIN? usa long antes de inverter sinal"
	echo -e "      %u    → cast para unsigned int antes de imprimir"
	echo -e "      %x/%X → mix de maiúsculas/minúsculas nos dígitos hex"
	echo -e "      %p    → prefixo 0x em minúscula obrigatório"
	echo -e "      %%    → deves imprimir só um % e retornar 1"
	echo -e "      ret=N → contagem de caracteres errada — cada write conta"
	echo ""
	echo -e "  ${RED}número de linhas errado${NC}"
	echo -e "    → a função imprime mais ou menos do que devia"
	echo -e "    → verifica se adicionas \\n quando não deves, ou vice-versa"
fi
echo ""

rm -rf "$TMP_DIR"
