using UnityEditor;
using UnityEditor.Callbacks;
#if UNITY_IOS
using System.IO;
using UnityEditor.iOS.Xcode;
#endif

namespace FTemplateNamespace
{
	public class BuildPostProcessor
	{
		[PostProcessBuild( 1 )]
		public static void OnPostprocessBuild( BuildTarget buildTarget, string pathToBuiltProject )
		{
#if UNITY_IOS
			// Credit: https://forum.unity.com/threads/the-info-plist-contains-a-key-uiapplicationexitsonsuspend.689200/#post-4612135
			string plistPath = pathToBuiltProject + "/Info.plist";
			PlistDocument plist = new PlistDocument();
			plist.ReadFromString( File.ReadAllText( plistPath ) );
			PlistElementDict rootDict = plist.root;

			// Set encryption usage boolean
			string encryptKey = "ITSAppUsesNonExemptEncryption";
			rootDict.SetBoolean( encryptKey, false );

			// Remove exit on suspend if exists
			string exitsOnSuspendKey = "UIApplicationExitsOnSuspend";
			if( rootDict.values.ContainsKey( exitsOnSuspendKey ) )
				rootDict.values.Remove( exitsOnSuspendKey );

			// Save changes
			File.WriteAllText( plistPath, plist.WriteToString() );
#endif
		}
	}
}