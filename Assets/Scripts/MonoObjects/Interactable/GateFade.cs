using ScriptableObjects;
using UnityEngine;

namespace MonoObjects.Interactable
{
    public class GateFade : MonoBehaviour
    {
        [SerializeField] private MaterialModifier materialModifier;
        [SerializeField] private ColorPalate fadePalate;

        private ColorPalate defaultPalate;
        public void Interact(Baby baby)
        {
            defaultPalate = materialModifier.GetMaterialProperties();
            materialModifier.SetMaterialProperties(fadePalate);
        }
        
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
                babyCollision.CollideExit(this);
            }
        }

        public void OnExit()
        {
            materialModifier.SetMaterialProperties(defaultPalate);
        }
    }
}
