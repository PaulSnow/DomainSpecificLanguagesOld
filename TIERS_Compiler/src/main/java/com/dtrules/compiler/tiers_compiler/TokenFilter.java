/*  
 * Copyright 2004-2009 DTRules.com, Inc.
 *   
 * Licensed under the Apache License, Version 2.0 (the "License");  
 * you may not use this file except in compliance with the License.  
 * You may obtain a copy of the License at  
 *   
 *      http://www.apache.org/licenses/LICENSE-2.0  
 *   
 * Unless required by applicable law or agreed to in writing, software  
 * distributed under the License is distributed on an "AS IS" BASIS,  
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  
 * See the License for the specific language governing permissions and  
 * limitations under the License.  
 */
package com.dtrules.compiler.tiers_compiler;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.HashMap;

import com.dtrules.compiler.tiers_compiler.cup.parser.RLocalType;
import com.dtrules.compiler.tiers_compiler.cup.parser.RSymbol;
import com.dtrules.compiler.tiers_compiler.cup.parser.sym;
import com.dtrules.entity.IREntity;
import com.dtrules.entity.REntity;
import com.dtrules.infrastructure.RulesException;
import com.dtrules.interpreter.IRObject;
import com.dtrules.interpreter.RName;
import com.dtrules.session.DTState;
import com.dtrules.session.IRSession;
import com.dtrules.session.IRType;

import java_cup.runtime.*;

public class TokenFilter implements Scanner{
    
    Scanner                     scanner;
    HashMap<RName, IRType>       types;
    IRSession                   session;
    DTState                     state;
    boolean                     EOF         = false;
    RSymbol                     lastToken   = null;
    RSymbol                     unget       = null;
    ArrayList<String>           tokens      = new ArrayList<String>();
    HashMap<String,RLocalType>  localtypes  = null;
    String						possessive  = null;
    
    public ArrayList<String> getParsedTokens(){
        return tokens;
    }
    
    TokenFilter(IRSession session, Scanner scanner, HashMap<RName, IRType> types, HashMap<String,RLocalType> localtypes){
        this.types      = types;
        this.scanner    = scanner;
        this.session    = session;
        this.state      = session.getState();
        this.localtypes = localtypes;
    }
    
    /**
     * Look up an Identifier in the symbol table and return its type.
     * @param ident
     * @return
     */
    int identType(String ident,String entity){
        
           TIERS_Type type = (TIERS_Type) types.get(RName.getRName(ident,true));
           boolean defined = true;
           if(entity != null && entity.length()!=0 && type!=null){
              defined = false;
              for(IREntity rEntity : type.getEntities()){
                  if(entity.equalsIgnoreCase(rEntity.getName().stringValue())){
                      if(rEntity.containsAttribute(RName.getRName(ident))){
                          defined = true;
                      }
                      break;
                  }
              }
           }
           if(type==null || defined==false){
               RName rname = RName.getRName(
                  (entity==null||entity.length()==0?"":entity+".")+ident);
               try {
                  IRObject o = session.getState().find(rname);
                  if(o==null)return -1;
                  return o.type().getId();
                } catch (RulesException e) {
                  return -1;
                }
           }
           
           type.addRef(entity);
           
           return type.getType();
         
    }
    /**
     * Looks at the sym.class with reflection and looks up the type
     * associated with the given code.
     * 
     * @param type integer code associated with a symbol.
     */
    private String type2str(int type){
        try{
            @SuppressWarnings("rawtypes")
            Class   tokentypes  = sym.class;
            Field[] types       = tokentypes.getDeclaredFields();
            for(int i=0;i<types.length;i++){
                String typeName = types[i].getName();
                String fieldType = types[i].getType().getName();
                if(fieldType.equals("int")&&types[i].getInt(types[i])==type){
                    return typeName; 
                }
            }
        }catch(Exception e){
            //Who Cares?  Ignore!
        }
        return "-not found-";
    }
    
    
    public Symbol next_token() throws Exception {
        RSymbol next=null;
        
        if(unget!=null){
            next  = unget;
            unget = null;
        }else{
            try {
              next = new RSymbol(false, scanner.next_token());
              if(next.sym == sym.ID){
                  next.leftvalue = "/"+next.value.toString()+" xdef ";
              }
            } catch (Error e) {
              throw new Exception(e);
            }
        }
        
        
        if(EOF || next.value==null || next.sym == sym.EOP){
                next.value="EOP";
                next.sym=sym.EOP;
                if(next.sym != sym.EOP){
                   EOF = true;
                }
        }else{
            EOF = false;
        }
        
        
        if(next.sym==sym.ID){
            String entity  = "";
            String ident   = next.value.toString();
            if(ident.indexOf('.')>=0){
                entity=ident.substring(0,ident.indexOf('.'));
                ident =ident.substring(ident.indexOf('.')+1);
            }
            
            int    theType = identType(ident,entity);
            
            if(theType == -1 ){
                if(localtypes.containsKey(next.value.toString().toLowerCase())){
                    RLocalType t = localtypes.get(next.value.toString().toLowerCase());
                    theType = t.type;
                    next = new RSymbol(true, next);
                    next.value = t.index +" local@ ";
                    ((RSymbol)next).leftvalue = t.index +" local! ";
                }
            }
            
            // Need to figure out USROPER ... edd.isUserOperator(token)
            if   (theType == IRObject.iEntity           ){ next.sym=(sym.ENTITY); 
            } else if (theType == IRObject.iBoolean          ){ next.sym=(sym.BOOL_ID);       
            } else if (theType == IRObject.iArray            ){ next.sym=(sym.RLIST);         
            } else {
                next.sym = sym.ID;
            }
        }
        
        tokens.add(next.sym+" "+type2str(next.sym)+" "+next.value.toString());
        lastToken = next;
        return next;
    
    }

    @Override
    public String toString() {
        StringBuffer sbuff = new StringBuffer();
        for(String token: tokens){
            sbuff.append(token);
            sbuff.append(", ");
        }
        return sbuff.toString();
    }
    
    

}
