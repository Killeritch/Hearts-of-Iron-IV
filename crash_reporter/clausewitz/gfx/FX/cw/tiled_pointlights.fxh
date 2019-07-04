Includes = {
	"cw/lighting.fxh"
}

PixelShader =
{
	ConstantBuffer( JominiTiledLight )
	{
		float4 GridStart_InvCellSize;
	}

	Code
	[[
		static const float2 INV_LIGHT_INDEX_TEXTURE_SIZE = float2(1.0 / 64.0, 1.0 / 64.0);
		static const float INV_LIGHT_DATA_TEXTURE_SIZE = float(1.0 / 128.0);

		float2 GetLightIndexUV(float3 WorldSpacePos)
		{
			float2 XZ = WorldSpacePos.xz;
			XZ -= GridStart_InvCellSize.xy;

			float2 cellIndex = XZ * GridStart_InvCellSize.zw;
			return cellIndex * INV_LIGHT_INDEX_TEXTURE_SIZE;
		}

		void CalculatePointLights(LightingProperties aProperties, in PdxTextureSampler2D LightData, in PdxTextureSampler2D LightIndexMap, inout float3 aDiffuseLightOut, inout float3 aSpecularLightOut)
		{
			float2 LightIndexUV = GetLightIndexUV(aProperties._WorldSpacePos);
			float4 LightIndices = PdxTex2DLod0(LightIndexMap, LightIndexUV);

			for (int i = 0; i < 4; ++i)
			{
				float LightIndex = LightIndices[i] * 255.0;
				if (LightIndex >= 255.0)
					break;

				float4 LightData1 = PdxTex2DLod0(LightData, float2((LightIndex * 2 + 0.5) * INV_LIGHT_DATA_TEXTURE_SIZE, 0));
				float4 LightData2 = PdxTex2DLod0(LightData, float2((LightIndex * 2 + 1.5) * INV_LIGHT_DATA_TEXTURE_SIZE, 0));
				PointLight pointlight = GetPointLight(LightData1, LightData2);

				ImprovedBlinnPhongPointLight(pointlight, aProperties, aDiffuseLightOut, aSpecularLightOut);
			}
		}

		/*
		float2 LightIndexUV = GetLightIndexUV(lightingProperties._WorldSpacePos);
		if (LightIndexUV.x < 0 || LightIndexUV.x > 1 || LightIndexUV.y < 0 || LightIndexUV.y > 1)
			vColor = float3(1, 0, 0);
		else
			vColor = float3(0, 1, 0);
		vColor = PdxTex2D(LightIndexMap, LightIndexUV).rgb; // 0 = b, 1 = g, 2 = r, 3 = a
		*/
	]]
}
