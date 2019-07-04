Includes = {
	"cw/lighting_constants.fxh"
}

PixelShader =
{
	Code
	[[
		struct PointLight
		{
			float3 _Position;
			float _Radius;
			float3 _Color;
			float _Falloff;
		};
		struct SpotLight
		{
			PointLight	_PointLight;
			float3		_ConeDirection;
			float		_ConeInnerCosAngle;
			float		_ConeOuterCosAngle;
		};

		PointLight GetPointLight( float4 PositionAndRadius, float4 ColorAndFalloff )
		{
			PointLight pointLight;
			pointLight._Position = PositionAndRadius.xyz;
			pointLight._Radius = PositionAndRadius.w;
			pointLight._Color = ColorAndFalloff.xyz;
			pointLight._Falloff = ColorAndFalloff.w;
			return pointLight;
		}
		
		SpotLight GetSpotLight( float4 PositionAndRadius, float4 ColorAndFalloff, float3 Direction, float InnerCosAngle, float OuterCosAngle )
		{
			SpotLight Ret;
			Ret._PointLight = GetPointLight( PositionAndRadius, ColorAndFalloff );
			Ret._ConeDirection = Direction;
			Ret._ConeInnerCosAngle = InnerCosAngle;
			Ret._ConeOuterCosAngle = OuterCosAngle;
			return Ret;
		}

		float CalcLightFalloff( float LightRadius, float Distance, float Falloff )
		{
			// TODO other, square, falloff?
			return saturate( (LightRadius - Distance) / Falloff );
		}
		
		
		float3 MetalnessToDiffuse( float Metalness, float3 Diffuse )
		{
			return lerp( Diffuse, vec3(0.0), Metalness );
		}

		float3 MetalnessToSpec( float Metalness, float3 Diffuse, float Spec )
		{
			return lerp( vec3(Spec), Diffuse, Metalness );
		}
		
		
		//#ifndef PDX_NewLightingModel
		
		
		#ifndef PDX_GlossScale
			#define PDX_GlossScale 11.0
		#endif
		#ifndef PDX_GlossBias
			#define PDX_GlossBias 0.0
		#endif
		
		// Should match max mip level of the environment cubemap used
		#ifndef PDX_MaxMipLevel
			#define PDX_MaxMipLevel 8.0
		#endif
		
		struct LightingProperties
		{
			float3 _WorldSpacePos;
			float3 _ToCameraDir;
			float3 _Normal;
			float3 _Diffuse;

			float3 _SpecularColor;
			float _Glossiness;
			float _NonLinearGlossiness;
		};
		
		
		// Direct lighting
		float3 FresnelSchlick(float3 SpecularColor, float3 E, float3 H)
		{
			return SpecularColor + (vec3(1.0f) - SpecularColor) * pow(1.0 - saturate(dot(E, H)), 5.0);
		}

		// Indirect lighting
		float3 FresnelGlossy(float3 SpecularColor, float3 E, float3 N, float Smoothness)
		{
			return SpecularColor + (max(vec3(Smoothness), SpecularColor) - SpecularColor) * pow(1.0 - saturate(dot(E, N)), 5.0);
		}
		
		float RoughnessToGloss( float Roughness )
		{
			return pow( 1.0 - Roughness, 1.5 );
		}
		
		float GetNonLinearGlossiness(float aGlossiness)
		{
			return exp2( PDX_GlossScale * aGlossiness + PDX_GlossBias );
		}

		float GetEnvmapMipLevel(float aGlossiness)
		{
			return (1.0 - aGlossiness) * (PDX_MaxMipLevel);
		}

		float3 AmbientLight( float3 WorldNormal, float3 AmbientColors[6] )
		{
			// add more of bottom ambient below objects
			WorldNormal = normalize(WorldNormal - smoothstep(-0.6, 0.5, dot(WorldNormal, float3(0, -1, 0))) * float3(0, 0.9, 0));

			float3 Squared = WorldNormal * WorldNormal;
			int3 isNegative = int3(lessThan(WorldNormal, vec3(0.0)));
			float3 Color = Squared.x * AmbientColors[isNegative.x] + Squared.y * AmbientColors[isNegative.y+2] + Squared.z * AmbientColors[isNegative.z+4];

			return Color;
		}
		
		float3 ComposeLight( LightingProperties Properties, float3 AmbientLight, float3 DiffuseLight, float3 SpecularLight )
		{
			float3 diffuse = ((AmbientLight + DiffuseLight) * Properties._Diffuse);
			float3 specular = SpecularLight;
			
			return diffuse + specular;
		}
		
		
		//------------------------------
		// Blinn-Phong -----------------
		//------------------------------
		void ImprovedBlinnPhong(float3 aLightColor, float3 aToLightDir, LightingProperties aProperties, out float3 aDiffuseLightOut, out float3 aSpecularLightOut)
		{
			float3 H = normalize(aProperties._ToCameraDir + aToLightDir);
			float NdotL = saturate(dot(aProperties._Normal, aToLightDir));
			float NdotH = saturate(dot(aProperties._Normal, H));

			float normalization = (aProperties._NonLinearGlossiness + 2.0) / 8.0;
			float3 specColor = normalization * pow(NdotH, aProperties._NonLinearGlossiness) * FresnelSchlick(aProperties._SpecularColor, aToLightDir, H);

			aDiffuseLightOut = aLightColor * NdotL;
			aSpecularLightOut = specColor * aLightColor * NdotL;
		}
		
		void ImprovedBlinnPhongPointLight(PointLight aPointlight, LightingProperties aProperties, inout float3 aDiffuseLightOut, inout float3 aSpecularLightOut)
		{
			float3 PosToLight = aPointlight._Position - aProperties._WorldSpacePos;
			float LightDistance = length(PosToLight);

			float LightIntensity = CalcLightFalloff( aPointlight._Radius, LightDistance, aPointlight._Falloff );
			if (LightIntensity > 0)
			{
				float3 ToLightDir = PosToLight / LightDistance;
				float3 DiffLight;
				float3 SpecLight;
				ImprovedBlinnPhong(aPointlight._Color * LightIntensity, ToLightDir, aProperties, DiffLight, SpecLight);
				aDiffuseLightOut += DiffLight;
				aSpecularLightOut += SpecLight;
			}
		}
		void ImprovedBlinnPhongSpotLight( SpotLight Spot, LightingProperties Properties, inout float3 DiffuseLightOut, inout float3 SpecularLightOut )
		{
			float3 	PosToLight = Spot._PointLight._Position - Properties._WorldSpacePos;
			float 	DistanceToLight = length(PosToLight);
			float3 	PosToLightDir = PosToLight / DistanceToLight;
			
			float LightIntensity = CalcLightFalloff( Spot._PointLight._Radius, DistanceToLight, Spot._PointLight._Falloff );
			float PdotL = dot( -PosToLightDir, Spot._ConeDirection );
			LightIntensity *= smoothstep( Spot._ConeOuterCosAngle, Spot._ConeInnerCosAngle, PdotL );
			if( LightIntensity > 0 )
			{
				float3 DiffuseLight, SpecularLight;
				ImprovedBlinnPhong( Spot._PointLight._Color * LightIntensity, PosToLightDir, Properties, DiffuseLight, SpecularLight );
				DiffuseLightOut += DiffuseLight;
				SpecularLightOut += SpecularLight;
			}
		}
		
		
		//#else // PDX_NewLightingModel
		
		
		#ifndef PDX_NumMips
			#define PDX_NumMips 10.0
		#endif
		
		#ifndef PDX_MipOffset
			#define PDX_MipOffset 2.0
		#endif
		
		#define PDX_SimpleLighting
		
		
		struct SMaterialProperties
		{
			float 	_PerceptualRoughness;
			float 	_Roughness;
			float	_Metalness;
			
			float3	_DiffuseColor;
			float3	_SpecularColor;
			float3	_Normal;
		};
		
		struct SLightingProperties
		{
			float3	_ToCameraDir;
			float3	_ToLightDir;
			float3	_LightIntensity;
			float	_ShadowTerm;
			float	_CubemapIntensity;
		};
		
		float RemapSpec( float SampledSpec )
		{
			return 0.25 * SampledSpec;
		}
			
		float RoughnessFromPerceptualRoughness( float PerceptualRoughness )
		{
			return PerceptualRoughness * PerceptualRoughness;
		}
		
		float BurleyToMipSimple( float PerceptualRoughness )
		{
		   float Scale = PerceptualRoughness * (1.7 - 0.7 * PerceptualRoughness);
		   return Scale * ( PDX_NumMips - 1 - PDX_MipOffset );
		}
		
		float3 GetSpecularDominantDir( float3 Normal, float3 Reflection, float Roughness )
		{
			float Smoothness = saturate( 1.0 - Roughness );
			float LerpFactor = Smoothness * ( sqrt( Smoothness ) + Roughness );
			return normalize( lerp( Normal, Reflection, LerpFactor ) );
		}
		
		float GetReductionInMicrofacets( float Roughness )
		{
			return 1.0 / (Roughness*Roughness + 1.0);
		}
		
		float F_Schlick( float f0, float f90, float CosAngle )
		{
			return f0 + ( f90 - f0 ) * pow( 1.0 - CosAngle, 5.0 );
		}
		
		float3 F_Schlick( float3 f0, float3 f90, float CosAngle )
		{
			return f0 + ( f90 - f0 ) * pow( 1.0 - CosAngle, 5.0 );
		}
        
		
		float DisneyDiffuse( float NdotV, float NdotL, float LdotH, float LinearRoughness )
		{
			float EnergyBias = lerp( 0.0, 0.5, LinearRoughness );
			float EnergyFactor = lerp( 1.0, 1.0 / 1.51, LinearRoughness );
			float f90 = EnergyBias + 2.0 * LdotH * LdotH * LinearRoughness;
			float LightScatter = F_Schlick( 1.0, f90, NdotL );
			float ViewScatter = F_Schlick( 1.0, f90, NdotV );
			
			return LightScatter * ViewScatter * EnergyFactor;
		}
		
		float CalcDiffuseBRDF( float NdotV, float NdotL, float LdotH, float PerceptualRoughness )
		{
		#ifdef PDX_SimpleLighting
			return 1.0 / PI;
		#else
			return DisneyDiffuse( NdotV, NdotL, LdotH, PerceptualRoughness ) / PI;
		#endif
		}
		
		
		float D_GGX( float NdotH, float Alpha )
		{
			float Alpha2 = Alpha * Alpha;
			float f = ( NdotH * Alpha2 - NdotH ) * NdotH + 1.0;
			return Alpha2 / (PI * f * f);
		}
		
		float G1( float CosAngle, float k )
		{
			return 1.0 / ( CosAngle * ( 1.0 - k ) + k );
		}
		
		float V_Schlick( float NdotL, float NdotV, float Alpha )
		{
			float k = Alpha * 0.5;
			return G1( NdotL, k ) * G1( NdotV, k ) * 0.25;
		}
		
		float V_Optimized( float LdotH, float Alpha )
		{
			float k = Alpha * 0.5;
			float k2 = k*k;
			float invk2 = 1.0 - k2;
			return 0.25 / ( LdotH * LdotH * invk2 + k2 );
		}
        
		float3 CalcSpecularBRDF( float3 SpecularColor, float LdotH, float NdotH, float NdotL, float NdotV, float Roughness )
		{
			float3 F = F_Schlick( SpecularColor, vec3(1.0), LdotH );
			float D = D_GGX( NdotH, lerp( 0.03, 1.0, Roughness ) ); // Remap to avoid super small and super bright highlights
		#ifdef PDX_SimpleLighting
			float Vis = V_Optimized( LdotH, Roughness );
		#else
			float Vis = V_Schlick( NdotL, NdotV, Roughness );
		#endif
			return D * F * Vis;
		}

		
		void CalculateLightingFromLight( SMaterialProperties MaterialProps, SLightingProperties LightingProps, out float3 DiffuseOut, out float3 SpecularOut )
		{
			float3 H = normalize( LightingProps._ToCameraDir + LightingProps._ToLightDir );
			float NdotV = saturate( dot( MaterialProps._Normal, LightingProps._ToCameraDir ) ) + 1e-5;
			float NdotL = saturate( dot( MaterialProps._Normal, LightingProps._ToLightDir ) ) + 1e-5;
			float NdotH = saturate( dot( MaterialProps._Normal, H ) );
			float LdotH = saturate( dot( LightingProps._ToLightDir, H ) );
			
			float3 LightIntensity = LightingProps._LightIntensity * NdotL * LightingProps._ShadowTerm;
			
			float DiffuseBRDF = CalcDiffuseBRDF( NdotV, NdotL, LdotH, MaterialProps._PerceptualRoughness );
			DiffuseOut = DiffuseBRDF * MaterialProps._DiffuseColor * LightIntensity;
			
			float3 SpecularBRDF = CalcSpecularBRDF( MaterialProps._SpecularColor, LdotH, NdotH, NdotL, NdotV, MaterialProps._Roughness );
			SpecularOut = SpecularBRDF * LightIntensity;
		}
	
		void CalculateLightingFromIBL( SMaterialProperties MaterialProps, SLightingProperties LightingProps, PdxTextureSamplerCube EnvironmentMap, out float3 DiffuseIBLOut, out float3 SpecularIBLOut )
		{
			float3 DiffuseRad = PdxTexCubeLod( EnvironmentMap, MaterialProps._Normal, ( PDX_NumMips - 1 - PDX_MipOffset ) ).rgb * LightingProps._CubemapIntensity; // TODO, maybe we should split diffuse and spec intensity?
			DiffuseIBLOut = DiffuseRad * MaterialProps._DiffuseColor;
			
			float3 ReflectionVector = reflect( -LightingProps._ToCameraDir, MaterialProps._Normal );
			float3 DominantReflectionVector = GetSpecularDominantDir( MaterialProps._Normal, ReflectionVector, MaterialProps._Roughness );

			float NdotR = saturate( dot( MaterialProps._Normal, DominantReflectionVector ) );
			float3 SpecularReflection = F_Schlick( MaterialProps._SpecularColor, vec3(1.0), NdotR );
			float SpecularFade = GetReductionInMicrofacets( MaterialProps._Roughness );

			float MipLevel = BurleyToMipSimple( MaterialProps._PerceptualRoughness );
			float3 SpecularRad = PdxTexCubeLod( EnvironmentMap, DominantReflectionVector, MipLevel ).rgb * LightingProps._CubemapIntensity; // TODO, maybe we should split diffuse and spec intensity?
			SpecularIBLOut = SpecularRad * SpecularFade * SpecularReflection;
		}
		
		//#endif // PDX_NewLightingModel
	]]
}
