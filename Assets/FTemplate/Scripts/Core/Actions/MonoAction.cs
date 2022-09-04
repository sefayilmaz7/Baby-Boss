using System.Collections;
using UnityEngine;

abstract public class MonoAction : MonoBehaviour, IAction
{
    abstract public void Execute();
}

abstract public class MonoAction<T> : MonoAction
{
    abstract public void Execute(T data);
}