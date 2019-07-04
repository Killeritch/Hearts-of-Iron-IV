ConstantBuffer( PdxCamera )
{
	float4x4	ViewProjectionMatrix;
	float4x4	InvViewProjectionMatrix;
	float4x4	ViewMatrix;
	float4x4	InvViewMatrix;
	float4x4	ProjectionMatrix;
	float4x4	InvProjectionMatrix;

	float3		CameraPosition;
	float		ZNear;
	float3		CameraLookAtDir;
	float		ZFar;
	float3		CameraUpDir;
	float 		CameraFoV;
	float3		CameraRightDir;
	float camera_dummy2;
	
	float4x4 	ShadowMapTextureMatrix;
}

Code
[[
	float CalcViewSpaceDepth( float Depth )
	{
		Depth = 2.0 * Depth - 1.0;
		float ZLinear = 2.0 * ZNear * ZFar / (ZFar + ZNear - Depth * (ZFar - ZNear));
		return ZLinear;
	}
	
	float3 WorldSpacePositionFromDepth( float Depth, float2 UV )
	{
		float x = UV.x * 2.0 - 1.0;
		float y = (1.0 - UV.y) * 2.0 - 1.0;
		
		float4 ProjectedPos = float4( x, y, Depth, 1.0 );
		
		float4 ViewSpacePos = mul( InvProjectionMatrix, ProjectedPos );
		float3 WorldSpacePos = mul( InvViewMatrix, float4( ViewSpacePos.xyz / ViewSpacePos.w, 1.0 ) ).xyz;
		
		return WorldSpacePos;  
	}
]]
