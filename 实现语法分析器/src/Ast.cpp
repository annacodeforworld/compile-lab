#include "Ast.h"
#include "SymbolTable.h"
#include <string>
#include "Type.h"

extern FILE *yyout;
int Node::counter = 0;

Node::Node()
{
    seq = counter++;
}

void Ast::output()
{
    fprintf(yyout, "program\n");
    if(root != nullptr)
        root->output(4);
}
//二元表达式
void BinaryExpr::output(int level)
{
    std::string op_str;
    switch(op)
    {
        case ADD:
            op_str = "add";
            break;
        case SUB:
            op_str = "sub";
            break;
        case AND:
            op_str = "and";
            break;
        case OR:
            op_str = "or";
            break;
        case LESS:
            op_str = "less";
            break;
        case MORE:
            op_str = "more";
            break;
        case MOREEQUAL:
            op_str = "moreequal";
            break;
        case LESSEQUAL:
            op_str = "lessequal";
            break;
        case EQUAL:
            op_str = "equal";
            break;
        case NOEQUAL:
            op_str = "noequal";
            break;
        case DIV:
            op_str = "div";
            break;
        case MUL:
            op_str = "mul";
            break;
        case MOD:
            op_str = "mod";
            break;
    }
    fprintf(yyout, "%*cBinaryExpr    op: %s\n", level, ' ', op_str.c_str());
    expr1->output(level + 4);
    //输出第一个操作数
    expr2->output(level + 4);
    //输出第二个操作数
}
//一元表达式 三种：- + !
void SingleExpr::output(int level)
{
    std::string op_str;
    switch(op)
    {
        case SUB:
            op_str = "negative";
            break;
        case ADD:
            op_str = "positive";
            break;
        case EXCLAMATION:
            op_str = "anti";
            break;
    }
    fprintf(yyout, "%*cSingleExpr    op: %s\n", level, ' ', op_str.c_str());
    expr->output(level + 4);
}
//
// 函数部分
// 函数形参 only 1
void FuncFParam::output(int level)
{
    std::string name, type;
    int scope;
    name = symbolEntry -> toStr();
    type = symbolEntry -> getType() -> toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry) -> getScope();
    fprintf(yyout, "%*cFuncFParam    name:%s    scope:%d    type:%s\n", level, ' ',
            name.c_str(), scope, type.c_str());
}
//函数形参表
void FuncFParams::output(int level)
{
    fprintf(yyout, "%*cFuncFParams\n", level, ' ');
    for(long unsigned int i = 0; i < FPs.size(); i++)
    {
        FPs[i] -> output(level + 4);
    }
    //输出变量的基础信息
    for(long unsigned int i = 0; i < Assigns.size(); i++)
    {
        Assigns[i] -> output(level + 4);
    }
    //输出变量的赋值语句
}
//函数实参表
void FuncRParams::output(int level)
{
    fprintf(yyout, "%*cFuncRParams\n", level, ' ');
    for(long unsigned int i = 0; i < Exprs.size(); i++)
    {
        Exprs[i] -> output(level + 4);
    }
    //输出实参的表达式
}
//函数定义
void FunctionDef::output(int level)
{
    std::string name, type;
    name = se->toStr();
    type = se->getType()->toStr();
    fprintf(yyout, "%*cFunctionDefine    function name: %s    type: %s\n", level, ' ', 
            name.c_str(), type.c_str());
    if(FPs != nullptr){
        FPs -> output(level + 4);
    }
    // 如果函数有形参，则需要输出形参
    stmt->output(level + 4);
}
//函数调用
void FunctionCall::output(int level)
{
    std::string name, type;
    name = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    fprintf(yyout, "%*cFuncCall    name: %s    type: %s\n", level, ' ',
            name.c_str(), type.c_str());
    if(RPs != nullptr)
    {
        RPs -> output(level + 4);
    }
    // 如果函数有形参，则需要输出形参
}
//常量相关
//常量
void Constant::output(int level)
{
    std::string type, value;
    type = symbolEntry->getType()->toStr();
    value = symbolEntry->toStr();
    fprintf(yyout, "%*cIntegerLiteral    value: %s    type: %s\n", level, ' ',
            value.c_str(), type.c_str());
}
//常量定义
void ConstDeclStmt::output(int level)
{
    fprintf(yyout, "%*cConstDeclineStmt\n", level, ' ');
    CIdList->output(level + 4);
}
//常量的id
void ConstId::output(int level)
{
    std::string name, type;
    int scope;
    name = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry)->getScope();
    fprintf(yyout, "%*cConstId    name: %s    scope: %d    type: %s\n", level, ' ',
            name.c_str(), scope, type.c_str());
}
//常量的idlist
void ConstIdList::output(int level)
{
    fprintf(yyout, "%*cConstIdList\n", level, ' ');
    for(long unsigned int i = 0; i < CIdList.size(); i++)
    {
        CIdList[i] -> output(level + 4);
        Assigns[i] -> output(level + 4);
        //常量一定存在赋值语句
    }
}
//控制相关
void BreakStmt::output(int level)
{
    fprintf(yyout, "%*cBreakStmt\n", level, ' ');
}

void ContinueStmt::output(int level)
{
    fprintf(yyout, "%*cContinueStmt\n", level, ' ');
}

void WhileStmt::output(int level)
{
    fprintf(yyout, "%*cWhileStmt\n", level, ' ');
    cond->output(level + 4);
    loop->output(level + 4);
    //输出条件和具体的循环体
}

void Id::output(int level)
{
    std::string name, type;
    int scope;
    name = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry)->getScope();
    fprintf(yyout, "%*cId    name: %s    scope: %d    type: %s\n", level, ' ',
            name.c_str(), scope, type.c_str());
}

void IdList::output(int level)
{
    fprintf(yyout, "%*cIdList\n", level, ' ');
    for(long unsigned int i = 0; i < Ids.size(); i++)
    {
        Ids[i] -> output(level + 4);
        //输出标识符的名称
    }
    for(long unsigned int i = 0; i < Assigns.size(); i++)
    {
        Assigns[i] -> output(level + 4);
        //输出标识符的赋值语句
    }
}
// 空语句
void Empty::output(int level)
{
    fprintf(yyout, "%*cEmptyStmt\n", level, ' ');
}
// 一元表达式
void SingleStmt::output(int level)
{
    fprintf(yyout, "%*cSingleStmt\n", level, ' ');
    expr->output(level + 4);
}
//以下几乎没动
void CompoundStmt::output(int level)
{
    fprintf(yyout, "%*cCompoundStmt\n", level, ' ');
    stmt->output(level + 4);
}

void SeqNode::output(int level)
{
    fprintf(yyout, "%*cSequence\n", level, ' ');
    stmt1->output(level + 4);
    stmt2->output(level + 4);
}

void DeclStmt::output(int level)
{
    fprintf(yyout, "%*cDeclStmt\n", level, ' ');
    ids->output(level + 4);
    //修改，要输出的是整个定义的列表，而不仅仅是一个值
}

void IfStmt::output(int level)
{
    fprintf(yyout, "%*cIfStmt\n", level, ' ');
    cond->output(level + 4);
    thenStmt->output(level + 4);
}

void IfElseStmt::output(int level)
{
    fprintf(yyout, "%*cIfElseStmt\n", level, ' ');
    cond->output(level + 4);
    thenStmt->output(level + 4);
    elseStmt->output(level + 4);
}

void ReturnStmt::output(int level)
{
    fprintf(yyout, "%*cReturnStmt\n", level, ' ');
    retValue->output(level + 4);
}

void AssignStmt::output(int level)
{
    fprintf(yyout, "%*cAssignStmt\n", level, ' ');
    lval->output(level + 4);
    expr->output(level + 4);
}
