// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Refraction"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _RefractColor("Refraction Color",Color) = (1,1,1,1)//获取投射颜色
        _RefractAmount("Refraction Amount",Range(0,1)) = 1//获取透射程度
        _RefractRatio("Refraction Ratio",Range(0.1,1)) = 0.5//使用该属性得到不同介质的透射比
        _Cubemap("Refraction Cubemap",Cube) = "_Skybox"{}
    }
    SubShader
    {
        Tags{"RenderType"="Opaque" "Queue"="Geometry"}
        
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _RefractColor;
            float _RefractAmount;
            fixed _RefractRatio;
            samplerCUBE _Cubemap;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefr : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);//转换世界法线

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//转换世界坐标

                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);//转换视角方向

                //完成折射的计算
                o.worldRefr = refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_RefractRatio);

                //计算光照阴影纹理
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //计算漫反射光照
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldNormal,worldLightDir));

                //计算折射光照
                fixed3 refraction = texCUBE(_Cubemap,i.worldRefr).rgb * _RefractColor.rgb;

                //计算光照衰减
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                //混合漫反射颜色和反射颜色
                fixed3 color = ambient + lerp(diffuse,refraction,_RefractAmount) * atten;

                return fixed4(color,1.0);
                
            }
            
            ENDCG
        }
    }
Fallback "Reflective/VertexLit"
}
