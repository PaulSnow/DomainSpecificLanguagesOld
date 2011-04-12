package com.dtrules.compiler.tiers_compiler.cup.parser;

import java.util.*;

/* A Utility class which has commonly used method, userful
for our lex file. */

public class ParserUtil 
{
    //We'll let the users use months of a year in the decsion table	
	public static final HashMap<String,String> dateMap = new HashMap<String,String>();
	
	static {
	   dateMap.put("jan", "1");
	   dateMap.put("jan", "1");
       dateMap.put("feb", "2");
       dateMap.put("mar", "3");
       dateMap.put("apr", "4");
       dateMap.put("may", "5");
       dateMap.put("jun", "6");
       dateMap.put("jul", "7");
       dateMap.put("aug", "8");
       dateMap.put("sep", "9");       
       dateMap.put("oct", "10");       
       dateMap.put("nov", "11");       
       dateMap.put("dec", "12");       
	}					
	                                       
   /* Returns a date in which the day and the year are zero. 
    * And the month is the month sent as parameter*/
   public static String getMonthOnlyDate(String month)
   {
   	 Object obj = dateMap.get(month.toLowerCase());
   	 if (obj != null)
   	 {
   	 	return "'" + (String) obj + "/01/2001'" ;
   	 }
   	 return null;
   }   
	                                       
   /**
   * Removes the XML tags from a string that we matched for
   */
   public static String getText(String text)
    {     
       text = text.substring(text.indexOf(">")+1);
       text = text.substring(0,text.indexOf("<")); 
       text = replaceAll (text,"quotes;", "'"  );
       text = replaceAll (text,"&amp;"  , "&"  );
       text = replaceAll (text,"&lt;"   , "<"  );
       text = replaceAll (text,"&gt;"   , ">"  );
       text = replaceAll (text,"  "     , " "  );
       return text;
    }
  
  public static String replaceAll(String source, String search, String newstr) 
  {
	if(search.length()==0) return source;	// Shouldn't search for null strings.
											//   just ignore them.
	int startSearch = 0;	
	int index;	 
	String previous,trailing;

	while((index = source.indexOf(search,startSearch))>=0 )
	{	// Loop while we find the search in
																// inStr.
	  previous = source.substring(0,index);	
	  trailing = source.substring(source.indexOf(search,startSearch)+search.length());

	  startSearch = previous.length()+newstr.length();    
 	  source = previous + newstr + trailing;
	}	  	  
	return source;	
  }
  
  //Modifies a string so that it becomes XML specific
  public static String converttoXMLSpecs(String sInput)
  {
	if (sInput == null)
	   return null;
	   
   	//String sReturn = replaceAll(sInput, "&&", "&amp;&amp;");
  	String sReturn = replaceAll(sInput, "&", "&amp;");
	sReturn = replaceAll(replaceAll(sReturn, "<", "&lt;"),">","&gt;");
	sReturn = replaceAll(replaceAll(sReturn, "<", "&lt;"),">","&gt;");
	return sReturn;
  }

public static String getBoolToUse(Object opr)
{
	 String sOpr = (String) opr;
     if (opr.equals("||"))	
        return "false";
     else
        return "true";
}

public static void main(String argv[]) 
{
  String sTest = "aa&&zz";
  String sReturn = ParserUtil.converttoXMLSpecs(sTest);
  System.out.println("\nsReturn:" + sReturn);
}

}

