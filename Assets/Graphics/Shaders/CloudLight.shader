Shader "CloudLight"
{
    Properties
    {
        Vector4_2a211ce868e64043a5cd16576a3e8d28("Projection", Vector) = (1, 0, 0, 90)
        Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9("NoiseScale", Range(0.0001, 10)) = 0.1
        Vector1_bc5a24dc955f4a15bde541fb049360e0("Speed", Float) = 15
        Vector1_d1bd133d4ed6412cb53ef9193351274b("Height", Float) = 60
        Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9("NoiseRemap", Vector) = (-0.4, 0.6, 0.73, 1)
        Color_e73d12e52e7f4f81993b7b9aba376c1e("Color Peak", Color) = (0.8632076, 0.9664637, 1, 1)
        Color_1987fef9d3e44bc298cb98ade66a2b0d("Color Valley", Color) = (0.5424528, 0.8066068, 1, 1)
        Vector1_880610a035744cb8ab86c86a914751f5("Noise Edge 1", Float) = 0.6
        Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39("Noise Edge 2", Float) = 1
        Vector1_a52bd6e5e76b434cb4f7be11676b1595("Noise Power", Float) = 2.15
        Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6("Fog Density", Range(0, 1)) = 0.035
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue"="Transparent"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_3809a1a620344210bd3c9e7503d0b65a_Out_0 = Color_1987fef9d3e44bc298cb98ade66a2b0d;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float4 _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3;
            Unity_Lerp_float4(_Property_3809a1a620344210bd3c9e7503d0b65a_Out_0, _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxxx), _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3);
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.BaseColor = (_Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3.xyz);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
        #pragma multi_compile _ _GBUFFER_NORMALS_OCT
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_GBUFFER
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_3809a1a620344210bd3c9e7503d0b65a_Out_0 = Color_1987fef9d3e44bc298cb98ade66a2b0d;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float4 _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3;
            Unity_Lerp_float4(_Property_3809a1a620344210bd3c9e7503d0b65a_Out_0, _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxxx), _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3);
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.BaseColor = (_Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3.xyz);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_3809a1a620344210bd3c9e7503d0b65a_Out_0 = Color_1987fef9d3e44bc298cb98ade66a2b0d;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float4 _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3;
            Unity_Lerp_float4(_Property_3809a1a620344210bd3c9e7503d0b65a_Out_0, _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxxx), _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3);
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.BaseColor = (_Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3.xyz);
            surface.Emission = float3(0, 0, 0);
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_3809a1a620344210bd3c9e7503d0b65a_Out_0 = Color_1987fef9d3e44bc298cb98ade66a2b0d;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float4 _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3;
            Unity_Lerp_float4(_Property_3809a1a620344210bd3c9e7503d0b65a_Out_0, _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxxx), _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3);
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.BaseColor = (_Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3.xyz);
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue"="Transparent"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_3809a1a620344210bd3c9e7503d0b65a_Out_0 = Color_1987fef9d3e44bc298cb98ade66a2b0d;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float4 _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3;
            Unity_Lerp_float4(_Property_3809a1a620344210bd3c9e7503d0b65a_Out_0, _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxxx), _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3);
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.BaseColor = (_Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3.xyz);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_3809a1a620344210bd3c9e7503d0b65a_Out_0 = Color_1987fef9d3e44bc298cb98ade66a2b0d;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float4 _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3;
            Unity_Lerp_float4(_Property_3809a1a620344210bd3c9e7503d0b65a_Out_0, _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxxx), _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3);
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.BaseColor = (_Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3.xyz);
            surface.Emission = float3(0, 0, 0);
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Off
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_2a211ce868e64043a5cd16576a3e8d28;
        float Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
        float Vector1_bc5a24dc955f4a15bde541fb049360e0;
        float Vector1_d1bd133d4ed6412cb53ef9193351274b;
        float4 Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
        float4 Color_e73d12e52e7f4f81993b7b9aba376c1e;
        float4 Color_1987fef9d3e44bc298cb98ade66a2b0d;
        float Vector1_880610a035744cb8ab86c86a914751f5;
        float Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
        float Vector1_a52bd6e5e76b434cb4f7be11676b1595;
        float Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        void Unity_Negate_float(float In, out float Out)
        {
            Out = -1 * In;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float3 _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxx), _Multiply_4fea2a781f784268938ffd59f99a3335_Out_2);
            float _Property_17e24ab57b3442d3874486c6c3b11369_Out_0 = Vector1_d1bd133d4ed6412cb53ef9193351274b;
            float3 _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2;
            Unity_Multiply_float(_Multiply_4fea2a781f784268938ffd59f99a3335_Out_2, (_Property_17e24ab57b3442d3874486c6c3b11369_Out_0.xxx), _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2);
            float3 _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_46e03c682860486e831a9a8352f8c4a2_Out_2, _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2);
            description.Position = _Add_ee8a688087ab449bbd08baf6d822c6d7_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_3809a1a620344210bd3c9e7503d0b65a_Out_0 = Color_1987fef9d3e44bc298cb98ade66a2b0d;
            float4 _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0 = Color_e73d12e52e7f4f81993b7b9aba376c1e;
            float _Property_9d0ffb397ba14d68b43584002a92bd35_Out_0 = Vector1_880610a035744cb8ab86c86a914751f5;
            float _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0 = Vector1_56b9c4dbc60644d8b5f13fc4e8a3ab39;
            float4 _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0 = Vector4_2a211ce868e64043a5cd16576a3e8d28;
            float _Split_585066040de246419a76c1f9db9ab984_R_1 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[0];
            float _Split_585066040de246419a76c1f9db9ab984_G_2 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[1];
            float _Split_585066040de246419a76c1f9db9ab984_B_3 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[2];
            float _Split_585066040de246419a76c1f9db9ab984_A_4 = _Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0[3];
            float3 _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.ObjectSpacePosition, (_Property_ad2df0bcbd6e432888e63e8ae16efdad_Out_0.xyz), _Split_585066040de246419a76c1f9db9ab984_A_4, _RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3);
            float _Property_9e92854b46bc41be8490ccd425828808_Out_0 = Vector1_bc5a24dc955f4a15bde541fb049360e0;
            float _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_9e92854b46bc41be8490ccd425828808_Out_0, _Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2);
            float2 _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), (_Multiply_d1f767d20a0b4f8784ec3c5cab3a969b_Out_2.xx), _TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3);
            float _Property_940b20a7dacd4f77b267690685df26ed_Out_0 = Vector1_e3beb6f2bc6f492c9953b8ef50d9dba9;
            float _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_7bb2648b7d354015a62eab78d50cccd2_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_4f6e1be316e44c09951e204417051254_Out_2);
            float2 _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_8bcfbfc68606408997196beb30424e1e_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3);
            float _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_c35a99d430214bce8d43f0ef4a943d4b_Out_3, _Property_940b20a7dacd4f77b267690685df26ed_Out_0, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2);
            float _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2;
            Unity_Add_float(_GradientNoise_4f6e1be316e44c09951e204417051254_Out_2, _GradientNoise_9a3d84b0775e4d21a58a14d7606e0c26_Out_2, _Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2);
            float _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2;
            Unity_Divide_float(_Add_4d7387dd820d4c9d91a6d547a29939e8_Out_2, 2, _Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2);
            float _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1;
            Unity_Saturate_float(_Divide_13ec4fb711e048fb9dbfe1459172f908_Out_2, _Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1);
            float _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0 = Vector1_a52bd6e5e76b434cb4f7be11676b1595;
            float _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2;
            Unity_Power_float(_Saturate_a29b8bae8ea94bdfbc90f6674086e16c_Out_1, _Property_a444ce760d074bde86f4efe3d414d9ff_Out_0, _Power_bae1620aed6c4f958f764b9aff1bf770_Out_2);
            float4 _Property_45c814db41754ed6b48914eaa1595200_Out_0 = Vector4_a0940e9707ae4a5c9ac5955c28c3f9b9;
            float _Split_f772d6c53a2049c5832177434de3276a_R_1 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[0];
            float _Split_f772d6c53a2049c5832177434de3276a_G_2 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[1];
            float _Split_f772d6c53a2049c5832177434de3276a_B_3 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[2];
            float _Split_f772d6c53a2049c5832177434de3276a_A_4 = _Property_45c814db41754ed6b48914eaa1595200_Out_0[3];
            float4 _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4;
            float3 _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5;
            float2 _Combine_9ab28888537c4885a7c96761454c72e5_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_R_1, _Split_f772d6c53a2049c5832177434de3276a_G_2, 0, 0, _Combine_9ab28888537c4885a7c96761454c72e5_RGBA_4, _Combine_9ab28888537c4885a7c96761454c72e5_RGB_5, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6);
            float4 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4;
            float3 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5;
            float2 _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6;
            Unity_Combine_float(_Split_f772d6c53a2049c5832177434de3276a_B_3, _Split_f772d6c53a2049c5832177434de3276a_A_4, 0, 0, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGBA_4, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RGB_5, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6);
            float _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3;
            Unity_Remap_float(_Power_bae1620aed6c4f958f764b9aff1bf770_Out_2, _Combine_9ab28888537c4885a7c96761454c72e5_RG_6, _Combine_a631053fe8d94cb98edb9e5dbdf9c80e_RG_6, _Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3);
            float _Absolute_8e941d5536b544afa49bf7919f277249_Out_1;
            Unity_Absolute_float(_Remap_7d6f6e209fb44873a67b93dc3a7ef32a_Out_3, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1);
            float _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3;
            Unity_Smoothstep_float(_Property_9d0ffb397ba14d68b43584002a92bd35_Out_0, _Property_b892edb6c5dd40acb9acbd0a963393a0_Out_0, _Absolute_8e941d5536b544afa49bf7919f277249_Out_1, _Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3);
            float4 _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3;
            Unity_Lerp_float4(_Property_3809a1a620344210bd3c9e7503d0b65a_Out_0, _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0, (_Smoothstep_97fc3a625d814aa3899624bc5cc82a11_Out_3.xxxx), _Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3);
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_R_1 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[0];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_G_2 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[1];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_B_3 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[2];
            float _Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4 = _Property_4ac9a944c11f4df49d18af3ca6d4ff16_Out_0[3];
            float _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1);
            float3 _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1);
            float3 _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2;
            Unity_Multiply_float((_SceneDepth_485f7efc8c844c81b334601f6e53095d_Out_1.xxx), _Normalize_25aab415b01b414baec166c31a3eaa67_Out_1, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2);
            float3 _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2;
            Unity_Subtract_float3(_WorldSpaceCameraPos, _Multiply_ad192d1c46c349d2b49366909d81be33_Out_2, _Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2);
            float3 _Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1 = TransformWorldToObject(_Subtract_ea95a4948a0340ea8da0c56e682c77e5_Out_2.xyz);
            float3 _Normalize_aa36634990464cfda56260adc5480cd8_Out_1;
            Unity_Normalize_float3(IN.ObjectSpaceNormal, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1);
            float _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2;
            Unity_DotProduct_float3(_Transform_5196ce81d419489a9dde3fb7abe9c3e7_Out_1, _Normalize_aa36634990464cfda56260adc5480cd8_Out_1, _DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2);
            float _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0 = Vector1_a344ba1c3bcb49bdb703cda0f03bf4a6;
            float _Multiply_90630d494d5d4318879b8134df0747ce_Out_2;
            Unity_Multiply_float(_DotProduct_ab84547f8458475d8ab28ea70fdc0a0e_Out_2, _Property_3013afb38b8b46808bcb5ea83f5a1fae_Out_0, _Multiply_90630d494d5d4318879b8134df0747ce_Out_2);
            float _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1;
            Unity_Negate_float(_Multiply_90630d494d5d4318879b8134df0747ce_Out_2, _Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1);
            float _Saturate_af7129554c744efca7c12592960241bb_Out_1;
            Unity_Saturate_float(_Negate_838a0a531815457aa0c36e66ce8c5ea1_Out_1, _Saturate_af7129554c744efca7c12592960241bb_Out_1);
            float _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            Unity_Multiply_float(_Split_bd6d08cb4d6a4dc7823e0f51ed6a7579_A_4, _Saturate_af7129554c744efca7c12592960241bb_Out_1, _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2);
            surface.BaseColor = (_Lerp_51fe054bb0ef4be7bb1b0d833b043897_Out_3.xyz);
            surface.Alpha = _Multiply_15b3a093cae14bfdb0ccbc54b1f718e6_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    CustomEditor "ShaderGraph.PBRMasterGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}