// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/BumpSpecular"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _BumpMap("Normal Map",2D) = "bump"{}
        _Specular("Specular Color",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
        //指定渲染类型和渲染队列
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry"}
        
        Pass
        {
            //设置光照模式
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            
            CGPROGRAM

            //unity预编译，确保在RenderType管线中能够正确
            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            fixed4 _Specular;
            float _Gloss;

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
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //计算主纹理和法线纹理的坐标
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                //利用unity内置，获取到转换到切线空间的矩阵
                TANGENT_SPACE_ROTATION;

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//从物体空间转换到世界空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//转换到世界法线
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//将切线转换到世界空间的切线位置
                fixed3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;//计算副切线*深度

                //将切线空间转换到世界空间
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);//获取顶点的世界空间位置
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));//获取该顶点的光照方向，并归一化
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));//获取该顶点的视角方向

                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));//获取主法线纹理并存储在_BumpMap中
                bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));//根据切线空间计算法线纹理

                fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb * _Color.rgb;//获取主纹理颜色

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//计算环境光照

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,lightDir));//计算漫反射光照
                
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * albedo * pow(max(0,dot(bump,halfDir)),_Gloss);//计算漫反射光照

                UNITY_LIGHT_ATTENUATION(atten,i,worldPos);//计算光照衰减

                return fixed4(ambient + (diffuse + specular) * atten,1.0);//计算最终光照颜色
            }
            
            ENDCG
        }

        Pass
        {
            //设置光照模式
            //额外光照设置
            Tags
            {
                "LightMode" = "ForwardAdd"
            }
            
            Blend One One
            
            CGPROGRAM

            //unity预编译，确保在RenderType管线中能够正确
            #pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;//添加法线尺寸
            fixed4 _Specular;
            float _Gloss;

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
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //计算主纹理和法线纹理的坐标
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                //利用unity内置，获取到转换到切线空间的矩阵
                TANGENT_SPACE_ROTATION;

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//从物体空间转换到世界空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//转换到世界法线
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//将切线转换到世界空间的切线位置
                fixed3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;//计算副切线*深度

                //将切线空间转换到世界空间
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target//SV_Targent的输出位置和格式的语义
            {
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);//获取顶点的世界空间位置
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));//获取该顶点的光照方向，并归一化
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));//获取该顶点的视角方向

                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));//获取主法线纹理并存储在_BumpMap中
                bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));//根据切线空间计算法线纹理

                fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb * _Color.rgb;//获取主纹理颜色

                //额外光照不计算环境光照
                //fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//计算环境光照

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,lightDir));//计算漫反射光照
                
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * albedo * pow(max(0,dot(bump,halfDir)),_Gloss);//计算漫反射光照

                UNITY_LIGHT_ATTENUATION(atten,i,worldPos);//计算光照衰减

                return fixed4((diffuse + specular) * atten,1.0);//计算最终光照颜色
            }
            
            ENDCG
        }
    }
Fallback "Specular"
}
