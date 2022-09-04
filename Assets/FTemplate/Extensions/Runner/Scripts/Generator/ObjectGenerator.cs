using System.Collections.Generic;
using FluffyUnderware.Curvy.Generator;
using FluffyUnderware.Curvy.Generator.Modules;
using UnityEngine;

public class ObjectGenerator : GeneratorBase
{
    [SerializeField, ReadOnly] private CurvyGenerator generator;
    [SerializeField, ReadOnly] private RoadGenerator roadGenerator;
    
    [SerializeField, ReadOnly] private InputGameObject inputGameObject;
    [SerializeField, ReadOnly] private BuildRasterizedPath path;
    [SerializeField, ReadOnly] private List<ObjectGroup> objectGroups;
    [SerializeField, ReadOnly] private int objectGroupCount;
    

    public override void AutoUpdate()
    {
        foreach (var objectGroup in objectGroups)
        {
            objectGroup.UpdateObjectGroupData();
        }
    }

    public override void Generate()
    {
        Init(generator, roadGenerator);
        inputGameObject?.Reset();

        if (objectGroupCount <= objectGroups.Count)
        {
            if (objectGroupCount == 0)
            {
                GenerateObjectGroup(0);
                objectGroupCount++;
            }

            return;
        }
        
        
        for (int i = Mathf.Max(0,objectGroups.Count - 1); i < objectGroupCount; i++)
        {
            GenerateObjectGroup(i);
        }
    }

    private void GenerateObjectGroup(int i)
    {
        objectGroups.Add(gameObject.AddComponent<ObjectGroup>());
        objectGroups[i].Init(generator, inputGameObject, path, this);
    }

    public void Init(CurvyGenerator curvyGenerator, RoadGenerator roadGenerator)
    {
        objectGroups = new List<ObjectGroup>();
        generator = curvyGenerator;
        this.roadGenerator = roadGenerator;

        var splinePath = generator.GetModule<InputSplinePath>(ModuleNames.PathSpline, true);
        path = generator.GetModule<BuildRasterizedPath>(ModuleNames.RasterPath, true);
        inputGameObject = generator.GetModule<InputGameObject>(ModuleNames.ObjectPlacerInput, true);


        if (inputGameObject == null)
        {
            inputGameObject = generator.AddModule<InputGameObject>();
            inputGameObject.ModuleName = ModuleNames.ObjectPlacerInput;
        }

        if (path == null)
        {
            path = generator.AddModule<BuildRasterizedPath>();
            path.ModuleName = ModuleNames.RasterPath;
        }

        path.Resolution = roadGenerator.roadData.resolution;
        path.AngleThreshold = roadGenerator.roadData.angleThreshold;
        path.Optimize = roadGenerator.roadData.optimize;
        
        splinePath.Path.LinkTo(path.InPath);
    }

    public override void DeleteAll()
    {
        foreach (var objectGroup in objectGroups)
        {
            objectGroup.Delete(generator);
            DestroyImmediate(objectGroup);
        }

        objectGroupCount = 0;
        objectGroups = new List<ObjectGroup>();
        generator.DeleteModule(inputGameObject);
        generator.DeleteModule(path);
        inputGameObject = null;
        path = null;
    }

    public float GetSplineLenght()
    {
        return roadGenerator.GetSplineLenght();
    }

    public override void AddNew()
    {
        
        if (objectGroupCount == 0)
        {
            Init(generator, roadGenerator);
        }
        
        GenerateObjectGroup(objectGroups.Count);
        objectGroupCount++;
    }

    public void Delete(ObjectGroup objectGroup)
    {
        objectGroups.Remove(objectGroup);
        objectGroup.Delete(generator);
        DestroyImmediate(objectGroup);
        objectGroupCount--;
        
        foreach (var oG in objectGroups)
        {
            oG.UpdateObjectGroupData();
        }
    }
    
    public override void RemoveLast()
    {
        if (objectGroupCount == 0) return;
        Delete(objectGroups[objectGroupCount - 1]);
    }
}