Shader "Unlit/AttenuationAndShadowUseBuildInFunctionsMat"
{
    
     Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque"}
        
        //Base Pass
        Pass
        {
            //指定该pass的渲染类型
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma multi_compile_fwdbase//确保使用光照衰减等光照变量能够正确赋值

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"//引入内置文件，计算阴影的宏都是在这个文件中声明的

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            //在顶点着色器输出结构体v2f中添加内置宏SHADOW_COORDS
            struct v2f
            {
                float4 pos :SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                SHADOW_COORDS(2)//声明一个对阴影采样的坐标，这个参数是一个可用插值寄存器的索引值
            };

            //片元着色器输入结构体
            //在顶点着色器返回之前加另一个内置宏TRANSFER_SHADOW
            v2f vert(a2v v)
            {
                //进行转换的相关计算
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                TRANSFER_SHADOW(o);//这个宏用于计算在上一步，顶点着色器声明的阴影坐标
                
                return o;
            }
            //在片元着色器中计算阴影值，使用SHADOW_ATTENUATION
            fixed4 frag(v2f i) :COLOR
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0,dot(worldNormal,worldLightDir));
                
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);
                
                //和9.4.2不同，在片元着色器中使用内置宏UNITY_LIGHT_ATTENUATION
                //不止计算光照衰减，还计算光照阴影
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                
                return fixed4(ambient + (diffuse + specular) * atten,1.0);
            }
            ENDCG
            
        }

        //Additional Pass
        Pass
        {
            //指定该pass的渲染类型
            Tags{"LightMode" = "ForwardAdd"}
            
            Blend One One //开启混合，缓存帧与之前缓冲区的混合，如果没有则得到的结果会直接覆盖掉之前的颜色
            
            CGPROGRAM
            #pragma multi_compile_fwdadd//确保在addition pass使用光照衰减等光照变量能够正确赋值
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos :SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            //片元着色器输入结构体
            v2f vert(a2v v)
            {
                //进行转换的相关计算
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }
            fixed4 frag(v2f i) :COLOR
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                
                #ifdef USING_DIRECTIONAL_LIGHT //如果采用的平行光
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);//光源方向 = 光源位置 - 顶点坐标
                #endif

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0,dot(worldNormal,worldNormal));
                
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                #ifdef USING_DIRECTIONAL_LIGHT  
                fixed atten = 1.0;//平行光可以认为没有衰减，即设置atten = 1.0
                #else
                    #if defined(POINT)//如果是点光源
                        float3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;
                        fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #elif defined(SPOT)
                        float4 lightCoord = mul(_lightMatrix0,float4(i.worldPos,1));
                        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0,lightCoord.xy/lightCoord.w + 0.5).w * tex2D(_lightTextureB0,dot(lightCoord,lightCoord).rr)UNITY_ATTEN_CHANNEL;
                    #else
                        fixed atten = 1.0;
                    #endif
                #endif
                
                return fixed4((diffuse + specular) * atten,1.0);
            }
            ENDCG
            
        }
    }
Fallback "Specular"
}
