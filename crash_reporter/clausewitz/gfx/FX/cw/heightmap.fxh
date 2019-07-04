ConstantBuffer( PdxHeightmapConstants )
{
	float4		TileToHeightMapScaleAndOffset[PDX_MAX_HEIGHTMAP_COMPRESS_LEVELS];
	float2		WorldSpaceToLookup;
	float2		OriginalHeightmapToWorldSpace;
	float2		IndirectionSize;
	float2		PackedHeightMapSize;
	float 		BaseTileSize;
	
	float		HeightScale;
}

TextureSampler HeightLookupTexture
{
	Ref = PdxHeightmap0
	MagFilter = "Point"
	MinFilter = "Point"
	MipFilter = "Point"
	SampleModeU = "Clamp"
	SampleModeV = "Clamp"
}	
TextureSampler PackedHeightTexture
{
	Ref = PdxHeightmap1
	MagFilter = "Linear"
	MinFilter = "Linear"
	MipFilter = "Linear"
	SampleModeU = "Clamp"
	SampleModeV = "Clamp"
}

Code
[[
	float2 GetLookupCoordinates( float2 WorldSpacePosXZ )
	{
		return clamp( WorldSpacePosXZ * WorldSpaceToLookup, vec2( 0.0 ), vec2( 0.999999 ) );
	}
	
	float4 SampleLookupTexture( float2 LookupCoordinates )
	{
		float4 IndirectionSample = PdxTex2DLod0( HeightLookupTexture, ( floor( LookupCoordinates * IndirectionSize ) + vec2( 0.5 ) ) / IndirectionSize ) * 255.0;
		return IndirectionSample;
	}
	
	float2 GetTileUV( float2 LookupCoordinates, float4 IndirectionSample, out float CurrentTileScale )
	{
		float CurrentTileSize = (BaseTileSize - 1.0) / IndirectionSample.z + 1;
		float CurrentTileOffset = 0.5 / CurrentTileSize;
		CurrentTileScale = (CurrentTileSize - 1.0) / CurrentTileSize;
		
		float2 WithinTileZeroToOne = frac( LookupCoordinates * IndirectionSize );
		float2 WithinTileUV = vec2( CurrentTileOffset ) + WithinTileZeroToOne * CurrentTileScale;
		float2 TileUV = IndirectionSample.rg + WithinTileUV;
		
		return TileUV;
	}
	
	float2 GetHeightMapCoordinates( float2 WorldSpacePosXZ )
	{
		float2 LookupCoordinates = GetLookupCoordinates( WorldSpacePosXZ );
		float4 IndirectionSample = SampleLookupTexture( LookupCoordinates );

		float4 CurrentTileToHeightMapScaleAndOffset = TileToHeightMapScaleAndOffset[int(IndirectionSample.w)];
		float CurrentTileScale;
		float2 TileUV = GetTileUV( LookupCoordinates, IndirectionSample, CurrentTileScale );
		
		float2 HeightMapCoord = TileUV * CurrentTileToHeightMapScaleAndOffset.xy + CurrentTileToHeightMapScaleAndOffset.zw; // 0 -> 1 in packed heightmap
		return HeightMapCoord;
	}
	
	float GetHeight01( float2 WorldSpacePosXZ )
	{
		float2 HeightMapCoord = GetHeightMapCoordinates( WorldSpacePosXZ );
		return PdxTex2DLod0( PackedHeightTexture, HeightMapCoord ).r;
	}
	
	float GetHeight( float2 WorldSpacePosXZ )
	{
		return GetHeight01( WorldSpacePosXZ ) * HeightScale;
	}
	
	
	float GetHeightMultisample01( float2 WorldSpacePosXZ, float FilterSize )
	{
		//return GetHeight( WorldSpacePosXZ );

		float2 LookupCoordinates = GetLookupCoordinates( WorldSpacePosXZ );
		float2 FilterSizeInWorldSpace = FilterSize * OriginalHeightmapToWorldSpace;
		float2 FilterSizeInLookup = FilterSizeInWorldSpace * WorldSpaceToLookup * IndirectionSize;
		
		float2 FracCoordinates = frac( LookupCoordinates * IndirectionSize );
		float2 MinFracCoordinatesScaled = min( FracCoordinates, vec2(1.0) - FracCoordinates );
		bool2 InBorder = lessThan( MinFracCoordinatesScaled, FilterSizeInLookup );

		float Height = 0.0;
		if ( any( InBorder ) )
		{
			Height = GetHeight01( WorldSpacePosXZ );
			Height += GetHeight01( WorldSpacePosXZ + float2( -FilterSizeInWorldSpace.x, 0 ) );
			Height += GetHeight01( WorldSpacePosXZ + float2( 0, -FilterSizeInWorldSpace.y ) );
			Height += GetHeight01( WorldSpacePosXZ + float2( FilterSizeInWorldSpace.x, 0 ) );
			Height += GetHeight01( WorldSpacePosXZ + float2( 0, FilterSizeInWorldSpace.y ) );
			Height += GetHeight01( WorldSpacePosXZ + float2( -FilterSizeInWorldSpace.x, -FilterSizeInWorldSpace.y ) );
			Height += GetHeight01( WorldSpacePosXZ + float2(  FilterSizeInWorldSpace.x, -FilterSizeInWorldSpace.y ) );
			Height += GetHeight01( WorldSpacePosXZ + float2(  FilterSizeInWorldSpace.x,  FilterSizeInWorldSpace.y ) );
			Height += GetHeight01( WorldSpacePosXZ + float2( -FilterSizeInWorldSpace.x,  FilterSizeInWorldSpace.y ) );
		}
		else
		{
			float4 IndirectionSample = SampleLookupTexture( LookupCoordinates );
			
			float4 CurrentTileToHeightMapScaleAndOffset = TileToHeightMapScaleAndOffset[int(IndirectionSample.w)];
			float CurrentTileScale;
			float2 TileUV = GetTileUV( LookupCoordinates, IndirectionSample, CurrentTileScale );
			
			float2 HeightMapCoord = TileUV * CurrentTileToHeightMapScaleAndOffset.xy + CurrentTileToHeightMapScaleAndOffset.zw; // 0 -> 1 in packed heightmap
			float2 FilterSizeInTile = FilterSizeInLookup * CurrentTileToHeightMapScaleAndOffset.xy * CurrentTileScale;
			
			Height = PdxTex2DLod0( PackedHeightTexture, HeightMapCoord ).r;
			Height += PdxTex2DLod0( PackedHeightTexture, HeightMapCoord + float2( -FilterSizeInTile.x, 0 ) ).r;
			Height += PdxTex2DLod0( PackedHeightTexture, HeightMapCoord + float2( 0, -FilterSizeInTile.y ) ).r;
			Height += PdxTex2DLod0( PackedHeightTexture, HeightMapCoord + float2( FilterSizeInTile.x, 0 ) ).r;
			Height += PdxTex2DLod0( PackedHeightTexture, HeightMapCoord + float2( 0, FilterSizeInTile.y ) ).r;
			Height += PdxTex2DLod0( PackedHeightTexture, HeightMapCoord + float2( -FilterSizeInTile.x, -FilterSizeInTile.y ) ).r;
			Height += PdxTex2DLod0( PackedHeightTexture, HeightMapCoord + float2(  FilterSizeInTile.x, -FilterSizeInTile.y ) ).r;
			Height += PdxTex2DLod0( PackedHeightTexture, HeightMapCoord + float2(  FilterSizeInTile.x,  FilterSizeInTile.y ) ).r;
			Height += PdxTex2DLod0( PackedHeightTexture, HeightMapCoord + float2( -FilterSizeInTile.x,  FilterSizeInTile.y ) ).r;
		}
		
		Height /= 9.0;
		return Height;
	}
	
	float GetHeightMultisample( float2 WorldSpacePosXZ, float FilterSize )
	{
		return GetHeightMultisample01( WorldSpacePosXZ, FilterSize ) * HeightScale;
	}
	
	
	// SAVE
	static const float c_x0 = -1.0;
	static const float c_x1 =  0.0;
	static const float c_x2 =  1.0;
	static const float c_x3 =  2.0;
    
	//=======================================================================================
	float CubicLagrange(float A, float B, float C, float D, float t)
	{
		return
			A * 
			(
				(t - c_x1) / (c_x0 - c_x1) * 
				(t - c_x2) / (c_x0 - c_x2) *
				(t - c_x3) / (c_x0 - c_x3)
			) +
			B * 
			(
				(t - c_x0) / (c_x1 - c_x0) * 
				(t - c_x2) / (c_x1 - c_x2) *
				(t - c_x3) / (c_x1 - c_x3)
			) +
			C * 
			(
				(t - c_x0) / (c_x2 - c_x0) * 
				(t - c_x1) / (c_x2 - c_x1) *
				(t - c_x3) / (c_x2 - c_x3)
			) +       
			D * 
			(
				(t - c_x0) / (c_x3 - c_x0) * 
				(t - c_x1) / (c_x3 - c_x1) *
				(t - c_x2) / (c_x3 - c_x2)
			);
	}
    
	//=======================================================================================
	float BicubicLagrangeBilinearGetHeight01( float2 WorldSpacePosXZ )
	{
		float2 Pixel = WorldSpacePosXZ - 0.5;
	
		float2 FracCoord = frac(Pixel);
		Pixel = floor(Pixel) + 0.5;
		
		float C00 = GetHeight01( float2( Pixel.x - 1, Pixel.y - 1 ) );
		float C10 = GetHeight01( float2( Pixel.x - 0, Pixel.y - 1 ) );
		float C20 = GetHeight01( float2( Pixel.x + 1, Pixel.y - 1 ) );
		float C30 = GetHeight01( float2( Pixel.x + 2, Pixel.y - 1 ) );
		
		float C01 = GetHeight01( float2( Pixel.x - 1, Pixel.y - 0 ) );
		float C11 = GetHeight01( float2( Pixel.x - 0, Pixel.y - 0 ) );
		float C21 = GetHeight01( float2( Pixel.x + 1, Pixel.y - 0 ) );
		float C31 = GetHeight01( float2( Pixel.x + 2, Pixel.y - 0 ) );
		
		float C02 = GetHeight01( float2( Pixel.x - 1, Pixel.y + 1 ) );
		float C12 = GetHeight01( float2( Pixel.x - 0, Pixel.y + 1 ) );
		float C22 = GetHeight01( float2( Pixel.x + 1, Pixel.y + 1 ) );
		float C32 = GetHeight01( float2( Pixel.x + 2, Pixel.y + 1 ) );
		
		float C03 = GetHeight01( float2( Pixel.x - 1, Pixel.y + 2 ) );
		float C13 = GetHeight01( float2( Pixel.x - 0, Pixel.y + 2 ) );
		float C23 = GetHeight01( float2( Pixel.x + 1, Pixel.y + 2 ) );
		float C33 = GetHeight01( float2( Pixel.x + 2, Pixel.y + 2 ) );
		
		float CP0X = CubicLagrange(C00, C10, C20, C30, FracCoord.x);
		float CP1X = CubicLagrange(C01, C11, C21, C31, FracCoord.x);
		float CP2X = CubicLagrange(C02, C12, C22, C32, FracCoord.x);
		float CP3X = CubicLagrange(C03, C13, C23, C33, FracCoord.x);
		
		return CubicLagrange(CP0X, CP1X, CP2X, CP3X, FracCoord.y);
	}
	
	//float BilinearGetHeight( float3 WorldSpacePos )
	//{
	//	float2 Pixel = WorldSpacePos.xz;
	//	
	//	float2 FracCoord = frac(Pixel);
	//	Pixel = floor(Pixel);
	//	
	//	float H11 = GetHeight01( float3( Pixel.x, 0.0, Pixel.y ) );
	//	float H21 = GetHeight01( float3( Pixel.x + 1.0, 0.0, Pixel.y ) );
	//	float H12 = GetHeight01( float3( Pixel.x, 0.0, Pixel.y + 1.0 ) );
	//	float H22 = GetHeight01( float3( Pixel.x + 1.0, 0.0, Pixel.y + 1.0 ) );
	//	
	//	//return H11;
	//	//return FracCoord.x;
	//	
	//	float h1 = lerp( H11, H21, FracCoord.x );
	//	float h2 = lerp( H12, H22, FracCoord.x );
	//	return lerp( h1, h2, FracCoord.y );
	//}
]]