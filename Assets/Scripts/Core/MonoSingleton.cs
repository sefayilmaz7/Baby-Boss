﻿using UnityEngine;

namespace Core
{
    public class MonoSingleton<T> : MonoBehaviour where T : MonoSingleton<T>
    {
        protected bool initialized;
        private static volatile T instance;

        public virtual void OnValidate()
        {
            gameObject.name = typeof(T).Name;
        }

        public static T Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = FindObjectOfType(typeof(T)) as T;

                    if (!instance.initialized)
                    {
                        instance.Initialize();
                        instance.initialized = true;
                    }
                }
                return instance;
            }
        }

        protected virtual void Initialize()
        { }

    }
}