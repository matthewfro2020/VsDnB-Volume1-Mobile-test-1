package util.tools;

/**
 * A static utility for providing functions relating to `Iterator`
 */
@:nullSafety
class IteratorTools
{
	/**
	 * Returns an array variant of this iterator.
	 * @param iterator The iterator to give an array for.
	 * @return The array from this iterator.
	 */
	public static function array<T>(iterator:Iterator<T>):Array<T>
	{
		return [for (i in iterator) i];
	}
}