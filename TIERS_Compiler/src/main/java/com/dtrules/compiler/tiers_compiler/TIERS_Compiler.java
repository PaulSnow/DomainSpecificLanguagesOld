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

import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import java_cup.runtime.Symbol;

import com.dtrules.compiler.tiers_compiler.cup.parser.DTRulesParser;
import com.dtrules.compiler.tiers_compiler.cup.parser.RLocalType;
import com.dtrules.compiler.tiers_compiler.flex.scanner.Lexer;
import com.dtrules.entity.IREntity;
import com.dtrules.entity.REntity;
import com.dtrules.entity.REntityEntry;
import com.dtrules.infrastructure.RulesException;
import com.dtrules.interpreter.IRObject;
import com.dtrules.interpreter.RName;
import com.dtrules.session.EntityFactory;
import com.dtrules.session.ICompiler;
import com.dtrules.session.IRSession;
import com.dtrules.session.IRType;

public class TIERS_Compiler implements ICompiler {
    
    private       HashMap<RName,IRType>    types = null;
    private       EntityFactory            ef;
    private       IRSession                session;
       
    private       int                      localcnt = 0;  // Count of local variables 
                  HashMap<String,RLocalType> localtypes = new HashMap<String,RLocalType>();
       
    public void setTableName(String tablename) {
        
    }
    
    
    /**
     * Add a identifier and type to the types HashMap.
     * @param entity
     * @param name
     * @param itype
     * @throws Exception
     */
    private void addType( IREntity entity, RName name, int itype) throws Exception {
        TIERS_Type type =  (TIERS_Type) types.get(name);
        if(type==null){
            type      = new TIERS_Type(name,itype,entity);
            types.put(name,type);
        }else{
            if(type.getType()!=itype){
                String entitylist = entity.getName().stringValue();
                for(int i=0; i<type.getEntities().size(); i++){
                    entitylist += " "+type.getEntities().get(i).getName().stringValue();
                }
                throw new Exception("Conflicting types for attribute "+name+" on "+entitylist);
            }
            type.addEntityAttribute(entity);
        }

    }
    /**
     * Get all the types out of the Entity Factory and make them
     * available to the compiler.
     * @param ef
     * @return
     * @throws Exception
     */
    public HashMap<RName,IRType> getTypes(EntityFactory ef) throws Exception {
        
        if(types!=null)return types;
        
        types = new HashMap<RName, IRType>();
        Iterator<RName> entities = ef.getEntityRNameIterator();
        while(entities.hasNext()){
            RName     name    = entities.next();
            IREntity  entity  = ef.findRefEntity(name);
            Iterator<RName> attribs = entity.getAttributeIterator();
            addType(entity,entity.getName(),IRObject.iEntity);
            while(attribs.hasNext()){
                RName        attribname = attribs.next();
                REntityEntry entry      = entity.getEntry(attribname);
                addType(entity,attribname,entry.type.getId());
            }
        }
        
        Iterator<RName> tables = ef.getDecisionTableRNameIterator();
        while(tables.hasNext()){
            RName tablename = tables.next();
            TIERS_Type type = new TIERS_Type(tablename,IRObject.iDecisiontable,(REntity) ef.getDecisiontables());
            if(types.containsKey(tablename)){
                System.out.println("Multiple Decision Tables found with the name '"+types.get(tablename)+"'");
            }else{
                types.put(tablename, type);
            }
        }
        
        return types;
    }
    
    /**
     * Prints all the types known to the compiler
     */
    public void printTypes(PrintStream out) throws RulesException {
        Object typenames[] = types.keySet().toArray();
        for(int i=0;i<typenames.length-1;i++){
            for(int j=0;j<typenames.length-1;j++){
                RName one = (RName)typenames[j], two = (RName)typenames[j+1];
                if(one.compare(two)>0){
                    Object hold = typenames[j];
                    typenames[j]=typenames[j+1];
                    typenames[j+1]=hold;
                }
            }
        }
        for(int i=0;i<typenames.length-1;i++){
            for(int j=0;j<typenames.length-1;j++){
                RName one = (RName)typenames[j], two = (RName)typenames[j+1];
                if(((TIERS_Type)types.get(one)).getType()> ((TIERS_Type)types.get(two)).getType()){
                    Object hold = typenames[j];
                    typenames[j]=typenames[j+1];
                    typenames[j+1]=hold;
                }
            }
        }
        for(int i=0;i<typenames.length; i++){
            out.println(types.get(typenames[i]));
        }
            
    }
    
    
    private TokenFilter   tfilter;
    
    public ArrayList<String> getParsedTokens(){
        return tfilter.getParsedTokens();
    }
    
    public void newDecisionTable () {
        localcnt = 0;
        localtypes.clear();
    }
    
    /**
     * The actual routine to compile either an action or condition.  The code
     * is all the same, only a flag is needed to decide to compile an action vs
     * condition.
     * @param action    Flag
     * @param s         String to compile
     * @return          Postfix
     * @throws Exception    Throws an Exception on any error.
     */
    private String compile (String s)throws Exception {

        
        InputStream      stream  = new ByteArrayInputStream(s.getBytes());
        DataInputStream  input   = new DataInputStream(stream);
        Lexer            lexer   = new Lexer (input);
                         tfilter = new TokenFilter(session, lexer,types, localtypes);
        DTRulesParser    parser  = new DTRulesParser(tfilter);
        Object           result  = null;
                
        try {
           Symbol ss = parser.parse();
           if(ss == null) return "";
           result = ss.value;
        }catch(Throwable e) {
           int parsed = lexer.getColumn();
           String message = "";
           if(parsed == 0){
               message = "[Error here]-> ";
           }else if (parsed >0){
               message = s.substring(0, parsed) + " [Error here]-> " + s.substring(parsed);
           }
           throw new RulesException("Compile Error", "Compiling <<"+message+">>", e.toString());
        }
        return result.toString();
    }
    
    /* (non-Javadoc)
     * @see com.dtrules.compiler.ICompiler#getLastPreFixExp()
     */
    public String getLastPreFixExp(){
        return "";
    }

    /**
     * Build a compiler instance.  This compiler compiles either a condition or
     * an action.  Use the compiler access methods to compile each.
     * 
     */
    public TIERS_Compiler(){};

    /**
     * @param session Needed to generate the symbol table used by the compiler.  
     * @throws If we cannot set up the session and entityfactory, an exception might be thrown.
     */
    public void setSession(IRSession session) throws Exception {
        this.session = session;
        ef = session.getEntityFactory();
        getTypes(ef);
    }

    
    /**
     * @see com.dtrules.compiler.ICompiler#compileContext(java.lang.String)
     **/
    @Override
    public String compileContext(String context) throws Exception {
        return compile("context "+context+" --EOF-- ");
    }
    
    /**
     * @see com.dtrules.compiler.ICompiler#compileAction(java.lang.String)
     **/
    @Override
    public String compileAction(String action) throws Exception {
        return compile("action "+action+" --EOF-- ");
    }
    /**
     * @see com.dtrules.compiler.ICompiler#compileCondition(java.lang.String)
     **/
    @Override
    public String compileCondition(String condition) throws Exception {
        return compile("condition "+ condition +" --EOF-- ");
    }
    
    /**
     * Returns the compiled version of the policy statement.  Double quotes are
     * replaced forcefully by single quotes.
     */
    @Override
    public String compilePolicyStatement(String policyStatement) throws Exception {
        if(policyStatement==null)return "";
        policyStatement = policyStatement.replaceAll("\"", "'");
        StringBuffer  sbuff = new StringBuffer();
        int s = 0;
        int e = policyStatement.indexOf("{",s);
        while(e>0){
            sbuff.append("\"");
            sbuff.append(policyStatement.substring(s, e));
            sbuff.append("\" ");
            s = e;
            e = policyStatement.indexOf("}",s);
            if(e<0){
                throw new RuntimeException("Unbalanced braces: "+policyStatement);
            }
            
            String source = "policystatement " + policyStatement.substring(s+1,e)+" --EOF-- ";

            try{
                String value = compile(source);
                sbuff.append(value);
                sbuff.append("cvs strconcat ");
            }catch(Exception ex){
                throw new Exception(ex.toString()+ "\n Source: >>"+ source +"<<");
            }
            
            s = e+1;
            e = policyStatement.indexOf("{",s);
        }
        
        sbuff.append("\"");
        sbuff.append(policyStatement.substring(s));
        if(s==0){
            sbuff.append("\" ");
        }else{
            sbuff.append("\" strconcat");
        }
        
        return sbuff.toString();
    }


    /**
     * @see com.dtrules.compiler.ICompiler#getTypes()
     **/
    public HashMap<RName,IRType> getTypes() {
        return types;
    }
    /**
     * Return the list of Possibly (but we can't tell for sure) referenced attributes
     * so far by this compiler.
     */
    public ArrayList<String> getPossibleReferenced() {
        ArrayList<String> v = new ArrayList<String>();
        for(IRType type :types.values()){
            v.addAll(((TIERS_Type)type).getPossibleReferenced());
        }
        return v;
    }
    /**
     * Return the list of UnReferenced attributes so far by this compiler
     */
    public ArrayList<String> getUnReferenced() {
        ArrayList<String> v = new ArrayList<String>();
        for(IRType type :types.values()){
            v.addAll(((TIERS_Type)type).getUnReferenced());
        }
        return v;
    }   
}
