Code
[[
	void BlendLEAN( float t, float2 B1, float3 M1, float2 B2, float3 M2, out float2 Bout, out float3 Mout )
	{
		float u = t;
		t = 1.0f - t;
		float t2 = t * t;
		float u2 = u * u;

		Bout = B1 * t + B2 * u;

		Mout.x = M1.x*t2 + M2.x*u2 + 2*t*u*B1.x*B2.x;
		Mout.y = M1.y*t2 + M2.y*u2 + 2*t*u*B1.y*B2.y;
		Mout.z = M1.z*t2 + M2.z*u2 + t*u*B1.x*B2.y + t*u*B1.y*B2.x;
	}

	void SampleLEAN( float2 uv, out float2 Bout, out float3 Mout, in PdxTextureSampler2D LeanTexture1, in PdxTextureSampler2D LeanTexture2 )
	{
		float4 lean1 = PdxTex2D( LeanTexture1, uv );
		float4 lean2 = PdxTex2D( LeanTexture2, uv );

		float vScale = 1.7f;
		Bout = ( 2*lean2.xy - 1 ) * vScale;
		Mout = float3( lean2.zw, 2*lean1.w - 1 ) * vScale * vScale;
	}

	void SampleBlendLEAN( float t, float2 uv1, float2 uv2, out float2 Bout, out float3 Mout, in PdxTextureSampler2D Lean1, in PdxTextureSampler2D Lean2 )
	{
		float2 B1, B2;
		float3 M1, M2;

		SampleLEAN( uv1, B1, M1, Lean1, Lean2 );
		SampleLEAN( uv2, B2, M2, Lean1, Lean2 );

		BlendLEAN( t, B1, M1, B2, M2, Bout, Mout );
	}
]]
