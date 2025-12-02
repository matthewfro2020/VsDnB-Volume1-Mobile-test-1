#pragma header

vec4 sineWave(vec4 pt)
{
	return vec4(1.0 - pt.x, 1.0 - pt.y, 1.0 - pt.z, pt.w);
}
void main()
{
	vec2 uv = openfl_TextureCoordv;
	gl_FragColor = sineWave(texture2D(bitmap, uv));
}