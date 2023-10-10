%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

typedef struct newtype{
    double val; // 存储变量的数值
    char* idname;  // 存储变量的标识符名字
}tty;

#define YYSTYPE tty
// 重新定义YYSTYPE

int yylex();
extern int yyparse();
extern YYSTYPE yylval;  
FILE* yyin;
void yyerror(const char* s);
double mysearch(char *name);
void myinsert(char *name, double value);

%}

%token ADD MINUS MUL DIV LEFT_BR RIGHT_BR NUMBER ID ASSIGN
//说明结合性
%left ADD MINUS
%left MUL DIV
%right UMINUS

%%

lines   :       lines expr ';' { printf("%f\n", $2.val); }
        |       lines ';'
        |
        ;

expr    :       expr ADD expr   { $$.val = $1.val + $3.val; } // 加法 a+b
        |       expr MINUS expr { $$.val = $1.val - $3.val; } // 减法a-b
        |       expr MUL expr   { $$.val = $1.val * $3.val; } // 乘法a*b
        |       expr DIV expr   { if($3.val==0) yyerror("can't be 0"); $$.val = $1.val / $3.val; } // 除法a/b
        |       LEFT_BR expr RIGHT_BR { $$.val = $2.val; } // 括号(a)
        |       NUMBER  { $$.val = $1.val; } //数值
        |       ID { $$.val = mysearch($1.idname); } //标识符代表的值
        |       MINUS expr %prec UMINUS { $$.val = -$2.val; } // 负号-a
        |       ID ASSIGN expr { myinsert($1.idname, $3.val); $$.val = $3.val; } //赋值a=expr
        ;

%%

#define MAXN 1001

tty symtab[MAXN];
//定义能容纳1001个标识符的符号表

int cnt=0;
//当前使用多少个符号

double mysearch(char *idname) {
    for (int i=0; i<cnt; i++) {
        if (strcmp(symtab[i].idname, idname) == 0) {
            return symtab[i].val;
        }//找到这个符号 返回它的值
    }
    yyerror("Variable not found");//没找到 使用yyerror报错
    return 0.00;
}   

void myinsert(char *idname, double val) {
    for (int i=0; i<cnt; i++) {
        if (strcmp(symtab[i].idname, idname) == 0) {
            symtab[i].val = val;
            return;
        }//存在这个符号，直接重新覆盖原来的值
    }
    if (cnt == MAXN) {
        yyerror("Symbol table has already been full");//符号表无空间
    }
    symtab[cnt].idname = (char*)malloc(100 * sizeof(char));
    strcpy(symtab[cnt].idname, idname);
    symtab[cnt].val = val;
    cnt++;
}

int yylex() {
    char t;
    while (1) {
        t = getchar();
        if (t == ' ' || t == '\t' || t == '\n') {
            // 忽略空白符号，存在问题！
        } else if (isdigit(t)) {
            // 识别数字
            ungetc(t, stdin);//读入的最后一个字符放回输入流
            double number;
            scanf("%lf", &number);
            yylval.val = number;
            return NUMBER;
        } else if (t == '+') {
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
        } else if (isalpha(t)) {
            // 识别数字或字母
            char s[100];
            int len = 0;
            while (isalnum(t)) {
                s[len++] = t;
                t = getchar();
            }
            s[len] = '\0';
            ungetc(t, stdin);//读入的最后一个字符放回输入流
            yylval.idname = (char*)malloc(100 * sizeof(char));
            strcpy(yylval.idname, s);
            return ID;
        } else if (t == '=') {
            return ASSIGN;
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


