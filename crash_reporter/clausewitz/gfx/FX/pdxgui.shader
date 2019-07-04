Includes = {
	"cw/pdxgui.fxh"
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

	MainCode VertexShaderGraph
	{
		Input = "VS_INPUT_PDX_GUI_GRAPH"
		Output = "VS_OUTPUT_PDX_GUI"
		Code 
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PDX_GUI Out;

				float2 PixelPos = WidgetLeftTop + Input.LeftTop_WidthHeight.xy + Input.Position * Input.LeftTop_WidthHeight.zw;
				Out.Position    = PixelToScreenSpace( PixelPos );
				Out.UV0         = Input.UV;
				Out.Color       = Input.Color;
				
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
	
	MainCode PixelShader
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code 
		[[
			PDX_MAIN
			{
				return Input.Color;
			}
		]]
	}

	MainCode PixelShaderTextGlow
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code 
		[[
			PDX_MAIN
			{	
				float2 AtlasSize;
				PdxTex2DSize( Texture, AtlasSize );

				float Offsets[3];
				Offsets[0] = 0.0;
				Offsets[1] = 1.3846153846;
				Offsets[2] = 3.2307692308;

				float Weights[3];
				Weights[0] = 0.2270270270;
				Weights[1] = 0.3162162162;
				Weights[2] = 0.0702702703;

				float Alpha = PdxTex2D( Texture, Input.UV0 ).r * Weights[0];
				for ( int j = 1; j < 3; j++ )
				{
					Alpha += PdxTex2D( 
						Texture, 
						Input.UV0 + float2( 0.0, Offsets[j] / AtlasSize.y ) ).r * Weights[j];

					Alpha += PdxTex2D( 
						Texture, 
						Input.UV0 - float2( 0.0, Offsets[j] / AtlasSize.y ) ).r * Weights[j];
				}

				for ( int j = 1; j < 3; j++ )
				{
					Alpha += PdxTex2D( 
						Texture, 
						Input.UV0 + float2( Offsets[j] / AtlasSize.x, 0.0 ) ).r * Weights[j];

					Alpha += PdxTex2D( 
						Texture, 
						Input.UV0 - float2( Offsets[j] / AtlasSize.x, 0.0 ) ).r * Weights[j];
				}

				return float4( Input.Color.rgb, TextTintColor.a * Input.Color.a * Alpha );
			}
		]]
	}

	MainCode PixelShaderText
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code 
		[[
			PDX_MAIN
			{	
				return TextTintColor * float4( Input.Color.rgb, PdxTex2D( Texture, Input.UV0 ).r * Input.Color.a );
			}
		]]
	}

	MainCode PixelShaderTextIcon
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code 
		[[
			PDX_MAIN
			{	
				float4 Color = PdxTex2D( Texture, Input.UV0 ) * Input.Color;
				Color.a = Color.a * TextTintColor.a;
				return Color;
			}
		]]
	}
	
	MainCode PixelShaderTextUnderline
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code 
		[[
			PDX_MAIN
			{	
				return TextTintColor * Input.Color;
			}
		]]
	}

	MainCode PixelShaderTexture
	{
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		Code 
		[[
			PDX_MAIN
			{	
				return PdxTex2D( Texture, Input.UV0 ) * Input.Color;
			}
		]]
	}
	
	MainCode PixelShaderOutsideRect
	{
		ConstantBuffer( PdxConstantBuffer2 )
		{
			float4 ParentRect;
			float Time;
		};
		
		Input = "VS_OUTPUT_PDX_GUI"
		Output = "PDX_COLOR"
		
		Code 
		[[
			PDX_MAIN
			{
				if( Input.Position.x > (ParentRect.x + ParentRect.z) ||
					Input.Position.x < ParentRect.x ||
					Input.Position.y > (ParentRect.y + ParentRect.w) ||
					Input.Position.y < ParentRect.y)
				{
					float inv_e = 1.0 / 2.71828;
					float min_red = 0.5;
					float v = min_red + (1.0 - min_red) * (1.0 - (exp( sin( Time * 2.0 ) ) - inv_e) * 0.42545906412);
					
					return float4( v, 0.0, 0.0, 0.6 );
				}
				else
					return float4( 0.0, 0.0, 0.0, 0.0 );
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


Effect PdxDefaultGUI
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect PdxDefaultGUITexture
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderTexture"
}

Effect PdxDefaultGUIGraph
{
	VertexShader = "VertexShaderGraph"
	PixelShader = "PixelShaderTexture"
}

Effect PdxDefaultGUIText
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderText"
}

Effect PdxDefaultGUITextGlow
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderTextGlow"
}

Effect PdxDefaultGUITextIcon
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderTextIcon"
}

Effect PdxDefaultGUITextUnderline
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderTextUnderline"
}

Effect PdxDefaultGUIDebug
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect PdxOutsideRect
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderOutsideRect"
}
