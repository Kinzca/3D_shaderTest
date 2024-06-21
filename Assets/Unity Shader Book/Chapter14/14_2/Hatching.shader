// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Hatching"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1) //控制模型颜色
        _TileFactor("Tile Factor",Float) = 1 //纹理的平铺系数，TileFactor越大纹理越密
        _Outline("Outline",Range(0,1)) = 0.1 
        _Hatch0("Hatch 0",2D) = "white"{} //使用的六张素描纹理
        _Hatch1("Hatch 1",2D) = "white"{}
        _Hatch2("Hatch 2",2D) = "white"{}
        _Hatch3("Hatch 3",2D) = "white"{}
        _Hatch4("Hatch 4",2D) = "white"{}
        _Hatch5("Hatch 5",2D) = "white"{}
    }
    
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry"}
        UsePass "Unlit/ToonShading/OUTLINE"
    
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityShaderVariables.cginc"

            fixed4 _Color;
            float _TileFactor;
            sampler2D _Hatch0;
            sampler2D _Hatch1;
            sampler2D _Hatch2;
            sampler2D _Hatch3;
            sampler2D _Hatch4;
            sampler2D _Hatch5;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float4 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };
            
            //在v2f结构体中定义纹理变量，以便在顶点着色器中计算六张纹理权重
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 hatchWeights0 : TEXCOORD1;//声明fixed3类型的变量存储六张纹理的权重
                fixed3 hatchWeights1 : TEXCOORD2;
                float3 worldPos : TEXCOORD3;//声明worldPos获取阴影坐标
                SHADOW_COORDS(4)
            };

            //顶点着色器
            v2f vert(a2v v)
            {
                v2f o;

                //对顶点进行基本的坐标变换
                o.pos = UnityObjectToClipPos(v.vertex);

                //使用_TileFactor得到基本的纹理坐标
                o.uv = v.texcoord.xy * _TileFactor;

                fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed diff = max(0,dot(worldLightDir,worldNormal));//使用世界空间下的光照和法线得到漫反射系数

                //将权重初始化为0
                o.hatchWeights0 = fixed3(0,0,0);
                o.hatchWeights1 = fixed3(0,0,0);

                //将hatchFactor缩放到[0,7]范围内 
                float hatchFactor = diff * 7.0;;

                //对应hatchFactor的子区间来混合纹理权重
                if (hatchFactor > 6.0)
                {
                    //纯白色不做任何事情
                }else if (hatchFactor > 5.0)
                {
                    o.hatchWeights0.x = hatchFactor - 5.0;
                }else if (hatchFactor > 4.0)
                {
                    o.hatchWeights0.x = hatchFactor - 4.0;
                    o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
                }else if (hatchFactor > 3.0)
                {
                    o.hatchWeights0.y = hatchFactor - 3.0;
                    o.hatchWeights0.z = 1.0 - o.hatchWeights0.y;
                }else if (hatchFactor - 2.0)
                {
                    o.hatchWeights0.z = hatchFactor - 2.0;
                    o.hatchWeights1.x = 1.0 - o.hatchWeights0.z;
                }else if (hatchFactor > 1.0)
                {
                    o.hatchWeights1.x = hatchFactor - 1.0;
                    o.hatchWeights1.y = 1.0 - o.hatchWeights1.x;
                }
                else
                {
                    o.hatchWeights1.y = hatchFactor;
                    o.hatchWeights1.z = 1.0 - o.hatchWeights1.y;
                }

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                TRANSFER_SHADOW(o);//计算阴影采样坐标

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                //得到六张纹理的混合权重后，对其进行采样再与权重值相乘
                fixed4 hatchTex0 = tex2D(_Hatch0,i.uv) * i.hatchWeights0.x;
                fixed4 hatchTex1 = tex2D(_Hatch1,i.uv) * i.hatchWeights0.y;
                fixed4 hatchTex2 = tex2D(_Hatch2,i.uv) * i.hatchWeights0.z;
                fixed4 hatchTex3 = tex2D(_Hatch3,i.uv) * i.hatchWeights1.x;
                fixed4 hatchTex4 = tex2D(_Hatch4,i.uv) * i.hatchWeights1.y;
                fixed4 hatchTex5 = tex2D(_Hatch4,i.uv) * i.hatchWeights1.z;

                //通过 1 - 六张纹理的权重值，得到六张纹理的贡献度
                fixed4 whiteColor = fixed4(1,1,1,1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z - i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);

                //将颜色值相加得到最终颜色
                fixed4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;

                //计算阴影值
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                //返回最终颜色
                return fixed4(hatchColor.rgb * _Color.rgb * atten,1.0);
            }
            
            ENDCG
        }
    }
    Fallback "Diffuse"
}
