using UnityEngine;

public class GeneratorBase : MonoBehaviour
{
    public bool autoRefresh = true;

    public virtual void Generate(){}
    public virtual void DeleteAll(){}

    public virtual void AutoUpdate() {}
    public virtual void AddNew() {}

    public virtual void RemoveLast() {}
}
