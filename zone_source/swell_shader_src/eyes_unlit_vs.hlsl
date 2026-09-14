// Rebuild of T6 pimp_shader_radiant_190f4788 (the "unlit" pass of
// mc_sw4_3d_model_unlit_cheap_zombie_eyes_jq3e7eqw) plus BO1 Moon's bloat line.
// Retail: 13 instructions - world transform, pass colour + uv, project.
#include "t6_consts.hlsli"

struct VS_IN
{
    float4 pos : POSITION0;
    float4 col : COLOR0;
    float2 uv  : TEXCOORD0;
#ifdef SWELL
    float3 nrm : NORMAL0;
#endif
};

struct VS_OUT
{
    float2 uv  : TEXCOORD0;
    float4 col : COLOR0;
    float4 pos : SV_Position;
};

VS_OUT main(VS_IN IN)
{
    VS_OUT OUT;
    float4 wp = mul(float4(IN.pos.xyz, 1.0), worldMatrix);
#ifdef SWELL
    float3 n = normalize(mul(DecodeNormal(IN.nrm), (float3x3)worldMatrix));
    wp.xyz += n * scriptVector3.x;
#endif
#ifdef ALWAYS
    wp.xyz += n * 5.0;
#endif
    OUT.uv = IN.uv;
    OUT.col = IN.col;
    OUT.pos = mul(float4(wp.xyz, 1.0), viewProjectionMatrix);
    return OUT;
}
