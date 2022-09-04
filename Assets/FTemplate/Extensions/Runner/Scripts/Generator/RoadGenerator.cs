using System.Collections.Generic;
using FluffyUnderware.Curvy;
using FluffyUnderware.Curvy.Generator;
using FluffyUnderware.Curvy.Generator.Modules;
using FluffyUnderware.Curvy.Shapes;
using UnityEditor;
using UnityEngine;

public class RoadGenerator : GeneratorBase
{
    [SerializeField] public RoadData roadData;
    [SerializeField, ReadOnly] private CurvyGenerator generator;
    [SerializeField, ReadOnly] private ObjectGenerator objectGenerator;
    [SerializeField, ReadOnly] private PathGenerator pathGenerator;
    [SerializeField, ReadOnly] private RoadEssentialModules roadEssentialModules;
    [SerializeField, ReadOnly] private List<RoadPart> roadParts;
    [SerializeField, ReadOnly] private int roadPartCount;

    private void Awake()
    {
        generator.Refresh();
    }

    private void OnValidate()
    {
        if (roadParts == null)
        {
            roadParts = new List<RoadPart>();
        }

#if UNITY_EDITOR
        if (roadData == null)
        {
            roadData = AssetDatabase.LoadAssetAtPath<RoadData>("Assets/FTemplate/Extensions/Runner/Data/RoadData Default.asset");
        }
#endif
    }

    public override void AddNew()
    {
        if (generator == null)
            return;
        
        // generator.Refresh();
        InitEssentials();
        
        roadParts.Add(gameObject.AddComponent<RoadPart>());
        roadParts[roadPartCount].Init(generator, roadEssentialModules, roadData,this);
        roadParts[roadPartCount].roadLenght = GetSplineLenght();
        roadPartCount++;
        
    }

    public void DeletePart(RoadPart part)
    {
        roadPartCount--;
        roadParts.Remove(part);

        part.Delete(generator);
    }
    
    public override void AutoUpdate()
    {
        base.AutoUpdate();
        if (generator == null)
            return;
        
        foreach (var part in roadParts)
        {
            part.UpdateRoadPart(roadEssentialModules, roadData);
        }
    }

    public override void Generate()
    {
        if (generator == null)
        {
            generator = CurvyGenerator.Create();
            generator.transform.parent = transform;
            // return;
        }

        if (roadData == null)
        {
            Debug.LogWarning("Assign Road Data");
        }

        
        generator.Refresh();
        InitEssentials();

        if (roadPartCount <= roadParts.Count)
        {
            if (roadParts.Count == 0)
            {
                roadParts.Add(gameObject.AddComponent<RoadPart>());
                roadParts[0].Init(generator, roadEssentialModules, roadData, this);
                roadParts[0].roadLenght = GetSplineLenght();  
                roadPartCount++;
            }
            
            foreach (var part in roadParts)
            {
                part.ReCreate(generator);
                part.Init(generator, roadEssentialModules, roadData, this);
            }
            
            
            return;
        }

        for (int i = Mathf.Max(0,roadParts.Count - 1); i < roadPartCount; i++)
        {
            roadParts.Add(gameObject.AddComponent<RoadPart>());
            roadParts[i].Init(generator, roadEssentialModules, roadData, this);
        }
        
    }

    private void InitEssentials()
    {
        var fieldsInRoadEssential = roadEssentialModules.GetType().GetFields();
        foreach (var field in fieldsInRoadEssential)
        {
            // if (field.FieldType.BaseType == typeof(CGModule))
            // {
            //     generator.DeleteModule((CGModule) field.GetValue(roadEssentialModules));
            //
            //     field.SetValue(roadEssentialModules, default);
            // }

            if (field.FieldType.BaseType == typeof(CGModule))
            {
                if((field.GetValue(roadEssentialModules) != null)) continue;
                
                var value = generator.AddModule(field.FieldType);
                field.SetValue(roadEssentialModules, value);
            }
        }

        if (roadEssentialModules.path == null)
        {
            roadEssentialModules.path = generator.AddModule<InputSplinePath>();
            roadEssentialModules.pathShape = generator.AddModule<InputSplineShape>();
            roadEssentialModules.railShape = generator.AddModule<InputSplineShape>();
            roadEssentialModules.path.ModuleName = ModuleNames.PathSpline;
            roadEssentialModules.pathShape.ModuleName = ModuleNames.PathShape;
            roadEssentialModules.railShape.ModuleName = ModuleNames.RailShape;
        }
        
        if(roadEssentialModules.path.Spline == null)
        {
            roadEssentialModules.path.Spline = CurvySpline.Create();
            roadEssentialModules.path.Spline.Interpolation = CurvyInterpolation.Bezier;
            roadEssentialModules.path.Spline.transform.parent = roadEssentialModules.path.transform;

            roadEssentialModules.pathShape.Shape = CurvySpline.Create();
            roadEssentialModules.pathShape.Shape.transform.parent = roadEssentialModules.pathShape.transform;
            roadEssentialModules.pathShape.Shape.Interpolation = CurvyInterpolation.Linear;
            roadEssentialModules.pathShape.Shape.Add(Vector3.zero);
            roadEssentialModules.pathShape.Shape.Add(Vector3.zero);
            roadEssentialModules.pathShape.Shape.Add(Vector3.zero);
            roadEssentialModules.pathShape.Shape.Add(Vector3.zero);
            
            var pathShape = roadEssentialModules.pathShape.Shape.gameObject.AddComponent<CSRectangle>();
            pathShape.Plane = CurvyPlane.XY;
            pathShape.Width = roadData.roadWidth;
            pathShape.Height = roadData.roadHeight;
            roadEssentialModules.railShape.Shape = CurvySpline.Create();
            roadEssentialModules.railShape.Shape.transform.parent = roadEssentialModules.railShape.transform;
            roadEssentialModules.railShape.Shape.Interpolation = CurvyInterpolation.Linear;
            roadEssentialModules.railShape.Shape.Add(Vector3.zero);
            roadEssentialModules.railShape.Shape.Add(Vector3.zero);
            roadEssentialModules.railShape.Shape.Add(Vector3.zero);
            roadEssentialModules.railShape.Shape.Add(Vector3.zero);
            var railShape = roadEssentialModules.railShape.Shape.gameObject.AddComponent<CSRectangle>();
            railShape.Plane = CurvyPlane.XY;
            railShape.Width = roadData.railWidth;
            railShape.Height = roadData.railHeight;
        }


        if (roadEssentialModules.path.Spline.Count == 0)
        {
            roadEssentialModules.path.Spline.Add(Vector3.zero);
            roadEssentialModules.path.Spline.Add(Vector3.forward * 25f);
        }
    }

    public override void DeleteAll()
    {
        var fieldsInRoadEssential = roadEssentialModules.GetType().GetFields();
        
        foreach (var field in fieldsInRoadEssential)
        {
            if (field.FieldType.BaseType == typeof(CGModule))
            {
                generator.DeleteModule((CGModule) field.GetValue(roadEssentialModules));

                field.SetValue(roadEssentialModules, default);
            }
            // if (field.FieldType.BaseType == typeof(SplineInputModuleBase))
            // {
            //     generator.DeleteModule((SplineInputModuleBase)field.GetValue(roadEssentialModules));
            //     
            //     field.SetValue(roadEssentialModules, default);
            // }
        }
        foreach (var part in roadParts)
        {
            part.Delete(generator);
        }

        roadPartCount = 0;
        roadParts = new List<RoadPart>();
    }

    public float GetSplineLenght()
    {
        var spline = roadEssentialModules.path?.Spline;

        return spline != null ? spline.Length : 1f;
    }

    public void AddObjectPlacer()
    {
        if (objectGenerator != null) return;
        
        var objectPlacerParent = new GameObject("Object Generator");
        objectGenerator = objectPlacerParent.AddComponent<ObjectGenerator>();
        objectGenerator.transform.parent = transform;
        objectGenerator.Init(generator, this);
    }

    public void RemoveObjectPlacer()
    {
        if (objectGenerator == null) return;

        objectGenerator.DeleteAll();
        DestroyImmediate(objectGenerator.gameObject);
        objectGenerator = null;
    }

    public void AddPathCreator()
    {
        if (pathGenerator != null) return;
        
        var objectPlacerParent = new GameObject("Path Creator");
        pathGenerator = objectPlacerParent.AddComponent<PathGenerator>();
        pathGenerator.transform.parent = transform;
        pathGenerator.Init(generator, this);
    }

    public override void RemoveLast()
    {
        if (roadPartCount == 0) return;
        DeletePart(roadParts[roadPartCount - 1]);
    }
    
    public void RemovePathCreator()
    {
        if (pathGenerator == null) return;

        pathGenerator.DeleteAll();
        DestroyImmediate(pathGenerator.gameObject);
        pathGenerator = null;
    }

    public bool IsTurning(float position, out PathDirection pathDirection, out float currentTurnValue)
    {
        return pathGenerator.IsTurning(position, out pathDirection, out currentTurnValue);
    }
}