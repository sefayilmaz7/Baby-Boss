using System.Collections.Generic;
using UnityEngine;

public sealed class ObjectPool : MonoBehaviour
{
    public List<ObjectPoolItem> ObjectPoolItems;
    private static List<ObjectPoolItem> SpawnedObjectPoolItems;
    private static GameObject Instance;

    private void Awake()
    {
        Instance = this.gameObject;
        SpawnedObjectPoolItems = ObjectPoolItems;
        StartObjectPool();
    }

    private void StartObjectPool()
    {
        foreach (ObjectPoolItem item in ObjectPoolItems)
            for (int i = 0; i < item.Count; i++)
                Despawn(InstantiatePoolObject(item));
    }

    private static ObjectPoolItem FindObjectPoolItem(GameObject obj)
    {
        if (!obj) return null;

        foreach (ObjectPoolItem item in SpawnedObjectPoolItems)
            if (item.poolObjectsID.Contains(obj.GetInstanceID()))
                return item;

        return null;
    }

    public static GameObject Spawn(GameObject obj)
    {
        if (!obj) return null;

        ObjectPoolItem poolItem = FindObjectPoolItem(obj);
        if (poolItem == null) return null;

        if (poolItem.poolObjects.Count != 0)
        {
            var poolObj = poolItem.poolObjects.Pop();
            poolObj.SetActive(true);
            return poolObj;
        }
        else
        {
            var poolObj = InstantiatePoolObject(poolItem);
            return poolObj;
        }
    }

    public static GameObject Spawn(GameObject obj, Transform newParent)
    {
        var poolObj = Spawn(obj);
        if (!poolObj) return null;

        poolObj.transform.SetParent(newParent);
        return poolObj;
    }

    public static void Despawn(GameObject obj)
    {
        if (!obj) return;

        ObjectPoolItem poolItem = FindObjectPoolItem(obj);
        if (poolItem == null) return;

        poolItem.poolObjects.Push(obj);
        obj.transform.SetParent(Instance.transform);
        obj.SetActive(false);
    }

    public static void Despawn(GameObject obj, float t)
    {
        if (!obj) return;

        DelayManager.WaitAndInvoke(() => Despawn(obj), t: t);
    }


    #region Instantiate
    private static GameObject InstantiatePoolObject(ObjectPoolItem item)
    {
        GameObject poolObj = Instantiate(item.Object);
        return PrepareInstantiatedPoolObject(item, poolObj);
    }

    private static GameObject PrepareInstantiatedPoolObject(ObjectPoolItem item, GameObject obj)
    {
        obj.name += "(Pooling)";
        item.poolObjectsID.Add(obj.GetInstanceID());
        return obj;
    }
    #endregion
}