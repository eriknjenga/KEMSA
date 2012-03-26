/**
 * StringExt class groups a bunch of string related functions.
*/
class com.fusioncharts.is.extensions.StringExt {
	/** 
	* We make the constructor private, as we do not want instances of
	* this class to be created, since it simply bunches a group of string
	* related static functions.
	*/
	private function StringExt() {
		//Private constructor to avoid creation of instances
	}
	/**
	 * Replace method searches for a given pattern in a string and
	 * replaces it with the given replacement.
	 * @param	str			String in which we've to search and replace 	 						
	 * @param	pattern		String pattern to search in the given string
	 * @param	replacement	String which should replace the given pattern
	 * @return				A string with the replaced values
	*/
	public static function replace(str:String, pattern:String, replacement:String):String {
		return str.split(pattern).join(replacement);
	}
	/**
	 * RemoveSpaces methods removes all the spaces from a given string
	 * irrespective of where they're located in a string.
	 * @param	str		String from which we've to remove the spaces
	 * @return			Same string with no spaces
	*/
	public static function removeSpaces(str:String):String {
		return StringExt.replace(str, " ", "");
	}
	/**
	 * leftTrimChar left trims the specified character from the string.
	 * @param	str		The string which we'll left trim
	 * @param	strChar	The character which we need to left trim from
	 *					the given string
	 * @return			String with the given character removed from left
	*/
	public static function leftTrimChar(str:String, strChar:String):String {
		//If the string is undefined return ""
		if (str == undefined) {
			return "";
		}
		//Create a copy of the string 
		var strString:String = str;
		//If the specified character is present in the string, continue...
		if (strString.indexOf(strChar) != -1) {
			//Get the length of the string
			var intLength:Number = strString.length;
			//Get the position of the first character which isn't the character to be trimmed
			//And, then extract the rest of the string from that point onwards till the end
			var startCharPos:Number = -1;
			var i:Number;
			for (i=0; i<=intLength; i++) {
				if ((strString.charAt(i) != strChar) && (startCharPos == -1)) {
					startCharPos = i;
					//Exit loop as we've already found our required position
					break;
				}
			}
			strString = strString.substring(startCharPos);
		}
		return strString;
	}
}
