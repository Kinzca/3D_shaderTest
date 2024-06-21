// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/AlphaTest"
{
    //材质面板中控制透明度测试使用的阈值
    //在Properties语义块中声明一个范围在[0,1]之间的属性_Cutoff
    Properties
    {
        _Color("Main Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _Cutoff("Alpha Cutoff",Range(0,1)) = 0.5//透明度测试时使用的判断条件，纹理的透明度范围就是在次范围内的
    }
    SubShader
    {
        //透明度测试使用的队列 AlphaTest
        //RenderType标签，可以让这个Unity讲这个Shader归入提前定义的组中，这里便是TransparentCutout   
        //来指明该shader 是采用了透明度测试的shader
        //IgnoreProjector设置为true,指明这个shader不会收投影器的影响
        //通常使用透明度测试的shader都应具备上述标签
        Tags{"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"}
        
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;//_Cutoff精度为[0,1]，用fixed修饰

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
                o.pos = UnityObjectToClipPos(v.vertex);//转换剪裁空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//顶点坐标转换为世界坐标
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);//获取主纹理坐标，并存储在v.texcoord
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex,i.uv);

                //透明度测试
                clip(texColor.a - _Cutoff);//如果值小于0，就会舍弃当前像素输出颜色
                    
                fixed3 albedo = texColor.rgb * _Color.rgb;//计算纹理颜色
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//计算环境光照

                fixed3 diffuse = _LightColor0.rgb * albedo *max(0,dot(worldNormal,worldLightDir));

                return fixed4(ambient + diffuse,1.0);
            }
            
            ENDCG
        }
    }
Fallback "Transparent/Cutout/VertexLit"
}
