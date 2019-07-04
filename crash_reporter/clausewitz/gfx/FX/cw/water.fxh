Includes = {
	"cw/lean.fxh"
}

Code
[[
	void SampleWater( float2 uv, float2 vUVMultipliers[4], float vTime, float2 vTimeMultipliers[4], out float2 B, out float3 M, out float3 normal, in PdxTextureSampler2D Lean1, in PdxTextureSampler2D Lean2 )
	{
		float2 B1;
		float2 B2;
		float3 M1;
		float3 M2;

		SampleBlendLEAN( 0.5f,
			uv * vUVMultipliers[0] + vTime * vTimeMultipliers[0],
			uv * vUVMultipliers[1] + vTime * vTimeMultipliers[1],
			B1, M1, Lean1, Lean2 );

		SampleBlendLEAN( 0.5f, 
			uv * vUVMultipliers[2] + vTime * vTimeMultipliers[2],
			uv * vUVMultipliers[3] + vTime * vTimeMultipliers[3],
			B2, M2, Lean1, Lean2 );

		BlendLEAN( 0.5f, B1, M1, B2, M2, B, M );

		normal = normalize( float3( B.x, 1.0f, B.y ) );
	}

	void SampleWater( float2 uv, float vTime, out float2 B, out float3 M, out float3 normal, in PdxTextureSampler2D Lean1, in PdxTextureSampler2D Lean2 )
	{
		float2 vUVMultipliers[4];
		vUVMultipliers[0] = 1000.0f * float2( 0.9f, 1.0f );
		vUVMultipliers[1] = 700.0f * float2( 0.95f, 1.05f );
		vUVMultipliers[2] = 534.0f * float2( 1.05f, 0.95f );
		vUVMultipliers[3] = 300.0f * float2( 1.0f, 1.0f );

		float2 vTimeMultipliers[4];
		vTimeMultipliers[0] = float2( 1.0f, 0.1f );
		vTimeMultipliers[1] = float2( 0.1f, 2.0f );
		vTimeMultipliers[2] = float2( -0.2f, -2.0f );
		vTimeMultipliers[3] = float2( -1.0f, -0.1f );

		SampleWater( uv, vUVMultipliers, vTime, vTimeMultipliers, B, M, normal, Lean1, Lean2 );
	}

	void SampleWater( float2 uv, float vTime, out float3 normal, in PdxTextureSampler2D Lean1, in PdxTextureSampler2D Lean2 )
	{
		float2 B;
		float3 M;
		SampleWater( uv, vTime, B, M, normal, Lean1, Lean2 );
	}
]]
