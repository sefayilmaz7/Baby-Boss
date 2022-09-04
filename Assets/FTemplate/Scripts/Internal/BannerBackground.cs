using UnityEngine;
using UnityEngine.UI;

namespace FTemplateNamespace
{
	public class BannerBackground : MonoBehaviour
	{
#pragma warning disable 0649
		[SerializeField]
		private Image background;
		private RectTransform backgroundTransform;

		[SerializeField]
		private Canvas canvas;
#pragma warning restore 0649

		private void Awake()
		{
			backgroundTransform = background.rectTransform;
		}

		private void OnEnable()
		{
			FTemplate.Ads.OnBannerAdVisibilityChanged -= BannerAdVisibilityChanged;
			FTemplate.Ads.OnBannerAdVisibilityChanged += BannerAdVisibilityChanged;

			BannerAdVisibilityChanged( FTemplate.Ads.BannerAdVisible );
		}

		private void OnDisable()
		{
			FTemplate.Ads.OnBannerAdVisibilityChanged -= BannerAdVisibilityChanged;
		}

		public void SetActive( bool isActive )
		{
			canvas.gameObject.SetActive( isActive );
		}

		public void SetColor( Color color )
		{
			background.color = color;
		}

		private void BannerAdVisibilityChanged( bool isVisible )
		{
			background.enabled = isVisible;

			if( isVisible )
			{
				Vector2 anchorMin = backgroundTransform.anchorMin;
				Vector2 anchorMax = backgroundTransform.anchorMax;
				Vector2 pivot = backgroundTransform.pivot;
				Vector2 sizeDelta = backgroundTransform.sizeDelta;

				sizeDelta.y = FTemplate.Ads.BannerAdHeightInPixels;
				if( FTemplate.Ads.BannerAdAtBottom )
				{
					anchorMin.y = 0f;
					anchorMax.y = 0f;
					pivot.y = 0f;
					sizeDelta.y += Screen.height - Screen.safeArea.yMax;
				}
				else
				{
					anchorMin.y = 1f;
					anchorMax.y = 1f;
					pivot.y = 1f;
					sizeDelta.y += Screen.safeArea.yMin;
				}

				backgroundTransform.anchorMin = anchorMin;
				backgroundTransform.anchorMax = anchorMax;
				backgroundTransform.pivot = pivot;
				backgroundTransform.sizeDelta = sizeDelta;
			}
		}
	}
}