Shader "Unlit/AlphaBlendWithShadow"
{
    //材质面板中控制透明度测试使用的阈值
    //在Properties语义块中声明一个范围在[0,1]之间的属性_Cutoff
    Properties
    {
        _Color("Main Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _AlphaScale("Alpha Scale",Range(0,1)) = 1//用于在透明纹理的基础上控制整体的透明度
    }
    SubShader
    {
        //透明度混合使用的队列是Transparent
        //Render标签将这个Shader归入提前定义的Transparent的组当中，用来指明该shader是使用了透明度混合的组
        //Ignoreproject = true 表明了它不会受投影器的影响
        //使用透明度混合的shader都需要具有以上的三个标签
        Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            ZWrite Off//关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha //将原颜色的混合因子设为SrcAlpha 目标颜色（以存在于缓冲区的颜色）设为OneMinusSrcAlpha得到半透明效果
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

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
                SHADOW_COORDS(3)
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//转换剪裁空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//顶点坐标转换为世界坐标
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);//获取主纹理坐标，并存储在v.texcoord

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex,i.uv);
                
                fixed3 albedo = texColor.rgb * _Color.rgb;//计算纹理颜色
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//计算环境光照

                fixed3 diffuse = _LightColor0.rgb * albedo *max(0,dot(worldNormal,worldLightDir));

                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                
                return fixed4(ambient + diffuse * atten,texColor.a * _AlphaScale);//透明度是纹理像素的透明通道和_AlphaScale的乘积
            }
            
            ENDCG
        }
    }
Fallback "VertexLit"
}
