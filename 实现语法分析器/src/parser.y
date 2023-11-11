%code top{
    #include <iostream>
    #include <assert.h>
    #include "parser.h"
    extern Ast ast;
    int yylex();
    int yyerror( char const * );
    Type* curType;
    Type* constCurType;
}

%code requires {
    #include "Ast.h"
    #include "SymbolTable.h"
    #include "Type.h"
}

%union {
    int itype;
    char* strtype;
    StmtNode* stmttype;
    ExprNode* exprtype;
    Type* type;

    IdList* Idlisttype;
    FuncFParams* Fstype;
    FuncRParams* FRtype;
    ConstIdList* CIdListtype;
}
//起始符号
%start Program
//终结符
%token <strtype> ID 
%token <itype> INTEGER
%token IF ELSE
%token BREAK CONTINUE
%token WHILE
%token INT VOID CHAR
%token CONST
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON COMMA
%token ADD SUB MUL DIV EXCLAMATION MORE OR AND LESS ASSIGN EQUAL NOEQUAL LESSEQUAL MOREEQUAL MOD
%token RETURN
%token LINECOMMENT COMMENTBEIGN COMMENTELEMENT COMMENTLINE COMMENTEND
//非终结符
%nterm <stmttype> Stmts Stmt AssignStmt BlockStmt IfStmt ReturnStmt DeclStmt FuncDef WhileStmt ConstDeclStmt SingleStmt
%nterm <exprtype> Exp UnaryExp AddExp MulExp Cond LOrExp PrimaryExp LVal RelExp LAndExp 
%nterm <type> Type 
%nterm <Idlisttype> Idlist 
%nterm <Fstype> FuncFParams
%nterm <FRtype> FuncRParams
%nterm <CIdListtype> ConstIdList
//优先级
%precedence THEN
%precedence ELSE
%%
Program
    : Stmts {
        ast.setRoot($1);
    }
    ;
Stmts
    : Stmt {$$ = $1;}
    | Stmts Stmt{
        $$ = new SeqNode($1, $2);
    }
    ;
Stmt
    : AssignStmt {$$ = $1;}
    | BlockStmt {$$ = $1;}
    | IfStmt {$$ = $1;}
    | ReturnStmt {$$ = $1;}
    | DeclStmt {$$ = $1;}
    | ConstDeclStmt {$$ = $1;}//常量定义
    | FuncDef {$$ = $1;}
    | WhileStmt {$$ = $1;}//while语句
    | SEMICOLON {$$ = new Empty();}//空语句
    | BREAK SEMICOLON {$$ = new BreakStmt();}//break语句
    | CONTINUE SEMICOLON {$$ = new ContinueStmt();}//continue语句
    | SingleStmt {$$ = $1;}//只有一个表达式的语句
    ;
SingleStmt
    :
    Exp SEMICOLON{
        $$ = new SingleStmt($1);
        //such as: a+b
    }
    ;
AssignStmt
    :
    LVal ASSIGN Exp SEMICOLON {
        $$ = new AssignStmt($1, $3);
        //such as: a=b+c;
    }
    ;
BlockStmt
    :   LBRACE 
        {identifiers = new SymbolTable(identifiers);} 
        Stmts RBRACE 
        {
            $$ = new CompoundStmt($3);
            SymbolTable *top = identifiers;
            // 切换当前使用的symboltable
            identifiers = identifiers->getPrev();
            delete top;
            // 之后就不会再用到这个symboltable
        }
    ;
IfStmt
    : IF LPAREN Cond RPAREN Stmt %prec THEN {
        $$ = new IfStmt($3, $5);
        // 这里的prec在实验指导书提到，是用于避免移入规约冲突
    }
    | IF LPAREN Cond RPAREN LBRACE RBRACE{
        $$ = new IfStmt($3, new Empty());
        // if语句中为空 形如 if(cond) {}
    } 
    | IF LPAREN Cond RPAREN Stmt ELSE Stmt {
        $$ = new IfElseStmt($3, $5, $7);
    }
    ;
WhileStmt
    : WHILE LPAREN Cond RPAREN Stmt {
        $$ = new WhileStmt($3, $5);
    }
    ;
ReturnStmt
    :
    RETURN Exp SEMICOLON{
        $$ = new ReturnStmt($2);
    }
    ;
Exp
    :
    AddExp {$$ = $1;}
    ;
Cond
    :
    LOrExp {$$ = $1;}
    ;
LVal
    : ID {//保证我们的左值可被赋值
        SymbolEntry *se;
        se = identifiers->lookup($1);
        //先去寻找id是否在当前作用域声明
        if(se == nullptr)
        {
            fprintf(stderr, "identifier \"%s\" is undefined\n", (char*)$1);
            delete [](char*)$1;
            assert(se != nullptr);
        }
        $$ = new Id(se);
        delete []$1;
    }
    ;
PrimaryExp
    :
    LVal {
        $$ = $1;
    }
    | INTEGER {
        SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, $1);
        $$ = new Constant(se);
    }
    | LPAREN Exp RPAREN{$$ = $2;}//加上括号还是当前表达式本身
    ;
UnaryExp
    :
    PrimaryExp {$$ = $1;}
    | ID LPAREN RPAREN{
        SymbolEntry *se;
        se = identifiers->lookup($1);
        if(se == nullptr)
        {
            fprintf(stderr, "Function \"%s\" is undefined\n", (char*)$1);
            delete [](char*)$1;
            assert(se != nullptr);
        }
        $$ = new FunctionCall(se, nullptr);//传入的实参为空
        delete []$1;
        //形如 id() 是函数调用
    }
    | ID LPAREN FuncRParams RPAREN{
        SymbolEntry *se;
        se = identifiers->lookup($1);
        if(se == nullptr)
        {
            fprintf(stderr, "Function \"%s\" is undefined\n", (char*)$1);
            delete [](char*)$1;
            assert(se != nullptr);
        }
        $$ = new FunctionCall(se, $3);//传入的实参不为空
        delete []$1;
        //形如 id(1,2)
    }
    | SUB UnaryExp {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new SingleExpr(se, SingleExpr::SUB, $2);
        //-
    }
    | EXCLAMATION UnaryExp{
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new SingleExpr(se, SingleExpr::EXCLAMATION, $2);
        //!
    }
    | ADD UnaryExp{
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new SingleExpr(se, SingleExpr::ADD, $2);
        //+
    }
    ;
MulExp
    :
    UnaryExp {$$ = $1;}
    | MulExp MUL UnaryExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MUL, $1, $3);
        // _ * _
    }
    | MulExp DIV UnaryExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::DIV, $1, $3);
        // _ / _
    }
    | MulExp MOD UnaryExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MOD, $1, $3);
        // _ % _
    }
    ;    
AddExp
    :
    MulExp {$$ = $1;}
    |
    AddExp ADD MulExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::ADD, $1, $3);
    }
    |
    AddExp SUB MulExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::SUB, $1, $3);
    }
    ;

RelExp
    :
    AddExp {$$ = $1;}
    |
    RelExp LESS AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::LESS, $1, $3);
    }
    |
    RelExp MORE AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MORE, $1, $3);
    }
    |
    RelExp MOREEQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MOREEQUAL, $1, $3);
    }
    |
    RelExp LESSEQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::LESSEQUAL, $1, $3);
    }
    |
    RelExp EQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::EQUAL, $1, $3);
    }
    |
    RelExp NOEQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::NOEQUAL, $1, $3);
    }
    ;
LAndExp
    :
    RelExp {$$ = $1;}
    |
    LAndExp AND RelExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::AND, $1, $3);
    }
    ;
LOrExp
    :
    LAndExp {$$ = $1;}
    |
    LOrExp OR LAndExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::OR, $1, $3);
    }
    ;
Type
    : INT {
        $$ = TypeSystem::intType;
    }
    | VOID {
        $$ = TypeSystem::voidType;
    }
    | CHAR{
        $$ = TypeSystem::charType;
    }
    ;
DeclStmt
    :
    Idlist SEMICOLON {
        $$ = new DeclStmt($1);
    }
    ;
ConstDeclStmt
    :
    ConstIdList SEMICOLON{
        $$ = new ConstDeclStmt($1);
    }
    ;
ConstIdList
    :
    CONST Type ID ASSIGN Exp {
        SymbolEntry* se = new IdentifierSymbolEntry($2, $3, identifiers -> getLevel());
    	identifiers->install($3, se);
        ConstId *t = new ConstId(se);
        
        std::vector<ConstId*> ConstIds;
        std::vector<AssignStmt*> Assigns;
        ConstIdList* temp = new ConstIdList(ConstIds, Assigns);
        
        temp -> CIdList.push_back(t);
        temp -> Assigns.push_back(new AssignStmt(t, $5));
        $$ = temp;
        constCurType = $2;
        delete []$3;
    }
    |
    ConstIdList COMMA ID ASSIGN Exp {
    	SymbolEntry *se;
        se = new IdentifierSymbolEntry(constCurType, $3, identifiers->getLevel());
        identifiers->install($3, se);
        ConstId *t = new ConstId(se);
        
        ConstIdList *temp = $1;
        temp -> CIdList.push_back(t);
        temp -> Assigns.push_back(new AssignStmt(t, $5));
        $$ = temp;
        delete []$3;
    }
    ;    
Idlist
    :
    Type ID {
    	SymbolEntry *se;
        se = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
        
        std::vector<Id*> Ids;
        std::vector<AssignStmt*> Assigns;
        IdList *temp = new IdList(Ids, Assigns);
        
        identifiers->install($2, se);
        temp -> Ids.push_back(new Id(se));
        $$ = temp;
        curType = $1;
        delete []$2;
    } 
    |
    Idlist COMMA ID{
        SymbolEntry *se;
        se = new IdentifierSymbolEntry(curType, $3, identifiers->getLevel());
        
        IdList *temp = $1;
        identifiers->install($3, se);
        temp -> Ids.push_back(new Id(se));
        $$ = temp;
        delete []$3;
    }
    |
    Type ID ASSIGN Exp {
    	SymbolEntry *se;
        se = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
        identifiers->install($2, se);
        Id *t = new Id(se);
        
        std::vector<Id*> Ids;
        std::vector<AssignStmt*> Assigns;
        IdList *temp = new IdList(Ids, Assigns);
        temp -> Ids.push_back(t);
        temp -> Assigns.push_back(new AssignStmt(t, $4));
        $$ = temp;
        curType = $1;
        delete []$2;
    }
    |
    Idlist COMMA ID ASSIGN Exp {
    	SymbolEntry *se;
        se = new IdentifierSymbolEntry(curType, $3, identifiers->getLevel());
        identifiers->install($3, se);
        Id *t = new Id(se);
        
        IdList *temp = $1;
        temp -> Ids.push_back(t);
        temp -> Assigns.push_back(new AssignStmt(t, $5));
        $$ = temp;
        delete []$3;
    }
    ;
FuncRParams
    :
    Exp
    {
        std::vector<ExprNode*> t;
        t.push_back($1);
        FuncRParams *temp = new FuncRParams(t);
        $$ = temp;
    }
    |
    FuncRParams COMMA Exp
    {
        FuncRParams *temp = $1;
        temp -> Exprs.push_back($3);
        $$ = temp;
    }
    ;
FuncFParams
    :
    Type ID
    {
    	SymbolEntry *se;
        se = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
        identifiers->install($2, se);
        
        std::vector<FuncFParam*> FPs;
        std::vector<AssignStmt*> Assigns;
        FuncFParams *temp = new FuncFParams(FPs, Assigns);
        temp -> FPs.push_back(new FuncFParam(se));
        $$ = temp;
        delete []$2;
    }
    |
    FuncFParams COMMA Type ID
    {
        SymbolEntry *se;
        se = new IdentifierSymbolEntry($3, $4, identifiers->getLevel());
        identifiers->install($4, se);
        
        FuncFParams *temp = $1;
        temp -> FPs.push_back(new FuncFParam(se));
        $$ = temp;
        delete []$4;
    }
    |
    Type ID ASSIGN Exp
    {
    	SymbolEntry *se;
        se = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
        identifiers->install($2, se);
        FuncFParam* t = new FuncFParam(se);
        
        std::vector<FuncFParam*> FPs;
        std::vector<AssignStmt*> Assigns;
        FuncFParams *temp = new FuncFParams(FPs, Assigns);
        temp -> FPs.push_back(t);
        temp -> Assigns.push_back(new AssignStmt(t, $4));
        $$ = temp;
        delete []$2;
    }
    |
    FuncFParams COMMA Type ID ASSIGN Exp
    {
    	SymbolEntry *se;
        se = new IdentifierSymbolEntry($3, $4, identifiers->getLevel());
        identifiers->install($4, se);
        FuncFParam* t = new FuncFParam(se);
        
        FuncFParams *temp = $1;
        temp -> FPs.push_back(t);
        temp -> Assigns.push_back(new AssignStmt(t, $6));
        $$ = temp;
        delete []$4;
    }
    ;
FuncDef
    :
    Type ID LPAREN {
        Type *funcType;
        funcType = new FunctionType($1,{});
        // 函数类型设置
        SymbolEntry *se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
        identifiers->install($2, se);
        identifiers = new SymbolTable(identifiers);
        //创建一个符号表项，并且创建一个新的符号表
        //such as int func(
    }
    RPAREN
    BlockStmt
    {
        SymbolEntry *se;
        se = identifiers->lookup($2);
        assert(se != nullptr);
        // 检查是否存在这个函数的id
        $$ = new FunctionDef(se, nullptr,$6);
        // 创建函数定义块
        SymbolTable *top = identifiers;
        // 需要我们恢复原来的symboltable
        identifiers = identifiers->getPrev();
        delete top;
        delete []$2;
        // such as ){}
    }
    |
    Type ID LPAREN {
    	Type *funcType;
        funcType = new FunctionType($1,{});
        // 函数类型设置
    	SymbolEntry *se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
        identifiers->install($2, se);
        identifiers = new SymbolTable(identifiers);
        //创建一个符号表项，并且创建一个新的符号表
        // such as int func(
    }
    FuncFParams RPAREN
    BlockStmt
    {
        SymbolEntry *se;
        se = identifiers->lookup($2);
        assert(se != nullptr);
        $$ = new FunctionDef(se, $5 ,$7);
        SymbolTable *top = identifiers;
        identifiers = identifiers->getPrev();
        delete top;
        delete []$2;
        // such as 形参){}
    }
    ;
%%


int yyerror(char const* message)
{
    std::cerr<<message<<std::endl;
    return -1;
}
