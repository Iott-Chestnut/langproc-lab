%option noyywrap
%option debug

%{
#include "nocomment.hpp"
#include <cstdio>
#include <cstdlib>

extern "C" int fileno(FILE *stream);

static int removed_count = 0;
static bool inside_attribute = false;

static char last_printed_char = '\n';

static void print_text(const char* text) {
    for (; *text; text++) {
        putchar(*text);
        last_printed_char = *text;
    }
}

static void print_char(char c) {
    putchar(c);
    last_printed_char = c;
}
%}

%x COMMENT

%%

^[ \t]*"//"[^\n]*\n {
    if (!inside_attribute) {
        removed_count++;
    }
}

^[ \t]*"//"[^\n]*$ {
    if (!inside_attribute) {
        removed_count++;
    }
}

"//"[^\n]*\n {
    if (!inside_attribute) {
        removed_count++;
    }
    if (last_printed_char != ' ' && last_printed_char != '\n') {
        print_char(' ');
    }
}

"//"[^\n]* {
    if (!inside_attribute) {
        removed_count++;
    }
}

"\\"[^ \t\n]* {
    print_text(yytext);
}

"\(\*" {
    inside_attribute = true;
    BEGIN(COMMENT);
}

<COMMENT>"//"[^\n]*\n {
}

<COMMENT>"//"[^\n]*$ {
}

<COMMENT>"\\"[^\t\n]* {
}

<COMMENT>"*\)" {
    removed_count++;
    inside_attribute = false;
    BEGIN(INITIAL);
}

<COMMENT>.|\n {
}

"(" {
    print_char('(');
}

")" {
    print_char(')');
}

"*" {
    print_char('*');
}

"/" {
    print_char('/');
}

[^/\\()\n]+ {
    print_text(yytext);
}

"\n" {
    print_char('\n');
}

<<EOF>> {
    printf("Number of comments and attributes removed: %d.\n", removed_count);
    yyterminate();
}

%%

void yyerror(const char *s)
{
    fprintf(stderr, "Flex Error: %s\n", s);
    exit(1);
}
