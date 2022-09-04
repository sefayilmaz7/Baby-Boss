using UnityEngine;
using UnityEngine.UI;

namespace FTemplateNamespace
{
	public class ShopTab : MonoBehaviour
	{
#pragma warning disable 0649
		[SerializeField]
		private Image m_icon;
		public Image Icon { get { return m_icon; } }

		[SerializeField]
		private Image m_background;
		public Image Background { get { return m_background; } }

		[SerializeField]
		private Button m_button;
		public Button Button { get { return m_button; } }
#pragma warning restore 0649
	}
}