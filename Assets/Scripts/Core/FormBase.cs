using System;
using MonoObjects;

namespace Core
{
    [Serializable]
    public abstract class FormBase
    {
        public abstract void Add(Baby baby);
        public abstract void Remove(Baby baby);
        public abstract void CopyFrom(FormBase formBase);
        public abstract Type Type();
        public abstract float GetValue();
    }
}