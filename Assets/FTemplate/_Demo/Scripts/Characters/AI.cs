using System.Collections.Generic;
using UnityEngine;

namespace FTemplateNamespace.Demo
{
	public class AI : Character
	{
		private readonly List<Character> enemies = new List<Character>( 4 );

		public void OnLevelStarted()
		{
			enemies.Add( GameManager.Instance.Player );
			foreach( Character ai in GameManager.Instance.AIs )
			{
				if( this != ai )
					enemies.Add( ai );
			}

			if( FTemplate.Gallery.PlayingBonusLevel )
				strength = 0.25f;
		}

		protected override void Update()
		{
			base.Update();

			float closestDistance = float.PositiveInfinity;
			Vector3 closestPoint = new Vector3();
			for( int i = 0; i < enemies.Count; i++ )
			{
				if( enemies[i].enabled )
				{
					Vector3 position = enemies[i].transform.position;
					float distance = ( transform.position - position ).sqrMagnitude;
					if( distance < closestDistance )
					{
						closestDistance = distance;
						closestPoint = position;
					}
				}
			}

			if( closestDistance < float.PositiveInfinity )
				targetDirection = closestPoint - transform.position;
			else
				targetDirection = Vector3.zero;
		}
	}
}