#define float4 vec4
#define float3 vec3
#define float2 vec2

#define int4 ivec4
#define int3 ivec3
#define int2 ivec2

#define uint4 uvec4
#define uint3 uvec3
#define uint2 uvec2

#define float4x4 mat4
#define float3x3 mat3
#define float2x2 mat2

#define bool4 bvec4
#define bool3 bvec3
#define bool2 bvec2

#define static 

float2x2 Create2x2( in float2 x, in float2 y )
{
	return float2x2( x, y );
}
float3x3 Create3x3( in float3 x, in float3 y, in float3 z )
{
	float3x3 Matrix = float3x3( x, y, z );
	Matrix = transpose( Matrix );
	return Matrix;
}
float4x4 Create4x4( in float4 x, in float4 y, in float4 z, in float4 w )
{
	return float4x4( x, y, z, w );
}

#define GetMatrixData( Matrix, row, col ) ( Matrix [ col ] [ row ] )

float3x3 CastTo3x3( in float4x4 M )
{
	return float3x3(M);
}

#define atan2 atan

#define PdxTextureSampler2D sampler2D
#define PdxTextureSampler2DArray sampler2DArray
#define PdxTextureSamplerCube samplerCube

#define PdxTextureSampler2DCmp sampler2DShadow
#define PdxTextureSampler2DMS sampler2DMS


#define PdxTex2D texture
#define PdxTex2DLod textureLod
#define PdxTex2DBias texture
#define PdxTex2DGrad textureGrad
#define PdxTex2DGather TODO
#define PdxTex2DLoad texelFetch
#define PdxTex2DMultiSampled texelFetch

#define PdxTexCube texture
#define PdxTexCubeLod textureLod
#define PdxTexCubeBias texture

#define PdxTex2DCmpLod0(samp,uv,value) texture((samp), vec3((uv),(value)))
#define PdxTex2DSize(samp,size) ivec2 _size = textureSize((samp), 0); size = _size


#define ddx dFdx
#define ddy dFdy

void sincos( float Value, out float vSin, out float vCos )
{
	vSin = sin(Value);
	vCos = cos(Value);
}

float4 saturate( float4 Value )
{
	return clamp( Value, vec4(0.0), vec4(1.0) );
}
float3 saturate( float3 Value )
{
	return clamp( Value, vec3(0.0), vec3(1.0) );
}
float2 saturate( float2 Value )
{
	return clamp( Value, vec2(0.0), vec2(1.0) );
}
float saturate( float Value )
{
	return clamp( Value, 0.0, 1.0 );
}

#ifdef PIXEL_SHADER
void clip( float4 x )
{
	if( any( lessThan( x, vec4( 0.0 ) ) ) ) { discard; }
}

void clip( float3 x )
{
    if( any( lessThan( x, vec3( 0.0 ) ) ) ) { discard; }
}

void clip( float2 x )
{
	if( any( lessThan( x, vec2( 0.0 ) ) ) ) { discard; }
}

void clip( float x )
{
	if( x < 0.0 ) { discard; }
}
#endif // PIXEL_SHADER

#define lerp mix
#define frac fract

float4 mul( float4 Vector, mat4 Matrix )
{
	return Vector * Matrix;
}
float3 mul( float3 Vector, mat3 Matrix )
{
	return Vector * Matrix;
}
float2 mul( float2 Vector, mat2 Matrix )
{
	return Vector * Matrix;
}
float4 mul( mat4 Matrix, float4 Vector )
{
	return Matrix * Vector;
}
float3 mul( mat3 Matrix, float3 Vector )
{
	return Matrix * Vector;
}
float2 mul( mat2 Matrix, float2 Vector )
{
	return Matrix * Vector;
}
mat4 mul( mat4 MatrixA, mat4 MatrixB )
{
	return MatrixA * MatrixB;
}
mat3 mul( mat3 MatrixA, mat3 MatrixB )
{
	return MatrixA * MatrixB;
}
mat2 mul( mat2 MatrixA, mat2 MatrixB )
{
	return MatrixA * MatrixB;
}

// Clip space [-1 -> 1] to [0 -> 1] fix for when glClipControl does not exist
float4x4 FixProjection( float4x4 ProjectionMatrix )
{
	#ifdef PDX_USE_CLIPCONTROL_WORKAROUND
	for ( int i = 0; i < 4; ++i )
	{
		// Enable for "debug" drawing to see if some objects is missing fix
		#if 0
		GetMatrixData( ProjectionMatrix, 0, i ) *= 0.5;
		GetMatrixData( ProjectionMatrix, 1, i ) *= 0.5;
		#endif
		
		GetMatrixData( ProjectionMatrix, 2, i ) *= 2.0;
		GetMatrixData( ProjectionMatrix, 2, i ) -= GetMatrixData( ProjectionMatrix, 3, i );
	}
	#endif
	
	return ProjectionMatrix;
}

#define PdxBufferFloat  samplerBuffer
#define PdxBufferFloat2	samplerBuffer
#define PdxBufferFloat3	samplerBuffer
#define PdxBufferFloat4	samplerBuffer
#define PdxBufferInt  	isamplerBuffer
#define PdxBufferInt2	isamplerBuffer
#define PdxBufferInt3	isamplerBuffer
#define PdxBufferInt4	isamplerBuffer
#define PdxBufferUint   usamplerBuffer
#define PdxBufferUint2	usamplerBuffer
#define PdxBufferUint3	usamplerBuffer
#define PdxBufferUint4	usamplerBuffer

float 	PdxReadBuffer( in PdxBufferFloat  Buf, int Index )  	{ return texelFetch( Buf, Index ).r; }
float2	PdxReadBuffer2( in PdxBufferFloat2 Buf, int Index )		{ return texelFetch( Buf, Index ).rg; }
float3	PdxReadBuffer3( in PdxBufferFloat3 Buf, int Index )		{ return texelFetch( Buf, Index ).rgb; }
float4	PdxReadBuffer4( in PdxBufferFloat4 Buf, int Index )		{ return texelFetch( Buf, Index ).rgba; }

int  	PdxReadBuffer( in PdxBufferInt  Buf, int Index ) 		{ return texelFetch( Buf, Index ).r; }
int2 	PdxReadBuffer2( in PdxBufferInt2 Buf, int Index )		{ return texelFetch( Buf, Index ).rg; }
int3 	PdxReadBuffer3( in PdxBufferInt3 Buf, int Index )    	{ return texelFetch( Buf, Index ).rgb; }
int4 	PdxReadBuffer4( in PdxBufferInt4 Buf, int Index )    	{ return texelFetch( Buf, Index ).rgba; }

uint  	PdxReadBuffer( in PdxBufferUint  Buf, int Index )    	{ return texelFetch( Buf, Index ).r; }
uint2 	PdxReadBuffer2( in PdxBufferUint2 Buf, int Index )  	{ return texelFetch( Buf, Index ).rg; }
uint3 	PdxReadBuffer3( in PdxBufferUint3 Buf, int Index )  	{ return texelFetch( Buf, Index ).rgb; }
uint4 	PdxReadBuffer4( in PdxBufferUint4 Buf, int Index )  	{ return texelFetch( Buf, Index ).rgba; }

#ifndef PDX_OPENGL
#define PdxRWBufferFloat  	imageBuffer
#define PdxRWBufferFloat2	imageBuffer
#define PdxRWBufferFloat3	imageBuffer
#define PdxRWBufferFloat4	imageBuffer

void PdxWriteBuffer( in PdxRWBufferFloat Buf, int Index, float Value )  	{ imageStore( Buf, Index, vec4( Value ) ); }
void PdxWriteBuffer2( in PdxRWBufferFloat2 Buf, int Index, float2 Value )	{ imageStore( Buf, Index, vec4( Value, 0.0, 0.0 ) ); }
void PdxWriteBuffer3( in PdxRWBufferFloat3 Buf, int Index, float3 Value )	{ imageStore( Buf, Index, vec4( Value, 0.0 ) ); }
void PdxWriteBuffer4( in PdxRWBufferFloat4 Buf, int Index, float4 Value )	{ imageStore( Buf, Index, Value ); }
#endif