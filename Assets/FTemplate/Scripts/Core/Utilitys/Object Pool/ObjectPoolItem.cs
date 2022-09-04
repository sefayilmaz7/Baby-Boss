using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ObjectPoolItem
{
    public GameObject Object;
    public int Count;
    [HideInInspector] public Stack<GameObject> poolObjects = new Stack<GameObject>();
    [HideInInspector] public List<int> poolObjectsID = new List<int>();
}