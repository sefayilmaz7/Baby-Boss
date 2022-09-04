Shader "Flamingo/Unlit Gradient (3 Colors)"
{
    Properties
    {
        _TopColor ("Top Color", Color) = (1,1,1,1)
        _MiddleColor ("Middle Color", Color) = (1,1,1,1)
        _BottomColor ("Bottom Color", Color) = (1,1,1,1)
        _Middle ("Middle Point", Range(0.01, 0.99)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half2 uv : TEXCOORD0;
            };

            fixed4 _TopColor;
            fixed4 _MiddleColor;
            fixed4 _BottomColor;
            half _Middle;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = lerp(_BottomColor,_TopColor, i.uv.y);
                fixed4 c = lerp(_BottomColor, _MiddleColor, i.uv.y / _Middle) * step(i.uv.y, _Middle);
                c += lerp(_MiddleColor, _TopColor, (i.uv.y - _Middle) / (1 - _Middle)) * step(_Middle, i.uv.y);
                return c;
            }
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
