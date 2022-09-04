using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace FTemplateNamespace
{
	public class CurrencyIconHolder : MonoBehaviour
	{
		private static readonly List<CurrencyIconHolder> instances = new List<CurrencyIconHolder>( 64 );

		private Image image;

		private static Sprite m_icon;
		public static Sprite Icon
		{
			get { return m_icon; }
			set
			{
				if( m_icon != value )
				{
					m_icon = value;

					for( int i = 0; i < instances.Count; i++ )
						instances[i].image.sprite = m_icon;
				}
			}
		}

		private void Awake()
		{
			image = GetComponent<Image>();
			instances.Add( this );

			if( m_icon )
				image.sprite = m_icon;
		}

		private void OnDestroy()
		{
			instances.Remove( this );
		}
	}
}