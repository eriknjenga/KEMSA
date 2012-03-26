/**
* @class Macros
* @author InfoSoft Global (P) Ltd. www.InfoSoftGlobal.com
* @version 3.0
*
* Copyright (C) InfoSoft Global Pvt. Ltd.
*
* Macros class helps manipulate the macros for the chart.
* Basically macros are symbols used to replace a numerical expression.
* like, $canvasStartX, $canvasStartY etc., whose values are computed
* at run-time and hence we cannot statically define them.
*/
import com.fusioncharts.is.helper.FCEnum;
import com.fusioncharts.is.helper.FCError;
import com.fusioncharts.is.helper.Logger;
import com.fusioncharts.is.helper.HashTable;
import com.fusioncharts.is.extensions.StringExt;
class com.fusioncharts.is.helper.Macros 
{
	//Private variables
	//We define a table of HashTable type in which we'll store all
	//the "fed" macros.
	private var table : HashTable;
	/**
	* Constructor Function
	* We initialize the hash table.
	*/
	function Macros ()
	{
		//Initialize the Hash Table
		table = new HashTable ();
	}
	/**
	* This method adds a macro and its value to the macro table.
	*	@param	strMacro	Name of macro to be added.
	*	@param	val			Value to be allotted.
	*/
	public function addMacro (strMacro : String, val : Number) : Void 
	{
		//Put it in the hash table
		table.put (strMacro, val);
	}
	/**
	* This method parses the expression passed it to, replaces the
	* macros in the expression with the required values and finally
	* evaluates the expression.
	* Assumptions		Expression can either be a mix of macros and numbers
	*					or purely macros or purely numbers only.
	*					e.g., $macroName+32+$macroA, $macroA + $macroB, 54
	*					You cannot set an expression as 21+23 having only
	*					numbers and operators
	* @param strExp	The expression containing macros, operators and
	*					numeric values
	* @return			Final value of the expression
	*/
	public function evalMacroExp (strExp : String) : Number 
	{
		//This function evaluates the value of an expression containing a Macro
		//Convert macro to string, as input can be a number too at times.
		strExp = String (strExp);
		//First check if strExp contains a macro
		//If not, just convert into number and send back
		if ( ! this.containsMacro (strExp))
		{
			return Number (strExp);
		}
		//Now, remove any spaces from the expression
		strExp = StringExt.removeSpaces (strExp);
		//Create a clone of strExp and store it
		var strFinalExp : String = strExp;
		//We now need to extract the macros individually and replace them with
		//the actual numerical values.
		//If any macro is not found in our hash table, we raise an error
		//We need to sequentially iterate through the exo string to find macros
		var macroStartPos : Number = 0;
		var macroEndPos : Number;
		var macroStartFound : Boolean = false;
		var strMacro : String;
		var strMacroValue : String;
		var i : Number;
		for (i = 0; i < strExp.length; i ++)
		{
			//Find the start position if already not found
			if ((strExp.charAt (i) == "$") && ( ! macroStartFound))
			{
				macroStartPos = i;
				macroStartFound = true;
			}
			//If we've already found the start of macro and now the character
			//is either an operator or the last character in the expression (single macro case)
			//set the macro end position flag
			if (macroStartFound && (this.isOperator (strExp.charAt (i)) || i == (strExp.length - 1)))
			{
				macroEndPos = i;
				//If it's the last character, we need to increment End position
				if (i == (strExp.length - 1))
				{
					macroEndPos ++;
				}
				//Now, extract this string and replace it with the value.
				//First extract
				strMacro = strExp.substring (macroStartPos, macroEndPos);
				//Get it's value and cast it as String
				strMacroValue = table.get (strMacro).toString ();
				//If the value is returned as undefined, check whether the
				//key actually exists in the hash table
				//If not, throw an error
				if (strMacroValue == undefined)
				{
					//Why we again need to check? It may sometimes happen that the user
					//has intentionally fed the undefined value in HashTable, as Flash
					//sets non-specified XML element attributes as undefined.
					if ( ! table.containsKey (strMacro))
					{
						//Assume the value of this macro to be 0.
						strMacroValue = "0";
						//Throw error
						throw new FCError ("Invalid Macro", "Couldn't find Macro \"" + strMacro + "\". Please provide a valid macro name in XML. Do remember that macros are Case-sensitive and you can only assign pre-defined macro values. See documentation for more details.", Logger.LEVEL.ERROR);
					}
				}
				//Now, that we've have the macro's value, replace the macro with the value
				strFinalExp = StringExt.replace (strFinalExp, strMacro, strMacroValue);
				//Update start found flag to false again
				macroStartFound = false;
			}
		}
		//Now, we've the final expression with just numeric values and operators
		//We calculate it's value.
		return evalExpression (strFinalExp);
	}
	/**
	* This method takes in an arithmetic operation with +,-
	* operators as String and evalutes the result.
	* It needs an expression in format N1+N2-N3+N4-N5... with no spaces,
	* where N1, N2, N3, N4, N5... are numeric values like 23,43,76 etc.
	* Assumptions		Expression cannot start with a + or -
	*
	* @param	strExp	Expression to be evaluted in string.
	* @return			Result of the expression (calculated value).
	*/
	private function evalExpression (strExp : String) : Number 
	{
		//If the string is null or the first value isn't a number, return 0
		if (strExp == null || strExp == "" || parseInt (strExp) == NaN)
		{
			return 0;
		}
		//If there are no + or -  signs in the expression return just the number
		if (strExp.indexOf ("+") == - 1 && strExp.indexOf ("-") == - 1)
		{
			return Number (strExp);
		}
		//Now, if the expression is in format, N1+N2-N3+N4-N5...., evaluate it
		var expSingleOp : String = strExp;
		var expTokens : Array = new Array ();
		var expResult : Number = 0;
		var count : Number = 0;
		var i : Number;
		//Replace the operators with #, so that we can split on a single character
		//Replace + with #
		expSingleOp = StringExt.replace (expSingleOp, "+", "#");
		//Replace - with #
		expSingleOp = StringExt.replace (expSingleOp, "-", "#");
		//Split the expression so that each cell of the array contains a numeric value
		expTokens = expSingleOp.split ("#");				
		//Take the value of first cell (if not blank)
		expResult = isNaN(expTokens)?0:parseInt (expTokens [0]);
		//Now, iterate through the expression
		//Now calculate the result
		for (i = 0; i <= strExp.length; i ++)
		{
			if (strExp.charAt (i) == "+")
			{
				//If the operator is add.
				//Increment the counter
				count ++;
				//If it's a number, add it
				if ( ! isNaN (expTokens [count]))
				{
					expResult = expResult + parseInt (expTokens [count]);
				}
			} else if (strExp.charAt (i) == "-")
			{
				//If the operator is minus
				//Increment the counter
				count ++;
				//Subtract it only if it's a number
				if ( ! isNaN (expTokens [count]))
				{
					expResult = expResult - parseInt (expTokens [count]);
				}
			}
		}
		return expResult;
	}
	/**
	* This method checks whether the passed character is an operator
	* that is allowed in the macro.
	* @param char	Input character to be checked for operator
	* @return		Boolean value indicating whether the given character
	*				is an operator supported by this macro. Here, we support
	*				only + and - operators.
	*/
	private function isOperator (char : String) : Boolean 
	{
		//By default assume that it is not a macro
		var _isASOperator : Boolean = false;
		//Now, check and set proper flag.
		if (char == "+" || char == "-")
		{
			_isASOperator = true;
		}
		return _isASOperator;
	}
	/**
	* This method checks whether a given literal contains a macro or not.
	* To do so, we simply check for the existence of a $ sign,
	* as all macros start with $
	* @param	strLiteral	The literal to be checked for existence of macros
	* @return				Boolean value indicating whether the literal
	* 						contains macros.
	*/
	private function containsMacro (strLiteral : String) : Boolean 
	{
		//See for existence of $
		return ! (strLiteral.indexOf ("$") == - 1);
	}
}
