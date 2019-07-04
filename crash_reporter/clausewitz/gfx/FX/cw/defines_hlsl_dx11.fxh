#define PDX_DIRECTX_11

#define PDX_POSITION SV_Position
#define PDX_COLOR SV_Target
#define PDX_COLOR0 SV_Target0
#define PDX_COLOR0_SRC1 SV_Target1 // Use this when doing dual source blending, currently only supports that for render target #0
#define PDX_COLOR1 SV_Target1
#define PDX_COLOR2 SV_Target2
#define PDX_COLOR3 SV_Target3
#define PDX_COLOR4 SV_Target4
#define PDX_COLOR5 SV_Target5
#define PDX_COLOR6 SV_Target6
#define PDX_COLOR7 SV_Target7
#define PDX_VertexID SV_VertexID
#define PDX_DispatchThreadID SV_DispatchThreadID
#define PDX_GroupThreadID SV_GroupThreadID
#define PDX_GroupID SV_GroupID
#define PDX_GroupIndex SV_GroupIndex

#define mod( X, Y ) ( (X) % (Y) )

float2x2 Create2x2( in float2 x, in float2 y )
{
	return transpose( float2x2( x, y ) );
}
// TODO, Create3x3 should be transposed in hlsl, and not in glsl, and then the mul() arguments should be reversed
#define Create3x3 float3x3
float4x4 Create4x4( in float4 x, in float4 y, in float4 z, in float4 w )
{
	return transpose( float4x4( x, y, z, w ) );
}

#define GetMatrixData( Matrix, row, col ) ( Matrix [ row ] [ col ] )

float3x3 CastTo3x3( in float4x4 M )
{
	return (float3x3)M;
}

#define lessThan( a, b ) ( (a) < (b) )

float2 vec2(float vValue) { return float2(vValue, vValue); }
float3 vec3(float vValue) { return float3(vValue, vValue, vValue); }
float4 vec4(float vValue) { return float4(vValue, vValue, vValue, vValue); }


struct PdxTextureSampler2D
{
    Texture2D 		_Texture;
    SamplerState 	_Sampler;
};
struct PdxTextureSampler2DMS
{
    Texture2DMS<float4>		_Texture;
};

struct PdxTextureSampler2DArray
{
    Texture2DArray	_Texture;
    SamplerState 	_Sampler;
};

struct PdxTextureSampler3D
{
    Texture3D 		_Texture;
    SamplerState 	_Sampler;
};

struct PdxTextureSamplerCube
{
    TextureCube 	_Texture;
    SamplerState 	_Sampler;
};

struct PdxTextureSampler2DCmp
{
    Texture2D 				_Texture;
    SamplerComparisonState 	_Sampler;
};

#define PdxTex2DSize(samp,size) (samp)._Texture.GetDimensions( size.x, size.y )
#define PdxTex2D(samp,uv) (samp)._Texture.Sample( (samp)._Sampler, (uv) )
#define PdxTex2DLod(samp,uv,lod) (samp)._Texture.SampleLevel( (samp)._Sampler, (uv), (lod) )
#define PdxTex2DBias(samp,uv,bias) (samp)._Texture.SampleBias( (samp)._Sampler, (uv), (bias) )
#define PdxTex2DGrad(samp,uv,ddx,ddy) (samp)._Texture.SampleGrad( (samp)._Sampler, (uv), (ddx), (ddy) )
#define PdxTex2DGather(samp,uv) (samp)._Texture.Gather( (samp)._Sampler, (uv) )
#define PdxTex2DLoad(samp,uv,lod) (samp)._Texture.Load( int3((uv), (lod)) )
#define PdxTex2DMultiSampled(samp,texelcoord,sampleidx) (samp)._Texture.Load( (texelcoord), (sampleidx) )

#define PdxTex3D(samp,uv) (samp)._Texture.Sample( (samp)._Sampler, (uv) )
#define PdxTex3DLod(samp,uv,lod) (samp)._Texture.SampleLevel( (samp)._Sampler, (uv), (lod) )
#define PdxTex3DLoad(samp,uv,lod) (samp)._Texture.Load( int4((uv), (lod)) )

#define PdxTexCube(samp,uv) (samp)._Texture.Sample( (samp)._Sampler, (uv) )
#define PdxTexCubeLod(samp,uv,lod) (samp)._Texture.SampleLevel( (samp)._Sampler, (uv), (lod) )
#define PdxTexCubeBias(samp,uv,bias) (samp)._Texture.SampleBias( (samp)._Sampler, (uv), (bias) )

#define PdxTex2DCmpLod0(samp,uv,value) (samp)._Texture.SampleCmpLevelZero( (samp)._Sampler, (uv), (value) )

float4x4 FixProjection( float4x4 ProjectionMatrix )
{
	// Enable for "debug" drawing to see if some objects is missing fix
	#if 0
	for ( int i = 0; i < 4; ++i )
	{
		GetMatrixData( ProjectionMatrix, 0, i ) *= 0.5;
		GetMatrixData( ProjectionMatrix, 1, i ) *= 0.5;
	}
	#endif
	
	return ProjectionMatrix;
}

#define PdxBufferFloat  Buffer<float>
#define PdxBufferFloat2	Buffer<float2>
#define PdxBufferFloat3	Buffer<float3>
#define PdxBufferFloat4	Buffer<float4>
#define PdxBufferInt  	Buffer<int>
#define PdxBufferInt2	Buffer<int2>
#define PdxBufferInt3	Buffer<int3>
#define PdxBufferInt4	Buffer<int4>
#define PdxBufferUint   Buffer<uint>
#define PdxBufferUint2	Buffer<uint2>
#define PdxBufferUint3	Buffer<uint3>
#define PdxBufferUint4	Buffer<uint4>

float 	PdxReadBuffer( in PdxBufferFloat Buf, int Index )  		{ return Buf.Load( Index ); }
float2	PdxReadBuffer2( in PdxBufferFloat2 Buf, int Index )		{ return Buf.Load( Index ); }
float3	PdxReadBuffer3( in PdxBufferFloat3 Buf, int Index )		{ return Buf.Load( Index ); }
float4	PdxReadBuffer4( in PdxBufferFloat4 Buf, int Index )		{ return Buf.Load( Index ); }

int  	PdxReadBuffer( in PdxBufferInt Buf, int Index ) 		{ return Buf.Load( Index ); }
int2 	PdxReadBuffer2( in PdxBufferInt2 Buf, int Index )		{ return Buf.Load( Index ); }
int3 	PdxReadBuffer3( in PdxBufferInt3 Buf, int Index )    	{ return Buf.Load( Index ); }
int4 	PdxReadBuffer4( in PdxBufferInt4 Buf, int Index )    	{ return Buf.Load( Index ); }

uint  	PdxReadBuffer( in PdxBufferUint Buf, int Index )    	{ return Buf.Load( Index ); }
uint2 	PdxReadBuffer2( in PdxBufferUint2 Buf, int Index )  	{ return Buf.Load( Index ); }
uint3 	PdxReadBuffer3( in PdxBufferUint3 Buf, int Index )  	{ return Buf.Load( Index ); }
uint4 	PdxReadBuffer4( in PdxBufferUint4 Buf, int Index )  	{ return Buf.Load( Index ); }


#define PdxRWBufferFloat  	RWBuffer<float>
#define PdxRWBufferFloat2	RWBuffer<float2>
#define PdxRWBufferFloat3	RWBuffer<float3>
#define PdxRWBufferFloat4	RWBuffer<float4>

void PdxWriteBuffer( in PdxRWBufferFloat Buf, int Index, float Value )  	{ Buf[Index] = Value; }
void PdxWriteBuffer2( in PdxRWBufferFloat2 Buf, int Index, float2 Value )	{ Buf[Index] = Value; }
void PdxWriteBuffer3( in PdxRWBufferFloat3 Buf, int Index, float3 Value )	{ Buf[Index] = Value; }
void PdxWriteBuffer4( in PdxRWBufferFloat4 Buf, int Index, float4 Value )	{ Buf[Index] = Value; }
