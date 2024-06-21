// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/NormalMapWorldSpace"
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
            //修改结构体,使其包含从切线空间到世界空间的变换矩阵
            struct v2f
            {
                float4 pos : SV_POSITION;
                //TEXCOORD并没有特定的含义，意义取决于用法
                float4 uv : TEXCOORD0;//纹理坐标，纹理图像上特定像素的坐标
                //依次存储了切线空间到世界空间的变换矩阵的每一行
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;//是float4类型的变量
                float4 TtoW2 : TEXCOORD3;
            };

            //修改顶点着色器，计算从切线空间到世界空间的变换矩阵
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//将顶点位置转换为剪裁空间

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;//当时这里出现了错误

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//转换到世界坐标
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//转换到世界法线
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//转换世界切线
                fixed3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;//计算凹凸程度，通过世界法线和世界切线的叉乘计算处第三个坐标轴，再*w以此确定这个坐标轴的朝向

                //存储世界空间下的切线，副切线和法线方向
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
                
                
                return o;
            }

            //采样得到切线空间下的法线方向，在切线空间下进行光照计算
            fixed4 frag(v2f i) : COLOR
            {
                //得到世界空间下的坐标
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                //完成光照和视角矢量
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                //从切图中获取法线纹理信息
                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                bump.xy *= _BumpScale;//调整法线强度
                //将法线长度和方向确定为一
                bump.z = sqrt(1.0 - saturate(dot(bump.xy,bump.xy)));
                //将切线空间转换到世界坐标空间，通过点乘（切线，副切线，和法线组成的矩阵）将其转换到世界空间
                bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));
                
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;//获取主纹理颜色，乘以漫反射度

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//计算环境光照
                //计算漫反射光照
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,lightDir));

                //半向量 = （光照 +视角）归一化
                fixed3 halfDir = normalize(lightDir + viewDir);
                //计算环境光照
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(bump,halfDir)),_Gloss);

                return fixed4(ambient + diffuse +specular,1.0);
            }
            ENDCG
        }
    }
Fallback "Specular"
}
