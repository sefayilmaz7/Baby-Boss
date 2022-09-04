using UnityEngine;

[CreateAssetMenu( fileName = "Customization", menuName = "Flamingo/Customization (Texture)", order = 111 )]
public class CustomizationTexture : CustomizationItem
{
#pragma warning disable 0649
	[System.Serializable]
	public class TextureData
	{
		public CustomizationObjectHolder Texture;
		public int MaterialIndex;
		public string MaterialProperty = "_MainTex";
		public string MaterialFallbackProperty = "_BaseMap";
	}

	[SerializeField]
	private TextureData[] m_textures;
	public TextureData[] Textures { get { return m_textures; } }
	public Texture Texture { get { return m_textures[0].Texture.GetObject<Texture>(); } }
#pragma warning restore 0649

	public bool ApplyTo( Renderer renderer )
	{
		if( m_textures.Length == 0 )
		{
			renderer.enabled = false;
			return true;
		}

		renderer.enabled = true;

		bool hasChanged = false;
		if( m_textures.Length == 1 && m_textures[0].MaterialIndex <= 0 )
		{
			Texture _texture = m_textures[0].Texture.GetObject<Texture>();
			if( _texture )
			{
				string propName = renderer.material.HasProperty( m_textures[0].MaterialProperty ) ? m_textures[0].MaterialProperty : m_textures[0].MaterialFallbackProperty;
				if( renderer.material.GetTexture( propName ) != _texture )
				{
					renderer.material.SetTexture( propName, _texture );
					hasChanged = true;
				}
			}
		}
		else
		{
			Material[] materials = renderer.materials;
			for( int i = 0; i < m_textures.Length; i++ )
			{
				Texture _texture = m_textures[i].Texture.GetObject<Texture>();
				if( _texture )
				{
					int clampedMaterialIndex = Mathf.Clamp( m_textures[i].MaterialIndex, 0, materials.Length - 1 );
					string propName = materials[clampedMaterialIndex].HasProperty( m_textures[i].MaterialProperty ) ? m_textures[i].MaterialProperty : m_textures[i].MaterialFallbackProperty;
					if( materials[clampedMaterialIndex].GetTexture( propName ) != _texture )
					{
						materials[clampedMaterialIndex].SetTexture( propName, _texture );
						hasChanged = true;
					}
				}
			}

			renderer.materials = materials;
		}

		return hasChanged;
	}
}