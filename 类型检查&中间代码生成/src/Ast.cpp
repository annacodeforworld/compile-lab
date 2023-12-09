#include "Ast.h"
#include "SymbolTable.h"
#include "Unit.h"
#include "Instruction.h"
#include "IRBuilder.h"
#include <string>
#include "Type.h"

extern FILE *yyout;
int Node::counter = 0;
IRBuilder* Node::builder = nullptr;

Node::Node()
{
    seq = counter++;
}

void Node::backPatch(std::vector<Instruction*> &list, BasicBlock*bb)
{
    for(auto &inst:list)
    {
        if(inst->isCond())
        {
            bb->addPred(dynamic_cast<CondBrInstruction*>(inst)->getParent());
            dynamic_cast<CondBrInstruction*>(inst)->getParent()->addSucc(bb);
            dynamic_cast<CondBrInstruction*>(inst)->setTrueBranch(bb);
        }
        else if(inst->isUncond())
        {
            bb->addPred(dynamic_cast<CondBrInstruction*>(inst)->getParent());
            dynamic_cast<CondBrInstruction*>(inst)->getParent()->addSucc(bb);
            dynamic_cast<UncondBrInstruction*>(inst)->setBranch(bb);
        }
    }
}

void Node::backPatchFalse(std::vector<Instruction*> &list, BasicBlock*bb)
{
    for(auto &inst:list)
    {
        if(inst->isCond())
        {
            bb->addPred(dynamic_cast<CondBrInstruction*>(inst)->getParent());
            dynamic_cast<CondBrInstruction*>(inst)->getParent()->addSucc(bb);
            dynamic_cast<CondBrInstruction*>(inst)->setFalseBranch(bb);
        }
        else if(inst->isUncond())
        {
            bb->addPred(dynamic_cast<CondBrInstruction*>(inst)->getParent());
            dynamic_cast<CondBrInstruction*>(inst)->getParent()->addSucc(bb);
            dynamic_cast<UncondBrInstruction*>(inst)->setBranch(bb);
        }
    }
}

std::vector<Instruction*> Node::merge(std::vector<Instruction*> &list1, std::vector<Instruction*> &list2)
{
    std::vector<Instruction*> res(list1);
    res.insert(res.end(), list2.begin(), list2.end());
    return res;
}

void Ast::genCode(Unit *unit)
{
    IRBuilder *builder = new IRBuilder(unit);
    // 新建一个中间代码构造辅助器，传入一个编译单元
    Node::setIRBuilder(builder);
    // 设置当前语法树节点的builder
    // fprintf(yyout, "declare i32 @getint()\ndeclare void @putint(i32)\ndeclare i32 @getch()\ndeclare void @putch(i32)\n");
    root->genCode();
    // 开始生成中间代码
}


//gencode

void FunctionDef::genCode()
{
    Unit *unit = builder->getUnit();
    Function *func = new Function(unit, se);  // 利用创建好的符号表项和父编译单元构造一个新的函数对象（会构造一个新的基本块）
    BasicBlock *entry = func->getEntry(); // 获取上面构造号的基本块指针
    builder->setInsertBB(entry);
    // 更新应当被插入的基本块为entry
    if(FPs != nullptr)
    {
        FPs -> genCode();
        // 如果有形参，需要调用形参的构造代码函数
    }
    stmt->genCode(); // 调用具体声明语句的构造代码函数
}

void BinaryExpr::genCode()
{
    BasicBlock *bb = builder->getInsertBB(); //获得应当被插入的基本块
    Function *func = bb->getParent(); // 获得该基本块的所在的函数
    if (op == AND) // 与操作
    {
        BasicBlock *trueBB = new BasicBlock(func);
        expr1->genCode();
        backPatch(expr1->trueList(), trueBB); // 让expr1的真值列表可以跳转到trueBB
        builder->setInsertBB(trueBB); //设置应当被插入的基本块
        expr2->genCode();
        true_list = expr2->trueList(); // 自己的真值列表等于expr2的
        false_list = merge(expr1->falseList(), expr2->falseList()); // 自己的假值列表等于expr1和expr2的加起来
        dst -> getType() -> kind = 4; // 设置BOOL类型
    }
    else if(op == OR)
    {
        // Todo
        BasicBlock *falseBB = new BasicBlock(func);
        expr1 -> genCode();
        backPatchFalse(expr1->falseList(), falseBB);
        // 让expr1的错误分支要跳转到falseBB
        builder->setInsertBB(falseBB);
        expr2->genCode();
        false_list=expr2->falseList(); // 自己的假值列表和expr2的相同
        true_list=merge(expr1->trueList(), expr2->trueList()); //自己的真值列表等于expr1和expr2的加起来
        dst -> getType() -> kind = 4;
    }
    else if(op >= LESS && op <= MORE)
    {
        // Todo
        expr1->genCode();
        expr2->genCode();
        Operand *src1 = expr1->getOperand();
        Operand *src2 = expr2->getOperand();
        int opcode = 0;
        switch (op)
        {
        case MORE:
            opcode = CmpInstruction::G;
            break;
        case MOREEQUAL:
            opcode = CmpInstruction::GE;
            break;
        case LESS:
            opcode = CmpInstruction::L;
            break;
        case LESSEQUAL:
            opcode = CmpInstruction::LE;
            break;
        case EQUAL:
            opcode = CmpInstruction::E;
            break;
        case NOEQUAL:
            opcode = CmpInstruction::NE;
            break;
        default:
            break;
        }
        new CmpInstruction(opcode, dst, src1, src2, bb); //新建比较指令 比较操作符 比较结果 比较操作数1 比较操作数2
        dst -> getType() -> kind = 4;
        
    }
    else if(op >= ADD && op <= SUB)
    {
        expr1->genCode();
        expr2->genCode();
        Operand *src1 = expr1->getOperand();
        Operand *src2 = expr2->getOperand();
        int opcode = 0;
        switch (op)
        {
        case ADD:
            opcode = BinaryInstruction::ADD;
            break;
        case SUB:
            opcode = BinaryInstruction::SUB;
            break;
        case MUL:
            opcode = BinaryInstruction::MUL;
            break;
        case DIV:
            opcode = BinaryInstruction::DIV;
            break;
        case MOD:
            opcode = BinaryInstruction::MOD;
            break;
        }
        new BinaryInstruction(opcode, dst, src1, src2, bb);
    }
}

void Constant::genCode()
{
    // do nothing
}

void Id::genCode()
{
    BasicBlock *bb = builder->getInsertBB();
    Operand *addr = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry)->getAddr();
    new LoadInstruction(dst, addr, bb);
}

void IfStmt::genCode()
{
    //std::cout  << "start4" << std::endl;
    Function *func;
    BasicBlock *then_bb, *end_bb;

    func = builder->getInsertBB()->getParent();
    then_bb = new BasicBlock(func);
    end_bb = new BasicBlock(func);

    then_bb -> addPred(builder->getInsertBB());//设置其前驱
    builder -> getInsertBB() -> addSucc(then_bb);//设置后继
    end_bb -> addPred(then_bb);
    then_bb -> addSucc(end_bb);//
    end_bb -> addPred(builder -> getInsertBB());
    builder -> getInsertBB() -> addSucc(end_bb);

    if(cond != nullptr)
    cond->genCode();
    if(!cond -> getOperand() -> getType() -> isBool())
    {
        BasicBlock* bb=cond->builder->getInsertBB();
        Operand *src = cond->getOperand();
        SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, 0);
        Constant* digit = new Constant(se);
        Operand* t = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
        CmpInstruction* temp = new CmpInstruction(CmpInstruction::EXCLAMATION, t, src, digit->getOperand(), bb);
        src=t;
        cond->trueList().push_back(temp);
        cond->falseList().push_back(temp);
        Instruction* m = new CondBrInstruction(nullptr,nullptr,t,bb);
        cond->trueList().push_back(m);
        cond->falseList().push_back(m);
    }
    backPatch(cond->trueList(), then_bb);
    backPatchFalse(cond->falseList(), end_bb);

    builder->setInsertBB(then_bb);
    thenStmt->genCode();
    then_bb = builder->getInsertBB();
    new UncondBrInstruction(end_bb, then_bb);

    builder->setInsertBB(end_bb);
    //std::cout  << "end4" << std::endl;
}

void IfElseStmt::genCode()
{
    // Todo
    Function *func;
    BasicBlock *then_bb, *else_bb, *end_bb;

    func = builder->getInsertBB()->getParent();
    then_bb = new BasicBlock(func);
    end_bb = new BasicBlock(func);
    else_bb = new BasicBlock(func);


    then_bb -> addPred(builder -> getInsertBB());
    builder -> getInsertBB() -> addSucc(then_bb);

    else_bb -> addPred(builder -> getInsertBB());
    builder -> getInsertBB() -> addSucc(else_bb);

    end_bb -> addPred(then_bb);
    then_bb -> addSucc(end_bb);
    end_bb -> addPred(else_bb);
    else_bb -> addSucc(end_bb);

    cond -> genCode();
    if(!cond -> getOperand() -> getType() -> isBool())
    {
        BasicBlock* bb=cond->builder->getInsertBB();
        Operand *src = cond->getOperand();
        SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, 0);
        Constant* digit = new Constant(se);
        Operand* t = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
        CmpInstruction* temp = new CmpInstruction(CmpInstruction::EXCLAMATION, t, src, digit->getOperand(), bb);
        src=t;
        cond->trueList().push_back(temp);
        cond->falseList().push_back(temp);
        Instruction* m = new CondBrInstruction(nullptr,nullptr,t,bb);
        cond->trueList().push_back(m);
        cond->falseList().push_back(m);
    }
    backPatch(cond -> trueList(), then_bb);
    backPatchFalse(cond -> falseList(), else_bb);

    builder -> setInsertBB(then_bb);
    thenStmt -> genCode();
    then_bb = builder -> getInsertBB();
    // builder->setInsertBB(then_bb);
    new UncondBrInstruction(end_bb, then_bb);

    builder -> setInsertBB(else_bb);
    elseStmt->genCode();
    else_bb = builder->getInsertBB();
    // builder->setInsertBB(else_bb);
    new UncondBrInstruction(end_bb, else_bb);

    builder->setInsertBB(end_bb);
}

void CompoundStmt::genCode()
{
    stmt -> genCode();
}

void SeqNode::genCode()
{
    stmt1 -> genCode();
    stmt2 -> genCode();
}

void DeclStmt::genCode()
{
    //std::cout  << "start8" << std::endl;
    for(auto iter = ids->Ids.rbegin(); iter != ids->Ids.rend(); iter++)
    {
        IdentifierSymbolEntry *se = dynamic_cast<IdentifierSymbolEntry *>((*iter)-> getSymPtr());
        if(se->isGlobal())
        {
            Operand *addr;
            SymbolEntry *addr_se;
            addr_se = new IdentifierSymbolEntry(*se);
            addr_se->setType(new PointerType(se->getType()));
            addr = new Operand(addr_se);
            se->setAddr(addr);
            bool temp = false;
            Operand *src;
            for(long unsigned int i = 0; i < ids -> Assigns.size(); i++)
            {
                if(ids -> Assigns[i] -> lval -> symbolEntry == se)
                {
                    ids -> Assigns[i] -> genCode();
                    src = ids -> Assigns[i] -> expr -> getOperand();
                    temp = true;
                    break; 
                }              
            }
            if(temp == false)
            {
                SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, 0);
                Constant* digit = new Constant(se);
                src = digit -> getOperand();
            }
            Instruction *alloca = new AllocaInstruction2(src, addr, se);
            alloca -> output();
        }
        else if(se->isLocal())
        {
            Function *func = builder->getInsertBB()->getParent();
            BasicBlock *entry = func->getEntry();
            Instruction *alloca;
            Operand *addr;
            SymbolEntry *addr_se;
            Type *type;
            type = new PointerType(se->getType());
            addr_se = new TemporarySymbolEntry(type, SymbolTable::getLabel());
            addr = new Operand(addr_se);
            alloca = new AllocaInstruction(addr, se);                   // allocate space for local id in function stack.
            entry->insertFront(alloca);                                 // allocate instructions should be inserted into the begin of the entry block.
            se->setAddr(addr);                                          // set the addr operand in symbol entry so that we can use it in subsequent code generation.
        }
    }
    for(long unsigned int i = 0; i < ids -> Assigns.size(); i++)
    {
        IdentifierSymbolEntry *se = dynamic_cast<IdentifierSymbolEntry *>(ids -> Assigns[i] -> lval -> getSymPtr());
        if(se -> isGlobal())
        { 
            continue;                   
        }
        else if(se -> isLocal())
        {
            Operand *addr = dynamic_cast<IdentifierSymbolEntry*>(ids -> Assigns[i] -> lval ->getSymPtr())->getAddr();
            se->setAddr(addr); 
            ids -> Assigns[i] -> genCode();
        }
    }
    //std::cout  << "end8" << std::endl;
}

void ReturnStmt::genCode()
{
    // Todo完成
    BasicBlock *bb = builder -> getInsertBB();
    //操作返回值不为空
    if(retValue != nullptr){
        retValue -> genCode();
        Operand* src = retValue -> getOperand();//获得操作数
        new RetInstruction(src, bb);//构造ret语句
    }
}

void AssignStmt::genCode()
{
    BasicBlock *bb = builder->getInsertBB();
    expr->genCode();
    Operand *addr = dynamic_cast<IdentifierSymbolEntry*>(lval->getSymPtr())->getAddr();
    Operand *src = expr->getOperand();//获得操作数
    new StoreInstruction(addr, src, bb);//构造赋值语句
}

void SingleStmt::genCode()
{
    expr -> genCode();
}

void Empty::genCode()
{
    
}

void FuncRParams::genCode()//函数实参
{

}

void FuncFParam::genCode()//函数形参
{

}

void FuncFParams::genCode()//函数形参列表
{
    //std::cout  << "start15" << std::endl;
    Function *func = builder -> getInsertBB() -> getParent();
    for(long unsigned int i = 0; i < FPs.size(); i++)
    {
        // BasicBlock *bb = builder->getInsertBB();
        // Operand *addr = dynamic_cast<IdentifierSymbolEntry*>(FPs[i] -> symbolEntry)->getAddr();
        // func->insertparam(addr);
        IdentifierSymbolEntry *se = dynamic_cast<IdentifierSymbolEntry *>(FPs[i]->getSymPtr());
        //if(FPs[i]->getOperand() == nullptr) std::cout << "fun";
        Type *type1 = new PointerType(se->getType());
        Type *type2 = new IntType(32);
        SymbolEntry *addr_se = new TemporarySymbolEntry(type2, SymbolTable::getLabel());
        Operand *addr = new Operand(addr_se);

        SymbolTable :: counter++; //为了分配新的
        SymbolEntry *addr_se2 = new TemporarySymbolEntry(type1, SymbolTable::getLabel());
        Operand *addr2 = new Operand(addr_se2);


        //SymbolEntry *temp = new TemporarySymbolEntry(type, SymbolTable::getLabel());
        BasicBlock *entry = func->getEntry();
        Instruction *alloca;
        alloca = new AllocaInstruction(addr2, se);                   // allocate space for local id in function stack.
        entry->insertBack(alloca);                                   // allocate instructions should be inserted into the begin of the entry block. 
        StoreInstruction *store = new StoreInstruction(addr2, addr);
        entry -> insertBack(store);


        se->setAddr(addr2);   
        func->params.push_back(addr); 
    }
    //fprintf(yyout, "test\n");
    //std::cout  << "end15" << std::endl;
}

void FunctionCall::genCode()
{
    //std::cout  << "start19" << std::endl;
    std::vector<Operand*> params;
    if(RPs != nullptr)
    for(unsigned i = 0; i < RPs -> Exprs.size(); i++)
    {
        if(RPs -> Exprs[i] != nullptr){
            RPs -> Exprs[i] -> genCode();
            params.push_back(RPs -> Exprs[i] -> getOperand());
        }
    }
    BasicBlock *entry = builder -> getInsertBB();

    Type *type2 = new IntType(32);
    SymbolTable :: counter++; //为了分配新的
    SymbolEntry *addr_se2 = new TemporarySymbolEntry(type2, SymbolTable::getLabel());
    dst = new Operand(addr_se2);
    FunctioncallInstruction *temp = new FunctioncallInstruction(dst ,symbolEntry, params);
    entry -> insertBack(temp);
    //this -> symbolEntry = addr_se2;
    //std::cout  << "end19" << std::endl;
}

void ConstIdList::genCode()
{
    //什么都不做
}

void IdList::genCode()
{
    //设么都不做
}

void WhileStmt::genCode()
{
     Function *func;
    BasicBlock *loop_bb, *end_bb , *cond_bb;


    func = builder -> getInsertBB() -> getParent();
    loop_bb = new BasicBlock(func);
    end_bb = new BasicBlock(func);
    cond_bb = new BasicBlock(func);

    UncondBrInstruction *temp = new UncondBrInstruction(cond_bb, builder -> getInsertBB());
    temp -> output();
    //设置前后
    cond_bb -> addPred(builder -> getInsertBB());
    builder -> getInsertBB() -> addSucc(cond_bb);
    loop_bb -> addPred(cond_bb);
    cond_bb -> addSucc(loop_bb);

    //builder -> getInsertBB() -> addSucc(loop_bb);
    end_bb -> addPred(loop_bb);
    loop_bb -> addSucc(end_bb);

    end_bb -> addPred(cond_bb);
    cond_bb -> addSucc(end_bb);

    builder->setInsertBB(cond_bb);

    cond -> genCode();
    if(!cond -> getOperand() -> getType() -> isBool())
    {
        BasicBlock* bb=cond->builder->getInsertBB();
        Operand *src = cond->getOperand();
        SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, 0);
        Constant* digit = new Constant(se);
        Operand* t = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
        CmpInstruction* temp = new CmpInstruction(CmpInstruction::EXCLAMATION, t, src, digit->getOperand(), bb);
        src=t;
        cond->trueList().push_back(temp);
        cond->falseList().push_back(temp);
        Instruction* m = new CondBrInstruction(nullptr,nullptr,t,bb);
        cond->trueList().push_back(m);
        cond->falseList().push_back(m);
    }
    backPatch(cond -> trueList(), loop_bb);
    backPatchFalse(cond -> falseList(), end_bb);

    builder -> setInsertBB(loop_bb);
    loop -> genCode();
    loop_bb = builder -> getInsertBB();
    new CondBrInstruction(cond_bb, end_bb, cond->getOperand(), loop_bb);

    builder->setInsertBB(end_bb);
}

void ConstDeclStmt::genCode()
{
    for(long unsigned int i = 0; i < CIdList -> CIdList.size(); i++)
    {
        IdentifierSymbolEntry *se = dynamic_cast<IdentifierSymbolEntry *>(CIdList -> CIdList[i] -> getSymPtr());
        if(se->isGlobal())
        {
            Operand *addr;
            SymbolEntry *addr_se;
            addr_se = new IdentifierSymbolEntry(*se);
            addr_se->setType(new PointerType(se->getType()));
            addr = new Operand(addr_se);
            se->setAddr(addr);
            CIdList -> Assigns[i] -> genCode();
            Operand *src = CIdList -> Assigns[i] -> expr -> getOperand();
            Instruction *alloca = new AllocaInstruction2(src ,addr, se);
            alloca -> output();
        }
        else if(se->isLocal())
        {
            Function *func = builder->getInsertBB()->getParent();
            BasicBlock *entry = func->getEntry();
            Instruction *alloca;
            Operand *addr;
            SymbolEntry *addr_se;
            Type *type;
            type = new PointerType(se->getType());
            addr_se = new TemporarySymbolEntry(type, SymbolTable::getLabel());
            addr = new Operand(addr_se);
            alloca = new AllocaInstruction(addr, se);                   // allocate space for local id in function stack.
            entry->insertFront(alloca);                                 // allocate instructions should be inserted into the begin of the entry block.
            se->setAddr(addr);

            CIdList -> Assigns[i] -> expr -> genCode();
            Operand *addr1 = dynamic_cast<IdentifierSymbolEntry*>(CIdList -> Assigns[i] -> lval ->getSymPtr())->getAddr();
            se->setAddr(addr1); 
            Operand *src = CIdList -> Assigns[i] -> expr -> getOperand();
            BasicBlock *ttt = builder -> getInsertBB();
            new StoreInstruction(addr1, src, ttt);                                          // set the addr operand in symbol entry so that we can use it in subsequent code generation.
        }
    }
}


void ContinueStmt::genCode()
{
    Function* func = builder->getInsertBB()->getParent();
    BasicBlock* bb = builder->getInsertBB();
    new UncondBrInstruction(((WhileStmt*)whileStmt)->get_cond_bb(), bb);
    BasicBlock* continue_next_bb = new BasicBlock(func);
    builder->setInsertBB(continue_next_bb);
}

void BreakStmt::genCode()
{
    Function* func = builder->getInsertBB()->getParent();
    BasicBlock* bb = builder->getInsertBB();
    new UncondBrInstruction(((WhileStmt*)whileStmt)->get_end_bb(), bb);
    BasicBlock* break_next_bb = new BasicBlock(func);
    builder->setInsertBB(break_next_bb);
}

void ConstId::genCode()
{
    //do nothing!
}
void SingleExpr::genCode()
{
    BasicBlock *bb = builder->getInsertBB();
    if(op == EXCLAMATION)
    {
        Operand *src = expr->getOperand(); 
        SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, 0);
        Constant* digit = new Constant(se);
        expr->genCode();
        if(!expr -> getOperand() -> getType() -> isBool()){
            Operand* t=new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
            new CmpInstruction(CmpInstruction::EXCLAMATION, t, src, digit->getOperand(), bb);
            src=t;
        }
        new XorInstruction(dst,src,bb);
        dst -> getType() -> kind = 4;
        isCond = true;
    }
    if(op >= SUB && op <= ADD)
    {
        expr->genCode();
        Operand *src = expr->getOperand();
        if(src -> getType() -> isBool())
        {
            Operand* t =new Operand(new TemporarySymbolEntry(TypeSystem::intType,SymbolTable::getLabel()));
            new ZextInstruction(t,expr -> dst,bb); 
            expr -> dst = t;   
            src = t; 
        }
        int opcode=0;
        switch (op)
        {
        case ADD:
            opcode = BinaryInstruction::ADD;
            break;
        case SUB:
            opcode = BinaryInstruction::SUB;
            break;
        default:
            break;
        }
        SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, 0);
        Constant* digit = new Constant(se);
        new BinaryInstruction(opcode, dst, digit -> getOperand(), src, bb);
        isCond = expr -> isCond;
    }
}


//typecheck

void Ast::typeCheck()
{
    fprintf(yyout, ";TypeCheck Begin!\n");
    if(root != nullptr)
        root->typeCheck();
}

void FunctionDef::typeCheck()
{
    stmt->typeCheck();
}

void BinaryExpr::typeCheck()
{ 
    // Todo
    fprintf(yyout, ";BinaryExpr TypeCheck Begin!\n");
    Type *type1 = expr1 -> getSymPtr() -> getType();
    Type *type2 = expr2 -> getSymPtr() -> getType();
    std::string cmp1 = type1->toStr();
    std::string cmp2 = type2->toStr();
    if(cmp1=="void" || cmp1=="void()" || cmp2=="void" || cmp2=="void()"){
        fprintf(stderr, "void can't do operate\n");
        exit(EXIT_FAILURE);
    }
    if(cmp1=="i1") cmp1="i32";
    if(cmp2=="i1") cmp2="i32";
    // 隐式类型转换
    if(cmp1 != cmp2 && cmp1 != cmp2+"()" && cmp2 != cmp1+"()"){
        fprintf(stderr, "type %s and %s mismatch2\n",
                type1 -> toStr().c_str(), type2 -> toStr().c_str());
        exit(EXIT_FAILURE);
    }
    fprintf(yyout, ";BinaryExpr TypeCheck OK!\n");
    symbolEntry -> setType(type1);
    expr1 -> typeCheck();
    expr2 -> typeCheck();
}

void Constant::typeCheck()
{

}

void Id::typeCheck()
{

}

void IfStmt::typeCheck()
{
    cond -> typeCheck();
    thenStmt -> typeCheck();
}

void IfElseStmt::typeCheck()
{
    cond -> typeCheck();
    thenStmt -> typeCheck();
    elseStmt -> typeCheck();
}

void CompoundStmt::typeCheck()
{
    stmt -> typeCheck();
}

void SeqNode::typeCheck()
{
    stmt1 -> typeCheck();
    stmt2 -> typeCheck();
}

void DeclStmt::typeCheck()
{
     for(long unsigned int i = 0; i < ids -> Assigns.size(); i++)
            {
                ids -> Assigns[i] -> typeCheck();
            }
}

void ReturnStmt::typeCheck()
{
    if(retValue != nullptr)
    {   
        retValue -> typeCheck();
    }
}

void AssignStmt::typeCheck()
{
    lval -> typeCheck();
    expr -> typeCheck();
    Type *type1 = lval -> getSymPtr() -> getType();
    Type *type2 = expr -> getSymPtr() -> getType();
    if(type1->isVoid()){
        fprintf(stderr, "type void can't be leftvalue\n");
        exit(EXIT_FAILURE);
    }
    if(type1->toStr() != type2->toStr() && type1->toStr() != type2->toStr()+"()" && type2->toStr() != type1->toStr()+"()"){
        fprintf(stderr, "type %s and %s mismatch\n",
                type1 -> toStr().c_str(), type2 -> toStr().c_str());
        exit(EXIT_FAILURE);
    }
}


void SingleStmt::typeCheck()
{
    expr -> typeCheck();
}

void FuncRParams::typeCheck()
{
    for(long unsigned int i = 0; i < Exprs.size(); i++)
    {
        Exprs[i] -> typeCheck();
    }
}

void Empty::typeCheck()
{
    
}

void FuncFParam::typeCheck()
{
    
}

void FuncFParams::typeCheck()
{
    
}

void ConstIdList::typeCheck()
{
    
}

void IdList::typeCheck()
{
    
}

void WhileStmt::typeCheck()
{
    cond -> typeCheck();
    loop -> typeCheck();
}

void FunctionCall::typeCheck()
{
    
}

void ConstDeclStmt::typeCheck()
{
    
}

void ContinueStmt::typeCheck()
{
    
}

void BreakStmt::typeCheck()
{
    
}

void ConstId::typeCheck()
{
    
}

void SingleExpr::typeCheck()
{
    Type *type = expr -> getSymPtr() -> getType();
    if(type -> isVoid()){
        fprintf(stderr, "type can't be void");
        exit(EXIT_FAILURE);
    }
    symbolEntry -> setType(type);
    expr -> typeCheck();
}


//output 

void Ast::output()
{
    fprintf(yyout, "program\n");
    if(root != nullptr)
        root->output(4);
}

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
    fprintf(yyout, "%*cBinaryExpr\top: %s\n", level, ' ', op_str.c_str());
    expr1->output(level + 4);
    expr2->output(level + 4);
}

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
    fprintf(yyout, "%*cSingleExpr\top: %s\n", level, ' ', op_str.c_str());
    expr->output(level + 4);
}


void Constant::output(int level)
{
    std::string type, value;
    type = symbolEntry->getType()->toStr();
    value = symbolEntry->toStr();
    fprintf(yyout, "%*cIntegerLiteral\tvalue: %s\ttype: %s\n", level, ' ',
            value.c_str(), type.c_str());
}

void ConstId::output(int level)
{
    std::string name, type;
    int scope;
    name = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry)->getScope();
    fprintf(yyout, "%*cConstId\tname: %s\tscope: %d\ttype: %s\n", level, ' ',
            name.c_str(), scope, type.c_str());
}

void Id::output(int level)
{
    std::string name, type;
    int scope;
    name = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry)->getScope();
    fprintf(yyout, "%*cId\tname: %s\tscope: %d\ttype: %s\n", level, ' ',
            name.c_str(), scope, type.c_str());
}

void FuncFParam::output(int level)
{
    std::string name, type;
    int scope;
    name = symbolEntry -> toStr();
    type = symbolEntry -> getType() -> toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry) -> getScope();
    fprintf(yyout, "%*cFuncFParam\tname:%s\tscope:%d\ttype:%s\n", level, ' ',
            name.c_str(), scope, type.c_str());
}

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

void BreakStmt::output(int level)
{
    fprintf(yyout, "%*cBreakStmt\n", level, ' ');
}

void ContinueStmt::output(int level)
{
    fprintf(yyout, "%*cContinueStmt\n", level, ' ');
}

void DeclStmt::output(int level)
{
    fprintf(yyout, "%*cDeclStmt\n", level, ' ');
    ids->output(level + 4);
}

void ConstDeclStmt::output(int level)
{
    fprintf(yyout, "%*cConstDeclStmt\n", level, ' ');
    CIdList->output(level + 4);
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

void FunctionDef::output(int level)
{
    std::string name, type;
    name = se->toStr();
    type = se->getType()->toStr();
    fprintf(yyout, "%*cFunctionDefine function name: %s, type: %s\n", level, ' ', 
            name.c_str(), type.c_str());
    if(FPs != nullptr){
        FPs -> output(level + 4);
    }
    stmt->output(level + 4);
}

void FunctionCall::output(int level)
{
    std::string name, type;
    name = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    fprintf(yyout, "%*cFuncCall\tname: %s\ttype: %s\n", level, ' ',
            name.c_str(), type.c_str());
    if(RPs != nullptr)
    {
        RPs -> output(level + 4);
    }
}

void WhileStmt::output(int level)
{
    fprintf(yyout, "%*cWhileStmt\n", level, ' ');
    cond->output(level + 4);
    loop->output(level + 4);
}

void IdList::output(int level)
{
    fprintf(yyout, "%*cIdList\n", level, ' ');
    for(long unsigned int i = 0; i < Ids.size(); i++)
    {
        Ids[i] -> output(level + 4);
    }
    for(long unsigned int i = 0; i < Assigns.size(); i++)
    {
        Assigns[i] -> output(level + 4);
    }
}
void ConstIdList::output(int level)
{
    fprintf(yyout, "%*cConstIdList\n", level, ' ');
    for(long unsigned int i = 0; i < CIdList.size(); i++)
    {
        CIdList[i] -> output(level + 4);
        Assigns[i] -> output(level + 4);
    }
}

void FuncFParams::output(int level)
{
    fprintf(yyout, "%*cFuncFParams\n", level, ' ');
    for(long unsigned int i = 0; i < FPs.size(); i++)
    {
        FPs[i] -> output(level + 4);
    }
    for(long unsigned int i = 0; i < Assigns.size(); i++)
    {
        Assigns[i] -> output(level + 4);
    }
}

void FuncRParams::output(int level)
{
    fprintf(yyout, "%*cFuncRParams\n", level, ' ');
    for(long unsigned int i = 0; i < Exprs.size(); i++)
    {
        Exprs[i] -> output(level + 4);
    }
}

void Empty::output(int level)
{
    fprintf(yyout, "%*cEmpty Statement\n", level, ' ');
}

void SingleStmt::output(int level)
{
    fprintf(yyout, "%*cSingle Statement\n", level, ' ');
    expr -> output(level + 4);
}
