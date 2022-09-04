using System.Collections.Generic;
using FluffyUnderware.Curvy;
using FluffyUnderware.Curvy.Generator;
using FluffyUnderware.Curvy.Generator.Modules;
using UnityEngine;

public class PathGenerator : GeneratorBase
{
    [SerializeField,ReadOnly] private CurvyGenerator curvyGenerator;
    [SerializeField,ReadOnly] private CurvySpline spline;
    [SerializeField,ReadOnly] private RoadGenerator roadGenerator;
    
    [SerializeField, ReadOnly] private List<PathPart> pathParts;
    [SerializeField, ReadOnly] private Vector3 currentDirection = Vector3.forward;
    [SerializeField] private PathPartData partData;


    public override void AutoUpdate()
    {
        base.AutoUpdate();
        UpdatePaths();
    }


    public override void AddNew()
    {
        pathParts.Add(gameObject.AddComponent<PathPart>());
        pathParts[pathParts.Count - 1].Init(spline, pathParts.Count - 1, partData, this, ref currentDirection);
        UpdatePaths();
    }


    public void Init(CurvyGenerator generator, RoadGenerator roadGenerator)
    {
        pathParts = new List<PathPart>();
        spline = generator.GetModule<InputSplinePath>(ModuleNames.PathSpline, true).Spline;
        this.roadGenerator = roadGenerator;
        curvyGenerator = generator;
    }

    public void UpdatePaths()
    {
        currentDirection = Vector3.forward;
        foreach (var pathPart in pathParts)
        {
            pathPart.UpdatePart(ref currentDirection, pathParts.IndexOf(pathPart));
        }
    }

    public override void DeleteAll()
    {
        foreach (var pathPart in pathParts)
        {
            pathPart.Delete();
        }
        
        currentDirection = Vector3.forward;
        pathParts = new List<PathPart>();
    }

    public void Delete(PathPart pathPart)
    {
        pathParts.Remove(pathPart);
        pathPart.Delete();
        UpdatePaths();
    }
    
    public override void RemoveLast()
    {
        if (pathParts.Count == 0) return;

        Delete(pathParts[pathParts.Count - 1]);
    }

    

    public bool IsTurning(float position, out PathDirection pathDirection, out float currentTurnValue)
    {
        var currentPathDistance = 0f;
        foreach (var pathPart in pathParts)
        {
            if (pathPart.Data.direction != PathDirection.Forward && 
                Between(position, currentPathDistance, pathPart.GetDistance(0) ))
            {
                var currentSin = Remap(position, currentPathDistance, pathPart.GetDistance(0), 0, 180 );
                pathDirection = pathPart.Data.direction;
                currentTurnValue = Mathf.Sin(currentSin * Mathf.Deg2Rad);
                return true;
            }

            currentPathDistance = pathPart.GetDistance(1);
        }

        currentTurnValue = 0;
        pathDirection = PathDirection.Forward;
        return false;
    }

    private bool Between(float value, float a, float b)
    {
        return value >= a && value <= b;
    }
    private float Remap(float value, float from1, float to1, float from2, float to2) {
        return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
    }
}