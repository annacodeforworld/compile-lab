%option noyywrap
%{
    #define YY_NO_UNPUT
    #define YY_NO_INPUT

    #include "parser.h"
    #include <ostream>
    #include <fstream>
    #include <string>
    #include <math.h>
    #include <vector>
    #include <iostream>
    #include <iomanip>
    using namespace std;

    extern FILE *yyin; 
    extern FILE *yyout;
    bool dump_tokens = false;

    string formatWidth(const std::string& input, int width){
        ostringstream oss;
        oss << left << setw(width) << setfill(' ') << input;
        return oss.str();
    }
    void print2file(string s1, string s2, string s3, string s4, string s5=""){
        string printInfo = formatWidth(s1,20) + formatWidth(s2,20) + formatWidth(s3,20) + formatWidth(s4,20) + formatWidth(s5,20) + "\n";
        fputs(printInfo.c_str(), yyout);
    }
%}
%{
    int columnNumber = 0;
%}

DECIMIAL ([1-9][0-9]*|0)
HEX (0(x|X)[1-9|A-F|a-f][0-9|A-F|a-f]*|0x0|0X0)
OCT (0[1-7][0-7]*|00)
ID [[:alpha:]_][[:alpha:][:digit:]_]*
CHARACTER ('.')
EOL (\r\n|\n|\r)
WHITE [\t ]

LINECOMMENT \/\/[^\n]*
COMMENTBEIGN "/*"
COMMENTELEMENT .
COMMENTLINE (\r\n|\n|\r)
COMMENTEND "*/"
%x BLOCKCOMMENT

%%

{LINECOMMENT}

{COMMENTBEIGN} {BEGIN BLOCKCOMMENT;}
<BLOCKCOMMENT>{COMMENTELEMENT} {}
<BLOCKCOMMENT>{COMMENTLINE} {yylineno++;}
<BLOCKCOMMENT>{COMMENTEND} {BEGIN INITIAL;}

"int" {
    if(dump_tokens)
        print2file("INT","int",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return INT;
}
"void" {
    if(dump_tokens)
        print2file("CHAR","char",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return VOID;
}
"char" {
    if(dump_tokens)
        print2file("CHAR","char",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return CHAR;
}
"if" {
    if(dump_tokens)
        print2file("IF","if",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return IF;
};
"else" {
    if(dump_tokens)
        print2file("ELSE","else",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return ELSE;
};
"return" {
    if(dump_tokens)
        print2file("RETURN","return",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return RETURN;
}

"while" {
    if(dump_tokens)
        print2file("WHILE","while",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return WHILE;
}

"break" {
    if(dump_tokens)
        print2file("BREAK","break",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return BREAK;
}

"continue" {
    if(dump_tokens)
        print2file("CONTINUE","continue",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return CONTINUE;
}

"const" {
    if(dump_tokens)
        print2file("CONST","const",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return CONST;
}
"==" {
    if(dump_tokens)
        print2file("EQUAL","==",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return EQUAL;
}
"=" {
    if(dump_tokens)
        print2file("ASSIGN","=",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return ASSIGN;
}
">=" {
    if(dump_tokens)
        print2file("MOREEQUAL",">=",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return MOREEQUAL;
}
"<=" {
    if(dump_tokens)
        print2file("LESSEQUAL","<=",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return LESSEQUAL;
}
"!=" {
    if(dump_tokens)
        print2file("NOEQUAL","!=",to_string(yylineno),to_string(columnNumber)); 
    columnNumber += yyleng;
    return NOEQUAL;
}
"<" {
    if(dump_tokens)
        print2file("LESS","<",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return LESS;
}
">" {
    if(dump_tokens)
        print2file("MORE",">",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return MORE;
}
"!" {
    if(dump_tokens)
        print2file("EXCLAMATION","!",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return EXCLAMATION;
}
"+" {
    if(dump_tokens)
        print2file("ADD","+",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return ADD;
}
"-" {
    if(dump_tokens)
        print2file("SUB","-",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return SUB;
}
"*" {
    if(dump_tokens)
        print2file("MUL","*",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return MUL;
}
"/" {
    if(dump_tokens)
        print2file("DIV","/",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return DIV;
}
"%" {
    if(dump_tokens)
        print2file("MOD","%",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return MOD;
}
";" {
    if(dump_tokens)
        print2file("SEMICOLON",";",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return SEMICOLON;
}
"&&" {
    if(dump_tokens)
        print2file("AND","&&",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return AND;
}
"||" {
    if(dump_tokens)
        print2file("OR","||",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return AND;
}
"(" {
    if(dump_tokens)
        print2file("LPAREN","(",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return LPAREN;
}
")" {
    if(dump_tokens)
        print2file("RPAREN",")",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return RPAREN;
}
"{" {
    if(dump_tokens)
        print2file("LBRACE","{",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return LBRACE;
}
"}" {
    if(dump_tokens)
        print2file("RBRACE","}",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return RBRACE;
}

"," {
    if(dump_tokens)
        print2file("COMMA",",",to_string(yylineno),to_string(columnNumber));
    columnNumber += yyleng;
    return COMMA;
}

{DECIMIAL} {
	if(dump_tokens)
		print2file("DECIMAL",(string)yytext,to_string(yylineno),to_string(columnNumber),(string)yytext);
	yylval.itype = atoi(yytext);
	columnNumber += yyleng;
	return INTEGER;
}

{HEX} {
	unsigned long long ans = stoull(yytext, 0, 16);
	if(dump_tokens)  
		print2file("HEX",(string)yytext,to_string(yylineno),to_string(columnNumber),to_string(ans));
	columnNumber += yyleng;
	yylval.itype = ans;
	return INTEGER;
}

{OCT} {
        string my_str = yytext;
        unsigned long long ans = stoull(yytext, 0, 8);
        if(dump_tokens)
        	print2file("OCT",(string)yytext,to_string(yylineno),to_string(columnNumber),to_string(ans));
        columnNumber += yyleng;
	yylval.itype = ans;
	return INTEGER;
} 

{ID} {
	if(dump_tokens)
		print2file("ID",string(yytext),to_string(yylineno),to_string(columnNumber));
	char *lexeme;
	lexeme = new char[strlen(yytext) + 1];
	strcpy(lexeme, yytext);
	yylval.strtype = lexeme;
	columnNumber += yyleng;
	return ID;
}
{EOL} yylineno++;
{WHITE}
%%
