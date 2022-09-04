using Core.Forms.StyleForms;
using MonoObjects.Interactable.Core;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects.Interactable.Machines
{
    public class HairDyeMachine : MachineBase
    {
        [SerializeField] private HairStyle hairStyle;

        public override MaterialModifier UpdateMaterialModifier()
        {
            base.UpdateMaterialModifier();
            robotArm.UpdateDisplay(hairStyle.GetPalate());

            materialModifier.SetMaterialProperties(hairStyle.GetPalate());
            return base.UpdateMaterialModifier();
        }
        
        public override void GetPalate()
        {
            hairStyle.UpdateColorPalate(ColorPalate.CreateInstance(gameColorPalate.GetPalate(bodyPart)));
            materialModifier.SetMaterialProperties(hairStyle.GetPalate());
        }

        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.GainForm(hairStyle);
        }
    }
}