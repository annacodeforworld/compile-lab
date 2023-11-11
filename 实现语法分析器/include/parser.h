/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_INCLUDE_PARSER_H_INCLUDED
# define YY_YY_INCLUDE_PARSER_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 12 "src/parser.y"

    #include "Ast.h"
    #include "SymbolTable.h"
    #include "Type.h"

#line 55 "include/parser.h"

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    ID = 258,                      /* ID  */
    INTEGER = 259,                 /* INTEGER  */
    IF = 260,                      /* IF  */
    ELSE = 261,                    /* ELSE  */
    BREAK = 262,                   /* BREAK  */
    CONTINUE = 263,                /* CONTINUE  */
    WHILE = 264,                   /* WHILE  */
    INT = 265,                     /* INT  */
    VOID = 266,                    /* VOID  */
    CHAR = 267,                    /* CHAR  */
    CONST = 268,                   /* CONST  */
    LPAREN = 269,                  /* LPAREN  */
    RPAREN = 270,                  /* RPAREN  */
    LBRACE = 271,                  /* LBRACE  */
    RBRACE = 272,                  /* RBRACE  */
    SEMICOLON = 273,               /* SEMICOLON  */
    COMMA = 274,                   /* COMMA  */
    ADD = 275,                     /* ADD  */
    SUB = 276,                     /* SUB  */
    MUL = 277,                     /* MUL  */
    DIV = 278,                     /* DIV  */
    EXCLAMATION = 279,             /* EXCLAMATION  */
    MORE = 280,                    /* MORE  */
    OR = 281,                      /* OR  */
    AND = 282,                     /* AND  */
    LESS = 283,                    /* LESS  */
    ASSIGN = 284,                  /* ASSIGN  */
    EQUAL = 285,                   /* EQUAL  */
    NOEQUAL = 286,                 /* NOEQUAL  */
    LESSEQUAL = 287,               /* LESSEQUAL  */
    MOREEQUAL = 288,               /* MOREEQUAL  */
    MOD = 289,                     /* MOD  */
    RETURN = 290,                  /* RETURN  */
    LINECOMMENT = 291,             /* LINECOMMENT  */
    COMMENTBEIGN = 292,            /* COMMENTBEIGN  */
    COMMENTELEMENT = 293,          /* COMMENTELEMENT  */
    COMMENTLINE = 294,             /* COMMENTLINE  */
    COMMENTEND = 295,              /* COMMENTEND  */
    THEN = 296                     /* THEN  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 18 "src/parser.y"

    int itype;
    char* strtype;
    StmtNode* stmttype;
    ExprNode* exprtype;
    Type* type;

    IdList* Idlisttype;
    FuncFParams* Fstype;
    FuncRParams* FRtype;
    ConstIdList* CIdListtype;

#line 126 "include/parser.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_INCLUDE_PARSER_H_INCLUDED  */
