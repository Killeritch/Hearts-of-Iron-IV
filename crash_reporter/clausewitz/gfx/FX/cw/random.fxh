Code
[[
	float CalcRandom( float2 Seed )
	{
		float DotProduct = dot( Seed, float2( 12.9898, 78.233 ) );
		return frac( sin( DotProduct ) * 43758.5453 );
	}
	
	float CalcRandom( float3 Seed )
	{
		float DotProduct = dot( Seed, float3( 12.9898,78.233,144.7272 ) );
		return frac( sin( DotProduct ) * 43758.5453 );
	}
	
	float CalcNoise( float2 Pos ) 
	{
		float2 i = floor( Pos );
		float2 f = frac( Pos );

		float a = CalcRandom(i);
		float b = CalcRandom(i + float2(1.0, 0.0));
		float c = CalcRandom(i + float2(0.0, 1.0));
		float d = CalcRandom(i + float2(1.0, 1.0));
		
		float2 u = f*f*(3.0-2.0*f);
		return lerp(a, b, u.x) + 
				(c - a)* u.y * (1.0 - u.x) + 
				(d - b) * u.x * u.y;
	}
]]