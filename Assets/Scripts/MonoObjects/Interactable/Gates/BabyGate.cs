using MonoObjects.Interactable.Core;
using UnityEngine;

namespace MonoObjects.Interactable.Gates
{
    public class BabyGate : GateBase
    {
        [SerializeField] private int babyCount;
        
        public override void Interact(Baby baby)
        {
            if (!baby.isLead) return;

            for (int i = 0; i < babyCount; i++)
            {
                baby.AddNew();
            }
            // baby.React();
            base.Interact(baby);
        }
    }
}