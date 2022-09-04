using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Compilation;
using UnityEngine;

namespace FTemplateNamespace
{
	public class SDKIntegrationsWindow : EditorWindow
	{
		private const string FTEMPLATE_ASSEMBLY_DEFINITION_PATH = "Assets/FTemplate/Scripts/FTemplate.asmdef";

#pragma warning disable 0649
		[System.Serializable]
		private class AssemblyDefinitionFile
		{
			public readonly string path;

			public string name;
			public List<string> references;
			public List<string> includePlatforms;
			public List<string> excludePlatforms;
			public bool allowUnsafeCode;
			public bool autoReferenced = true;
			public bool overrideReferences;
			public List<string> precompiledReferences;
			public List<string> defineConstraints;
			public List<string> optionalUnityReferences;

			public bool EditorOnly
			{
				get { return includePlatforms != null && includePlatforms.Count == 1 && includePlatforms[0] == "Editor"; }
				set
				{
					includePlatforms = value ? new List<string>() { "Editor" } : null;
					excludePlatforms = null;
				}
			}

			public AssemblyDefinitionFile( string path )
			{
				this.path = path;

				if( File.Exists( path ) )
					JsonUtility.FromJsonOverwrite( File.ReadAllText( path ), this );
			}

			public void Save()
			{
				File.WriteAllText( path, JsonUtility.ToJson( this, true ) );
			}
		}

		private struct AssemblyDefinitionInfo
		{
			public string path;
			public bool editorOnly;
			public List<string> references;
			public bool referencedByFTemplate;
		}

		private struct SDKIntegrationInfo
		{
			public string name;
			public string compilerDefine;
			public string[] rootDirectories;
			public AssemblyDefinitionInfo[] assemblies;
			public bool assembliesMustPreExist;
		}
#pragma warning restore 0649

		private static readonly SDKIntegrationInfo[] SDK_INTEGRATIONS = new SDKIntegrationInfo[]
		{
			new SDKIntegrationInfo()
			{
				name = "Elephant SDK (Analytics)(Rollic)",
				compilerDefine = "ELEPHANT_ENABLED",
				rootDirectories = new string[1] { "Assets/Elephant" },
				assemblies = new AssemblyDefinitionInfo[2]
				{
					new AssemblyDefinitionInfo()
					{
						path = "Assets/Elephant/ElephantRuntime.asmdef",
						editorOnly = false,
						references = null,
						referencedByFTemplate = true
					},
					new AssemblyDefinitionInfo()
					{
						path = "Assets/Elephant/Editor/ElephantEditor.asmdef",
						editorOnly = true,
						references = new List<string>() { "ElephantRuntime" },
						referencedByFTemplate = false
					}
				},
				assembliesMustPreExist = false
			},
			new SDKIntegrationInfo()
			{
				name = "Facebook SDK (Analytics)",
				compilerDefine = "FACEBOOK_ENABLED",
				rootDirectories = new string[1] { "Assets/FacebookSDK" },
				assemblies = null,
				assembliesMustPreExist = false
			},
			new SDKIntegrationInfo()
			{
				name = "GameAnalytics (Analytics)",
				compilerDefine = "GAMEANALYTICS_ENABLED",
				rootDirectories = new string[1] { "Assets/GameAnalytics" },
				assemblies = new AssemblyDefinitionInfo[2]
				{
					new AssemblyDefinitionInfo()
					{
						path = "Assets/GameAnalytics/Plugins/GameAnalyticsRuntime.asmdef",
						editorOnly = false,
						references = null,
						referencedByFTemplate = true
					},
					new AssemblyDefinitionInfo()
					{
						path = "Assets/GameAnalytics/Editor/GameAnalyticsEditor.asmdef",
						editorOnly = true,
						references = new List<string>() { "GameAnalyticsRuntime" },
						referencedByFTemplate = false
					}
				},
				assembliesMustPreExist = false
			},
			new SDKIntegrationInfo()
			{
				name = "GGI SDK (Ads & Analytics)(Good Job Games)",
				compilerDefine = "GGI_ENABLED",
				rootDirectories = new string[1] { "Assets/GGI" },
				assemblies = new AssemblyDefinitionInfo[2]
				{
					new AssemblyDefinitionInfo()
					{
						path = "Assets/GGI/GGIRuntime.asmdef",
						editorOnly = false,
						references = null,
						referencedByFTemplate = true
					},
					new AssemblyDefinitionInfo()
					{
						path = "Assets/GGI/Scripts/Editor/GGIEditor.asmdef",
						editorOnly = true,
						references = new List<string>() { "GGIRuntime" },
						referencedByFTemplate = false
					}
				},
				assembliesMustPreExist = false
			},
			new SDKIntegrationInfo()
			{
				name = "ironSource (Ads)",
				compilerDefine = "IRONSOURCE_ENABLED",
				rootDirectories = new string[1] { "Assets/IronSource" },
				assemblies = new AssemblyDefinitionInfo[2]
				{
					new AssemblyDefinitionInfo()
					{
						path = "Assets/IronSource/IronSourceRuntime.asmdef",
						editorOnly = false,
						references = null,
						referencedByFTemplate = true
					},
					new AssemblyDefinitionInfo()
					{
						path = "Assets/IronSource/Editor/IronSourceEditor.asmdef",
						editorOnly = true,
						references = new List<string>() { "IronSourceRuntime" },
						referencedByFTemplate = false
					}
				},
				assembliesMustPreExist = false
			},
			new SDKIntegrationInfo()
			{
				name = "LionKit SDK (Ads & Analytics)(Lion Studios)",
				compilerDefine = "LIONKIT_ENABLED",
				rootDirectories = new string[1] { "Packages/com.lionstudios.release.lionkit" },
				assemblies = new AssemblyDefinitionInfo[2]
				{
					new AssemblyDefinitionInfo()
					{
						path = "Packages/com.lionstudios.release.lionkit/LionStudios/Runtime/lionKit.asmdef",
						editorOnly = false,
						references = null,
						referencedByFTemplate = true
					},
					new AssemblyDefinitionInfo()
					{
						path = "Packages/com.lionstudios.release.lionkit/MaxSdk/Scripts/MaxSdk.Scripts.asmdef",
						editorOnly = false,
						references = null,
						referencedByFTemplate = true
					}
				},
				assembliesMustPreExist = true
			}
		};

		private static readonly BuildTargetGroup[] BUILD_TARGETS = new BuildTargetGroup[]
		{
			BuildTargetGroup.Android,
			BuildTargetGroup.iOS,
			BuildTargetGroup.Standalone,
			BuildTargetGroup.WebGL
		};

		private bool[] sdkEnabledStates;

		[MenuItem( "Flamingo/SDK Integrations", priority = 2 )]
		private static void Init()
		{
			SDKIntegrationsWindow window = GetWindow<SDKIntegrationsWindow>();
			window.titleContent = new GUIContent( "SDKs" );
			window.minSize = new Vector2( 300f, 150f );
			window.Show();
		}

		private void OnEnable()
		{
			// Unity serializes this array during compilation so that its data persists, don't recreate it unless necessary
			if( sdkEnabledStates == null || sdkEnabledStates.Length != SDK_INTEGRATIONS.Length )
			{
				sdkEnabledStates = new bool[SDK_INTEGRATIONS.Length];
				for( int i = 0; i < sdkEnabledStates.Length; i++ )
					sdkEnabledStates[i] = IsSDKEnabled( SDK_INTEGRATIONS[i] );
			}
		}

		private void OnGUI()
		{
			for( int i = 0; i < SDK_INTEGRATIONS.Length; i++ )
			{
				SDKIntegrationInfo sdk = SDK_INTEGRATIONS[i];

				GUI.enabled = IsSDKImported( sdk );
				sdkEnabledStates[i] = EditorGUILayout.ToggleLeft( sdk.name, sdkEnabledStates[i] );
				GUI.enabled = true;
			}

			EditorGUILayout.Space();

			if( GUILayout.Button( "Apply Changes" ) )
			{
				AssetDatabase.StartAssetEditing();
				try
				{
					for( int i = 0; i < SDK_INTEGRATIONS.Length; i++ )
					{
						SDKIntegrationInfo sdk = SDK_INTEGRATIONS[i];
						if( IsSDKImported( sdk ) )
							SetSDKEnabled( sdk, sdkEnabledStates[i] );
					}
				}
				finally
				{
					AssetDatabase.StopAssetEditing();
					AssetDatabase.Refresh();
				}
			}
		}

		private bool IsSDKImported( SDKIntegrationInfo sdk )
		{
			for( int i = 0; i < sdk.rootDirectories.Length; i++ )
			{
				if( !AssetDatabase.IsValidFolder( sdk.rootDirectories[i] ) )
					return false;
			}

			if( sdk.assembliesMustPreExist && sdk.assemblies != null )
			{
				for( int i = 0; i < sdk.assemblies.Length; i++ )
				{
					if( !File.Exists( sdk.assemblies[i].path ) )
						return false;
				}
			}

			return true;
		}

		private bool IsSDKEnabled( SDKIntegrationInfo sdk )
		{
			return PlayerSettings.GetScriptingDefineSymbolsForGroup( EditorUserBuildSettings.selectedBuildTargetGroup ).Contains( sdk.compilerDefine );
		}

		private void SetSDKEnabled( SDKIntegrationInfo sdk, bool enabled )
		{
			for( int i = 0; i < sdk.rootDirectories.Length; i++ )
			{
				if( !Directory.Exists( sdk.rootDirectories[i] ) )
				{
					Debug.LogError( "Couldn't " + ( enabled ? "enable" : "disable" ) + " " + sdk.name + "! Directory doesn't exist: " + sdk.rootDirectories[i] );
					return;
				}
			}

			if( sdk.assemblies != null )
			{
				for( int i = 0; i < sdk.assemblies.Length; i++ )
				{
					string assemblyDir = Path.GetDirectoryName( sdk.assemblies[i].path );
					if( !Directory.Exists( assemblyDir ) )
					{
						Debug.LogError( "Couldn't " + ( enabled ? "enable" : "disable" ) + " " + sdk.name + "! Directory doesn't exist: " + assemblyDir );
						return;
					}
				}

				ModifyAssemblyDefinitionFiles( sdk, enabled );
			}

			ModifyCompilerDefines( sdk, enabled );
		}

		private void ModifyCompilerDefines( SDKIntegrationInfo sdk, bool enabled )
		{
			// Credit: https://wiki.unity3d.com/index.php/Custom_Defines_Manager
			string compilerDefine = sdk.compilerDefine;
			for( int i = 0; i < BUILD_TARGETS.Length; i++ )
			{
				string defines = PlayerSettings.GetScriptingDefineSymbolsForGroup( BUILD_TARGETS[i] );
				if( enabled )
				{
					if( defines.Contains( compilerDefine ) )
						continue;

					if( defines.Length > 0 )
						defines += ";";

					defines += compilerDefine;
				}
				else
				{
					int index = defines.IndexOf( compilerDefine );
					if( index < 0 )
						continue;

					if( index > 0 )
						defines = defines.Remove( index - 1, compilerDefine.Length + 1 ); // Semicolon at the beginning
					else if( index < defines.Length - compilerDefine.Length )
						defines = defines.Remove( index, compilerDefine.Length + 1 ); // Semicolon at the end
					else
						defines = defines.Remove( index, compilerDefine.Length );
				}

				PlayerSettings.SetScriptingDefineSymbolsForGroup( BUILD_TARGETS[i], defines );
			}
		}

		private void ModifyAssemblyDefinitionFiles( SDKIntegrationInfo sdk, bool enabled )
		{
			AssemblyDefinitionInfo[] assemblies = sdk.assemblies;
			AssemblyDefinitionFile fAssembly = new AssemblyDefinitionFile( FTEMPLATE_ASSEMBLY_DEFINITION_PATH );
			bool fAssemblyModified = false;

			if( !enabled )
			{
				List<string> references = fAssembly.references;
				
				if( references == null )
					return;

				for( int i = 0; i < assemblies.Length; i++ )
				{
					if( assemblies[i].referencedByFTemplate && File.Exists( assemblies[i].path ) )
					{
						string assemblyName = new AssemblyDefinitionFile( assemblies[i].path ).name;

						if( references.Contains( assemblyName ) )
						{
							Debug.Log( "Removing assembly reference: " + assemblies[i].path );

							references.Remove( assemblyName );
							fAssemblyModified = true;
						}
					}
				}
			}
			else
			{
				if( fAssembly.references == null )
					fAssembly.references = new List<string>();

				for( int i = 0; i < assemblies.Length; i++ )
				{
					AssemblyDefinitionInfo assembly = assemblies[i];
					string assemblyName;
					if( sdk.assembliesMustPreExist || File.Exists( assembly.path ) )
						assemblyName = new AssemblyDefinitionFile( assembly.path ).name;
					else
					{
						Debug.Log( "Creating Assembly Definition File: " + assembly.path );

						assemblyName = Path.GetFileNameWithoutExtension( assembly.path );
						AssemblyDefinitionFile assemblyDefinitionFile = new AssemblyDefinitionFile( assembly.path )
						{
							name = assemblyName,
							references = assembly.references,
							EditorOnly = assembly.editorOnly
						};

						assemblyDefinitionFile.Save();
					}

					if( assembly.referencedByFTemplate && !fAssembly.references.Contains( assemblyName ) )
					{
						Debug.Log( "Adding assembly reference: " + assembly.path );

						fAssembly.references.Add( assemblyName );
						fAssemblyModified = true;
					}
				}
			}

			if( fAssemblyModified )
				fAssembly.Save();
		}
	}
}