#include "t6_consts.hlsli"

struct VS_IN
{
    float4 pos : POSITION0;
    float4 col : COLOR0;
    float2 uv  : TEXCOORD0;
    float3 nrm : NORMAL0;
    float3 tan : TEXCOORD2;
};

struct VS_OUT
{
    float3 fogCol : TEXCOORD0;
    float4 wpos   : TEXCOORD1;
    float4 col    : TEXCOORD2;
    float4 nrm    : TEXCOORD3;
    float4 tan    : TEXCOORD4;
    float2 uv     : TEXCOORD5;
#ifdef SHADOW
    float4 shadow : TEXCOORD6;
#endif
    float4 grid   : TEXCOORD7;
    float3 sh     : TEXCOORD8;
    float4 pos    : SV_Position;
};

VS_OUT main(VS_IN IN)
{
    VS_OUT OUT;

    float4 wp = mul(float4(IN.pos.xyz, 1.0), worldMatrix);

    float3 n = normalize(mul(DecodeNormal(IN.nrm), (float3x3)worldMatrix));
    float3 t = normalize(mul(DecodeNormal(IN.tan), (float3x3)worldMatrix));

#ifdef SWELL
    // BO1 Moon pimp_shader_sw4_3d_char_cloth_bloat pushed each vertex out along
    // its world normal by scriptVector3.x. SwellOffset (t6_consts.hlsli) is
    // that push limited to a ball around the stomach (v2.15.51).
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

    OUT.col = IN.col;
    OUT.nrm = float4(n, 0.0);
    OUT.tan = float4(t, sign(sign(IN.pos.w)));
    OUT.uv = IN.uv;
#ifdef SHADOW
    OUT.shadow = mul(float4(wp.xyz, 1.0), shadowLookupMatrix);
#endif
    OUT.grid = gridLightingCoordsAndVis;

    float4 qv = float4(n.z * n.x, n.y * n.z, n.x * n.y, n.x * n.x - n.y * n.y);
    float nz2 = n.z * n.z;
    float g = dot(gridLightingSH2, qv) + dot(gridLightingSH1, float4(n, 1.0)) + gridLightingSH0.w * nz2;
    float3 grid = max(g * gridLightingSH0.xyz, 0.1);
    float r = dot(reflectionLightingSH2, qv) + dot(reflectionLightingSH1, float4(n, 1.0)) + reflectionLightingSH0.w * nz2;
    float3 refl = max(r * reflectionLightingSH0.xyz, 0.1);
    OUT.sh = grid / refl;

    OUT.pos = mul(float4(wp.xyz, 1.0), viewProjectionMatrix);
    return OUT;
}
