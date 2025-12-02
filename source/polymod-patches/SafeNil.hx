package thx;

/**
 * Replacement type for thx.Nil breaking on iOS.
 * Avoids conflict with Obj-C 'Nil'.
 */
typedef Nil = SafeNil;

@:keep
class SafeNil {
    public static var nil:SafeNil = new SafeNil();

    public function new() {}

    public static function toString():String return "nil";
}
