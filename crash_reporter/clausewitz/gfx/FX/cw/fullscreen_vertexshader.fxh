
VertexStruct VS_OUTPUT_FULLSCREEN
{
    float4 position			: PDX_POSITION;
	float2 uv				: TEXCOORD0;
};

VertexShader = {

	VertexStruct VS_INPUT_FULLSCREEN
	{
		int2 position	: POSITION;
	};
	
	Code
	[[
		VS_OUTPUT_FULLSCREEN FullscreenVertexShader( VS_INPUT_FULLSCREEN Input )
		{
			VS_OUTPUT_FULLSCREEN VertexOut;
			VertexOut.position = float4( Input.position, 0.0, 1.0 );

			VertexOut.uv = Input.position.xy * 0.5 + 0.5;
			VertexOut.uv.y = 1.0 - VertexOut.uv.y;

			return VertexOut;
		}
	]]
	
	MainCode VertexShaderFullscreen
	{
		Input = "VS_INPUT_FULLSCREEN"
		Output = "VS_OUTPUT_FULLSCREEN"
		Code
		[[
			PDX_MAIN
			{
				return FullscreenVertexShader( Input );
			}
		]]
	}
}