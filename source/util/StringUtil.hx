package util;

/**
 * A utility for providing useful functions relating to Strings.
 */
class StringUtil
{
    /**
     * Formats a string in spaced uppercase format.
     * ex. `Formatted Song`
     * @param string The string to format.
     * @param separator The separate the string is using.
     * @return A newly formatted string.
     */
    public static function format(string:String, separator:String):String
	{
		var split:Array<String> = string.split(separator);
		var formattedString:String = '';
		for (i in 0...split.length)
		{
			var piece:String = split[i];
			var allSplit = piece.split('');
			var firstLetterUpperCased = allSplit[0].toUpperCase();
			var substring = piece.substr(1, piece.length - 1);
			var newPiece = firstLetterUpperCased + substring;
			if (i != split.length - 1)
			{
				newPiece += " ";
			}
			formattedString += newPiece;
		}
		return formattedString;
	}
	
    /**
     * Properly formats a list of strings to be used as one string.
     * @param array The list of strings to be formatted.
     * @return A neatly formatted string
     */
    public static function formatStringList(array:Array<String>):String
    {
        var fullString:String = '';
        for (i in 0...array.length) {
            fullString += array[i];
            fullString += switch (i) {
                default: ', ';
                case (_ == (array.length - 2) && (array.length == 2)) => true: ' and ';
                case (_ == (array.length - 2)) => true: ', and ';
                case (_ == (array.length - 1)) => true: '';
            }
        }
        return fullString;
    }
}