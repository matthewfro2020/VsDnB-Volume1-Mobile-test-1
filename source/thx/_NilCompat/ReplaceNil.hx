package thx._NilCompat;

class ReplaceNil {
    macro public static function build() {
        return macro thx.NilFix;
    }
}
