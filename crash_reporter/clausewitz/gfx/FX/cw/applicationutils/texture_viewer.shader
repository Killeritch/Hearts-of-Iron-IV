Includes = {
	"cw/pdxgui.fxh"
	"cw/utility.fxh"
}


ConstantBuffer( 2 )
{
	float4x4 	ColorMatrix;
	float4		ColorAdd;
	float		FlipV;
}


VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT_PDX_GUI"
		Output = "VS_OUTPUT_PDX_GUI"
		Code
		[[
			PDX_MAIN
			{
				return PdxGuiDefaultVertexShader( Input );
			}
		]]
	}
}


PixelShader =
{
	Code
	[[
		float4 MainCode( VS_OUTPUT_PDX_GUI Input )
		{
			float2 UV = Input.UV0;
			if( FlipV > 0.0f )
			{
				UV.y = 1.0f - UV.y;
			}
			float4 OutColor = saturate( mul( ColorMatrix, PdxTex2D( Texture, UV ) ) + ColorAdd );

		#ifdef TO_GAMMA
			OutColor.rgb = ToGamma( OutColor.rgb );
		#endif
			OutColor *= Input.Color;
			
		#ifdef DISABLED
			OutColor.rgb = DisableColor( OutColor.rgb );
		#endif
			
			return OutColor;
		}
	]]
	
	MainCode PixelShaderLinear
	{
		TextureSampler Texture
		{
			Index = 0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}
		
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
			    return MainCode( Input );
			}
		]]
	}
	
	MainCode PixelShaderPoint
	{
		TextureSampler Texture
		{
			Index = 0
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "Point"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}
		
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
			    return MainCode( Input );
			}
		]]
	}
}


BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}

DepthStencilState DepthStencilState
{
	DepthEnable = no
}


Effect PdxGuiDefaultLinear
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderLinear"
}

Effect PdxGuiDefaultLinearDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderLinear"
	
	Defines = { "DISABLED" }
}

Effect PdxGuiDefaultPoint
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderPoint"
}

Effect PdxGuiDefaultPointDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderPoint"
	
	Defines = { "DISABLED" }
}