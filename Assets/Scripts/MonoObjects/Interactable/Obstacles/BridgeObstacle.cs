using Core;
using DG.Tweening;
using MonoObjects.Interactable.Core;
using UnityEngine;

namespace MonoObjects.Interactable.Obstacles
{
    public class BridgeObstacle : ObstacleBase
    {
        public override void Interact(Baby baby)
        {
            baby.RemoveFromGroup(false);
            baby.SplineController.Speed /= 2f;
            var sequence = DOTween.Sequence();
            sequence.Append(baby.Model.DOLocalJump(
                ((Mathf.Sign(baby.Model.localPosition.x) * 4f * Vector3.right) - baby.Model.up * 3).normalized,
                0.5f, 1, 0.5f));
            sequence.Append(baby.Model.DOScale(Vector3.zero, 0.3f));
            var onComplete = new TweenCallback((() => { baby.Model.localScale = Vector3.zero;
                                                            baby.ReturnToPool();}));
            sequence.AppendCallback(onComplete);

            sequence.SetId(baby.Model.GetInstanceID());
            baby.babyModel.Animate(AnimationVariables.Fall);
        }
    }
}