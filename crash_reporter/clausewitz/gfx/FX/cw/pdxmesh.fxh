Includes = {
	"cw/camera.fxh"
	"cw/random.fxh"
}


VertexStruct VS_INPUT_PDXMESHSTANDARD
{
    float3 Position			: POSITION;
	float3 Normal      		: TEXCOORD0;
	float4 Tangent			: TEXCOORD1;
	float2 UV0				: TEXCOORD2;
	
@ifdef PDX_MESH_UV1
	float2 UV1				: TEXCOORD3;
@endif

	uint2 InstanceIndices 	: TEXCOORD4;
	
@ifdef PDX_MESH_SKINNED
	uint4 BoneIndex 		: TEXCOORD5;
	float3 BoneWeight		: TEXCOORD6;
@endif
};

VertexStruct VS_OUTPUT_PDXMESHSHADOW
{
    float4 Position			: PDX_POSITION;
	float2 UV				: TEXCOORD0;
};
VertexStruct VS_OUTPUT_PDXMESHSHADOWSTANDARD
{
	float4 Position				: PDX_POSITION;
	float3 UV_InstanceIndex		: TEXCOORD0;
};

VertexStruct VS_INPUT_DEBUGNORMAL
{
    float3 Position			: POSITION;
	float3 Normal      		: TEXCOORD0;
	float4 Tangent			: TEXCOORD1;
	float2 UV0				: TEXCOORD2;
	float2 UV1				: TEXCOORD3;
	uint2 InstanceIndices 	: TEXCOORD4;
@ifdef PDX_MESH_SKINNED
	uint4 BoneIndex 		: TEXCOORD5;
	float3 BoneWeight		: TEXCOORD6;
@endif
	float  Offset      		: TEXCOORD7;
};

VertexStruct VS_OUTPUT_DEBUGNORMAL
{
    float4 Position 	: PDX_POSITION;
	float2 UV0			: TEXCOORD0;
	float Offset		: TEXCOORD1;
};

ConstantBuffer( 1 )
{
	float4		Data[2]; # TODO, setting to 4096 makes hlsl compile take ages, and this seems to produce the same code
};

ConstantBuffer( 2 )
{
	float4x4 BoneMatrices[2]; # TODO, setting to 1024 makes hlsl compile take ages, and this seems to produce the same code
};

ConstantBuffer( 3 )
{
	uint4	blendShapeIndices[20];
	float4	blendShapeWeights[20];
	uint	nActiveBlendShapes;
};

ConstantBuffer( 4 )
{
	uint 	nBlendShapesVertexOffset;
};

Code
[[
	static const int PDXMESH_MAX_INFLUENCE = 4;
	static const int PDXMESH_WORLD_MATRIX_OFFSET = 0;
	static const int PDXMESH_OPACITY_OFFSET = 4;
	static const int PDXMESH_USER_DATA_OFFSET = 5;
	
	float4x4 PdxMeshGetWorldMatrix( uint nIndex )
	{
		return Create4x4( 
			Data[nIndex + PDXMESH_WORLD_MATRIX_OFFSET + 0], 
			Data[nIndex + PDXMESH_WORLD_MATRIX_OFFSET + 1], 
			Data[nIndex + PDXMESH_WORLD_MATRIX_OFFSET + 2], 
			Data[nIndex + PDXMESH_WORLD_MATRIX_OFFSET + 3] );
	}
	float PdxMeshGetOpacity( uint nIndex )
	{
		return Data[nIndex + PDXMESH_OPACITY_OFFSET].x;
	}
	float3 PdxMeshGetMeshDummyValues( uint nIndex )
	{
		return Data[nIndex + PDXMESH_OPACITY_OFFSET].yzw;
	}
]]


VertexShader =
{
	Code
	[[
		struct VS_OUTPUT_PDXMESH
		{
			float4 Position;
			float3 WorldSpacePos;
			float3 Normal;
			float3 Tangent;
			float3 Bitangent;
			float2 UV0;
			float2 UV1;
		};
		
		struct VS_INPUT_PDXMESH
		{
			float3 Position;
			float3 Normal;
			float4 Tangent;
			float2 UV0;
		#ifdef PDX_MESH_UV1
			float2 UV1;
		#endif
		#ifdef PDX_MESH_SKINNED
			uint4 BoneIndex;
			float3 BoneWeight;
		#endif
		};
		
		VS_INPUT_PDXMESH PdxMeshConvertInput( in VS_INPUT_PDXMESHSTANDARD Input )
		{
			VS_INPUT_PDXMESH Out;
			Out.Position = Input.Position;
			Out.Normal = Input.Normal;
			Out.Tangent = Input.Tangent;
			Out.UV0 = Input.UV0;
		#ifdef PDX_MESH_UV1
			Out.UV1 = Input.UV1;
		#endif
		#ifdef PDX_MESH_SKINNED
			Out.BoneIndex = Input.BoneIndex;
			Out.BoneWeight = Input.BoneWeight;
		#endif
			return Out;
		}
		
	#ifdef PDX_MESH_SKINNED
	
		VS_OUTPUT_PDXMESH PdxMeshVertexShader( VS_INPUT_PDXMESH Input, uint BoneOffset, float4x4 WorldMatrix )
		{
			VS_OUTPUT_PDXMESH Out;

			float4 Position = float4( Input.Position.xyz, 1.0 );
			float4 SkinnedPosition = vec4( 0.0 );
			float3 SkinnedNormal = vec3( 0.0 );
			float3 SkinnedTangent = vec3( 0.0 );
			float3 SkinnedBitangent = vec3( 0.0 );

			float4 Weights = float4( Input.BoneWeight.xyz, 1.0 - Input.BoneWeight.x - Input.BoneWeight.y - Input.BoneWeight.z );
			for( int i = 0; i < PDXMESH_MAX_INFLUENCE; ++i )
			{
				int nIndex = int( Input.BoneIndex[i] );
				float4x4 mat = BoneMatrices[nIndex + BoneOffset];
				SkinnedPosition += mul( mat, Position ) * Weights[i];

				float3 Normal = mul( CastTo3x3(mat), Input.Normal );
				float3 Tangent = mul( CastTo3x3(mat), Input.Tangent.xyz );
				float3 Bitangent = cross( Normal, Tangent ) * Input.Tangent.w;

				SkinnedNormal += Normal * Weights[i];
				SkinnedTangent += Tangent * Weights[i];
				SkinnedBitangent += Bitangent * Weights[i];
			}

			Out.Position = mul( WorldMatrix, SkinnedPosition );
			Out.WorldSpacePos = Out.Position.xyz;
			Out.WorldSpacePos /= WorldMatrix[3][3];
			Out.Position = FixProjectionAndMul( ViewProjectionMatrix, Out.Position );

			Out.Normal = normalize( mul( CastTo3x3(WorldMatrix), normalize( SkinnedNormal ) ) );
			Out.Tangent = normalize( mul( CastTo3x3(WorldMatrix), normalize( SkinnedTangent ) ) );
			Out.Bitangent = normalize( mul( CastTo3x3(WorldMatrix), normalize( SkinnedBitangent ) ) );

			Out.UV0 = Input.UV0;
		#ifdef PDX_MESH_UV1
			Out.UV1 = Input.UV1;
		#else
			Out.UV1 = vec2( 0.0 );
		#endif

			return Out;
		}
		
	#else
	
		VS_OUTPUT_PDXMESH PdxMeshVertexShader( VS_INPUT_PDXMESH Input, uint BoneOffset, float4x4 WorldMatrix )
		{
			VS_OUTPUT_PDXMESH Out;
	
			float4 Position = float4( Input.Position.xyz, 1.0 );
			Out.Normal = normalize( mul( CastTo3x3( WorldMatrix ), Input.Normal ) );
			Out.Tangent = normalize( mul( CastTo3x3( WorldMatrix ), Input.Tangent.xyz ) );
			Out.Bitangent = normalize( cross( Out.Normal, Out.Tangent ) * Input.Tangent.w );
	
			Out.Position = mul( WorldMatrix, Position );
			Out.WorldSpacePos = Out.Position.xyz;
			Out.WorldSpacePos /= WorldMatrix[3][3];
			Out.Position = FixProjectionAndMul( ViewProjectionMatrix, Out.Position );
	
			Out.UV0 = Input.UV0;
		#ifdef PDX_MESH_UV1
			Out.UV1 = Input.UV1;
		#else
			Out.UV1 = vec2( 0.0 );
		#endif
	
			return Out;
		}
		
	#endif
	
	VS_OUTPUT_PDXMESH PdxMeshVertexShaderStandard( VS_INPUT_PDXMESHSTANDARD Input )
	{
		return PdxMeshVertexShader( PdxMeshConvertInput( Input ), Input.InstanceIndices.x, PdxMeshGetWorldMatrix( Input.InstanceIndices.y ) );
	}
	
	VS_OUTPUT_PDXMESHSHADOW PdxMeshVertexShaderShadow( VS_INPUT_PDXMESH Input, uint BoneOffset, float4x4 WorldMatrix )
	{
		VS_OUTPUT_PDXMESHSHADOW Out;
				
		float4 Position = float4( Input.Position.xyz, 1.0 );
		
	#ifdef PDX_MESH_SKINNED
		float4 vWeight = float4( Input.BoneWeight.xyz, 1.0 - Input.BoneWeight.x - Input.BoneWeight.y - Input.BoneWeight.z );
		float4 vSkinnedPosition = vec4( 0.0 );
		for( int i = 0; i < PDXMESH_MAX_INFLUENCE; ++i )
		{
			int nIndex = int( Input.BoneIndex[i] );
			float4x4 mat = BoneMatrices[nIndex + BoneOffset];
			vSkinnedPosition += mul( mat, Position ) * vWeight[i];
		}
		Out.Position = mul( WorldMatrix, vSkinnedPosition );
	#else
		Out.Position = mul( WorldMatrix, Position );
	#endif
		Out.Position = FixProjectionAndMul( ViewProjectionMatrix, Out.Position );
		Out.UV = Input.UV0;
		return Out;
	}
	VS_OUTPUT_PDXMESHSHADOWSTANDARD PdxMeshVertexShaderShadowStandard( VS_INPUT_PDXMESHSTANDARD Input )
	{
		VS_OUTPUT_PDXMESHSHADOW CommonOut = PdxMeshVertexShaderShadow( PdxMeshConvertInput(Input), Input.InstanceIndices.x, PdxMeshGetWorldMatrix( Input.InstanceIndices.y ) );
		VS_OUTPUT_PDXMESHSHADOWSTANDARD Out;
		Out.Position = CommonOut.Position;
		Out.UV_InstanceIndex.xy = CommonOut.UV;
		Out.UV_InstanceIndex.z = Input.InstanceIndices.y;
		return Out;
	}
	]]

	MainCode VertexPdxMeshStandardShadow
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT_PDXMESHSHADOWSTANDARD"
		Code
		[[
			PDX_MAIN
			{
				return PdxMeshVertexShaderShadowStandard( Input );
			}
		]]
	}
	
	MainCode VertexDebugNormal
	{
		Input = "VS_INPUT_DEBUGNORMAL"
		Output = "VS_OUTPUT_DEBUGNORMAL"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_DEBUGNORMAL Out;
				
				float4x4 WorldMatrix = PdxMeshGetWorldMatrix( Input.InstanceIndices.y );
			#ifdef PDX_MESH_SKINNED
				float4 Position = float4( Input.Position.xyz, 1.0 );

				float4 vWeight = float4( Input.BoneWeight.xyz, 1.0 - Input.BoneWeight.x - Input.BoneWeight.y - Input.BoneWeight.z );
				float4 vSkinnedPosition = vec4( 0.0 );
				float3 Normal = vec3( 0.0 );
				for( int i = 0; i < PDXMESH_MAX_INFLUENCE; ++i )
				{
					int nIndex = int( Input.BoneIndex[i] );
					float4x4 mat = BoneMatrices[nIndex + Input.InstanceIndices.x];
					vSkinnedPosition += mul( mat, Position ) * vWeight[i];
					Normal += mul( CastTo3x3(mat), Input.Normal ) * vWeight[i];
				}

				Out.Position = mul( WorldMatrix, vSkinnedPosition );
			#else
				Out.Position = mul( WorldMatrix, float4( Input.Position.xyz, 1.0 ) );
				float3 Normal = Input.Normal;
			#endif

				Out.Position.xyz += mul( CastTo3x3(WorldMatrix), normalize( Normal ) ) * Input.Offset * 0.3;
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, Out.Position );

				Out.UV0 = Input.UV0;
				Out.Offset = Input.Offset;

				return Out;
			}
		]]
	}
}


PixelShader =
{
	Code
	[[
		#ifndef PDXMESH_AlphaBlendShadowMap
			#define PDXMESH_AlphaBlendShadowMap DiffuseMap
		#endif
		
		#ifndef PDXMESH_DISABLE_DITHERED_OPACITY
			#define PDXMESH_USE_DITHERED_OPACITY
		#endif
		
		void PdxMeshApplyDitheredOpacity( in float Opacity, in float2 NoiseCoordinate )
		{
			#ifdef PDXMESH_SCREENDOOR_DITHER				
				const float4x4 ThresholdMatrix =
				{
					1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
					13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
					4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
					16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
				};
				float Factor = ThresholdMatrix[NoiseCoordinate.x % 4][NoiseCoordinate.y % 4];
			#else
				float Factor = CalcRandom( NoiseCoordinate );
			#endif
			
			clip( Opacity - Factor * sign( Opacity ) );
		}
		
		float PdxMeshApplyOpacity( in float Alpha, in float2 NoiseCoordinate, in float Opacity )
		{
			#ifdef PDXMESH_USE_DITHERED_OPACITY
				if( Opacity < 1.0f )
				{
					PdxMeshApplyDitheredOpacity( Opacity, NoiseCoordinate );
				}
			#endif
			return Alpha;
		}
	]]

	MainCode PixelPdxMeshStandardShadow
	{
		Input = "VS_OUTPUT_PDXMESHSHADOWSTANDARD"
		Output = "void"
		Code
		[[
			PDX_MAIN
			{
			#ifdef PDXMESH_USE_DITHERED_OPACITY
				float Opacity = PdxMeshGetOpacity( uint( Input.UV_InstanceIndex.z ) );
				PdxMeshApplyDitheredOpacity( Opacity, Input.Position.xy );
			#endif
			}
		]]
	}
	
	MainCode PixelPdxMeshAlphaBlendShadow
	{
		Input = "VS_OUTPUT_PDXMESHSHADOWSTANDARD"
		Output = "void"
		Code 
		[[
			PDX_MAIN
			{
				float Alpha = PdxTex2D( PDXMESH_AlphaBlendShadowMap, Input.UV_InstanceIndex.xy ).a;
			#ifdef PDXMESH_USE_DITHERED_OPACITY
				float Opacity = PdxMeshGetOpacity( uint( Input.UV_InstanceIndex.z ) );
				PdxMeshApplyDitheredOpacity( Opacity, Input.Position.xy );
			#endif
				clip( Alpha - 0.5 );
			}
		]]
	}
	
	MainCode PixelDebugNormal
	{
		Input = "VS_OUTPUT_DEBUGNORMAL"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float4 vColor = float4( 1.0 - Input.Offset, Input.Offset, 0.0,  1.0 );
				return vColor;
			}
		]]
	}
}
