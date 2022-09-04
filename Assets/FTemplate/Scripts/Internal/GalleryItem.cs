using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace FTemplateNamespace
{
	public class GalleryItem : MonoBehaviour
	{
#pragma warning disable 0649
		[SerializeField]
		private Image m_background;
		public Image Background { get { return m_background; } }

		[SerializeField]
		private Image icon;

		[SerializeField]
		private TextMeshProUGUI highscoreText;

		[SerializeField]
		private GameObject lockIcon;
#pragma warning restore 0649

		public GalleryConfiguration.LevelHolder Level { get; private set; }
		public bool IsUnlocked { get; private set; }

		public void Initialize( GalleryConfiguration.LevelHolder level, int highscore )
		{
			Level = level;
			IsUnlocked = highscore >= 0;

			icon.sprite = level.Icon;

			if( highscore >= 0 )
			{
				icon.color = Color.white;
				highscoreText.SetText( highscore, "Score: ", "%" );
				lockIcon.SetActive( false );
			}
			else
			{
				icon.color = FTemplate.Gallery.LockedItemColor;
				highscoreText.SetText( "Score: -" );
				lockIcon.SetActive( true );
			}
		}
	}
}