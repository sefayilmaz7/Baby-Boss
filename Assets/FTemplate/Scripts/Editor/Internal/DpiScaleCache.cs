using UnityEditor;
using UnityEditor.Build.Reporting;

namespace FTemplateNamespace
{
	public class DpiScaleCache : UnityEditor.Build.IPreprocessBuildWithReport
	{
		public int callbackOrder { get { return 0; } }

		public void OnPreprocessBuild( BuildReport report )
		{
			// Set all AdsConfiguration assets' DpiScaling property to Target DPI defined in Player Settings (or 0 if it is disabled)
			// so that AdsModule can correctly calculate banner ads' sizes even when Resolution Scaling is enabled
			int? resolutionScalingMode = null, dpiScaling = null;
			SerializedProperty iterator = new SerializedObject( AssetDatabase.LoadMainAssetAtPath( "ProjectSettings/ProjectSettings.asset" ) ).GetIterator();
			if( iterator.NextVisible( true ) )
			{
				do
				{
					if( iterator.name == "resolutionScalingMode" )
					{
						resolutionScalingMode = iterator.intValue;
						if( resolutionScalingMode.HasValue && dpiScaling.HasValue )
							break;
					}
					else if( iterator.name == "targetPixelDensity" )
					{
						dpiScaling = iterator.intValue;
						if( resolutionScalingMode.HasValue && dpiScaling.HasValue )
							break;
					}
				}
				while( iterator.NextVisible( false ) );
			}

			if( !resolutionScalingMode.HasValue || resolutionScalingMode.Value == 0 || !dpiScaling.HasValue )
				dpiScaling = 0;

			string[] adsConfigurations = AssetDatabase.FindAssets( "t:FTemplateNamespace.AdsConfiguration" );
			for( int i = 0; i < adsConfigurations.Length; i++ )
			{
				SerializedObject so = new SerializedObject( AssetDatabase.LoadAssetAtPath<AdsConfiguration>( AssetDatabase.GUIDToAssetPath( adsConfigurations[i] ) ) );
				so.FindProperty( "DpiScaling" ).intValue = dpiScaling.Value;
				so.ApplyModifiedPropertiesWithoutUndo();
			}
		}
	}
}