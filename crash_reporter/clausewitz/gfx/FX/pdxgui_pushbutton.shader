Includes = {
	"cw/pdxgui.fxh"
	"cw/pdxgui_sprite.fxh"
}


ConstantBuffer( PdxConstantBuffer2 )
{
	float3 HighlightColor;
};


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
	TextureSampler Texture
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	
	MainCode PixelShader
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{			
				float4 OutColor = SampleImageSprite( Texture, Input.UV0 );

				OutColor *= Input.Color;
				#ifndef NO_HIGHLIGHT
					OutColor.rgb += HighlightColor;
				#endif
				
				#ifdef DISABLED
					OutColor.rgb = DisableColor( OutColor.rgb );
				#endif
				
			    return OutColor;
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


Effect Up
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect Disabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" }
}


Effect NoHighlightUp
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "NO_HIGHLIGHT" }
}

Effect NoHighlightOver
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "NO_HIGHLIGHT" }
}

Effect NoHighlightDown
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "NO_HIGHLIGHT" }
}

Effect NoHighlightDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" "NO_HIGHLIGHT" }
}
