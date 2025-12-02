#pragma header
uniform vec2 blockSize;

void main()
{
    vec2 blocks = openfl_TextureSize / blockSize;
    gl_FragColor = flixel_texture2D(bitmap, floor(openfl_TextureCoordv * blocks) / blocks);
}