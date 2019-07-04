Includes = {
	"cw/random.fxh"
}

ConstantBuffer( PdxShadowmap )
{
	float		ShadowFadeFactor;
	float		Bias;
	float		KernelScale;
	float		ShadowScreenSpaceScale;
	int			NumSamples;
	
	float4		DiscSamples[8];
}

PixelShader = 
{
	Code
	[[
		// Generate the texture co-ordinates for a PCF kernel
		void CalculateCoordinates( float2 ShadowCoord, inout float2 TexCoords[5] )
		{
			// Generate the texture co-ordinates for the specified depth-map size
			TexCoords[0] = ShadowCoord + float2( -KernelScale, 0.0f );
			TexCoords[1] = ShadowCoord + float2( 0.0f, KernelScale );
			TexCoords[2] = ShadowCoord + float2( KernelScale, 0.0f );
			TexCoords[3] = ShadowCoord + float2( 0.0f, -KernelScale );
			TexCoords[4] = ShadowCoord;
		}
		
		float CalculateShadow( float4 ShadowProj, PdxTextureSampler2D ShadowMap )
		{
			ShadowProj.xyz = ShadowProj.xyz / ShadowProj.w;
			
			float2 TexCoords[5];
			CalculateCoordinates( ShadowProj.xy, TexCoords );
			
			// Sample each of them checking whether the pixel under test is shadowed or not
			float fShadowTerm = 0.0f;
			for( int i = 0; i < 5; i++ )
			{				
				float A = PdxTex2DLod0( ShadowMap, TexCoords[i] ).r;
				float B = ShadowProj.z - Bias;
				
				// Texel is shadowed
				fShadowTerm += ( A < 0.99f && A < B ) ? 0.0 : 1.0;
			}
			
			// Get the average
			fShadowTerm = fShadowTerm / 5.0f;
			return lerp( 1.0, fShadowTerm, ShadowFadeFactor );
		}
		
		float2 RotateDisc( float2 Disc, float2 Rotate )
		{
			return float2( Disc.x * Rotate.x - Disc.y * Rotate.y, Disc.x * Rotate.y + Disc.y * Rotate.x );
		}
		
		float CalculateShadow( float4 ShadowProj, PdxTextureSampler2DCmp ShadowMap )
		{
			ShadowProj.xyz = ShadowProj.xyz / ShadowProj.w;
			
			float RandomAngle = CalcRandom( round( ShadowScreenSpaceScale * ShadowProj.xy ) ) * 3.14159 * 2.0;
			float2 Rotate = float2( cos( RandomAngle ), sin( RandomAngle ) );

			// Sample each of them checking whether the pixel under test is shadowed or not
			float ShadowTerm = 0.0;
			for( int i = 0; i < NumSamples; i++ )
			{
				float4 Samples = DiscSamples[i] * KernelScale;
				ShadowTerm += PdxTex2DCmpLod0( ShadowMap, ShadowProj.xy + RotateDisc( Samples.xy, Rotate ), ShadowProj.z - Bias );
				ShadowTerm += PdxTex2DCmpLod0( ShadowMap, ShadowProj.xy + RotateDisc( Samples.zw, Rotate ), ShadowProj.z - Bias );
			}
			
			// Get the average
			ShadowTerm *= 0.5; // We have 2 samples per "sample"
			ShadowTerm = ShadowTerm / float(NumSamples);
			return lerp( 1.0, ShadowTerm, ShadowFadeFactor );
		}
	]]
}