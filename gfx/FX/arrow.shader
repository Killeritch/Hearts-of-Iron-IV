Includes = {
	"constants.fxh"
	"standardfuncsgfx.fxh"
}

PixelShader =
{
	Samplers =
	{
		DiffuseTexture =
		{
			Index = 0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		NormalMap =
		{
			Index = 1
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		SpecularMap =
		{
			Index = 2
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
	}
}


VertexStruct VS_INPUT
{
    float3 vPosition  : POSITION;
	float2 vTexCoord  : TEXCOORD0;
};

VertexStruct VS_OUTPUT
{
    float4 vPosition : PDX_POSITION;
    float2 vTexCoord : TEXCOORD0;
	float3 vPos		 : TEXCOORD1;
};


ConstantBuffer( 1, 32 )
{
	float4x4 ViewProj;
	float3 vProgress_MoveArmy;
	float4 vDesaturationLengths;
	float fOffsetX;
};


VertexShader =
{
	MainCode VertexShader
	[[
		VS_OUTPUT main(const VS_INPUT v )
		{
		 	VS_OUTPUT Out;
		
			float4 pos = float4( v.vPosition, 1.0f );
			pos.y -= 0.1f;//2.0f;
			pos.x += fOffsetX;
			Out.vPos = pos.xyz;
		   	Out.vPosition  = mul( ViewProj, pos );	
			Out.vTexCoord = v.vTexCoord;
		
			return Out;
		}
		
		
	]]
}

PixelShader =
{
	MainCode PixelShader
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			//return float4( 1, 0, 0, 0.75f );
		 	clip( vProgress_MoveArmy.x - v.vTexCoord.y );
			clip( v.vTexCoord.y - vProgress_MoveArmy.z );
		
			float vPassed = v.vTexCoord.y < vProgress_MoveArmy.y ? 1.0f : 0.0f;
		
			float vArrowPart = 12.0f;
			
			float vArrowDiff = v.vTexCoord.y - ( vProgress_MoveArmy.x - vArrowPart );
			float vArrow = saturate( vArrowDiff * 10000.0f );
		
			float BODY = 0.125f;
			float ARROW = 1.0f - BODY;
		
			float vBodyV = frac( v.vTexCoord.y * 0.00001f ) * BODY;
			float vArrowV = BODY + ( vArrowDiff / vArrowPart ) * ARROW;
			
			//Calculate color
			float4 OutColorBody = tex2D( DiffuseTexture, float2( vBodyV, v.vTexCoord.x * 0.5f ) );
			float4 OutColorBodyPass = tex2D( DiffuseTexture, float2( vBodyV, 0.5f + v.vTexCoord.x * 0.5f ) );
			float4 OutColorArrow = tex2D( DiffuseTexture, float2( vArrowV, v.vTexCoord.x * 0.5f ) );
			float4 OutColorArrowPass = tex2D( DiffuseTexture, float2( vArrowV, 0.5f + v.vTexCoord.x * 0.5f ) );
		
			float4 OutColor = lerp(
					lerp( OutColorBody, OutColorArrow, vArrow ),
					lerp( OutColorBodyPass, OutColorArrowPass, vArrow ),
					vPassed );
			
			//Calculate normal
			float3 NormalBody = normalize( tex2D( NormalMap, float2( vBodyV, v.vTexCoord.x * 0.5f ) ).rbg  - 0.5f  );
			float3 NormalBodyPass = normalize( tex2D( NormalMap, float2( vBodyV, 0.5f + v.vTexCoord.x * 0.5f ) ).rbg - 0.5f  );
			float3 NormalArrow = normalize( tex2D( NormalMap, float2( vArrowV, v.vTexCoord.x * 0.5f ) ).rbg - 0.5f );
			float3 NormalArrowPass = normalize( tex2D( NormalMap, float2( vArrowV, 0.5f + v.vTexCoord.x * 0.5f ) ).rbg - 0.5f );					
			float3 vNormal = lerp(
					lerp( NormalBody, NormalArrow, vArrow ),
					lerp( NormalBodyPass, NormalArrowPass, vArrow ),
					vPassed );
			vNormal = normalize( vNormal );
			
			//Calculate Specular
			float4 SpecBody = tex2D( SpecularMap, float2( vBodyV, v.vTexCoord.x * 0.5f ) );
			float4 SpecBodyPass = tex2D( SpecularMap, float2( vBodyV, 0.5f + v.vTexCoord.x * 0.5f ) );
			float4 SpecArrow = tex2D( SpecularMap, float2( vArrowV, v.vTexCoord.x * 0.5f ) );
			float4 SpecArrowPass = tex2D( SpecularMap, float2( vArrowV, 0.5f + v.vTexCoord.x * 0.5f ) );					
			float4 vSpecColor = lerp(
					lerp( SpecBody, SpecArrow, vArrow ),
					lerp( SpecBodyPass, SpecArrowPass, vArrow ),
					vPassed );
				
			//Lightning
			//OutColor.rgb = CalculateLighting( OutColor.rgb, vNormal );
			
			float vFadeLength = vProgress_MoveArmy.z + 2.0f;
			float vAlpha = v.vTexCoord.y - vFadeLength;
			vAlpha = vAlpha * saturate( 1.0f - ( vAlpha/-vFadeLength ) );
			
			return float4( ToLinear(OutColor.rgb), OutColor.a * saturate( vAlpha ) * 0.85f );
			//return float4( ComposeSpecular( OutColor.rgb, CalculateSpecular( v.vPos, vNormal, ( vSpecColor.a * 2.0f ) ) ), OutColor.a );
		}
		
	]]
}


BlendState BlendState
{
	BlendEnable = yes
	AlphaTest = no
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}


Effect ArrowEffect
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

