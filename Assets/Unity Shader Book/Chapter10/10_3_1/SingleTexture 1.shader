// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/SingleTexture"
{
    //添加纹理属性
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        //声明一个_MainTex的纹理，2D是纹理属性的声明方式，使用一个字符串加一个花括号作为它的初始值，“white"则是内置纹理的名字
        //并使用COLOR来控制色调
        _MainTex("Main Tex",2D) = "white"{}
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    
    SubShader
    {
        Pass
        {   
            //定义Pass在光照流水线中的角色
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            //在CG代码段中声明和上述变量相匹配的变量，以便和材质面板中的属性建立联系
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;

            //定义顶点着色器的输入和输出
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                //物体坐标转换为剪裁空间坐标
                o.pos = UnityObjectToClipPos(v.vertex);

                //将物体法线转换为世界法线
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //将物体坐标转换为世界坐标
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                //纹理坐标 = v的第一纹理坐标 * _MainTex的缩放值 * _MainTex的偏移值
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                //或者使用内置的函数自动处理缩放值和偏移值
                //o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

                return o;
            }

            fixed4 frag(v2f i):COLOR
            {
                //世界法线归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                //获取世界光照并归一化
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                //材质颜色 = 纹理颜色 * 材质颜色
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                //计算环境光照
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                //漫反射光照 = 光照颜色 * 材质颜色 *（世界法线与世界光照的余弦值）
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,worldLightDir));

                //对观察方向归一化
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                //半向量 = 世界光照方向 + 观察方向 并归一化
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                //计算镜面反射 = 光照 * 高光颜色 * （世界法线与半向量的余弦值）的_Gloss次幂
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                //最终颜色 = 环境光 + 漫反射光照 + 镜面反射
                return fixed4(ambient + diffuse + specular , 1.0);
            }
            
            ENDCG
        }
    }
    Fallback "Specular"
}
