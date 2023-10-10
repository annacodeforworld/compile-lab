%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define YYSTYPE char*
// 重新定义YYSTYPE

int yylex();
extern int yyparse();
extern YYSTYPE yylval;  
FILE* yyin;
void yyerror(const char* s);

%}

%token ADD MINUS MUL DIV LEFT_BR RIGHT_BR ID
//说明结合性
%left ADD MINUS
%left MUL DIV
%right UMINUS

%%

lines   :       lines expr ';' { printf("Result: %s\n", $2); }
        |       lines ';'
        |
        ;

expr    :       expr ADD expr   { $$ = (char*)malloc(100 * sizeof(char)); sprintf($$, "%s %s +", $1, $3);} // a+b _ ab+
        |       expr MINUS expr { $$ = (char*)malloc(100 * sizeof(char)); sprintf($$, "%s %s -", $1, $3);} // a-b _ ab-
        |       expr MUL expr   { $$ = (char*)malloc(100 * sizeof(char)); sprintf($$, "%s %s *", $1, $3);} // a*b _ ab*
        |       expr DIV expr   { $$ = (char*)malloc(100 * sizeof(char)); sprintf($$, "%s %s /", $1, $3);} // a/b _ ab/
        |       LEFT_BR expr RIGHT_BR { $$ = (char*)malloc(100 * sizeof(char)); strcpy($$, $2); } // 括号(a)
        |       ID { $$ = (char*)malloc(100 * sizeof(char)); sprintf($$, "%s", $1); } //标识符代表的值
        |       MINUS expr %prec UMINUS { $$ = (char*)malloc(100 * sizeof(char)); sprintf($$, "%s -", $2); } // 负号-a a-
        ;

%%

int yylex() {
    int t;
    while (1) {
        t = getchar();
        if (t == ' ' || t == '\t' || t == '\n') {
            // 忽略空白符号，存在问题！
        } else if (isalpha(t)) {
            // 识别数字或字母
            char buffer[100];
            int index = 0;
            while (isalnum(t)) {
                buffer[index++] = t;
                t = getchar();
            }
            buffer[index] = '\0';
            ungetc(t, stdin);//读入的最后一个字符放回输入流
            yylval = strdup(buffer);
            return ID;
        } else if (isdigit(t)) {
            // 识别数字或字母
            char buffer[100];
            int index = 0;
            while (isdigit(t)) {
                buffer[index++] = t;
                t = getchar();
            }
            buffer[index] = '\0';
            ungetc(t, stdin);//读入的最后一个字符放回输入流
            yylval = strdup(buffer);
            return ID;
        }else if (t == '+') {
            return ADD;
        } else if (t == '-') {
            return MINUS;
        } else if (t == '*') {
            return MUL;
        } else if (t == '/') {
            return DIV;
        } else if (t == '(') {
            return LEFT_BR;
        } else if (t == ')') {
            return RIGHT_BR;
        } else {
            return t;
        }
    }
}


int main(void) {
    yyin = stdin;
    do {
        yyparse();
    } while (!feof(yyin));
    return 0;
}

void yyerror(const char* s) {
    fprintf(stderr, "Parse error: %s\n", s);
    exit(1);
}


