/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
    if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
        YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

 /*
  *  Add Your own definitions here
  */

int yy_comment_nesting = 0; /* count comment nesting*/

%}

 /*
  * these are elements used to handle string/string-like constructs
  */

%x yy_string
%x yy_str_err
%x yy_escape
%x yy_comment

 /*
  * Define names for regular expressions here.
  */

 /*
  * Define regular expressions for case insensitive keywords
  */
DIGITS      [0-9]+
CLASS       ?i:class
ELSE        ?i:else
FI          ?i:fi
IF          ?i:if
IN          ?i:in
INHERITS    ?i:inherits
LET         ?i:let
LOOP        ?i:loop
POOL        ?i:pool
THEN        ?i:then
WHILE       ?i:while
CASE        ?i:case
ESAC        ?i:esac
OF          ?i:of
NEW         ?i:new
ISVOID      ?i:isvoid
NOT         ?i:not

 /*
  * Define regular expressions for operators
  */

DARROW      "=>"
ASSIGN      "<-"
LE          "<="

 /*
  * Define regular expressions special chars or sequence of chars
  */

COMMA           [\,]
DOT             [\.]
OPEN_FLWR_BRACE [\{]
CLSE_FLWR_BRACE [\}]
OPEN_BRACE      [\(]
CLSE_BRACE      [\)]
COLON           [\:]
SEMI_COLON      [\;]
STR_DELIM       [\"]
PLUS            [\+]
MINUS           [\-]
STAR            [\*]
OTH_SLASH       [\/]
TIDLE           [\~]
LEFT_ANGLE      [\<]
EQUAL           [\=]
AT              [\@]
COMMENT_START   "(*"
COMMENT_END     "*)"
SGL_COMMENT     --(.)*
TYPE_ID         [A-Z][A-Za-z0-9_]*
OBJECTID        [a-z][A-Za-z0-9_]*
TRUE            (t)(?i:rue)
FALSE           (f)(?i:alse)
WS              [ \f\r\t\v]+

%%

 /*
  *  The multiple-character operators.
  */

\n              { ++curr_lineno;    }
{DARROW}        { return (DARROW);  }
{ASSIGN}        { return (ASSIGN);  }
{LE}            { return (LE);      }

 /*
  *  Rules for case insensitive keywords.
  */

{CLASS}         { return (CLASS);   }
{ELSE}          { return (ELSE);    }
{FI}            { return (FI);      }
{IF}            { return (IF);      }
{IN}            { return (IN);      }
{INHERITS}      { return (INHERITS);}
{LET}           { return (LET);     }
{LOOP}          { return (LOOP);    }
{POOL}          { return (POOL);    }
{THEN}          { return (THEN);    }
{WHILE}         { return (WHILE);   }
{CASE}          { return (CASE);    }
{ESAC}          { return (ESAC);    }
{OF}            { return (OF);      }
{NEW}           { return (NEW);     }
{ISVOID}        { return (ISVOID);  }
{NOT}           { return (NOT);     }


{DIGITS}        {
                    cool_yylval.symbol = idtable.add_string(yytext);
                    return (INT_CONST);
                }
 /*
  * Rules for case sensitive keywords.
  */

 /*
  * Booleans are to be matched before object id RE,
  * as objectId can also match bools, ie bools are also objectId
  */

{TRUE}          {
                    cool_yylval.boolean = true;
                    return BOOL_CONST;
                }
{FALSE}         {
                    cool_yylval.boolean = false;
                    return BOOL_CONST;
                }
{TYPE_ID}       {
                    cool_yylval.symbol = idtable.add_string(yytext);
                    return (TYPEID);
                }
{OBJECTID}      {
                    cool_yylval.symbol = idtable.add_string(yytext);
                    return (OBJECTID);
                }

{DOT}               { return '.';       }
{OPEN_FLWR_BRACE}   { return '{';       }
{CLSE_FLWR_BRACE}   { return '}';       }
{OPEN_BRACE}        { return '(';       }
{CLSE_BRACE}        { return ')';       }
{COLON}             { return ':';       }
{SEMI_COLON}        { return ';';       }
{COMMA}             { return ',';       }
{PLUS}              { return '+';       }
{MINUS}             { return '-';       }
{STAR}              { return '*';       }
{OTH_SLASH}         { return '/';       }
{TIDLE}             { return '~';       }
{LEFT_ANGLE}        { return '<';       }
{EQUAL}             { return '=';       }
{AT}                { return '@';       }

 /*
  * Comments
  */

{COMMENT_END}       {
                        cool_yylval.error_msg = "Unmatched *)";
                        return ERROR;
                    }
{COMMENT_START}     {
                        //Begin comments
                        ++yy_comment_nesting;
                        BEGIN(yy_comment);
                    }
<yy_comment>{COMMENT_START} {
                        ++yy_comment_nesting;
                    }

<yy_comment>{COMMENT_END}  {
                        --yy_comment_nesting;
                        if(yy_comment_nesting == 0)
                        {
                            BEGIN(INITIAL);
                        }
                        else if(yy_comment_nesting < 0)
                        {
                            cool_yylval.error_msg   = "Unmatched *)";
                            yy_comment_nesting      = 0;
                            BEGIN(INITIAL);
                            return ERROR;
                        }
                    }

<yy_comment>\n      {  ++curr_lineno;    }
<yy_comment><<EOF>> {
                        BEGIN(INITIAL);
                        if(yy_comment_nesting > 0)
                        {
                            cool_yylval.error_msg   = "EOF in comment.";
                            yy_comment_nesting      = 0;
                            return ERROR;
                        }
                    }

<yy_comment>.       { /* eating comments. Nom nom ...   */ }
<yy_comment>{WS}    { /* eating white space in comments */ }
{SGL_COMMENT}       { /* eating single line comments.   */ }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  *
  */

{STR_DELIM}             {
                            //Begin string constant
                            BEGIN(yy_string);
                            string_buf_ptr = string_buf;
                        }
<yy_string>{STR_DELIM}  {
                            //End of string constant
                            if(string_buf_ptr - string_buf > MAX_STR_CONST-1)
                            {
                                *string_buf             = '\0';
                                cool_yylval.error_msg   = "String constant too long.";
                                BEGIN(yy_escape);
                                return ERROR;
                            }
                            *string_buf_ptr     = '\0';
                            cool_yylval.symbol  = stringtable.add_string(string_buf);
                            BEGIN(INITIAL);
                            return STR_CONST;
                        }
<yy_string>\n           {
                            BEGIN(INITIAL);
                            *string_buf_ptr     = '\0';
                            cool_yylval.error_msg = "Unterminated string constant.";
                            return ERROR;
                        }
<yy_string><<EOF>>      {
                            BEGIN(INITIAL);
                            *string_buf_ptr     = '\0';
                            cool_yylval.error_msg = "EOF in string constant.";
                            return ERROR;
                        }
<yy_string>\\\x00       {
                            BEGIN(yy_str_err);
                            *string_buf_ptr     = '\0';
                            cool_yylval.error_msg = "String contains escaped null character.";
                            return ERROR;            
                        }
<yy_string>\x00        {
                            BEGIN(yy_str_err);
                            *string_buf_ptr     = '\0';
                           cool_yylval.error_msg = "String contains null character.";
                           return ERROR;
                        }
<yy_str_err>.           {}
<yy_str_err>\n          {}
<yy_str_err>\"          { BEGIN(INITIAL); }
<yy_string>"\\n"        { *string_buf_ptr++ = '\n';     }
<yy_string>"\\t"        { *string_buf_ptr++ = '\t';     }
<yy_string>"\\b"        { *string_buf_ptr++ = '\b';     }
<yy_string>"\\f"        { *string_buf_ptr++ = '\f';     }
<yy_string>"\\"[^\0]    { *string_buf_ptr++ = yytext[1];}
<yy_string>.            { *string_buf_ptr++ = *yytext;  }
<yy_escape>[\n|"]       { BEGIN(INITIAL);               }
<yy_escape>[^\n|"]      { /* escape malformed string */ }

{WS}                        /* eat up whitespace */

 /*
  * when nothing matches
  */
.                       {
                            cool_yylval.error_msg = yytext;
                            return ERROR;
                        }

%%