using FTemplateNamespace;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class PointerEventListener : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
{
	private const int NULL_POINTER_ID = -98754;
	private int pointerId;

	public event System.Action<PointerEventData> PointerDown, PointerDrag, PointerUp;

	private void Awake()
	{
		Graphic graphic = GetComponent<Graphic>();
		if( graphic == null )
			graphic = gameObject.AddComponent<NonDrawingGraphic>();

		graphic.raycastTarget = true;
	}

	private void OnDisable()
	{
		if( pointerId != NULL_POINTER_ID )
		{
			PointerEventData eventData = new PointerEventData( EventSystem.current ) { pointerId = pointerId };
#if UNITY_EDITOR || UNITY_STANDALONE
			eventData.position = Input.mousePosition;
#elif UNITY_ANDROID || UNITY_IOS
			if( Input.touchCount > 0 )
			{
				eventData.position = Input.GetTouch( 0 ).position;

				for( int i = 0; i < Input.touchCount; i++ )
				{
					Touch touch = Input.GetTouch( i );
					if( touch.fingerId == pointerId )
					{
						eventData.position = touch.position;
						break;
					}
				}
			}
#endif

			( (IPointerUpHandler) this ).OnPointerUp( eventData );
		}
	}

	void IPointerDownHandler.OnPointerDown( PointerEventData eventData )
	{
		if( !enabled )
			return;

		pointerId = eventData.pointerId;

		if( PointerDown != null )
			PointerDown( eventData );
	}

	void IDragHandler.OnDrag( PointerEventData eventData )
	{
		if( pointerId == eventData.pointerId && PointerDrag != null )
			PointerDrag( eventData );
	}

	void IPointerUpHandler.OnPointerUp( PointerEventData eventData )
	{
		if( pointerId == eventData.pointerId )
		{
			if( PointerUp != null )
				PointerUp( eventData );

			pointerId = NULL_POINTER_ID;
		}
	}
}