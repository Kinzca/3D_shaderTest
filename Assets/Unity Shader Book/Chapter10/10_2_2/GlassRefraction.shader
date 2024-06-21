// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/GlassRefraction"
{
    Properties
    {
        _MainTex("Main Tex",2D) = "white"{}//为该物体的纹理材质，默认白色
        _BumpMap("Normal Map",2D) = "bump"{}//纹理法线
        _Cubemap("Environment Cubemap",Cube) = "_Skybox"{}//模拟反射的环境纹理
        _Distortion("Distorion",Range(0,100)) = 10//控制折射时图像的扭曲程度
        _RefractionAmount("Refraction Amount",Range(0.0,1.0)) = 1.0//值为0时只包含反射效果，值为1时只包含折射效果
    }
    SubShader
    {
        //必须使用透明渲染队列，确保其他物体在他之前绘制完
        Tags{"Queue" = "Transparent" "RenderType" = "Opaque"}
        
        GrabPass{"_RefractionTex"}//使用GrabPass获取环境图像,并将抓取到的屏幕图像存储到_RefractionTex
        
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //主纹理
            sampler2D _MainTex;
            float4 _MainTex_ST;
            //法线纹理
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            //环境纹理
            samplerCUBE _Cubemap;
            float _Distortion;
            fixed _RefractAmount;
            //反射纹理,对应着在使用GrassPass时指定的纹理名称
            sampler2D _RefractionTex;//纹理
            float4 _RefractionTex_TexelSize;//可以获得该纹理的像素大小

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPOS : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //通过内置的ComputeScreenPos对应抓取的屏幕函数采样坐标
                o.scrPOS = ComputeScreenPos(o.pos);

                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent;

                //计算从切线空间到世界空间的变换矩阵并将该矩阵的每一行保存在TtoW0,1,2的xyz分量中，分别对应着切线副切线和法线的方向
                //TtoW等值的w值同样被利用起来，用于存储世界空间下的顶点坐标
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target{
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);//通过TtoW等值的w分量得到i的世界坐标
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));//并用该值得到该片元的视角方向

                //对法线纹理进行采样，获取在切线空间的法线纹理
                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));

                //在切线空间进行纹理计算
                //使用该值与_Distortion,_RefractionTex_TexelSize对法线纹理进行偏移
                //_Distorion的值越大偏移越大，玻璃后的物体变形程度越大
                float2 offest = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                i.scrPOS.xy = offest * i.scrPOS.z + i.scrPOS.xy;
                //对scrPos进行透视除法得到真正的屏幕坐标，再使用该坐标对抓取的颜色进行采样得到真正的反射颜色
                fixed3 refrCol = tex2D(_RefractionTex,i.scrPOS/i.scrPOS.w).rgb;

                //将法线从切线空间转换到世界空间，通过点乘变换矩阵
                bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));
                fixed3 reflDir = reflect(-worldViewDir,bump);//计算反射方向
                fixed4 texColor = tex2D(_MainTex,i.uv.xy);//计算主纹理颜色
                fixed3 reflCol = texCUBE(_Cubemap,reflDir).rgb * texColor.rgb;//用反射方向对Cubemap采样，并于主纹理颜色混合

                //最后用RefractAmount对反射和折射进行混合，输出最终的颜色
                fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;

                return fixed4(finalColor,1);
            }
            
            ENDCG
        }
    }
Fallback "Diffuse"
}
