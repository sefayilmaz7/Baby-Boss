using Core.Forms.StyleForms;
using MonoObjects.Interactable.Core;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects.Interactable.Machines
{
    public class ShirtMachine : MachineBase
    {
        [SerializeField] private ShirtStyle shirtStyle;
        
        public override MaterialModifier UpdateMaterialModifier()
        {
            base.UpdateMaterialModifier();  
            robotArm.UpdateDisplay(shirtStyle.GetPalate());

            materialModifier.SetMaterialProperties(shirtStyle.GetPalate());
            return base.UpdateMaterialModifier();

        }
        
        public override void GetPalate()
        {
            shirtStyle.UpdateColorPalate(ColorPalate.CreateInstance(gameColorPalate.GetPalate(bodyPart)));
            materialModifier.SetMaterialProperties(shirtStyle.GetPalate());

        }
        
        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.GainForm(shirtStyle);
        }
    }
}