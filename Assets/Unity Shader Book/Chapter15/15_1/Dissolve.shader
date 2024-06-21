// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Dissolve"
{
    //声明消融的各个属性
    Properties
    {
        _BurnAmount("Burn Amount",Range(0.0,1.0)) = 0.0 //控制消融程度，物体为0时为正常效果，为1时完全消融
        _LineWidth("Burn Line Width",Range(0.0,0.2)) = 0.1 //控制灼烧时的线宽，值越大灼烧线蔓延范围越广
        _MainTex("Base (RGB)",2D) = "white"{} //漫反射纹理
        _BumpMap("Normal Map",2D) = "bump"{} //法线纹理
        _BurnFirstColor("Burn First Color",Color) = (1,0,0,1)//火焰边缘的两种颜色
        _BurnSecondColor("Burn Second Color",Color) = (1,0,0,1)
        _BurnMap("Burn Map",2D) = "white"{} //关键的噪声纹理
    }
    
    SubShader
    {
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            Cull Off//关闭片面渲染使得模型的正面和背面都能被渲染
            
            CGPROGRAM

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag
            
            fixed _BurnAmount;
            fixed _LineWidth;
            sampler2D _MainTex;
            sampler2D _BumpMap;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSecondColor;
            sampler2D _BurnMap;

            float4 _MainTex_ST;
            float4 _BumpMap_ST;
            float4 _BurnMap_ST;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uvMainTex : TEXCOORD0;
                float2 uvBumpMap : TEXCOORD1;
                float2 uvBurnMap : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //计算三张纹理对应的纹理坐标
                o.uvMainTex = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord,_BumpMap);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord,_BurnMap);

                //使用内置宏，将光源从世界空间转换到切线空间
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                TRANSFER_SHADOW(o)

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                //对噪声纹理进行采样
                fixed3 burn = tex2D(_BurnMap,i.uvBurnMap).rgb;

                //将结果和用于控制消融的系数相减，如果结果小于0，则像素会被剔除，通过测试那么进行正常的光照计算
                clip(burn.r - _BurnAmount);

                //计算切线空间下的光照和法线
                float3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uvBumpMap));

                //根据漫反射纹理得到反射率
                fixed3 albedo = tex2D(_MainTex,i.uvMainTex).rgb;

                //将反射率和环境关照相乘得到环境光照
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //计算得到漫反射光照
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));

                //使用smooth计算消融系数，t=1,表示在消融边界处，t=0,表示正常模型
                //同时用t混合火焰颜色
                //最后将结果用pow进行进一步的处理
                fixed t = 1 - smoothstep(0.0,_LineWidth,burn.r - _BurnAmount);
                fixed3 burnColor = lerp(_BurnFirstColor,_BurnSecondColor,t);
                burnColor = pow(burnColor,5);

                //计算阴影
                //计算最终颜色，并通过step越阶函数，确保当_BurnAmount来确保为0时不显示任何效果
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                fixed3 finalColor = lerp(ambient + diffuse * atten,burnColor,t * step(0.0001,_BurnAmount));

                //返回最终颜色
                return fixed4(finalColor,1);
            }
            
            ENDCG
        }

        //定义第二个pass来处理阴影
        Pass
        {
            Tags{"LightMode" = "ShadowCaster"}
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"

            fixed _BurnAmount;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;
            
            
            struct v2f
            {
                V2F_SHADOW_CASTER;//定义投射阴影所需要的变量    
                float2 uvBurnMap : TEXCOORD1;
            };
            v2f vert(appdata_base v)
            {
                v2f o;

                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)//使用TRANSFER_SHADOW_CASTER_NORMALOFFSET填充V2F_SHADOW_CASTER定义的一些变量

                o.uvBurnMap = TRANSFORM_TEX(v.texcoord,_BurnMap);//填充灼烧的纹理坐标

                return o;
            }
            fixed4 frag(v2f i) : SV_Target{
                fixed3 burn = tex2D(_BurnMap,i.uvBurnMap).rgb;//对噪声纹理进行采样
                clip(burn.r - _BurnAmount);//剔除片元
                SHADOW_CASTER_FRAGMENT(i)//完成阴影映射，将结果图输出到深度图，阴影纹理中
            }
            
            ENDCG
        }
    }
Fallback "Diffuse"
}
