/* --------------------------Usercode Section------------------------ */
package com.dtrules.compiler.tiers_compiler.flex.scanner;   

import com.dtrules.compiler.tiers_compiler.cup.parser.sym;
import com.dtrules.compiler.tiers_compiler.cup.parser.ParserUtil;
import java_cup.runtime.*;
import java.util.Vector;
      
%%
   
/* -----------------Options and Declarations Section----------------- */

%public
%class Lexer

%xstate COMMENTS
%xstate TABLENAME
%state  LEXING   
%xstate SKIPSTATE
%state  FINDSTATEMENT
%xstate NEWSTATEMENT

%line
%column  
%cup

%unicode
%caseless
%ignorecase

   
%{   
    Vector tablesCalled = null;
    public String sCurrentTableName = "";
    StringBuffer tableName = new StringBuffer();
    public StringBuffer sbLexOut = new StringBuffer();
    boolean bPrint = true;
    
    boolean conditionState = true;
      
    public int getColumn(){ return yycolumn; }
    
    private Symbol symbol(int type, Object value) 
    {
        return new Symbol(type, yyline, yycolumn, value);
    }

    private void dprint(String s)
    {
	   if ( bPrint)
	   {
         System.out.print(s);
	   }
	   else
	   {
		 sbLexOut.append(s);
	   }
    }
    
    private void addToListOfTables(String sName)
    {
        if (this.tablesCalled != null)
        { 
            sName = sName.trim();                        
            String vectorValue = sName.substring(1,sName.length()-1) + "@@@@@" + this.sCurrentTableName;
            if (vectorValue == null)
            {
              System.out.println("Inserting a null in vector containing list of tables called."); 
            }            
	      this.tablesCalled.add(vectorValue);		       
        }                
    }
%}

LineTerminator = \r|\n|\r\n
WhiteSpace     = {LineTerminator} | [ \t\f]
dec_int_id = [A-Za-z][A-Za-z_0-9_"."]*
GREATER=(">"|"&gt;")
LESS=("<"|"&lt;")
ALPHA=[A-Za-z]
DIGIT=[0-9]
DIGITS=({DIGIT})+
FLOAT={DIGIT}*("."{DIGIT}+)?
TABLEIDENT=({ALPHA}|{DIGIT}|_|-|"."|"%")*
LITERAL_CHAR1=[^"'"]
LITERAL_CHAR2=[^"\""]
NOT_EOP       =([^";"]|([";"][^";"]))*        
EOP           =[";"][";"]
LITERAL=(\'({LITERAL_CHAR1})*\')|(\"({LITERAL_CHAR2})*\")
SPACE=[ \t\b\n\r]
SPACES=({SPACE})+
ANYTHING=(.|[ \t\b\n\r])*
MONTHSOFYEAR=JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC

   
%%
/* ------------------------Lexical Rules Section---------------------- */
    
"//"{ANYTHING}               { dprint(" EOP "); return symbol(sym.EOP, yytext()); }
"/*"{ANYTHING}"*/"           {}

<YYINITIAL> 
{         
  . {
	   yybegin(NEWSTATEMENT);
	   yypushback(1);
	}
}

"the"|"an"|"a"		{ }

individual{SPACES}is{SPACES}(the{SPACES}|an{SPACES})?applicant {
                     yypushback(9);
                    }

				
{WhiteSpace}       	{ /* just skip what was found, do nothing */ }


<NEWSTATEMENT> {
    ({SPACES})*CONDITION           { dprint("\nCONDITION: "); 
                                     yybegin(LEXING);
                                     conditionState = true;
                                     return symbol(sym.CONDITION, yytext()); }
    ({SPACES})*ACTION              { dprint("\nACTION: ");
                                     yybegin(LEXING);
                                     conditionState = false;
                                     return symbol(sym.ACTION, yytext());    }
    .                              {
                                     yybegin(LEXING);      
                                     yypushback(1);                  
                                   }                                     
}

<TABLENAME>  
{
  ({SPACES}for{SPACES}each)|({SPACES}for{SPACES}all)|"--EOF--"
				{ 	 
					yypushback(yytext().length());
					yybegin(LEXING);
				    String sName;
					if (tableName.toString().indexOf("'") > 0)
					{
						sName = "\"" + tableName.toString().trim() + "\"" ;
					}
					else
					{
						sName = "\'" + tableName.toString().trim() + "\'" ;
					}
					tableName.setLength(0);
					dprint(sName);
					addToListOfTables(sName);					
					return symbol(sym.TABLENAME, sName); 
				}
				
  ({TABLEIDENT}|{DIGITS}|{LITERAL}|","|"$"|"*"|"'"|"("|")"|"+")+
			    {
					tableName.append(" " + yytext().trim());
				}
  
  {WhiteSpace}       { }
  
  ;;			     {      
					 yypushback(yytext().length()); 
					 String sName = "\'" + tableName.toString().trim() + "\'" ;      			 
					 if (tableName.toString().indexOf("'") > 0)
					 {
						sName = "\"" + tableName.toString().trim() + "\"" ;
					 }
					 else
					 {
						sName = "\'" + tableName.toString().trim() + "\'" ;
					 }
					 tableName.setLength(0);
					 yybegin(LEXING);
	 				 dprint(sName);
 					 addToListOfTables(sName);
					 return symbol(sym.TABLENAME,sName); 
		           }				 
}

<LEXING>
{
    
    "--EOF--"                      { dprint("--EOF--"); return symbol(sym.EOP,"EOF"); }
    
    SKIP                           { yybegin(SKIPSTATE);
                                     return symbol(sym.SKIP,"skip"); }

    where|whose|which{SPACES}is|for{SPACES}which{SPACES}|who{SPACES}is  
	                                   { dprint(" WHERE "); return symbol(sym.WHERE, yytext()); }

    set                            { dprint(" SET "); return symbol(sym.SET, yytext()); }

    using                          { dprint(" USING "); return symbol(sym.USING, yytext()); }

    exit{NOT_EOP}                  { dprint(" EXIT "); return symbol(sym.EXIT, yytext()); }

    find                           { yybegin(FINDSTATEMENT); }  
    
    and{SPACES}set                 { dprint(" ANDSET "); return symbol(sym.ANDSET, yytext()); }
    
    in{SPACES}years                { dprint(" DATEMODIFIER ");  return symbol(sym.DATEMODIFIER,"setyear"); } 
    in{SPACES}months               { dprint(" DATEMODIFIER ");  return symbol(sym.DATEMODIFIER,"setmonth"); } 
    in{SPACES}days                 { dprint(" DATEMODIFIER ");  return symbol(sym.DATEMODIFIER,"setday"); } 

    month{SPACES}of{SPACES}{dec_int_id} 
                                   {                
                                       String id = yytext().substring(yytext().lastIndexOf(" "));
                                     
		                               dprint(" ID ");  return symbol(sym.ID, id + " monthof");
		                           }
		                           
    end                            { dprint(" END ");          return symbol(sym.END, yytext()); }
    start                          { dprint(" START ");        return symbol(sym.START, yytext()); }
    of                             { dprint(" OF ");           return symbol(sym.OF, yytext()); }
    on                             { dprint(" ON ");           return symbol(sym.ON, yytext()); }

    if                             { dprint(" IF ");           return symbol(sym.IF, yytext()); }
    then                           { dprint(" THEN ");         return symbol(sym.THEN, yytext()); }

    sum{SPACES}of{SPACES}(each|the) {dprint(" SUMOFEACH ");	   return symbol(sym.SUMOFEACH, yytext()); }

    sort                           { dprint(" SORT ");         return symbol(sym.SORT, yytext()); }
    ascending                      { dprint(" ASCENDING ");    return symbol(sym.ASCENDING, yytext()); }
    descending                     { dprint(" DESCENDING ");   return symbol(sym.DESCENDING, yytext()); }
    by                             { dprint(" BY ");           return symbol(sym.BY, yytext()); }

  }

  <FINDSTATEMENT> {
        a{SPACES}person            { dprint(" FINDAPERSON "); 
                                     yybegin(LEXING); 
                                     return symbol(sym.FINDAPERSON, yytext()); }

        all{SPACES}persons
                                   { dprint(" FINDALLPERSONS ");
                                     yybegin(LEXING); return  
                                     symbol(sym.FINDALLPERSONS, yytext()); }

        individual{SPACES}         { dprint(" FINDINDIVIDUAL ");
                                     yybegin(LEXING); 
                                     return symbol(sym.FINDINDIVIDUAL, yytext()); 
                                   }
        edg_individual             { dprint(" FINDINDIVIDUAL ");
                                     yybegin(LEXING); 
                                     return symbol(sym.FINDINDIVIDUAL, yytext());                                       
                                   }    

        all{SPACES}edg_individuals { dprint(" FINDALLEDGINDIVIDUAL ");
                                     yybegin(LEXING); 
                                     return symbol(sym.FINDALLEDGINDIVIDUAL, yytext()); 
                                   } 

       (a|an){SPACES}element      {                                  
	                                dprint(" FINDAELEMENT[FINDAELEMENT] "); 
                                      yybegin(LEXING); 
		                          return symbol(sym.FINDAELEMENT, yytext());		               
		                      }                                   
      
      (a|an){SPACES}{dec_int_id}  {                                      
                                      String sEntity = (yytext().substring(1,yytext().length())).trim();
	                                  dprint(" ENTITY["+sEntity+"] "); 
                                          yybegin(LEXING); 
		                              return symbol(sym.FINDAENTITY, sEntity);		               
		                      }
  }

  <LEXING> {
  
    {NOT_EOP}{LESS}postfix{GREATER}{NOT_EOP}{LESS}"/postfix"{GREATER}{NOT_EOP}
                                   { String postfix = yytext();
                                     if(postfix.indexOf("&lt;")>0){
                                       postfix = postfix.substring(
                                                    postfix.indexOf("&lt;postfix&gt;")+15, 
                                                    postfix.indexOf("&lt;/postfix&gt;")).trim();
                                     }else{               
                                       postfix = postfix.substring(
                                                    postfix.indexOf("<postfix>")+9, 
                                                    postfix.indexOf("</postfix>")).trim();
                                     }
                                     yybegin(NEWSTATEMENT);
                                     if(conditionState){
                                       dprint(" CPOSTFIX "+postfix+"\n");
                                       return symbol(sym.CPOSTFIX, postfix);
                                     }else{  
                                       dprint(" CPOSTFIX "+postfix+"\n");
                                       return symbol(sym.APOSTFIX, postfix);
                                     }  
                                    }
                                     
    and{SPACES}find{SPACES}individual
		                   { dprint(" ANDFINDINDIVIDUAL ");
                                     return symbol(sym.ANDFINDINDIVIDUAL, yytext()); 
                                   }    

    and{SPACES}find{SPACES}referenced{SPACES}individual  {
                                          dprint(" ISA ");  return symbol(sym.ANDFINDREFERNCEDINDIVIDUAL, yytext());    
                                       }
    
    there{SPACES}is{SPACES}no { dprint(" THEREISNO ");    return symbol(sym.THEREISNO, yytext()); }
  
    within{SPACES}the                            { dprint(" WITHIN ");       return symbol(sym.WITHIN, yytext()); }
  
    edg_individual{SPACES}(in|within){SPACES}the{SPACES}edg_group{SPACES}has
                                                 { dprint(" EDGINDIVHAS ");  return symbol(sym.EDGINDIVHAS, yytext()); }

    individual{SPACES}is{SPACES}(a|an){SPACES}   { dprint(" ISA ");          return symbol(sym.ISA, yytext());}

    individual{SPACES}has{SPACES}a{SPACES}person { dprint(" HASAPERSON ");   return symbol(sym.HASAPERSON, yytext()); }

    to{SPACES}(a|an){SPACES}person{SPACES}       { dprint(" TOAPERSON ");    return symbol(sym.TOAPERSON, yytext()); }
    
    individual{SPACES}has{SPACES}(a|an){SPACES}  {  dprint(" HASA ");        return symbol(sym.HASA, yytext());}
    
    who{SPACES}has{SPACES}(a|an){SPACES}
                                   { dprint(" WHOHASA "); return symbol(sym.WHOHASA, yytext()); }
        
    is{SPACES}there({SPACES}(a|an))?|there{SPACES}is({SPACES}(a|an))? 
                                   { dprint(" ISTHERE "); return symbol(sym.ISTHERE, yytext()); }
                                   
    does                           { dprint(" DOES "); return symbol(sym.DOES, yytext()); } 

    has                            { dprint(" HAS "); return symbol(sym.HAS, yytext()); } 

    for{SPACES}every               { dprint(" FOREVERY "); return symbol(sym.FOREVERY, yytext()); }                                                                                                                 

    every                          { dprint(" EVERY "); return symbol(sym.EVERY, yytext()); }                                                                                                                 
                                       
    of{SPACES}(the{SPACES})?individual{SPACES}have                       
                                   { dprint(" OFINDIVIDUALHAVE "); return symbol(sym.OFINDIVIDUALHAVE, yytext()); } 
                                   
    perform{SPACES}when{SPACES}called { return symbol(sym.BOOL, "true");}
	
    Perform{SPACES}{LITERAL}	   {  
                           String sName = yytext().substring(yytext().indexOf(" "), yytext().length());
	       					addToListOfTables(sName);
          					return symbol(sym.TABLENAME, sName);
				         }

    true{SPACES}if{SPACES}	     { dprint(" TRUEIF ");       return symbol(sym.TRUEIF, yytext()); }

    false{SPACES}if{SPACES}	     { dprint(" FALSEIF ");      return symbol(sym.TRUEIF, yytext()); }

    ->|"-"{GREATER}                { dprint(" -> ");           return symbol(sym.ARROW, yytext());  }   

    perform			           { dprint(" PERFORM "); tableName.setLength(0); yybegin(TABLENAME); }
    				   		
    copy                           { dprint(" COPY ");         return symbol(sym.COPY, yytext()); }  	

    from                           { dprint(" FROM ");         return symbol(sym.FROM, yytext()); }  	

    remove                         { dprint(" REMOVE ");       return symbol(sym.REMOVE, yytext()); }  	
   
    form{SPACES}(a|an)             { dprint(" FORMAGROUP ");   return symbol(sym.FORMAGROUP, yytext()); }

    called                         { dprint(" CALLED ");       return symbol(sym.CALLED, yytext()); }

    lookup                         { dprint(" LOOKUP ");       return symbol(sym.LOOKUP, yytext()); }

    code                           { dprint(" CODE ");         return symbol(sym.CODE, yytext()); }

    using{SPACES}column            { dprint(" USINGCOLUMN ");  return symbol(sym.USINGCOLUMN, yytext()); }

    from{SPACES}table              { dprint(" FROMTABLE ");    return symbol(sym.FROMTABLE, yytext()); }

    each                           { dprint(" EACH ");         return symbol(sym.EACH, yytext()); }

    for{SPACES}date                { dprint(" FORDATE ");      return symbol(sym.FORDATE, yytext()); }

    returning                      { dprint(" RETURNING ");    return symbol(sym.RETURNING, yytext()); }
    
    add{SPACES}all{SPACES}individuals{SPACES}to                 
                                   { dprint(" ADDALL ");       return symbol(sym.ADDALL, yytext()); } 
                        
    copy{SPACES}of{SPACES}all{SPACES}members{SPACES}in
                                   { dprint(" ACOPYOFALLMEMBERSIN "); return symbol(sym.ACOPYOFALLMEMBERSIN , yytext()); }

	add{SPACES}all{SPACES}edg_individuals{SPACES}to                 
                                   { dprint(" ADDALL_EDG_INDV "); 
                                      return symbol(sym.ADDALL_EDG_INDV, yytext()); 
                                   }

   and{SPACES}their  { dprint(" ANDTHEIR ");       return symbol(sym.ANDTHEIR, yytext()); }                                    
    
   and{SPACES}for{SPACES}each     
                     { dprint(" ANDFOREACH ");     return symbol(sym.ANDFOREACH, yytext()); }  

   is{SPACES}a{SPACES}member{SPACES}of
                     { dprint(" ISAMEMBEROF ");    return symbol(sym.ISAMEMBEROF, yytext()); }

   includes{SPACES}at{SPACES}least{SPACES}one{SPACES}member{SPACES}of
                     { dprint(" INCLUDESMEMBER "); return symbol(sym.INCLUDESMEMBER, yytext()); }

   {SPACES}for{SPACES}each{SPACES}
                     { dprint(" FOREACH ");        return symbol(sym.FOREACH, yytext()); }
   
   {SPACES}for{SPACES}all{SPACES}
                     { dprint(" FORALL ");         return symbol(sym.FORALL, yytext()); }

   to{SPACES}the{SPACES}context{SPACES}for{SPACES}this{SPACES}decision{SPACES}table
                     { dprint(" tothecontext ");   return symbol(sym.TOTHECONTEXT, yytext()); }    

   find{SPACES}the{SPACES}first
                     { dprint(" findthefirst ");   return symbol(sym.FINDTHEFIRST, yytext()); }
	   
   in{SPACES}(the{SPACES})? 
			  { dprint(" inthe ");           return symbol(sym.IN, yytext()); }

   element                                      
                    { dprint(" element ");           return symbol(sym.ELEMENT, yytext()); }
  
   and{SPACES}add{SPACES}it{SPACES}
                    { dprint(" andaddit ");        return symbol(sym.ANDADDIT, yytext()); }

   quit{SPACES}rules{SPACES}engine{SPACES}with{SPACES}error{SPACES}message   {
                      String msg = yytext().substring(yytext().lastIndexOf(" "));  
                      dprint(" THROWRULESEXCEPTION ");  return symbol(sym.THROWRULESEXCEPTION, yytext());
   				  }		
   	
   create{SPACES}comma{SPACES}list{SPACES}with   {
                                dprint(yytext()); 
					  return symbol(sym.COMMALIST, yytext());
                            }
			  
   true|false	 { 
					dprint(yytext()); 
					return symbol(sym.BOOL, yytext());
			     }     

    {MONTHSOFYEAR}     {
                          dprint(" MONTHSOFYEAR ");  
                          return symbol(sym.ID, " setmonth " +ParserUtil.getMonthOnlyDate(yytext()) + " createdate monthof setday" );
                       }

    for{SPACES}any{SPACES}of{SPACES}(the{SPACES})?     { 
                           dprint(" FORANYOFTHE ");  
                           return symbol(sym.FORANYOFTHE, "||");  
                       }

    {SPACES}for{SPACES}all{SPACES}of{SPACES}(the{SPACES})?     { 
                           dprint(" FORALLOFTHE ");  
                           return symbol(sym.FORALLOFTHE, "&&");  
                       }
                                                  			     
    greater{SPACES}of  { dprint(" GREATEROF ");  return symbol(sym.GREATEROF, yytext()); }
    
    lesser{SPACES}of   { dprint(" LESSEROF ");   return symbol(sym.LESSEROF, yytext()); }
        
    listequals         { dprint(" LISTEQUALS "); return symbol(sym.LISTEQUALS, yytext()); }
	
	rounded{SPACES}up{SPACES}for  
	                   { dprint(" ROUNDED ");    return symbol(sym.ROUNDED, yytext()); }	
	
	scaled{SPACES}to   { dprint(" SCALED ");     return symbol(sym.SCALED, yytext()); }	
	
	decimal{SPACES}places
	                   { dprint(" DECPLACES ");    return symbol(sym.DECPLACES, yytext()); }	
	 
                    	
	or{SPACES}more     { dprint(" ORMORE ");     return symbol(sym.ORMORE, yytext()); }
			     
    "[dummy]"{NOT_EOP} { dprint(" DUMMY "); return symbol(sym.DUMMY, yytext()); }
    "[true]"{NOT_EOP}  { dprint(" true ");  return symbol(sym.BOOL, "true" ); }
    "[false]"{NOT_EOP} { dprint(" false "); return symbol(sym.BOOL, "false"); }


    yes	 	           { dprint(yytext()); return symbol(sym.BOOL, "true" ); }  
    no	 	           { dprint(yytext()); return symbol(sym.BOOL, "false" ); }  
    
    individual{SPACES}is     {  dprint(" removing individual is "); }  			     

    size{SPACES}of   { dprint(yytext()); return symbol(sym.SIZEOF, yytext()); }                         

    ","              { dprint(" COMMA "); return symbol(sym.COMMA,            ","  ); }
    "<"|"&lt;"       { dprint(" < ");     return symbol(sym.LESSTHAN,         "<"  ); }
    ">"|"&gt;"       { dprint(" > ");     return symbol(sym.GREATERTHAN,      ">"  ); }
    ">="|"&gt;="     { dprint(" >= ");    return symbol(sym.GREATERTHANEQUALS,">=" ); }	
    "<="|"&lt;="     { dprint(" >= ");    return symbol(sym.LESSTHANEQUALS,   "<=" ); }	

    "||"|"or"	     { dprint(" || ");          return symbol(sym.OR,        "||" ); }
    "and"|"&&"|&amp;&amp; { dprint(" AND ");    return symbol(sym.AND,      "&&" ); }	
    "=="|"="         { dprint(" = ");           return symbol(sym.EQUALS,    "==" ); }
    "!="	         { dprint(" != ");          return symbol(sym.NOTEQUALS, "!=" ); }	
    "!"	     	     { dprint(" ! ");           return symbol(sym.NOT,       "!"  ); }	
    "+"              { dprint(" + ");           return symbol(sym.PLUS,      "+"  ); }
    "-"              { dprint(" - ");           return symbol(sym.MINUS,     "-"  ); }
    "*"              { dprint(" * ");           return symbol(sym.TIMES,     "*"  ); }
    "/"              { dprint(" / ");           return symbol(sym.DIVIDE,    "div"); }
    "("              { dprint(" ( ");           return symbol(sym.LPAREN,    "("  ); }
    ")"              { dprint(" ) ");           return symbol(sym.RPAREN,    ")"  ); }
    add              { dprint(" add ");         return symbol(sym.ADD,       "add"); }
    to               { dprint(" to ");          return symbol(sym.TO,        "to");  }
    plus             { dprint(" plus ");        return symbol(sym.PLUSSTR,   "plus");  }

    {DIGITS}     { 
                    try
                    {
                       Integer.parseInt(yytext());
                    }
                    catch(NumberFormatException e)
                    {
                       throw new Error(" Invalid integer : " +  yytext());
                    }
                    dprint(" INTEGER["+yytext()+"] ");
                    return symbol(sym.INTEGER,yytext());
	             }   
   
    {FLOAT}     { 
                    try
                    {
                       Float.valueOf(yytext());
                    }
                    catch(NumberFormatException e)
                    {
                       throw new Error(" Invalid float : " +  yytext());
                    }
                    dprint(" FLOAT["+yytext()+"] ");
                    return symbol(sym.FLOAT,yytext());
	             }   
	                              
    (years|months|days)
                 { 
                       dprint(" TIMEPERIOD["+yytext().substring(0,yytext().length()-1)+"] ");
                       return symbol(sym.TIMEPERIOD,yytext());
	            }   
 
    number{SPACES}of{SPACES}days
                 {
                       return symbol(sym.NUMBEROFTIMEPERIOD, "numberofdays");
                 }

    between      {
                      return symbol(sym.BETWEEN, yytext());
                 }

    number{SPACES}of{SPACES}months
                 {
                       return symbol(sym.NUMBEROFTIMEPERIOD, "numberofmonths");
                 }
                                  
    (year(s)?|month(s)?|day(s)?)
                 { 
                       dprint(" TIMEPERIOD["+yytext()+"] ");
                       return symbol(sym.TIMEPERIOD,yytext()+"s");
	             }   
	     
	is{SPACES}     {	              
	                   dprint(" IS ");
                       return symbol(sym.IS, yytext());          
	                }    
	
	(a{SPACES})?substring{SPACES}of  
	                {
                              dprint(" SUBSTRINGOF ");
                              return symbol(sym.SUBSTRINGOF, yytext());          	             
	                }
	               
        {dec_int_id}"'s"{SPACE} {
           String token = yytext();
           token = token.substring(0,token.indexOf("'s"));
           dprint(" POSSESSION["+token+"] ");
           return symbol(sym.POSSESSION, token);
        }      
                     
        {dec_int_id} {       

                       String  token      = yytext();    
                       dprint(" ID["+token+"] "); 
		               return symbol(sym.ID, token);		                   		               
		               	
                     }                     
                         
    {LITERAL}        { dprint(" STRING["+yytext()+"] ");
                       return symbol(sym.STR,   yytext());
                     }
}

<SKIPSTATE> {           
  ({ANYTHING})*         { return symbol(sym.SKIP, yytext()); }
}


{EOP}               { yybegin(NEWSTATEMENT);
                         dprint(" EOP ");
                         return symbol(sym.EOP, yytext()); }

[^]                    { throw new Error("Illegal character <"+yytext()+">"); }
