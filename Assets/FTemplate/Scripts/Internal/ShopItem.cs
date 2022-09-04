using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace FTemplateNamespace
{
	public class ShopItem : MonoBehaviour
	{
#pragma warning disable 0649
		[SerializeField]
		private Image icon;

		[SerializeField]
		private TextMeshProUGUI priceText;

		[SerializeField]
		private GameObject lockIcon;

		[SerializeField]
		private GameObject coinIcon;
#pragma warning restore 0649

		public CustomizationItem CustomizationItem { get; private set; }
		public bool IsUnlocked { get; private set; }

		public void Initialize( CustomizationItem customizationItem, bool isUnlocked, bool showPrice )
		{
			CustomizationItem = customizationItem;
			IsUnlocked = isUnlocked;

			icon.sprite = customizationItem.Icon;

			if( isUnlocked )
			{
				icon.color = new Color( 1f, 1f, 1f, 1f );
				lockIcon.SetActive( false );
			}
			else
			{
				icon.color = FTemplate.Shop.LockedItemColor;
				lockIcon.SetActive( true );
			}

			if( isUnlocked || !showPrice )
			{
				coinIcon.SetActive( false );
				priceText.SetText( "" );
			}
			else
			{
				coinIcon.SetActive( true );
				priceText.SetText( customizationItem.Price );
			}
		}
	}
}