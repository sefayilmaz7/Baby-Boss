// Matcap shader credit: https://forum.unity.com/threads/getting-normals-relative-to-camera-view.452631/#post-2933684
Shader "Flamingo/Matcap (Two Sided)"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white"
		[NoScaleOffset] _Matcap("Matcap", 2D) = "white"
	}

	SubShader
	{
		Cull Off
		LOD 200

		Pass
		{
			Tags { "LightMode" = "ForwardBase" "Queue" = "Geometry" "RenderType" = "Opaque" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				half3 normal : NORMAL;
				half2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half2 cap : TEXCOORD1;
				SHADOW_COORDS(2)
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Matcap;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				half3 worldNorm = UnityObjectToWorldNormal(v.normal);
				half3 viewNorm = mul((half3x3) UNITY_MATRIX_V, worldNorm);
				o.cap = viewNorm.xy * 0.5 + 0.5;

				TRANSFER_SHADOW(o)
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed shadow = SHADOW_ATTENUATION(i);
				fixed4 col = _Color * tex2D(_Matcap, i.cap) * tex2D(_MainTex, i.uv) * shadow;
				col.a = 1.0;
				return col;
			}

			ENDCG
		}

		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}