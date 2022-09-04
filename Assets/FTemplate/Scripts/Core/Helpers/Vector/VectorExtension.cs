using UnityEngine;

public static class VectorExtension
{
    public static Vector3 AddX(this Vector3 v, float x)
    {
        v.x += x;
        return v;
    }

    public static Vector3 AddY(this Vector3 v, float y)
    {
        v.y += y;
        return v;
    }
        
    public static Vector3 AddZ(this Vector3 v, float z)
    {
        v.z += z;
        return v;
    }
        
    public static Vector3 WithX(this Vector3 v, float x)
    {
        v.x = x;
        return v;
    }
     
    public static Vector3 WithY(this Vector3 v, float y)
    {
        v.y = y;
        return v;
    }
    
    public static Vector3 WithZ(this Vector3 v, float z)
    {
        v.z = z;
        return v;
    }

    public static Vector3 Round(this Vector3 v)
    {
        v.x = Mathf.Round(v.x);
        v.y = Mathf.Round(v.y);
        v.z = Mathf.Round(v.z);
        return v;
    }
}
