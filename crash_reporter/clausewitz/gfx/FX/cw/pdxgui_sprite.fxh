Includes = {
	"cw/utility.fxh"
}

PixelShader =
{
	ConstantBuffer( PdxGuiSpriteConstants )
	{
		float4 SpriteTextureAndFrameUVSize[PDX_GUI_MAX_NUM_SPRITES];
		float4 SpriteBorder[PDX_GUI_MAX_NUM_SPRITES];
		float4 SpriteTranslateRotateUVAndAlpha[PDX_GUI_MAX_NUM_SPRITES];
		float4 SpriteSize;
		float4 SpriteFrameBlendAlpha;
		int4   SpriteFramesTypeBlendMode[PDX_GUI_MAX_NUM_SPRITES];
		int4   SpriteFrameAndGridSize[PDX_GUI_MAX_NUM_SPRITES];
		int    NumSprites;
	};

	TextureSampler ModifyTexture1
	{
		Ref = PdxTexture1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler ModifyTexture2
	{
		Ref = PdxTexture2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler ModifyTexture3
	{
		Ref = PdxTexture3
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}

	Code
	[[
		float CalcBorderUV( float UV, float UVEdge, float UVScale )
		{
			float Offset = UV - UVEdge;
			Offset *= UVScale;
			return Offset + UVEdge;
			
			// Could be just multiply and add?
			//return UV * UVScale + UVEdge - UVEdge * UVScale; // 'UVEdge - UVEdge * UVScale' constant
		}
		
		float CalcInternalUV( float UV, float UVCutoff, float UVTileFactor, float UVScale, float UVOffset )
		{
			float Offset = UV - UVCutoff;
			Offset *= UVTileFactor;
			Offset = mod( Offset, 1.0 );
			Offset *= UVScale;
			return Offset + UVOffset;
		}
		
		float4 SampleSpriteTexture(
			in PdxTextureSampler2D SpriteTexture,
			float2 uv,
			float4 UVRect,
			float2 BorderUVScale,
			float4 BorderUVCutoff,
			float2 MiddleUVTileFactor,
			float2 MiddleUVScale,
			float2 MiddleUVOffset,
			float2 TranslateUV,
			float RotateUV,
			float2 Dimension )
		{
#ifdef PDX_GUI_SPRITE_EFFECT
			uv = lerp( UVRect.xy, UVRect.zw, uv );

			float2 texDdx = ddx(uv * BorderUVScale);
			float2 texDdy = ddy(uv * BorderUVScale);

			if ( uv.x <= BorderUVCutoff.x )
			{
				uv.x = CalcBorderUV( uv.x, UVRect.x, BorderUVScale.x );
			}
			else if ( uv.x >= BorderUVCutoff.z )
			{
				uv.x = CalcBorderUV( uv.x, UVRect.z, BorderUVScale.x );
			}
			else
			{
				uv.x = CalcInternalUV( uv.x, BorderUVCutoff.x, MiddleUVTileFactor.x, MiddleUVScale.x, MiddleUVOffset.x );
			}
			
			if ( uv.y <= BorderUVCutoff.y )
			{
				uv.y = CalcBorderUV( uv.y, UVRect.y, BorderUVScale.y );
			}
			else if ( uv.y >= BorderUVCutoff.w )
			{
				uv.y = CalcBorderUV( uv.y, UVRect.w, BorderUVScale.y );
			}
			else
			{
				uv.y = CalcInternalUV( uv.y, BorderUVCutoff.y, MiddleUVTileFactor.y, MiddleUVScale.y, MiddleUVOffset.y );
			}

			uv += TranslateUV;

			{
				float s = sin( RotateUV );
				float c = cos( RotateUV );

				uv.x = uv.x * Dimension.x - Dimension.x * 0.5;
				uv.y = uv.y * Dimension.y - Dimension.y * 0.5;

				float UVx = uv.x;
				float UVy = uv.y;

				uv.x = UVx * c - UVy * s;
				uv.y = UVy * c + UVx * s;

				uv.x = uv.x / Dimension.x + 0.5;
				uv.y = uv.y / Dimension.y + 0.5;
			}

			return PdxTex2DGrad( SpriteTexture, uv, texDdx, texDdy );
#else
			return PdxTex2DLod0( SpriteTexture, uv );
#endif
		}

		float4 CalcSpriteUV( int Index, int Frame )
		{
			int2 FrameSize     = SpriteFrameAndGridSize[Index].xy;
			float2 TextureSize = SpriteTextureAndFrameUVSize[Index].xy;

			if ( FrameSize.x <= 0 || FrameSize.y <= 0 )
				return float4( 0.0, 0.0, 1.0, 1.0 );

			int2 GridSize = SpriteFrameAndGridSize[Index].zw;
			if ( GridSize.x <= 0 || GridSize.y <= 0 )
				return float4( 0.0, 0.0, 1.0, 1.0 );

			int2 GridPos;
			GridPos.y = min( Frame / GridSize.x, GridSize.y - 1 );
			GridPos.x = min( Frame - GridPos.y * GridSize.x, GridSize.x - 1 );

			float2 FrameUVSize = SpriteTextureAndFrameUVSize[Index].zw;

			float4 UVRect;
			UVRect.xy = GridPos * FrameUVSize;
			UVRect.zw = FrameUVSize;

			return UVRect;
		}

		float4 SampleSpriteTexture( 
			in PdxTextureSampler2D SpriteTexture, 
			float2 UV, 
			int Index, 
			int Frame, 
			int Type )
		{
			float4 UVRect             = float4( 0.0, 0.0, 1.0, 1.0 );
			float4 BorderUVRect       = float4( 0.0, 0.0, 1.0, 1.0 );
			float2 BorderUVScale      = float2( 1.0, 1.0 );
			float2 MiddleUVScale      = float2( 1.0, 1.0 );
			float2 MiddleUVOffset     = float2( 0.0, 0.0 );
			float2 MiddleUVTileFactor = float2( 1.0, 1.0 );
			float4 BorderSize         = float4( 0.0, 0.0, 0.0, 0.0 );
			float4 BorderUV           = float4( 0.0, 0.0, 0.0, 0.0 );
			float4 BorderUVCutoff     = float4( 0.0, 0.0, 1.0, 1.0 );

#ifdef PDX_GUI_SPRITE_EFFECT
			UVRect = CalcSpriteUV( Index, Frame );
			float2 UVRectSize = UVRect.zw;
			float2 UVRectBR   = UVRect.xy + UVRectSize;
			float2 UVRectTL   = UVRect.xy;

			BorderUVRect = float4( UVRectTL, UVRectBR );

			float2 ImageSize = float2( SpriteFrameAndGridSize[Index].xy );
			if ( SpriteFrameAndGridSize[Index].x <= 0 || SpriteFrameAndGridSize[Index].y <= 0 )
			{
				ImageSize = SpriteTextureAndFrameUVSize[Index].xy;
			}

			if ( Type != 0 )
			{
				BorderUVScale = SpriteSize.xy / ImageSize;
				BorderSize    = SpriteBorder[Index];

				float BorderWidth = BorderSize.x + BorderSize.z;
				if ( BorderWidth > SpriteSize.x )
				{
					float ScaleFactor = SpriteSize.x / BorderWidth;
					BorderSize.x = BorderSize.x * ScaleFactor;
					BorderSize.z = SpriteSize.x - BorderSize.x;
				}

				float BorderHeight = BorderSize.y + BorderSize.w;
				if ( BorderHeight > SpriteSize.y )
				{
					float ScaleFactor = SpriteSize.y / BorderHeight;
					BorderSize.y = BorderSize.y * ScaleFactor;
					BorderSize.w = SpriteSize.y - BorderSize.y;
				}

				BorderUV.xy = ( BorderSize.xy / ImageSize ) * UVRectSize.xy;
				BorderUV.zw = ( BorderSize.zw / ImageSize ) * UVRectSize.xy;

				float2 TextureMiddle = ImageSize - BorderSize.xy - BorderSize.zw;
				if ( Type == 1 && TextureMiddle.x > 0.0 && TextureMiddle.x > 0.0 )
				{
					float2 Middle = SpriteSize.xy - BorderSize.xy - BorderSize.zw;
					MiddleUVScale.xy = Middle / TextureMiddle;
				}
			}

			BorderUVCutoff.xy = UVRectTL + BorderUV.xy / BorderUVScale.xy;
			BorderUVCutoff.zw = UVRectBR - BorderUV.zw / BorderUVScale.xy;

			MiddleUVTileFactor = MiddleUVScale;
			MiddleUVTileFactor.x = MiddleUVTileFactor.x / ( BorderUVCutoff.z - BorderUVCutoff.x );
			MiddleUVTileFactor.y = MiddleUVTileFactor.y / ( BorderUVCutoff.w - BorderUVCutoff.y );

			MiddleUVScale = UVRectSize.xy - BorderUV.xy - BorderUV.zw;
			MiddleUVOffset = UVRect.xy + BorderUV.xy;

#endif // PDX_GUI_SPRITE_EFFECT

			float2 TranslateUV = SpriteTranslateRotateUVAndAlpha[Index].xy;
			float  RotateUV    = SpriteTranslateRotateUVAndAlpha[Index].z;

			return SampleSpriteTexture(
				SpriteTexture,
				UV,
				BorderUVRect,
				BorderUVScale,
				BorderUVCutoff,
				MiddleUVTileFactor,
				MiddleUVScale,
				MiddleUVOffset,
				TranslateUV,
				RotateUV,
				SpriteSize.xy );
		}

		float4 SampleSpriteTexture( in PdxTextureSampler2D SpriteTexture, float2 UV, int Index )
		{
			int Frame0 = SpriteFramesTypeBlendMode[Index].x;
			int Type   = SpriteFramesTypeBlendMode[Index].z;
			float4 Color0 = SampleSpriteTexture( SpriteTexture, UV, Index, Frame0, Type );
#if defined(PDX_GUI_FRAME_BLEND_EFFECT)
			int Frame1 = SpriteFramesTypeBlendMode[Index].y;

			float4 Color1 = SampleSpriteTexture( SpriteTexture, UV, Index, Frame1, Type );
			return lerp( Color0, Color1, SpriteFrameBlendAlpha[Index] );
#else
			return Color0;
#endif
		}

		
		// This needs to be in sync with "CPdxGuiImageSprite::EBlendMode"
		float4 Blend( float4 Base, float4 Blend, float Opacity, inout float BlendMask, int Mode )
		{			
			if ( Mode == 1 ) // Overlay
			{
				return float4( Overlay( Base.rgb, Blend.rgb, Opacity ), Base.a );
			}
			else if ( Mode == 2 ) // Multiply
			{
				return float4( Multiply( Base.rgb, Blend.rgb, Opacity ), Base.a);
			}
			else if ( Mode == 3 ) // ColorDodge
			{
				return float4( ColorDodge( Base.rgb, Blend.rgb, Opacity ), Base.a );
			}
			else if ( Mode == 4 ) // Lighten
			{
				return float4( Lighten( Base.rgb, Blend.rgb, Opacity ), Base.a );
			}
			else if ( Mode == 5 ) // Darken
			{
				return float4( Darken( Base.rgb, Blend.rgb, Opacity ), Base.a );
			}
			else if ( Mode == 6 ) // AlphaMultiply
			{
				return float4( Base.rgb, Base.a * lerp( 1.0, Blend.a, Opacity ) );
			} 
			else if ( Mode == 7 ) // Mask
			{
				BlendMask = Blend.r;
				return Base;
			}
			
			// Mode == 0, Add
			return float4( Add( Base.rgb, Blend.rgb, Opacity ), Base.a );
		}
		
		float4 SampleImageSprite( in PdxTextureSampler2D SpriteTexture, float2 UV )
		{
			float4 Base = SampleSpriteTexture( SpriteTexture, UV, 0 );

#ifdef PDX_GUI_SPRITE_EFFECT
			float4 ModifyTextures[3];

			float BlendMask = 1.0f;

		#if PDX_GUI_MAX_NUM_SPRITES > 4
			NOT CURRENTLY SUPPORTED
		#endif
		#if PDX_GUI_MAX_NUM_SPRITES > 3
			if ( NumSprites > 3 )
			{
				ModifyTextures[2] = SampleSpriteTexture( ModifyTexture3, UV, 3 );
			}
		#endif
		#if PDX_GUI_MAX_NUM_SPRITES > 2
			if ( NumSprites > 2 )
			{
				ModifyTextures[1] = SampleSpriteTexture( ModifyTexture2, UV, 2 );
			}
		#endif
		#if PDX_GUI_MAX_NUM_SPRITES > 1
			if ( NumSprites > 1 )
			{
				ModifyTextures[0] = SampleSpriteTexture( ModifyTexture1, UV, 1 );
			}
		#endif
				
			for ( int i = 0; i < NumSprites - 1; ++i )
			{
				Base = Blend( 
					Base, 
					ModifyTextures[i], 
					BlendMask * SpriteTranslateRotateUVAndAlpha[i+1].w, 
					BlendMask, 
					SpriteFramesTypeBlendMode[i+1].w );
			}
#endif // PDX_GUI_SPRITE_EFFECT

			return Base;
		}
	]]
}
