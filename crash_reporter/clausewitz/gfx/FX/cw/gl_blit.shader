Includes = {
	"cw/fullscreen_vertexshader.fxh"
}

PixelShader =
{
	TextureSampler BackBuffer
	{
		Ref = PdxTexture0
		MagFilter = "Point"
		MinFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
}

PixelShader =
{
	MainCode Blit
	{
		Input = "VS_OUTPUT_FULLSCREEN"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				return PdxTex2DLod0( BackBuffer, float2( Input.uv.x, 1.0 - Input.uv.y ) );
			}		
		]]
	}
}


#BlendState BlendState
#{
#	BlendEnable = no
#}

DepthStencilState DepthStencilState
{
	DepthEnable = no
	DepthWriteEnable = no
}


Effect blit
{
	VertexShader = "VertexShaderFullscreen"
	PixelShader = "Blit"
}
