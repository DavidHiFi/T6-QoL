#include "t6_consts.hlsli"

struct VS_IN
{
    float3 pos : POSITION0;
#ifdef SWELL
    float3 nrm : NORMAL0;
#endif
};

float4 main(VS_IN IN) : SV_Position
{
    float4 wp = mul(float4(IN.pos, 1.0), worldMatrix);
#ifdef SWELL
    float3 n = normalize(mul(DecodeNormal(IN.nrm), (float3x3)worldMatrix));
    wp.xyz += n * scriptVector3.x;
#endif
#ifdef ALWAYS
    // diagnostic build: unconditional inflation, proves the asset VS runs
    wp.xyz += n * 5.0;
#endif
    return mul(float4(wp.xyz, 1.0), viewProjectionMatrix);
}
