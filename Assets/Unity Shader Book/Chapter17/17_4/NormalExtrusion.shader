Shader "Unlit/NormalExtrusion"
{
    Properties
    {
        _ColorTint("Color Tint",Color) = (1,1,1,1)
        _MainTex("Base (RGB)",2D) = "white"{}
        _BumpMap("Normalmap",2D) = "bump"{}
        _Amount("Extrusion Amount",Range(-0.5,0.5)) = 0.1
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque"}
        LOD 300
        
        CGPROGRAM

        //surf表面着色器
        //CustomLambert 光照模型
        //vertex:myvert 使用修改顶点的函数
        //finalcolor:mycolor 使用最终颜色修改函数
        //addshadow 生成一个阴影投射面，因为我们修改了顶点坐标
        //shadow 需要特殊的渲染路径
        //exclude_path:deferred/exclude_path:prepass 告诉unity不要为延迟渲染路劲生成代码
        //normate 不需要生成“mate”Pass 取消对提取元数据的生成
        #pragma surface surf CustomLambert vertex:myvert finalcolor:mycolor addshadow exclude_path:deferred exclude_path:prepass nometa
        #pragma target 3.0

        fixed4 _ColorTint;
        sampler2D _MainTex;
        sampler2D _BumpMap;
        half _Amount;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
        };

        //顶点修改函数，对法线顶点进行缩放
        void myvert(inout appdata_full v)
        {
            v.vertex.xyz += v.normal * _Amount;
        }

        //表面函数。使用主纹理设置了表面的反射率，并用法线纹理设置了法线方向
        void surf(Input IN,inout SurfaceOutput o)
        {
            fixed4 tex = tex2D(_MainTex,IN.uv_MainTex);
            o.Albedo = tex.rgb;
            o.Alpha = tex.a;
            o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
        }

        //使用半伯兰特光照模型
        half4 LightingCustomLambert(SurfaceOutput s,half3 lightDir,half atten)
        {
            half NdotL = dot(s.Normal,lightDir);
            half4 c;
            c.rgb = s.Albedo * _LightColor0.rgb * (NdotL * atten);
            c.a = s.Alpha;
            return c;
        }

        //最终对输出颜色进行调整
        void mycolor(Input IN,SurfaceOutput o,inout fixed4 color)
        {
            color *= _ColorTint;
        }
        ENDCG
    }
Fallback "Legacy Shader/Diffuse"
}
