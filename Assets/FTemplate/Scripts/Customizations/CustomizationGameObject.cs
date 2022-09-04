using UnityEngine;

[CreateAssetMenu( fileName = "Customization", menuName = "Flamingo/Customization (GameObject)", order = 111 )]
public class CustomizationGameObject : CustomizationItem
{
#pragma warning disable 0649
	[SerializeField]
	private CustomizationObjectHolder m_prefab;
	public GameObject Prefab { get { return m_prefab.GetObject<GameObject>(); } }

	[SerializeField]
	private Vector3 m_position;
	public Vector3 Position { get { return m_position; } }

	[SerializeField]
	private Vector3 m_rotation;
	public Vector3 Rotation { get { return m_rotation; } }

	[SerializeField]
	private Vector3 m_scale = Vector3.one;
	public Vector3 Scale { get { return m_scale; } }
#pragma warning restore 0649

	public Transform Instantiate( Transform parent )
	{
		GameObject _prefab = Prefab;
		if( !_prefab )
			return null;

		Transform instance = Instantiate( _prefab, parent, false ).transform;
		instance.localPosition = m_position;
		instance.localEulerAngles = m_rotation;
		instance.localScale = m_scale;

		return instance;
	}
}