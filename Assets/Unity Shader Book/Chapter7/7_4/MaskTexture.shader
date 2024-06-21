// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/MaskTexture"
{
    //声明更多变量来控制高光反射
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _BumpMap("Normal Map",2D) = "bump"{}
        _BumpScale("Bump Scale",Float) = 1.0
        _SpecularMask("Specular",Color) = (1,1,1,1) //高光反射遮罩
        _Gloss("Gloss",Range(8.0,256)) = 20    
    }
    SubShader
    {
        Pass
        {
            //LightMode是pass标签得一种，用于定义光照流水线中得角色
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            //主纹理
            sampler2D _MainTex;
            float4 _MainTex_ST;
            //法线纹理
            sampler2D _BumpMap;
            float _BumpScale;
            //遮罩纹理
            sampler2D _SpecularMask;
            //高光纹理
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;
            
            //定义顶点输入输出结构体
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
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                TANGENT_SPACE_ROTATION;//引入unity切线空间转换矩阵
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;//讲光线方向转换到，切线空间
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;//讲观察方向转换到，切线空间

                return o;
            }

            //使用遮罩纹理的是片元着色器，用于控制高光反射的强度
            fixed4 frag(v2f i) : COLOR
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv));//利用tex2D获取法线纹理
                tangentNormal.xy *= _BumpScale;//利用_BumpScale控制法线长度
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));//计算法线的z分量使其在【0，1】

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;//计算主纹理颜色并乘以颜色属性
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//计算环境光照

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentViewDir));//计算漫反射光照

                fixed3 halfDir = normalize(tangentLightDir + tangentLightDir);//计算半向量

                fixed specularMask = tex2D(_SpecularMask,i.uv).r * _SpecularScale;//获取遮罩纹理并进行缩放，利用掩盖码 * _Specular 对高光范围进行控制
                fixed specular = _LightColor0.rgb *  _Specular.rgb *pow(max(0,dot(tangentNormal,halfDir)),_Gloss) * specularMask;//计算高光

                return fixed4(ambient + diffuse + specular,1.0);
            }
            
            ENDCG
        }
    }
Fallback "specular"
}
