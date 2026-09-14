// Rebuild of T6 pimp_shader_sw4_3d_model_unlit_cheap_zombie_eyes_6a8c6a7c (the
// "emissive" pass of mc_sw4_3d_model_unlit_cheap_zombie_eyes_jq3e7eqw) plus BO1
// Moon's bloat line. Retail: 42 instructions - world transform, sun/height fog
// (same maths as the char_cloth shader), uv, project.
#include "t6_consts.hlsli"

struct VS_IN
{
    float4 pos : POSITION0;
    float2 uv  : TEXCOORD0;
#ifdef SWELL
    float3 nrm : NORMAL0;
#endif
};

struct VS_OUT
{
    float3 fogCol : TEXCOORD0;
    float4 wpos   : TEXCOORD1;
    float2 uv     : TEXCOORD2;
    float4 pos    : SV_Position;
};

VS_OUT main(VS_IN IN)
{
    VS_OUT OUT;
    float4 wp = mul(float4(IN.pos.xyz, 1.0), worldMatrix);
#ifdef SWELL
    // torso-ball swell in eye-relative world space, see SwellOffset (v2.15.51)
    float3 n = normalize(mul(DecodeNormal(IN.nrm), (float3x3)worldMatrix));
    wp.xyz += SwellOffset(wp.xyz, n);
#endif

    float dist = length(wp.xyz);
    float3 wdir = wp.xyz / dist;
    float4 fc = lerp(fogColor, sunFogColor, saturate(sunFog.y * dot(sunFogDir, wdir) + sunFog.x));
    OUT.fogCol = fc.xyz;

    float tt = fogConsts.w * wp.z + fogConsts.x;
    float a = (tt < 0.0) ? exp(min(tt, 64.0)) : (tt + 1.0);
    a = a - fogConsts2.x;
    float d = wp.z * fogConsts.w;
    bool small = abs(d) < 0.0001;
    d = small ? 1.0 : d;
    float q = a / d;
    q = small ? saturate(fogConsts2.x) : q;
    q = q * fogConsts.y;
    q = q * dist + fogConsts.z;
    float fogAmt = 1.0 - min(exp2(q), 1.0);
    OUT.wpos = float4(wp.xyz, 1.0 - fogAmt * fc.w);

    OUT.uv = IN.uv;
    OUT.pos = mul(float4(wp.xyz, 1.0), viewProjectionMatrix);
    return OUT;
}
