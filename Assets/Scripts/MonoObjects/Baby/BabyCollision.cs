using System;
using MonoObjects.Interactable;
using UnityEngine;


namespace MonoObjects
{
    public class BabyCollision : MonoBehaviour
    {
        [SerializeField] private Collider col;
        [SerializeField] private Collider poolCollider;
        
        [SerializeField] private Baby baby;
        [SerializeField] private bool inGroup;
        private Interactable.Interactable lastInteractable;

        public bool InGroup => inGroup;
        
        public void UpdateGroupInfo(bool value)
        {
            inGroup = value;
        }
        
        public void Collided(Interactable.Interactable interactable)
        {
            if (!inGroup || lastInteractable == interactable)
            {
                return;
            }
            
            interactable.Interact(baby);
            lastInteractable = interactable;
            baby.babyManager.EvaluateBabyUpgrades();
        }
        
        public void CollisionExit(Interactable.Interactable interactable)
        {
            if (!inGroup)
            {
                return;
            }

            interactable.InteractionOver(baby);
        }

        private void OnTriggerEnter(Collider other)
        {
            if (other.TryGetComponent(out BabyCollision babyCollision))
            {
                if (inGroup && !babyCollision.InGroup)
                {
                    baby.AddToGroup(babyCollision.baby);
                    baby.babyManager.EvaluateBabyUpgrades();
                }   
            }
        }

        public void SetActive(bool value)
        {
            col.enabled = value;
        }

        public void Enable()
        {
            poolCollider.enabled = true;
        }

        public void Collided(GateFade gateFade)
        {
            gateFade.Interact(baby);
        }

        public void CollideExit(GateFade gateFade)
        {
            gateFade.OnExit();
        }
    }
}