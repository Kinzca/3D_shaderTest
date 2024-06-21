// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/NormalMapTargetSpace"
{
    //添加控制法线纹理的属性，用于控制凹凸程度
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _BumpMap("Normal Map",2D) = "bump"{}//unity自带的法线纹理,bump对应这模型自带的法线信息
        _BumpScale("Bump Scalse",Float) = 1.0//控制凹凸程度，为0时纹理不会对光照产生影响
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
        Pass
        {
            //指明该Pass的光照效果
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            //定义顶点着色器和片元着色器
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            //CG代码块中与Properties的变量相匹配
            fixed4 _Color;
            //纹理和纹理的偏移值
            sampler2D _MainTex;
            float4 _MainTex_ST;
            //法线纹理和它的偏移值
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            //高光和其面积
            fixed4 _Specular;
            float _Gloss;

            //在顶点着色器的输入结构中获得顶点的切线信息（顶点空间由顶点法线和切线构建的坐标系）
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;//切线
                float4 texcoord : TEXCOORD0;//第一纹理坐标
            };
            
            //在片元着色器中新定义两个变量来存储变换后的光照和视角方向
            struct v2f
            {
                float4 pos : SV_POSITION;
                //TEXCOORD并没有特定的含义，意义取决于用法
                float4 uv : TEXCOORD0;//纹理坐标，纹理图像上特定像素的坐标
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//将顶点位置转换为剪裁空间

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                //完成法线纹理计算
                //副切线方向的计算，（顶点坐标 x 顶点法线切线坐标）*切线的偏移值
                //v.tangent的作用因为切线与法线方向都垂直的方向有两个，w的值确定了这个方向是哪一个
                //float3 binormal = cross(normalize(v.vertex),normalize(v.tangent.xyz))*v.tangent.w;
                //将模型空间的切线方向，副切线方向和法线方向按行排列得到从模型空间，转换到切线空间的变换矩阵rotation
                //float3x3 rotation = float3x3(v.tangent.xyz,binormal,v.normal);

                //unity的内置宏，可以直接获取将模型空间转换为切线空间的矩阵
                TANGENT_SPACE_ROTATION;

                //ObjSpaceLightDir获取模型空间下的光照
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                //再利用rotation矩阵将模型空间转到切线空间
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex).xyz);

                return o;
            }

            //采样得到切线空间下的法线方向，在切线空间下进行光照计算
            fixed4 frag(v2f i) : COLOR
            {
                //将光照和，视角的方向转换为切线空间的方向
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                //得到法线纹理
                //利用tex2D获取法线纹理，法线纹理是法线进过映射得到的像素值，所以需要进行反映射操作，如果没有设置为Normal则需要手动代码设置
                fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
                fixed3 tangentNormal;

                //将法线纹理映射到到法线方向
                //然后*_BumpScale控制法线方向的长度（凹凸程度）
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;//获取主纹理颜色，乘以漫反射度

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//计算环境光照
                //计算漫反射光照
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                //计算环境光照
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(tangentNormal,halfDir)),_Gloss);

                return fixed4(ambient + diffuse +specular,1.0);
            }
            ENDCG
        }
    }
Fallback "Specular"
}
