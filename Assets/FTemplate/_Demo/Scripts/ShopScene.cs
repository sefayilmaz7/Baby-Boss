using DG.Tweening;
using System.Collections.Generic;
using UnityEngine;

namespace FTemplateNamespace.Demo
{
	// Active (currently selected) shop customizations are previewed in this scene
	public class ShopScene : MonoBehaviour
	{
#pragma warning disable 0649
		// Customizations are applied to these objects
		[System.Serializable]
		private struct ShopCategoryProperties
		{
			public string Category;
			public int Group; // Categories belonging to the same group are previewed together
			public Transform PreviewTarget;
			public Object EditorPreview; // This object is used only as a placeholder in the Scene to have a visual clue about how the scene will look
		}

		[SerializeField]
		private Transform cameraParent;

		[SerializeField]
		private float cameraRotationSpeed = 60f;

		[SerializeField]
		private ShopCategoryProperties[] categories;
#pragma warning restore 0649

		private GameObject[] activeItems;
		private GameObject[] activeItemPrefabs;

		private void Awake()
		{
			activeItems = new GameObject[categories.Length];
			activeItemPrefabs = new GameObject[categories.Length];

			// Destroy placeholder objects
			for( int i = 0; i < categories.Length; i++ )
				Destroy( categories[i].EditorPreview );
		}

		private void Start()
		{
			// Hide all UI elements immediately (duration: 0f) and then show shop menu
			FTemplate.UI.HideAllUIElements( 0f );
			FTemplate.UI.Show( UIElementType.ShopMenu );

			// Register to customization change events of Shop
			FTemplate.Shop.OnActiveTabChanged += OnActiveShopTabChanged;
			FTemplate.Shop.OnCustomizationChanged += OnCustomizationChanged;

			// Refresh displayed customizations
			OnActiveShopTabChanged( FTemplate.Shop.GetActiveTab() );
		}

		private void OnDisable()
		{
			// Unregister from customization change events of Shop
			FTemplate.Shop.OnActiveTabChanged -= OnActiveShopTabChanged;
			FTemplate.Shop.OnCustomizationChanged -= OnCustomizationChanged;

			// If a DOTween animation is running in this scene, force kill it. Otherwise DOTween complains about it
			DOTween.KillAll();
		}

		private void Update()
		{
			// Rotate the camera around previewed customizations
			if( cameraRotationSpeed != 0f )
				cameraParent.Rotate( new Vector3( 0f, cameraRotationSpeed * Time.deltaTime, 0f ) );
		}

		private void OnActiveShopTabChanged( ShopConfiguration.TabHolder activeTab )
		{
			RefreshCustomizations( true );
		}

		private void OnCustomizationChanged( List<CustomizationItem> customizations )
		{
			RefreshCustomizations( false );
		}

		private void RefreshCustomizations( bool hasTabChanged )
		{
			List<CustomizationItem> customizations = FTemplate.Shop.GetActiveCustomizations();

			// Find the currently active shop tab's group
			string activeShopTabCategory = FTemplate.Shop.GetActiveTab().DefaultItem.Category;
			int activeGroup = 0;
			for( int i = 0; i < categories.Length; i++ )
			{
				if( categories[i].Category == activeShopTabCategory )
				{
					activeGroup = categories[i].Group;
					break;
				}
			}

			for( int i = 0; i < customizations.Count; i++ )
			{
				CustomizationItem customization = customizations[i];
				if( !customization )
					continue;

				// Check if this customization can be previewed
				int index = -1;
				for( int j = 0; j < categories.Length; j++ )
				{
					if( categories[j].Category == customization.Category )
					{
						index = j;
						break;
					}
				}

				// The customization can't be previewed
				if( index < 0 )
					continue;

				if( categories[index].Group == activeGroup )
					categories[index].PreviewTarget.gameObject.SetActive( true );
				else
				{
					// Don't show preview objects of the inactive groups
					categories[index].PreviewTarget.gameObject.SetActive( false );
					continue;
				}

				Transform modifiedObject = null;

				if( customization is CustomizationGameObject ) // Customization is a GameObject
				{
					// Check if the GameObject is already in the scene
					CustomizationGameObject _customization = (CustomizationGameObject) customization;
					if( activeItems[index] && activeItemPrefabs[index] == _customization.Prefab )
						continue;

					// Instantiate the customization item
					Transform newItem = _customization.Instantiate( categories[index].PreviewTarget );
					if( newItem )
					{
						// Remove the previous customization item in the same category, if exists
						if( activeItems[index] )
						{
							DOTween.Kill( activeItems[index].transform );
							Destroy( activeItems[index] );
						}

						activeItems[index] = newItem.gameObject;
						activeItemPrefabs[index] = _customization.Prefab;

						modifiedObject = activeItems[index].transform;
					}
				}
				else if( customization is CustomizationMaterial ) // Customization is a material
				{
					// Apply the material to the preview target
					Renderer renderer = categories[index].PreviewTarget.GetComponent<Renderer>();
					if( renderer && ( (CustomizationMaterial) customization ).ApplyTo( renderer ) )
						modifiedObject = categories[index].PreviewTarget;
				}
				else if( customization is CustomizationTexture ) // Customization is a Texture
				{
					// Apply the texture to the preview target
					Renderer renderer = categories[index].PreviewTarget.GetComponent<Renderer>();
					if( renderer && ( (CustomizationTexture) customization ).ApplyTo( renderer ) )
						modifiedObject = categories[index].PreviewTarget;
				}

				// Play a nice punch scale animation on the changed customization item since it looks C00L
				// Don't play this animation while switching tabs, though
				if( modifiedObject && !hasTabChanged )
				{
					DOTween.Kill( modifiedObject );
					modifiedObject.DOPunchScale( modifiedObject.localScale * 0.2f, 0.5f );
				}
			}
		}
	}
}