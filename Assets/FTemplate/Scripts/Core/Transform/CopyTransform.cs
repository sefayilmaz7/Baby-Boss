using System.Collections;
using UnityEngine;

public static class CopyTransform
{
    public static void Execute(Transform sourceTransform, Transform destinationTransform, Vector3 velocity)
    {
        for (int i = 0; i < sourceTransform.childCount; i++)
        {
            var source = sourceTransform.GetChild(i);
            var destination = destinationTransform.GetChild(i);

            destination.position = source.position;
            destination.rotation = source.rotation;

            var rbody = destination.GetComponent<Rigidbody>();

            if (rbody != null)
                rbody.velocity = velocity;

            Execute(source, destination, velocity);
        }
    }
}