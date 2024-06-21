// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/Billboard"
{
    Properties
    {
        _MainTex("Main Tex",2D) = "white"{} //广告牌显示的透明纹理
        _Color("Color Tint",Color) = (1,1,1,1) //控制整体颜色
        _VerticalVillboarding("Vertical Restraints",Range(0,1)) = 1 //用于调整固定法线还是固定指向方向上的方向，即用于约束垂直方向上的程度
    }
    
    SubShader
    {
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
        
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off //关闭剔除模式让广告牌的每个面都能显示
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed4 _Color;
            float _VerticalVillboarding;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;

                //固定物体空间的正中心
                float3 center = float3(0,0,0);
                float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));

                //计算三个正交矢量
                float3 normalDir = viewer - center;
                //如果_VerticalVillboarding等于1，意味着法线方向固定视角方向
                //如果_VerticalVillboarding等于0，意味着向上方固定着（0，1，0）
                //最后对法线归一化得到单位矢量
                normalDir.y = normalDir.y * _VerticalVillboarding;
                normalDir = normalize(normalDir);

                //为了防止法线方向与向上平行（平行叉乘得到的结果是错误的）
                //我们需要对法线方向的的 y 方向进行判断，以得到合适的上方向
                //之后根据法线的上方向和粗略的向上方向得到向右方向，并对结果进行归一化
                //但此时向上的方向是不确定的，所以根据法线方向和向右方向得到最后的向右方向
                float3 upDir = abs(normalDir.y)>0.999 ? float3(0,0,1) : float3(0,1,0);
                float3 rightDir = normalize(cross(upDir,normalDir));
                upDir = normalize(cross(normalDir,rightDir));

                //得到三个正交矢量根据原始的位置及偏移量以及三个正交矢量，就能计算得到新的顶点位置
                //固定向上的视角方向
                float3 centerOffs = v.vertex.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

                o.pos = UnityObjectToClipPos(float4(localPos,1));
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target{
                fixed4 c = tex2D(_MainTex,i.uv);
                c.rgb *= _Color.rgb;

                return c;
            }
            ENDCG
        }
    }

Fallback "Transparent/VertexLit"
}
