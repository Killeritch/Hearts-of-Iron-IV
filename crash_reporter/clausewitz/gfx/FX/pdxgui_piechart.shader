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
				VS_OUTPUT_PDX_GUI Out;

				float2 Normalised = ( Input.Position.xy + 1.0f ) / 2.0f;
				float2 PixelPos = Normalised * Input.LeftTop_WidthHeight.zw + Input.LeftTop_WidthHeight.xy;

				Out.Position = PixelToScreenSpace( PixelPos );
				Out.UV0      = Normalised;
				Out.Color    = Input.Color;

				return Out;
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

	TextureSampler MaskTexture
	{
		Ref = PdxTexture4
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
				float4 Mask  = PdxTex2DLod0( MaskTexture, Input.UV0 );
				float4 Color = SampleImageSprite( Texture, Input.UV0 );

				float4 OutColor = Color * Input.Color * Mask;
				OutColor.rgb += HighlightColor;

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


Effect Default 
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

