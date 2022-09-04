using DG.Tweening;
using FTemplateNamespace;
using UnityEngine;

namespace FTemplateNamespace.Demo
{
	public abstract class Character : MonoBehaviour
	{
		public Color materialColor;
		protected Rigidbody m_rigidbody;

		public float speed = 20f;

		protected float strength = 1f;
		protected Vector3 targetDirection;

		private float inputHorizontal;
		private float inputVertical;

		private void Awake()
		{
			GetComponent<Renderer>().material.color = materialColor;
			m_rigidbody = GetComponent<Rigidbody>();
		}

		protected virtual void Update()
		{
			if( targetDirection.sqrMagnitude <= 0.001f )
			{
				inputHorizontal = Mathf.Lerp( inputHorizontal, 0f, 0.25f );
				inputVertical = Mathf.Lerp( inputVertical, 0f, 0.25f );
			}
			else
			{
				// Smoothly rotate character towards target direction
				Vector3 forward = transform.forward;
				if( forward.y != 0f )
				{
					forward.y = 0f;
					forward.Normalize();
				}

				if( targetDirection.y != 0f )
				{
					targetDirection.y = 0f;
					targetDirection.Normalize();
				}

				float rotation = Quaternion.FromToRotation( forward, targetDirection ).eulerAngles.y;
				if( rotation > 180f )
					rotation -= 360f;

				float horizontalInput;
				if( rotation > 5f )
					horizontalInput = 1f;
				else if( rotation < -5f )
					horizontalInput = -1f;
				else
					horizontalInput = 0f;

				inputHorizontal = Mathf.Lerp( inputHorizontal, horizontalInput, 0.25f );
				inputVertical = 1f - Mathf.Abs( rotation / 180f );

				transform.Rotate( 0f, inputHorizontal * 5f, 0f, Space.World );
			}
		}

		protected virtual void FixedUpdate()
		{
			m_rigidbody.AddRelativeForce( new Vector3( 0f, 0f, inputVertical ) * speed );
		}

		private void OnCollisionEnter( Collision collision )
		{
			if( collision.gameObject.CompareTag( "Player" ) )
			{
				// Scale the collided characters for a C00L effect
				transform.DOKill( true );
				transform.DOScale( transform.localScale * 1.25f, 0.25f ).SetLoops( 2, LoopType.Yoyo ).SetEase( Ease.Linear );

				m_rigidbody.AddForce( collision.GetContact( 0 ).normal * 4f / strength, ForceMode.Impulse );
				CollidedWithCharacter( collision );
			}
		}

		private void OnTriggerEnter( Collider other )
		{
			if( enabled && other.CompareTag( "Finish" ) )
			{
				enabled = false;
				m_rigidbody.constraints = RigidbodyConstraints.None;

				GameManager.Instance.CharacterDied( this );
			}
		}

		private bool IsGrounded()
		{
			return Physics.Raycast( transform.position, Vector3.down, 1.75f );
		}

		protected virtual void CollidedWithCharacter( Collision collision )
		{
		}
	}
}