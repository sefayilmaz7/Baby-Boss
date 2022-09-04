using Core.Forms.StyleForms;
using MonoObjects.Interactable.Core;
using ScriptableObjects;
using UnityEngine;

namespace MonoObjects.Interactable.Hands
{
    public class TieHand : HandBase
    {
        [SerializeField] private TieStyle tieStyle;
        public override MaterialModifier UpdateMaterialModifier()
        {
            base.UpdateMaterialModifier();
            robotArm.UpdateDisplay(tieStyle.GetPalate());

            materialModifier.SetMaterialProperties(tieStyle.GetPalate());
            return materialModifier;

        }
        
        public override void GetPalate()
        {
            tieStyle.UpdateColorPalate(ColorPalate.CreateInstance(gameColorPalate.GetPalate(bodyPart)));
            materialModifier.SetMaterialProperties(tieStyle.GetPalate());
        }
        
        public override void Interact(Baby baby)
        {
            base.Interact(baby);
            baby.GainForm(tieStyle);
        }
    }
}