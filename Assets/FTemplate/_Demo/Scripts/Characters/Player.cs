using DG.Tweening;
using UnityEngine;

namespace FTemplateNamespace.Demo
{
	public class Player : Character
	{
		private Camera _camera;
		private Transform cameraTransform;

		public Vector3 cameraOffset;
		private Vector3 cameraForward, cameraRight;

		private void Start()
		{
			_camera = Camera.main;
			cameraTransform = _camera.transform;
			cameraTransform.position = m_rigidbody.position + cameraOffset;

			cameraForward = cameraTransform.forward;
			cameraForward.y = 0f;
			cameraForward.Normalize();

			cameraRight = cameraTransform.right;
			cameraRight.y = 0f;
			cameraRight.Normalize();
		}

		public void OnLevelStarted()
		{
			if( FTemplate.Gallery.PlayingBonusLevel )
				strength = 100f;
		}

		protected override void Update()
		{
			base.Update();

			if( GameManager.Instance.IsPlaying )
				targetDirection = cameraForward * SimpleInput.GetAxis( "Vertical" ) + cameraRight * SimpleInput.GetAxis( "Horizontal" );
			else
				targetDirection = Vector3.zero;
		}

		protected override void FixedUpdate()
		{
			base.FixedUpdate();
			cameraTransform.position = Vector3.Lerp( cameraTransform.position, m_rigidbody.position + cameraOffset, 0.25f );
		}

		protected override void CollidedWithCharacter( Collision collision )
		{
			base.CollidedWithCharacter( collision );

			_camera.DOKill( true );
			DOTween.Punch( () => new Vector3( _camera.orthographicSize, _camera.orthographicSize, _camera.orthographicSize ), ( v ) => _camera.orthographicSize = v.x, new Vector3( 1, 1, 1 ), 1f, 10 ).SetTarget( _camera );
		}
	}
}