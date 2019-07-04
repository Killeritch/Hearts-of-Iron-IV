Includes = {
	"cw/pdxgui.fxh"
	"cw/pdxgui_sprite.fxh"
}


ConstantBuffer( PdxConstantBuffer2 )
{
	float2 Progress;
	float InvertOffset;
	float InvertScale;
};


VertexStruct VS_OUTPUT_PDX_GUI_PROGRESSBAR
{
	float4 Position		: PDX_POSITION;
	float2 UV0			: TEXCOORD0;
	float2 LocalPos		: TEXCOORD1;
	float4 Color		: COLOR;
};


VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT_PDX_GUI"
		Output = "VS_OUTPUT_PDX_GUI_PROGRESSBAR"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PDX_GUI Default = PdxGuiDefaultVertexShader( Input );
				
				VS_OUTPUT_PDX_GUI_PROGRESSBAR Out;
				Out.Position = Default.Position;
				Out.UV0 = Default.UV0;
				Out.Color = Default.Color;
				Out.LocalPos = Input.Position;
				return Out;
			}
		]]
	}
	
	MainCode VertexShaderFramed
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
	TextureSampler Texture0
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	
	TextureSampler Texture1
	{
		Ref = PdxTexture1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	
	MainCode PixelShader
	{
		Input = "VS_OUTPUT_PDX_GUI_PROGRESSBAR"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float4 OutColor;
				float2 ProgressPos = vec2(InvertOffset) - Input.LocalPos * InvertScale;
				if ( ProgressPos.x <= Progress.x && ProgressPos.y <= Progress.y )
					OutColor = SampleImageSprite( Texture0, Input.UV0 );
				else
					OutColor = SampleImageSprite( Texture1, Input.UV0 );
					
				OutColor *= Input.Color;
				
				#ifdef DISABLED
					OutColor.rgb = DisableColor( OutColor.rgb );
				#endif
				
			    return OutColor;
			}
		]]
	}
	
	MainCode PixelShaderFramed
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{			
				float4 OutColor = SampleImageSprite( Texture0, Input.UV0 );
				OutColor *= Input.Color;
				
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


Effect PdxProgressBar
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect PdxProgressBarDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" }
}


Effect PdxFramedProgressBar
{
	VertexShader = "VertexShaderFramed"
	PixelShader = "PixelShaderFramed"
}

Effect PdxFramedProgressBarDisabled
{
	VertexShader = "VertexShaderFramed"
	PixelShader = "PixelShaderFramed"
	
	Defines = { "DISABLED" }
}