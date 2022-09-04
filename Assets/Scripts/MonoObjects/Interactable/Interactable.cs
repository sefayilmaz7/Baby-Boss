using System;
using UnityEngine;

namespace MonoObjects.Interactable
{    
    [SelectionBase]
    public abstract class Interactable : MonoBehaviour
    {
        
        private void OnTriggerEnter(Collider other)
        {
            if (other.TryGetComponent(out BabyCollision babyCollision))
            {
                babyCollision.Collided(this);
            }
        }

        private void OnTriggerExit(Collider other)
        {
            if (other.TryGetComponent(out BabyCollision babyCollision))
            {
                babyCollision.CollisionExit(this);
            }
        }

        public virtual void Interact(Baby baby)
        {
        }

        public virtual void InteractionOver(Baby baby)
        {
        }
    }
}
