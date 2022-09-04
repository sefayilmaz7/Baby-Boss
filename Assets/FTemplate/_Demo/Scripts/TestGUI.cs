using UnityEngine;

namespace FTemplateNamespace.Demo
{
	// Creates OnGUI buttons for testing the different features of FTemplate
	public class TestGUI : MonoBehaviour
	{
#if UNITY_EDITOR
		private const float MIN_WIDTH = 150f;

		private int uiElementCount = 13;

		private float showDuration = -0.5f;
		private float hideDuration = -0.5f;

		private int totalCoins = 0;
		private int progress = 0;

		private void Awake()
		{
			uiElementCount = System.Enum.GetValues( typeof( UIElementType ) ).Length;
		}

		private void OnGUI()
		{
			#region UI Elements
			GUILayout.BeginHorizontal();

			GUILayout.BeginVertical( GUILayout.MinWidth( MIN_WIDTH ) );
			GUILayout.Box( "SHOW" );
			showDuration = FloatField( "Duration: ", showDuration, -1f, 5f );
			for( int i = 0; i < uiElementCount; i++ )
			{
				if( System.Enum.IsDefined( typeof( UIElementType ), i ) && GUILayout.Button( ( (UIElementType) i ).ToString() ) )
					FTemplate.UI.Show( (UIElementType) i, showDuration );
			}
			GUILayout.EndVertical();

			GUILayout.BeginVertical( GUILayout.MinWidth( MIN_WIDTH ) );
			GUILayout.Box( "HIDE" );
			hideDuration = FloatField( "Duration: ", hideDuration, -1f, 5f );
			for( int i = 0; i < uiElementCount; i++ )
			{
				if( System.Enum.IsDefined( typeof( UIElementType ), i ) && GUILayout.Button( ( (UIElementType) i ).ToString() ) )
					FTemplate.UI.Hide( (UIElementType) i, hideDuration );
			}
			GUILayout.EndVertical();

			GUILayout.BeginVertical( GUILayout.MinWidth( MIN_WIDTH ) );
			GUILayout.Box( "PARAMS" );
			int _totalCoins = IntField( "Coins: ", totalCoins, 0, 100 );
			int _progress = IntField( "Progress: ", progress, 0, 4 );
			UIModule.LevelFailedMenu levelFailedMenuType = (UIModule.LevelFailedMenu) IntField( "LevelFail Type: ", (int) FTemplate.UI.LevelFailedMenuType, 0, 1 );
			UIModule.BonusLevelRewardMenu bonusLevelRewardMenuType = (UIModule.BonusLevelRewardMenu) IntField( "BonusReward Type: ", (int) FTemplate.UI.BonusLevelRewardMenuType, 0, 1 );
			if( GUILayout.Button( "Spawn Coins" ) )
				FTemplate.UI.SpawnCollectedCoins( new Vector2( Screen.width * 0.5f, Screen.height * 0.5f ), Random.Range( 1, 10 ), 10 );
			if( GUILayout.Button( "Play Next Unlock Anim" ) )
				FTemplate.UI.PlayNextUnlockAnimation();
			if( GUILayout.Button( "Show Dialog" ) )
				FTemplate.UI.ShowDialog( "Time: " + Time.time, () => Debug.Log( "YES" ), () => Debug.Log( "NO" ) );
			GUILayout.EndVertical();

			GUILayout.EndHorizontal();
			#endregion

			if( totalCoins != _totalCoins )
			{
				totalCoins = _totalCoins;
				FTemplate.UI.SetTotalCoins( totalCoins, true );
			}

			if( progress != _progress )
			{
				progress = _progress;
				FTemplate.UI.SetProgress( progress + 5, progress, true );
			}

			if( FTemplate.UI.LevelFailedMenuType != levelFailedMenuType )
			{
				bool isLevelFailedMenuVisible = FTemplate.UI.IsVisible( UIElementType.LevelFailedMenu );
				if( isLevelFailedMenuVisible )
					FTemplate.UI.Hide( UIElementType.LevelFailedMenu, 0f );

				FTemplate.UI.LevelFailedMenuType = levelFailedMenuType;

				if( isLevelFailedMenuVisible )
					FTemplate.UI.Show( UIElementType.LevelFailedMenu );
			}

			if( FTemplate.UI.BonusLevelRewardMenuType != bonusLevelRewardMenuType )
			{
				bool isBonusLevelRewardMenuVisible = FTemplate.UI.IsVisible( UIElementType.BonusLevelRewardMenu );
				if( isBonusLevelRewardMenuVisible )
					FTemplate.UI.Hide( UIElementType.BonusLevelRewardMenu, 0f );

				FTemplate.UI.BonusLevelRewardMenuType = bonusLevelRewardMenuType;

				if( isBonusLevelRewardMenuVisible )
					FTemplate.UI.Show( UIElementType.BonusLevelRewardMenu );
			}
		}

		private int IntField( string label, int value, int min, int max )
		{
			GUILayout.BeginHorizontal();
			GUILayout.Label( label + value );
			value = (int) GUILayout.HorizontalSlider( value, min, max );
			GUILayout.EndHorizontal();

			return value;
		}

		private float FloatField( string label, float value, float min, float max )
		{
			GUILayout.BeginHorizontal();
			GUILayout.Label( label + value.ToString( "F1" ) );
			value = GUILayout.HorizontalSlider( value, min, max );
			GUILayout.EndHorizontal();

			return value;
		}
#endif
	}
}