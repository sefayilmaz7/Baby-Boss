using System;
using MonoObjects;
using UnityEngine;

namespace Core.Forms.StyleForms
{
    [Serializable]

    public class JacketStyle : StyleFormBase
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
        
        public override Type Type()
        {
            return typeof(JacketStyle);
        }

        public override string ToString()
        {
            return stylePalate.type.ToString();
        }
        
        public override float GetValue()
        {
            return 15f;
        }
    }
}