using System.Collections;
using UnityEngine;

abstract public class SOAction : ScriptableObject, IAction
{
    abstract public void Execute();
}

abstract public class SOAction<T> : SOAction
{
    abstract public void Execute(T data);
}