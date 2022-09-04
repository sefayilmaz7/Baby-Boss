using System.Collections;
using System.Collections.Generic;
using Core;
using DG.Tweening;
using MonoObjects.Interactable.Core;
using UnityEngine;

namespace MonoObjects.Interactable.Obstacles
{
    public class BallPoolObstacle : ObstacleBase
    {
        [SerializeField] private List<Renderer> balls;
        [SerializeField] private Color[] colors;
        [SerializeField] private List<Transform> idleTransforms;
        

        private void Awake()
        {
            foreach (var ballRenderer in balls)
            {
                var propertyBlock = new MaterialPropertyBlock();
                ballRenderer.GetPropertyBlock(propertyBlock, 0);
                propertyBlock.SetColor(PropertyBlockNames.BabyColor, colors[Random.Range(0, colors.Length-1)]);
                ballRenderer.SetPropertyBlock(propertyBlock, 0);
            }
        }

        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            var hasTransformPos = idleTransforms.Count > 0;
            baby.RemoveFromGroup(!hasTransformPos);
            if (!hasTransformPos) return;

            baby.SplineController.Speed = 0;
            
            var index = Random.Range(0, idleTransforms.Count - 1);
            var idleTransform = idleTransforms[index];
            idleTransforms.Remove(idleTransform);
            baby.Model.DOMove(idleTransform.position, 1f).SetId(baby.Model.GetInstanceID());
            baby.Model.DORotateQuaternion(Quaternion.Euler(0f, Random.Range(0, 360f), 0f), 1f).SetId(baby.Model.GetInstanceID());;
            baby.babyModel.Animate(AnimationVariables.Idle);
            baby.babyCollision.Enable();
        }
    }
}