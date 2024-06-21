Shader "Unlit/FresnelMat"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _FresnelScale("Fresnel Scale",Range(0,1)) = 0.5
        _Cubemap("Reflection Cubemap",Cube) = "_Skybox"{}
    }
    
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry"}
        
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            
            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed _FresnelScale;
            samplerCUBE _Cubemap;

            struct a2v
            {
                float4 vertex : POSITION;
                float3  normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);//转换至剪裁空间坐标

                o.worldNormal = UnityObjectToWorldNormal(v.normal);//将物体法线转换到世界空间下的法线

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//将物体坐标转换到世界空间下

                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);//视角方向转换到世界空间下的坐标

                //在世界空间下完成反射计算
                o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));//归一化世界光照方向
                fixed3 worldViewDir = normalize(i.worldViewDir);//归一化视角方向

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                //从反射贴图上用texCUBE获取特定方向上的颜色值
                fixed3 reflection = texCUBE(_Cubemap,i.worldRefl).rgb;

                //混合菲涅尔光照，菲涅尔反射系数 + （1-反射系数） * （1 -（世界视角方向 与 世界法线 的 余弦值）的 五次方）
                fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1-dot(worldViewDir,worldNormal),5);

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldNormal,worldLightDir));

                //进行最终颜色的计算
                fixed3 color = ambient + lerp(diffuse,reflection,saturate(fresnel)) * atten;

                return fixed4(color,1.0);
            }
            
            ENDCG
        }
    }
Fallback "Reflective/VertexLit"
}
