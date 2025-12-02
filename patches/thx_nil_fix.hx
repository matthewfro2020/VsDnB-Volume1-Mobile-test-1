package thx;

// iOS-safe Nil replacement
class ThxNil {
    public static var thx_nil:ThxNil = new ThxNil();

    public function new() {}

    public function toString():String
        return "nil";
}
