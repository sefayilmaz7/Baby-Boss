using Managers;
using UnityEngine;

namespace Core
{
    public abstract class MonoPooled : MonoBehaviour
    {
        public virtual MonoPooled Init()
        {
            return this;
        }
        
        public virtual void ReturnToPool()
        {
            ObjectPoolManager.Instance.ReturnToPool(this);
        }
    }
}