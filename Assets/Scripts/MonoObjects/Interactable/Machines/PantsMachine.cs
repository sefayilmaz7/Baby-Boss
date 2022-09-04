using Core.Forms.StyleForms;
using MonoObjects.Interactable.Core;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects.Interactable.Machines
{
    public class PantsMachine : MachineBase
    {
        [SerializeField] private PantsStyle pantsStyle;
        
        public override MaterialModifier UpdateMaterialModifier()
        {
            base.UpdateMaterialModifier();
            robotArm.UpdateDisplay(pantsStyle.GetPalate());

            materialModifier.SetMaterialProperties(pantsStyle.GetPalate());
            return base.UpdateMaterialModifier();

        }
        
        public override void GetPalate()
        {
            pantsStyle.UpdateColorPalate(ColorPalate.CreateInstance(gameColorPalate.GetPalate(bodyPart)));
            materialModifier.SetMaterialProperties(pantsStyle.GetPalate());

        }
        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.GainForm(pantsStyle);
        }
    }
}