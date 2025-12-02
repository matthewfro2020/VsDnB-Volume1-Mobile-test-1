package data;

/**
 * A type definition that defines what kind of a JSON file.
 */
typedef JsonFile = 
{
    /**
     * The contents of the file.
     */
    public var contents:String;
    
    /**
     * The name of the file that's being parsed.
     */
    public var fileName:String;
}