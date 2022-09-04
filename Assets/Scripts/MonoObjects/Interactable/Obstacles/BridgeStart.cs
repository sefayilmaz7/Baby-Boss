using Core;
using MonoObjects.Interactable.Core;
using UnityEngine;

namespace MonoObjects.Interactable.Obstacles
{
    [RequireComponent(typeof(Rigidbody))]
    [RequireComponent(typeof(BoxCollider))]
    public class BridgeStart : ObstacleBase
    {
        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.isOnBridge = true;
            baby.babyModel.SetBool(AnimationVariables.Caution, true);
            baby.babyModel.SetBool(AnimationVariables.MirrorWalk, Random.Range(0,100) % 2 == 0);
        }
    }
}