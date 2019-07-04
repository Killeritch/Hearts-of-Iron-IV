Includes = {
	"cw/lighting.fxh"
	"cw/camera.fxh"
}

PixelShader =
{
	Code
	[[
		LightingProperties GetLightingProperties( float3 WorldSpacePos, float3 Diffuse, float3 Normal, float4 Material )
		{
			float3 ToCameraDir = normalize( CameraPosition - WorldSpacePos );
			
			LightingProperties lightingProperties;
			lightingProperties._WorldSpacePos = WorldSpacePos;
			lightingProperties._ToCameraDir = ToCameraDir;
			lightingProperties._Normal = Normal;
			
		#ifdef PDX_NewLighting
			float SpecRemapped = ToLinear( Material.g ) * 0.4;
			float Metalness = Material.b; // Should probably be ToLinear( Material.b );? aka load as sRGB
			float Glossiness = RoughnessToGloss( Material.a );
		#else
			float SpecRemapped = Material.g * Material.g * 0.4;
			float Metalness = 1.0 - (1.0 - Material.b) * (1.0 - Material.b);
			float Glossiness = Material.a;
		#endif
			lightingProperties._Diffuse = MetalnessToDiffuse( Metalness, Diffuse );
			lightingProperties._Glossiness = Glossiness;
			lightingProperties._SpecularColor = MetalnessToSpec( Metalness, Diffuse, SpecRemapped );
			lightingProperties._NonLinearGlossiness = GetNonLinearGlossiness( Glossiness );
			
			return lightingProperties;
		}
		
		SMaterialProperties GetMaterialProperties( float3 SampledDiffuse, float3 Normal, float SampledRoughness, float SampledSpec, float SampledMetalness )
		{
			SMaterialProperties MaterialProps;
			
			MaterialProps._PerceptualRoughness = SampledRoughness;
			MaterialProps._Roughness = RoughnessFromPerceptualRoughness( MaterialProps._PerceptualRoughness );

			float SpecRemapped = RemapSpec( SampledSpec );
			MaterialProps._Metalness = SampledMetalness;

			MaterialProps._DiffuseColor = MetalnessToDiffuse( MaterialProps._Metalness, SampledDiffuse );
			MaterialProps._SpecularColor = MetalnessToSpec( MaterialProps._Metalness, SampledDiffuse, SpecRemapped );
			
			MaterialProps._Normal = Normal;
			
			return MaterialProps;
		}
		
		float3 FresnelGlossy( LightingProperties Properties )
		{
			return FresnelGlossy( Properties._SpecularColor, Properties._ToCameraDir, Properties._Normal, Properties._Glossiness );
		}
		
		float3 GetReflectiveColor( LightingProperties Properties, PdxTextureSamplerCube EnvironmentMap, float EnvironmentMapIntensity )
		{		
			float3 ReflectionVector = reflect( -Properties._ToCameraDir, Properties._Normal );
			float MipmapIndex = GetEnvmapMipLevel( Properties._Glossiness );
			float3 ReflectiveColor = PdxTexCubeLod( EnvironmentMap, ReflectionVector, MipmapIndex ).rgb * EnvironmentMapIntensity;
			return ReflectiveColor * FresnelGlossy( Properties );
		}
		
		void GGXSpotLight( SpotLight Spot, float3 WorldSpacePos, float ShadowTerm, SMaterialProperties MaterialProps, inout float3 DiffuseLightOut, inout float3 SpecularLightOut )
		{
			float3 	PosToLight = Spot._PointLight._Position - WorldSpacePos;
			float 	DistanceToLight = length(PosToLight);
			float3	ToLightDir = PosToLight / DistanceToLight;
			
			float LightIntensity = CalcLightFalloff( Spot._PointLight._Radius, DistanceToLight, Spot._PointLight._Falloff );
			float PdotL = dot( -ToLightDir, Spot._ConeDirection );
			LightIntensity *= smoothstep( Spot._ConeOuterCosAngle, Spot._ConeInnerCosAngle, PdotL );
			if ( LightIntensity > 0.0 )
			{
				SLightingProperties LightingProps;
				LightingProps._ToCameraDir = normalize( CameraPosition - WorldSpacePos );
				LightingProps._ToLightDir = ToLightDir;
				LightingProps._LightIntensity = Spot._PointLight._Color * LightIntensity;
				LightingProps._ShadowTerm = ShadowTerm;
				LightingProps._CubemapIntensity = 0.0;
				
				float3 DiffuseLight;
				float3 SpecularLight;
				CalculateLightingFromLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight );
				DiffuseLightOut += DiffuseLight;
				SpecularLightOut += SpecularLight;
			}
		}
		
		void GGXPointLight( PointLight Pointlight, float3 WorldSpacePos, float ShadowTerm, SMaterialProperties MaterialProps, inout float3 DiffuseLightOut, inout float3 SpecularLightOut )
		{
			float3 PosToLight = Pointlight._Position - WorldSpacePos;
			float DistanceToLight = length( PosToLight );

			float LightIntensity = CalcLightFalloff( Pointlight._Radius, DistanceToLight, Pointlight._Falloff );
			if ( LightIntensity > 0.0 )
			{
				SLightingProperties LightingProps;
				LightingProps._ToCameraDir = normalize( CameraPosition - WorldSpacePos );
				LightingProps._ToLightDir = PosToLight / DistanceToLight;
				LightingProps._LightIntensity = Pointlight._Color * LightIntensity;
				LightingProps._ShadowTerm = ShadowTerm;
				LightingProps._CubemapIntensity = 0.0;
				
				float3 DiffuseLight;
				float3 SpecularLight;
				CalculateLightingFromLight( MaterialProps, LightingProps, DiffuseLight, SpecularLight );
				DiffuseLightOut += DiffuseLight;
				SpecularLightOut += SpecularLight;
			}
		}
		
	]]
}