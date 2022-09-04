using System;
using System.Collections.Generic;
using Core;
using UnityEngine;

namespace Managers
{
    public class ObjectPoolManager : MonoSingleton<ObjectPoolManager>
    {
        [SerializeField] private MonoPooledData[] pooledObjects;
        
        private Dictionary<Type, Queue<MonoPooled>> _pools;
        
        public override void OnValidate()
        {
            base.OnValidate();
            if (pooledObjects == null)
                return;
            
            foreach (var pooledObject in pooledObjects)
            {
                if(pooledObject.prefab != null)
                {
                    pooledObject.SetName(pooledObject.prefab.name);
                }
                else
                {
                    pooledObject.SetName("NaN");
                }
            }    
        }
        
        private void Awake()
        {
            _pools = new Dictionary<Type, Queue<MonoPooled>>();

            foreach (var pooledObject in pooledObjects)
            {
                Pool(pooledObject);
            }
        }

        private void Pool(MonoPooledData pooledObject)
        {
            if (pooledObject.count == 0)
            {
                return;
            }

            var type = pooledObject.prefab.GetType();
            GameObject typesParent = new GameObject($"{type.Name} Parent");
            
            typesParent.transform.parent = transform; 
            if (!_pools.ContainsKey(type))
            {
                _pools.Add(type, new Queue<MonoPooled>());
            }

            for (int i = 0; i < pooledObject.count; i++)
            {
                var monoPooled = Instantiate(pooledObject.prefab, typesParent.transform);
                _pools[type].Enqueue(monoPooled.Init());
                monoPooled.gameObject.SetActive(false);
            }
        }
        
        public void ReturnToPool(MonoPooled pooledObject)
        {
            pooledObject.gameObject.SetActive(false);
            _pools[pooledObject.GetType()].Enqueue(pooledObject);   
        }

        public T GetFromPool<T>() where T : MonoPooled
        {                
            _pools[typeof(T)].Peek()?.gameObject.SetActive(true);

            return (T) _pools[typeof(T)].Dequeue();
        }
    }

    [Serializable]
    public class MonoPooledData
    {
        [HideInInspector]
        public string _name = "";
        public MonoPooled prefab;
        public int count;

        public void SetName(string name)
        {
            _name = name;
        }
    }
}