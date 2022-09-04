using UnityEngine;

[CreateAssetMenu( fileName = "Customization", menuName = "Flamingo/Customization (Material)", order = 111 )]
public class CustomizationMaterial : CustomizationItem
{
#pragma warning disable 0649
	[System.Serializable]
	public class MaterialData
	{
		public CustomizationObjectHolder Material;
		public int MaterialIndex;
	}

	[SerializeField]
	private MaterialData[] m_materials;
	public MaterialData[] Materials { get { return m_materials; } }
	public Material Material { get { return m_materials[0].Material.GetObject<Material>(); } }
#pragma warning restore 0649

	public bool ApplyTo( Renderer renderer )
	{
		if( m_materials.Length == 0 )
			return false;

		bool hasChanged = false;
		if( m_materials.Length == 1 && m_materials[0].MaterialIndex <= 0 )
		{
			Material _material = m_materials[0].Material.GetObject<Material>();
			if( _material && renderer.sharedMaterial != _material )
			{
				renderer.sharedMaterial = _material;
				hasChanged = true;
			}
		}
		else
		{
			Material[] materials = renderer.sharedMaterials;
			for( int i = 0; i < m_materials.Length; i++ )
			{
				Material _material = m_materials[i].Material.GetObject<Material>();
				if( _material )
				{
					int clampedMaterialIndex = Mathf.Clamp( m_materials[i].MaterialIndex, 0, materials.Length - 1 );
					if( materials[clampedMaterialIndex] != _material )
					{
						materials[clampedMaterialIndex] = _material;
						hasChanged = true;
					}
				}
			}

			renderer.sharedMaterials = materials;
		}

		return hasChanged;
	}
}