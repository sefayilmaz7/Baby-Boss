Shader "Particles/Matcap"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_InvFade("Soft Particles Factor", Range(0.01,3.0)) = 1.0
		[NoScaleOffset] _Matcap("Matcap", 2D) = "white"
	}
	Category
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend One OneMinusSrcAlpha
		ColorMask RGB
		Cull Off Lighting Off ZWrite Off

		SubShader
		{
			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_particles

				#include "UnityCG.cginc"

				struct appdata_t
				{
					float4 vertex : POSITION;
					half3 normal : NORMAL;
					fixed4 color : COLOR;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
					fixed4 color : COLOR;
					half2 cap : TEXCOORD1;
#ifdef SOFTPARTICLES_ON
					float4 projPos : TEXCOORD2;
#endif
					UNITY_VERTEX_OUTPUT_STEREO
				};

				sampler2D _Matcap;

				v2f vert(appdata_t v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
					o.pos = UnityObjectToClipPos(v.vertex);
#ifdef SOFTPARTICLES_ON
					o.projPos = ComputeScreenPos(o.pos);
					COMPUTE_EYEDEPTH(o.projPos.z);
#endif
					o.color = v.color;

					// Matcap shader credit: https://forum.unity.com/threads/getting-normals-relative-to-camera-view.452631/#post-2933684
					half3 worldNorm = UnityObjectToWorldNormal(v.normal);
					half3 viewNorm = mul((half3x3) UNITY_MATRIX_V, worldNorm);
					o.cap = viewNorm.xy * 0.5 + 0.5;

					return o;
				}

				UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
				fixed4 _Color;
				float _InvFade;

				fixed4 frag(v2f i) : SV_Target
				{
#ifdef SOFTPARTICLES_ON
					float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
					float partZ = i.projPos.z;
					float fade = saturate(_InvFade * (sceneZ - partZ));
					i.color.a *= fade;
#endif

					return i.color * _Color * tex2D(_Matcap, i.cap) * i.color.a;
				}
				ENDCG
			}
		}
	}
}
