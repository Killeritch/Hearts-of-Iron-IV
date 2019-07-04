
VertexStruct VS_INPUT
{
    float3 vPosition  : POSITION;
	float4 vColor	  : COLOR;
};

VertexStruct VS_INPUT2D
{
    float2 vPosition  : POSITION;
	float4 vColor	  : COLOR;
};

VertexStruct VS_OUTPUT
{
    float4  vPosition : PDX_POSITION;
 	float4  vColor	  : TEXCOORD1;
};


ConstantBuffer( PdxConstantBuffer0 )
{
	float4x4 Matrix;
};

ConstantBuffer( PdxConstantBuffer1 )
{
	float3 SphereCenter;
	float SphereRadius;
	float4 SphereColor;
};


VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT"
		Output = "VS_OUTPUT"
		Code	
		[[
			PDX_MAIN
			{
			    VS_OUTPUT Out;
				
				float3 Position = Input.vPosition.xyz;
				float4 Color = Input.vColor;
				
				#ifdef IS_SPHERE
					Position *= SphereRadius;
					Position += SphereCenter;
					Color = SphereColor;
				#endif
				
			    Out.vPosition = FixProjectionAndMul( Matrix, float4( Position, 1.0 ) );	
				Out.vColor = Color;
			    return Out;
			}
		]]
	}
	
	MainCode VertexShader2D
	{	
		Input = "VS_INPUT2D"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
			    VS_OUTPUT Out;
			    Out.vPosition = FixProjectionAndMul( Matrix, float4( Input.vPosition.xy, 0.0, 1.0 ) );	
				Out.vColor = Input.vColor;
			    return Out;
			}
		]]
	}
}

PixelShader =
{
	MainCode PixelShader
	{	
		Input = "VS_OUTPUT"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
			  	float4 OutColor = Input.vColor;
			    return OutColor;
			}
		]]
	}
}


BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = SRC_ALPHA
	DestBlend = INV_SRC_ALPHA
}


Effect DebugLines
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect DebugSphere
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "IS_SPHERE" }
}

Effect DebugLines2D
{
	VertexShader = "VertexShader2D"
	PixelShader = "PixelShader"
}
