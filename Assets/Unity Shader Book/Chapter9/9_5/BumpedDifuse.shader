// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/BumpedDifuse"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1) //颜色
        _MainTex("Main Tex",2D) = "white"{} //主纹理
        _BumpMap("Normal Map",2D) = "bump"{} //法线纹理
    }
    SubShader
    {
        //指定渲染模式和渲染队列，并指定渲染队列
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry"}
        
        Pass
        {
            //定义光照模式，用于处理基本的光照
            //在片元着色器中，计算环境光照，漫反射和光照衰减
            Tags{"lightMode" = "ForwardBase"}
            
            CGPROGRAM

            #pragma multi_compile_fwdbase //提前提供变体，为后续得工作做准备

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"//包含光照着色函数
            #include "AutoLight.cginc"//包含自动光照函数

            fixed4 _Color;//颜色
            sampler2D _MainTex;//主纹理
            float4 _MainTex_ST;//纹理缩放和偏移
            sampler2D _BumpMap;//法线纹理
            float4 _BumpMap_ST;//法线纹理和偏移

            struct a2v
            {
                float4 vertex : POSITION;//顶点坐标
                float3 normal : NORMAL;//法线
                float4 tangent : TANGENT;//切线
                float4 texcoord : TEXCOORD0;//纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION;//剪裁空间中的位置
                float4 uv : TEXCOORD0;//主纹理和法线纹理的纹理坐标
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4)//在顶点输出结构体中，进行对阴影纹理的采样
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//将世界坐标转换为剪裁坐标

                //计算主纹理和法线纹理的纹理坐标
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                //计算世界空间的切线副切线和法线
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//法线
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//切线
                fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;//副切线

                //存储从世界空间到切线空间的转换矩阵
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                //转换阴影坐标
                TRANSFER_SHADOW(o)

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{

                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);//转换到切线空间
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));//光照方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));//视图方向

                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));//解包法线纹理并存储到_BumpMap上
                bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2,bump)));//根据切线空间转换矩阵转换法线纹理

                fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb * _Color.rgb;//获取主纹理颜色

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//将环境光照和纹理颜色进行混合

                //Phong光照模型 计算反射分量 = 光源颜色 * 主纹理颜色 * （法线贴图的法线和光照方向的余弦值）
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,lightDir));//计算漫反射光照
                //_LightColor0与unity_LightColor0得区别，
                //unity_LightColor0是全局变量用于获取第一个光源得颜色，
                //_LightColor0是局部变量，需要在着色器中定义使用，用于储存着色器中得光源颜色信息

                UNITY_LIGHT_ATTENUATION(atten,i,worldPos);//进行光照衰减的计算，将计算结果存储到atten中

                return fixed4(ambient + diffuse * atten,1.0);//返回最终的颜色
            }
            ENDCG
        }

        Pass
        {
            //定义光照模式，用于计算额外的光照
            //在片元着色器中仅仅计算漫反射
            Tags{"lightMode" = "ForwardAdd"}
            
            Blend One One //混合模式
            
            CGPROGRAM

            #pragma multi_compile_fwdadd//提前提供变体，为后续得工作做准备

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;

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
                SHADOW_COORDS(4)//在顶点输出结构体中，进行对纹理的采样
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                TRANSFER_SHADOW(o)

                return o;
            }

            fixed4 frag(v2f i) : SV_Target{

                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2,bump)));//根据切线空间计算法线纹理

                fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb * _Color.rgb;//计算主纹理，并将结果存储到 _MainTex中
                
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,lightDir));//计算漫反射光照

                UNITY_LIGHT_ATTENUATION(atten,i,worldPos);//计算阴影，并将阴影存储到atten中

                return fixed4(diffuse * atten,1.0);
            }
            ENDCG
        }
    }
Fallback "Diffuse"
}
