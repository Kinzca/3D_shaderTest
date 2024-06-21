// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/WaterWave"
{
    Properties
    {
        _Color("Main Color",Color) = (0,0.15,0.115,1)//控制水面颜色
        _MainTex("Base (RGB)",2D) = "white"{}//水面波纹材质纹理
        _WaveMap("Wave Map",2D) = "bump"{}//由噪声纹理生成的法线纹理
        _Cubemap("Environment Cubemap",Cube) = "_Skybox"{}
        _WaveXSpeed("Wave Horizontal Speed",Range(-0.1,0.1)) = 0.01//法线x方向上的移动速度
        _WaveYSpeed("Wave Vertical Speed",Range(-0.1,0.1)) = 0.01//法线y方向上的移动速度
        _Distortion("Distortion",Range(0,100)) = 10//模拟折射时物体的扭曲程度
    }
    
    SubShader
    {
        //设置Transparent确保其他物体渲染完毕后最后渲染，RenderType确保在使用了颜色替换器时可以被正确渲染
        Tags{"Queue" = "Transparent" "RenderType" = "Opaque"}
        
        //通过关键字GrabPass定义了一个抓取屏幕的Pass，内部字符串定义的名称会决定抓取到的纹理会存储到哪一个纹理中
        GrabPass{"_RefractionTex"}
        
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM

        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        #pragma multi_compile_fwdbase

        #pragma vertex vert
        #pragma fragment frag

        fixed4 _Color;
        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D _WaveMap;
        float4 _WaveMap_ST;
        samplerCUBE _Cubemap;
        fixed _WaveXSpeed;
        fixed _WaveYSpeed;
        float _Distortion;
        sampler2D _RefractionTex;//下面两个对应着在使用GrabPass时使用的纹理名称
        float4 _RefractionTex_TexelSize;//得到该纹理的纹素大小

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
            float4 scrPos : TEXCOORD0;
            float4 uv : TEXCOORD1;
            float4 TtoW0 : TEXCOORD2;
            float4 TtoW1 : TEXCOORD3;
            float4 TtoW2 : TEXCOORD4;
        };

        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            //进行了必要的顶点变换后调用ComputeScreenPos抓取对应的屏幕坐标
            o.scrPos = ComputeScreenPos(o.pos);

            //计算_MainTex和_Wavemap的采样坐标
            o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
            o.uv.zw = TRANSFORM_TEX(v.texcoord,_WaveMap);

            //将顶点，法线，切线，副切线转换到世界坐标，进行坐标变换
            float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
            fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
            fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
            fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

            //计算从世界空间到切线空间的变换矩阵，xyz分别对应着切线，副切线，和法线方向
            o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
            o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
            o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

            return o;
        }

        //片元着色器
        fixed4 frag(v2f i) : SV_Target{
            //首先使用TW0的w分量得到世界坐标，并用该值得到当前坐标的视角方向】
            //使用内置变量_Time.y与float()相乘用于模拟两层水波交叉波动的效果
            float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
            fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
            float2 speed = _Time.y * float2(_WaveXSpeed,_WaveYSpeed);

            //在切线空间得到法线，再对其归一化
            fixed3 bump1 = UnpackNormal(tex2D(_WaveMap,i.uv.zw + speed)).rgb;
            fixed3 bump2 = UnpackNormal(tex2D(_WaveMap,i.uv.zw - speed)).rgb;
            fixed3 bump = normalize(bump1 + bump2);

            //在切线空间完成偏移量计算
            //使用该值和_Diistortion与_RefractionTex_TexelSize进行相乘模拟折射效果，_Distortion越大，物体扭曲越大
            float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
            i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;//将偏移量和屏幕坐标的z分量进行相称用于模拟法线深度越大扭曲程度越大
            fixed3 refrCol = tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;//进行透视除法，并使用该坐标对抓取屏幕图像_RefractionTex进行采样，得到模拟的颜色

            //将法线再从切线空间转换到世界空间
            bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));
            fixed4 texColor = tex2D(_MainTex,i.uv.xy + speed);
            fixed3 reflDir = reflect(-viewDir,bump);
            fixed3 reflCol = texCUBE(_Cubemap,reflDir).rgb * texColor.rgb * _Color.rgb;//使用texCUBE对_Cubemap的反射方向进行采样，并混合颜色得到最终值

            fixed fresnel = pow(1 - saturate(dot(viewDir,bump)),4);//计算菲涅尔系数
            fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);//并用此混合反射和折射颜色

            return fixed4(finalColor,1);
        }
        ENDCG
        }
    }
Fallback Off
}
