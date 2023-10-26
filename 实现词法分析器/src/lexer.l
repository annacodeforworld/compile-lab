%option noyywrap
%option nounput
%option noinput
%{
    #include <string>
    #include <vector>
    #include <ostream>
    #include <fstream>
    #include <iostream>
    #include <math.h>
    #include <iomanip>
    using namespace std;
    extern FILE *yyin; 
    extern FILE *yyout;

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
    struct Node{
        string id_name;
        int id_of_field;
    };
    int id_num = 0;
    int field_id = 0;
    vector<int> field_list;
    Node sym_table[1000];
    
%}

FRACTION [-+]?[0-9]*(\.)?[0-9]*([eE][-+]?[0-9]*)?
HEX (0(x|X)[1-9|A-F|a-f][0-9|A-F|a-f]*|0x0|0X0)
OCT (0[1-7][0-7]*|00)
ID [[:alpha:]_][[:alpha:][:digit:]_]*
CHARACTER ('.')
EOL (\r\n|\n|\r)
WHITE [\t ]
linecomment \/\/.*
commentbegin "/*"
commentelement .|\n
commentend "*/"

%x COMMENT

%%

{linecomment} {

}
{commentbegin} {
        BEGIN COMMENT;
}
<COMMENT>{commentend} {
        BEGIN INITIAL; 
}
<COMMENT>{commentelement} {
        string mystr = (string)yytext;
        while(mystr.find('\n') != mystr.npos)
        /* .npos用于表示字符串或序列的末尾位置*/
        {
            yylineno++;
            mystr.replace(mystr.find('\n'),1,"");
        }
}
"int" {
        print2file("INT","int",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"char" { 
        print2file("CHAR","char",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"float" {
        print2file("FLOAT","float",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"while" {
        print2file("WHILE","while",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"break" {
        print2file("BREAK","break",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"continue" {
        print2file("CONTINUE","continue",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"const" {
        print2file("CONST","const",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"new" {
        print2file("NEW","new",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"delete" {
        print2file("DELETE","delete",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"using" {
        print2file("USING","using",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"namespace" {
        print2file("NAMESPACE","namespace",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"void" {
        print2file("VOID","void",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"if" {
        print2file("IF","if",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"else" {
        print2file("ELSE","else",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"return" {
        print2file("RETURN","return",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"==" {
        print2file("EQUAL","==",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"=" {
        print2file("ASSIGN","=",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"!=" {
        print2file("UNEQUAL","!=",to_string(yylineno),to_string(columnNumber)); 
        columnNumber += yyleng;
}
"!" {
        print2file("AGAINST","!",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"*" {
        print2file("MUL","*",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
">=" {
        print2file("GTE",">=",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng; 
}
"<=" {
        print2file("LTE","<=",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"<" {
        print2file("LESS","<",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
">" {
        print2file("MORE",">",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"," {
        print2file("COMMA",",",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
":" {
        print2file("COLON",":",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"'" {
        print2file("QUOTE","'",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"+" {
        print2file("ADD","+",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"-" {
        print2file("SUB","-",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"/" {
        print2file("DIV","/",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"%" {
        print2file("MOD","%",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
";" {
        print2file("SEMICOLON",";",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"(" {
        print2file("LPAREN","(",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
")" {
        print2file("RPAREN",")",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"{" {
	/* 来到新的作用域 */
        field_id++;
        field_list.push_back(field_id);
        print2file("LBRACE","{",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"}" {
	if(field_list.size())   field_list.pop_back();
        print2file("RBRACE","}",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"[" {
        print2file("LSQUARE","[",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"]" {
        print2file("RSQUARE","]",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
"#" {
        print2file("POUND","#",to_string(yylineno),to_string(columnNumber));
        columnNumber += yyleng;
}
{ID} {
        int my_idnum = 0;
        bool exist_flag = 0;
        for(int i = 0; i < id_num; i++)
        {
        /* 当前标识符存在 */
            if(sym_table[i].id_name == yytext && sym_table[i].id_of_field == field_list.back())
            {
                my_idnum = i + 1;
                exist_flag = 1;
                break;
            }
        }
        /* 当前标识符不存在 */
        if(exist_flag == 0)
        {
            sym_table[id_num].id_name = yytext;
            if(field_list.size() != 0){
                sym_table[id_num].id_of_field = field_list.back();
            }
            id_num++;
            my_idnum = id_num;
        }
        print2file("ID",string(yytext),to_string(yylineno),to_string(columnNumber),"IDcount:" + to_string(my_idnum));
        columnNumber += yyleng; 
}
{OCT} {
        string my_str = yytext;
	/*
        int len = my_str.length();
        int ans = 0;
        for(int i = 1; i <= len-1; i++)
        {
            ans = ans + (pow(8, (len - i - 1)) * (my_str[i] - '0'));         
        }
        */
        unsigned long long ans = stoull(yytext, 0, 8);
        print2file("OCT",(string)yytext,to_string(yylineno),to_string(columnNumber),to_string(ans));
        columnNumber += yyleng;
} 
{HEX} {
        string my_str = yytext;
        /*
        int len = my_str.length();
        int ans = 0;
        for(int i = 2; i <= len - 1; i++)
        {
            int ans1 = (pow(16, (len - i - 1)));
            int ans2 = 0;
            if(my_str[i] >= '0' && my_str[i] <= '9'){
                ans2 = (my_str[i] - '0');
            }
            else if(my_str[i] >= 'A' && my_str[i] <= 'F'){
                ans2 = my_str[i] - 'A' + 10;
            }
            else if(my_str[i] >= 'a' && my_str[i] <= 'f'){
                ans2 = my_str[i] - 'a' + 10;
            }
            ans = ans + ans1 * ans2;         
        }
        */
        unsigned long long ans = stoull(yytext, 0, 16);
        print2file("HEX",(string)yytext,to_string(yylineno),to_string(columnNumber),to_string(ans));
        columnNumber += yyleng;
}
{FRACTION} {
	if((string)yytext==".") 
		print2file("POINT",".",to_string(yylineno),to_string(columnNumber));
	else{
		float floatValue = stof(yytext);
		print2file("DECIMAL",(string)yytext,to_string(yylineno),to_string(columnNumber),to_string(floatValue));
	}
	columnNumber += yyleng;
}
{CHARACTER} {
        print2file("CHARACTER",(string)yytext,to_string(yylineno),to_string(columnNumber),string(yytext));
	columnNumber += yyleng;
}
{EOL} {
	yylineno++;
	columnNumber = 0;
}
{WHITE} {
	if(string(yytext)==" ") columnNumber += yyleng;
}
%%
