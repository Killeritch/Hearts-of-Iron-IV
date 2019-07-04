#define UINT16_MAX 0xffff
#define PI 3.14159265359

float2x2 Create2x2( float a, float b, float c, float d ) { return Create2x2( float2( a, b ), float2( c, d ) ); }

#define PdxTex2DProj(samp,uv_proj) PdxTex2DLod0( (samp), (uv_proj).xy / (uv_proj).w )
#define PdxTex2DLod0(samp,uv) PdxTex2DLod( (samp), (uv), 0 )
#define PdxTex2DLoad0(samp,uv) PdxTex2DLoad( (samp), (uv), 0 )

#define PdxTex3DLod0(samp,uv) PdxTex3DLod( (samp), (uv), 0 )
#define PdxTex3DLoad0(samp,uv) PdxTex3DLoad( (samp), (uv), 0 )

float4 FixProjectionAndMul( float4x4 ProjectionMatrix, float4 Vector )
{
	return mul( FixProjection( ProjectionMatrix ), Vector );
}
