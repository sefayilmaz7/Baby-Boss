using System;
using MonoObjects;

namespace Core.Forms
{
    [Serializable]
    public class GrowthFormBase : FormBase
    {
        private bool hasPacifier;
        public bool HasPacifier => hasPacifier;

        public override void Add(Baby baby)
        {
            
        }

        public override void Remove(Baby baby)
        {
            
        }

        public override void CopyFrom(FormBase formBase)
        {
        }
        
        public override Type Type()
        {
            return typeof(GrowthFormBase);
        }
        
        public override float GetValue()
        {
            return 0f;
        }
    }
}