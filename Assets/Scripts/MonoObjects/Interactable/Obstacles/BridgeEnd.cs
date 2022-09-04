using Core;
using MonoObjects.Interactable.Core;
using UnityEngine;

namespace MonoObjects.Interactable.Obstacles
{
    [RequireComponent(typeof(Rigidbody))]
    [RequireComponent(typeof(BoxCollider))]
    public class BridgeEnd : ObstacleBase
    {
        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.isOnBridge = false;
            baby.babyModel.SetBool(AnimationVariables.Caution, false);
        }
    }
}