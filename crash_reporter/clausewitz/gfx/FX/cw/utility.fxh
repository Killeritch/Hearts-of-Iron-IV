Code
[[
	float ToGamma(float aLinear)
	{
		return pow(aLinear, 1.0/2.2);
	}

	float3 ToGamma(float3 aLinear)
	{
		return pow(aLinear, vec3(1.0/2.2));
	}
	
	float ToLinear(float aGamma)
	{
		return pow(aGamma, 2.2);
	}
	
	float3 ToLinear(float3 aGamma)
	{
		return pow(aGamma, vec3(2.2));
	}

	float4 ToLinear(float4 aGamma)
	{
		return float4(pow(aGamma.rgb, vec3(2.2)), aGamma.a);
	}
	
	float3 RGBtoHSV( float3 RGB )
	{
		float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		float4 p = RGB.g < RGB.b ? float4(RGB.bg, K.wz) : float4(RGB.gb, K.xy);
		float4 q = RGB.r < p.x ? float4(p.xyw, RGB.r) : float4(RGB.r, p.yzx);

		float d = q.x - min(q.w, q.y);
		float e = 1.0e-10;
		return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x );
	}
	
	float3 HSVtoRGB( float3 HSV )
	{
		float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		float3 p = abs( frac(HSV.xxx + K.xyz) * 6.0 - K.www );
		return HSV.z * lerp( K.xxx, clamp(p - K.xxx, 0.0, 1.0), HSV.y );
	}
	float4 RGBtoHSV( float4 RGBa )
	{
		return float4( RGBtoHSV( RGBa.rgb ), RGBa.a );
	}
	float4 HSVtoRGB( float4 HSVa )
	{
		return float4( HSVtoRGB( HSVa.xyz ), HSVa.a );
	}

	float3 Add( float3 Base, float3 Blend, float Opacity ) 
	{
		return ( Base + Blend ) * Opacity + Base * ( 1.0 - Opacity );
	}

	float3 Multiply( float3 Base, float3 Blend, float Opacity )
	{
		return Base * Blend * Opacity + Base * ( 1.0 - Opacity );
	}
	
	float Overlay( float Base, float Blend )
	{
		return (Base < 0.5) ? (2.0 * Base * Blend) : (1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend));
	}
	float3 Overlay( float3 Base, float3 Blend )
	{
		return float3( Overlay(Base.r, Blend.r), Overlay(Base.g, Blend.g), Overlay(Base.b, Blend.b) );
	}
	float3 Overlay( float3 Base, float3 Blend, float Opacity )
	{
		return Overlay( Base, Blend ) * Opacity + Base * (1.0 - Opacity );
	}

	float3 GetOverlay( float3 Color, float3 OverlayColor, float OverlayPercent )
	{
		// Flip OverlayColor/BaseColor since that was how it was before
		return lerp( Color, Overlay( OverlayColor, Color ), OverlayPercent );
	}
	
	float ColorDodge( float Base, float Blend )
	{
		return (Blend == 1.0) ? Blend : min( Base / (1.0 - Blend), 1.0 );
	}
	float3 ColorDodge( float3 Base, float3 Blend )
	{
		return float3( ColorDodge(Base.r, Blend.r), ColorDodge(Base.g, Blend.g), ColorDodge(Base.b, Blend.b) );
	}
	float3 ColorDodge( float3 Base, float3 Blend, float Opacity )
	{
		return ColorDodge( Base, Blend ) * Opacity + Base * ( 1.0 - Opacity );
	}
	
	float Lighten( float Base, float Blend )
	{
		return max( Base, Blend );
	}
	float3 Lighten( float3 Base, float3 Blend )
	{
		return float3( Lighten(Base.r, Blend.r), Lighten(Base.g, Blend.g), Lighten(Base.b, Blend.b) );
	}
	float3 Lighten( float3 Base, float3 Blend, float Opacity )
	{
		return Lighten( Base, Blend ) * Opacity + Base * ( 1.0 - Opacity );
	}

	float Darken( float Base, float Blend )
	{
		return min( Base, Blend );
	}
	float3 Darken( float3 Base, float3 Blend )
	{
		return float3( Darken(Base.r, Blend.r), Darken(Base.g, Blend.g), Darken(Base.b, Blend.b) );
	}
	float3 Darken( float3 Base, float3 Blend, float Opacity )
	{
		return Darken( Base, Blend ) * Opacity + Base * ( 1.0 - Opacity );
	}
	
	float3 Levels( float3 vInColor, float3 vMinInput, float3 vMaxInput )
	{
		float3 vRet = saturate( vInColor - vMinInput );
		vRet /= vMaxInput - vMinInput;
		return saturate( vRet );
	}
	
	float Levels( float vInValue, float vMinValue, float vMaxValue )
	{
		return saturate( ( vInValue - vMinValue ) / ( vMaxValue - vMinValue ) );
	}

	float3 UnpackNormal( in PdxTextureSampler2D NormalTex, float2 uv )
	{
		float3 vNormalSample = normalize( PdxTex2D( NormalTex, uv ).rgb - 0.5f );
		vNormalSample.g = -vNormalSample.g;
		return vNormalSample;
	}
	
	float3 UnpackNormal( float4 NormalMapSample )
	{
		float3 vNormalSample = NormalMapSample.rgb - 0.5;
		vNormalSample.g = -vNormalSample.g;
		return vNormalSample;
	}
	
	float3 UnpackRRxGNormal( float4 NormalMapSample )
	{
		float x = NormalMapSample.g * 2.0 - 1.0;
		float y = NormalMapSample.a * 2.0 - 1.0;
		y = -y;
		float z = sqrt(saturate(1.0 - x * x - y * y));
		return float3(x, y, z);
	}
	
	float Fresnel( float NdotL, float FresnelBias, float FresnelPow )
	{
		return saturate( FresnelBias + (1.0 - FresnelBias) * pow( 1.0 - NdotL, FresnelPow ) );
	}
	
	#define REMAP_IMPL NewMin + ( NewMax - NewMin ) * ( (Value - OldMin) / (OldMax - OldMin) )
	float Remap( float Value, float OldMin, float OldMax, float NewMin, float NewMax ) { return REMAP_IMPL; }
	float2 Remap( float2 Value, float2 OldMin, float2 OldMax, float2 NewMin, float2 NewMax ) { return REMAP_IMPL; }
	float3 Remap( float3 Value, float3 OldMin, float3 OldMax, float3 NewMin, float3 NewMax ) { return REMAP_IMPL; }
	#undef REMAP_IMPL
	#define REMAP_IMPL NewMin + ( NewMax - NewMin ) * saturate( (Value - OldMin) / (OldMax - OldMin) )
	float RemapClamped( float Value, float OldMin, float OldMax, float NewMin, float NewMax ) { return REMAP_IMPL; }
	float2 RemapClamped( float2 Value, float2 OldMin, float2 OldMax, float2 NewMin, float2 NewMax ) { return REMAP_IMPL; }
	float3 RemapClamped( float3 Value, float3 OldMin, float3 OldMax, float3 NewMin, float3 NewMax ) { return REMAP_IMPL; }
	#undef REMAP_IMPL
]]