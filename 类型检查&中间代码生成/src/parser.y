%code top{
    #include <iostream>
    #include <cstring>
    #include <assert.h>
    #include <stack>
    #include "parser.h"
    extern Ast ast;
    int yylex();
    int yyerror( char const * );
    Type* curType;
    Type* constCurType;
    std::stack<StmtNode*> whileStk;
    int while_level = 0;
    WhileStmt *lstwhile;
    Type* funcret;
    bool have_return = false;
    Type *lstfuncType;
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
    | BREAK SEMICOLON { 
        if(!while_level)
            fprintf(stderr, "\'break\' statement not in while statement\n");
        $$ = new BreakStmt(whileStk.top());
    }//break语句
    | CONTINUE SEMICOLON {
        if(!while_level)
            fprintf(stderr, "\'break\' statement not in while statement\n");
        $$ = new ContinueStmt(whileStk.top());
    }//continue语句
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
    : WHILE LPAREN Cond RPAREN {
        while_level++;
        WhileStmt *whileNode = new WhileStmt($3);
        $<stmttype>$ = whileNode;
        whileStk.push(whileNode);
    }
    Stmt {
        StmtNode *whileNode = $<stmttype>5; 
        ((WhileStmt*)whileNode)->setloop($6);
        $$=whileNode;
        whileStk.pop();
        while_level--;
    }
    ;
ReturnStmt
    :
    RETURN Exp SEMICOLON{
        $$ = new ReturnStmt($2);
        Type* valuetype = (((ReturnStmt*)$$) -> getvaluetype());
        //fprintf(stderr, "%s\n",valuetype->toStr().c_str()); 
        //fprintf(stderr, "%s\n",funcret->toStr().c_str()); 
        if(valuetype != funcret && (valuetype->toStr()) != (funcret->toStr()) + "()"){
            fprintf(stderr, "return type dismatch\n"); 
            exit(EXIT_FAILURE);
        }
        have_return = true;
    }
    | RETURN SEMICOLON{
        $$ = new ReturnStmt();
        if(!funcret->isVoid()){
            fprintf(stderr, "return type dismatch\n"); 
            exit(EXIT_FAILURE);
        }
        have_return = true;
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
        FunctionType* shouldtype = (FunctionType*)(se -> getType());
        int numpara = shouldtype->getParaType().size();
        if(numpara!=0)
        {
            fprintf(stderr, "Function \"%s\" need more paras\n", (char*)$1);
            delete [](char*)$1;
            exit(EXIT_FAILURE);
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
        FunctionType* shouldtype = (FunctionType*)(se -> getType());
        std::vector<Type*> shouldvec = shouldtype->getParaType();
        long unsigned int numpara = shouldvec.size();
        FuncRParams* funcreal = $3;
        std::vector<ExprNode*> funcrealvec = funcreal->Exprs;
        if(numpara!=funcrealvec.size()&& strcmp($1,"putint")!=0 && strcmp($1,"putch")!=0)
        {
            fprintf(stderr, "Function \"%s\" need parameter's num is wrong\n", (char*)$1);
            delete [](char*)$1;
            exit(EXIT_FAILURE);
        }
        if(strcmp($1,"putint")!=0 && strcmp($1,"putch")!=0)
        for(long unsigned int i=0;i<funcrealvec.size();i++)
        {
            if(funcrealvec[i]->symbolEntry->getType()!=shouldvec[i] && !strcmp($1,"putint"))  
            {
                fprintf(stderr, "Function \"%s\" parameter's type dismatch\n", (char*)$1);
                delete [](char*)$1;
                exit(EXIT_FAILURE);
            }
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
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::LESS, $1, $3);
    }
    |
    RelExp MORE AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MORE, $1, $3);
    }
    |
    RelExp MOREEQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::MOREEQUAL, $1, $3);
    }
    |
    RelExp LESSEQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::LESSEQUAL, $1, $3);
    }
    |
    RelExp EQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::EQUAL, $1, $3);
    }
    |
    RelExp NOEQUAL AddExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::NOEQUAL, $1, $3);
    }
    ;
LAndExp
    :
    RelExp {$$ = $1;}
    |
    LAndExp AND RelExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::AND, $1, $3);
    }
    ;
LOrExp
    :
    LAndExp {$$ = $1;}
    |
    LOrExp OR LAndExp
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
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
        se = identifiers->lookup($2);
        if(se != nullptr)
        {
            fprintf(stderr, "ID \"%s\" has been defined\n", (char*)$2);
            delete [](char*)$2;
            exit(EXIT_FAILURE);
        }
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
        se = identifiers->lookup($3);
        if(se != nullptr)
        {
            fprintf(stderr, "ID \"%s\" has been defined\n", (char*)$3);
            delete [](char*)$3;
            exit(EXIT_FAILURE);
        }
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
    	se = identifiers->lookup($2);
        if(se != nullptr)
        {
            fprintf(stderr, "ID \"%s\" has been defined\n", (char*)$2);
            delete [](char*)$2;
            exit(EXIT_FAILURE);
        }
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
    	se = identifiers->lookup($3);
        if(se != nullptr)
        {
            fprintf(stderr, "ID \"%s\" has been defined\n", (char*)$3);
            delete [](char*)$3;
            exit(EXIT_FAILURE);
        }
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
        SymbolEntry * se = identifiers->lookup($2);
        if(se != nullptr)
        {
            fprintf(stderr, "Func \"%s\" has been defined\n", (char*)$2);
            delete [](char*)$2;
            exit(EXIT_FAILURE);
        }
        Type *funcType;
        funcType = new FunctionType($1,{});
        funcret = $1; // 最近定义的一个函数体的返回值类型
        have_return = false;
        // 函数类型设置
        se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
        identifiers->install($2, se);
        identifiers = new SymbolTable(identifiers);
        //创建一个符号表项，并且创建一个新的符号表
        //such as int func(
    }
    RPAREN
    BlockStmt
    {
        if(!have_return)
        {
            fprintf(stderr, "Func \"%s\" dont return\n", (char*)$2);
            exit(EXIT_FAILURE);
        }
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
    Type ID LPAREN{
        SymbolEntry * se = identifiers->lookup($2);
        if(se != nullptr)
        {
            fprintf(stderr, "Func \"%s\" has been defined\n", (char*)$2);
            delete [](char*)$2;
            exit(EXIT_FAILURE);
        }
    	Type *funcType;
        funcType = new FunctionType($1,{}); //
        lstfuncType = funcType;
        funcret = $1;
        have_return = false;
        // 函数类型设置
    	se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
        identifiers->install($2, se);
        identifiers = new SymbolTable(identifiers);
        //创建一个符号表项，并且创建一个新的符号表
        // such as int func(
    }
    FuncFParams{
        std::vector<Type*> curTypeList;
    	FuncFParams* curfunc = $5;
    	for(long unsigned int i = 0; i < curfunc->FPs.size(); i++)
        {
            curTypeList.push_back(curfunc->FPs[i]->symbolEntry->getType());
        }
        ((FunctionType*)lstfuncType) -> setParaType(curTypeList);
    }
    RPAREN
    BlockStmt
    {
        if(!have_return)
        {
            fprintf(stderr, "Func \"%s\" dont return\n", (char*)$2);
            exit(EXIT_FAILURE);
        }
        SymbolEntry *se;
        se = identifiers->lookup($2);
        assert(se != nullptr);
        $$ = new FunctionDef(se, $5 ,$8);
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
