using System;
using MonoObjects;
using UnityEngine;

namespace Core.Forms.StyleForms
{
    
    
    [Serializable]
    public class HairStyle : StyleFormBase
    {

        public override void Add(Baby baby)
        {
            base.Add(baby);
            baby.babyModel.GainBodyPart(stylePalate.type, stylePalate);
        }

        public override void Remove(Baby baby)
        {
            base.Remove(baby);
            baby.babyModel.LoseBodyPart(stylePalate.type);
        }

        public override void CopyFrom(FormBase formBase)
        {
        }
        
        public override Type Type()
        {
            return typeof(HairStyle);
        }
        
        public override float GetValue()
        {
            return  10f;
        }
    }
}