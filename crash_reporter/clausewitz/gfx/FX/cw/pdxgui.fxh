ConstantBuffer( PdxGuiConstants )
{
	float2 ScreenDimension;
};

ConstantBuffer( PdxGuiWidgetConstants )
{
	float4 TextTintColor; 		#Maybe this should just be TintColor?
	float2 WidgetLeftTop;
};

VertexStruct VS_INPUT_PDX_GUI
{
	float2 Position					: POSITION;
	float4 LeftTop_WidthHeight		: TEXCOORD0;
	float4 UVLeftTop_WidthHeight	: TEXCOORD1;
	float4 Color					: COLOR0;
};

VertexStruct VS_INPUT_PDX_GUI_PROFILER
{
	float2 Position					: POSITION;
	float4 LeftTop_WidthHeight		: TEXCOORD0;
	float4 UVLeftTop_WidthHeight	: TEXCOORD1;
	float4 Color					: COLOR0;
	uint VertexID                   : PDX_VertexID;
};

VertexStruct VS_OUTPUT_PDX_GUI
{
	float4 Position		: PDX_POSITION;
	float2 UV0			: TEXCOORD0;
	float4 Color		: COLOR0;
};

Code
[[
	float4 PixelToScreenSpace( float2 PixelPos )
	{
		float2 Pos = PixelPos * 2.0 - ScreenDimension;
		Pos /= ScreenDimension;
		Pos.y = -Pos.y;
	  
		return float4( Pos, 0.0, 1.0 );
	}
]]

VertexShader =
{
	Code
	[[
		VS_OUTPUT_PDX_GUI PdxGuiDefaultVertexShader( const VS_INPUT_PDX_GUI v )
		{
			VS_OUTPUT_PDX_GUI Out;
			float2 PixelPos = WidgetLeftTop + v.LeftTop_WidthHeight.xy + v.Position * v.LeftTop_WidthHeight.zw;
			Out.Position = PixelToScreenSpace( PixelPos );
			Out.UV0 = v.UVLeftTop_WidthHeight.xy + v.Position * v.UVLeftTop_WidthHeight.zw;
			Out.Color = v.Color;
			return Out;
		}
	]]
}

PixelShader =
{
	Code
	[[
		float3 DisableColor( float3 Color )
		{
			float Grey = dot( Color.rgb, float3( 0.212671, 0.715160, 0.072169 ) ); 
			return float3( Grey, Grey, Grey );
		}
		
		float4 DisableColorReturn( float4 Color )
		{
			#ifdef DISABLED
				Color.rgb = DisableColor( Color.rgb );
				return Color;			
			#else
				return Color;
			#endif
		}
	]]
}

