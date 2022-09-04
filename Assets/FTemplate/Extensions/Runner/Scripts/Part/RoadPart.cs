using FluffyUnderware.Curvy.Generator;
using FluffyUnderware.Curvy.Generator.Modules;
using FluffyUnderware.Curvy.Shapes;
using FluffyUnderware.DevTools;
using UnityEditor;
using UnityEngine;

public class RoadPart : GeneratorPartBase
{
    [SerializeField, ReadOnly] private CurvyGenerator curvyGenerator;
    [SerializeField, ReadOnly] private RoadGenerator roadGenerator;
    [SerializeField, ReadOnly] private GameObject[] objects;

    [ReadOnly]public RoadPartModules modules;
    [ReadOnly] public bool initialized;

    [RangeEx(0f, "MaxSplineLenght", Precision = 1)] public float startPosition;
    [RangeEx(0f, "MaxSplineLenght", Precision = 1)] public float roadLenght;
     
    [SerializeField] private bool doRoadPartObjectStart = true;
    [SerializeField] private bool doRoadPartObjectEnd = true;

    public float MaxSplineLenght => roadGenerator.GetSplineLenght();


    public void Init(CurvyGenerator curvyGenerator, RoadEssentialModules essentialModules, RoadData roadData,
        RoadGenerator roadGenerator)
    {
        this.curvyGenerator = curvyGenerator;
        this.roadGenerator = roadGenerator;
        modules = new RoadPartModules();
        var fields = modules.GetType().GetFields();

        foreach (var field in fields)
        {
            if (field.FieldType.BaseType == typeof(CGModule))
            {
                var value = curvyGenerator.AddModule(field.FieldType);
                // value.UpdateGenerator();
                field.SetValue(modules, value);
            }

            if (field.FieldType.BaseType == typeof(TRSModuleBase))
            {
                var value = curvyGenerator.AddModule(field.FieldType);
                // value.UpdateGenerator();
                field.SetValue(modules, value);
            }
        }

        InitNodes(this.curvyGenerator, essentialModules, roadData);

        UpdateRoadPart(essentialModules, roadData);
    }

    public void InitNodes(CurvyGenerator generator, RoadEssentialModules essentialModules, RoadData roadData)
    {
        InitRoadNodes(essentialModules);

        InitBarrierRails(essentialModules, generator, roadData);

        initialized = true;

        InitRoadPartObjects(roadData);
    }

    private void InitRoadPartObjects(RoadData roadData)
    {
        if (!roadData.doRoadPartObjects) return;
        
        if (objects != null)
        {
            foreach (var o in objects)
            {
                DestroyImmediate(o);
            }
        }
        
        objects = new GameObject[2];

#if UNITY_EDITOR
        objects[0] = PrefabUtility.InstantiatePrefab(roadData.roadStartCapPrefab) as GameObject;
        objects[1] = PrefabUtility.InstantiatePrefab(roadData.roadEndCapPrefab) as GameObject;
#endif
        for (var i = 0; i < objects.Length; i++)
        {
            objects[i].transform.parent = modules.createRoadMesh.transform;
        }
    }

    private void InitRoadNodes(RoadEssentialModules essentialModules)
    {
        //Road Nodes Init
        essentialModules.path.Path.LinkTo(modules.roadExtrusion.InPath);
        essentialModules.pathShape.OutShape.LinkTo(modules.roadShapeTrs.InShape);
        modules.roadShapeTrs.OutShape.LinkTo(modules.roadExtrusion.InCross);
        modules.roadExtrusion.OutVolume.LinkTo(modules.roadMesh.InVolume);
        modules.roadExtrusion.OutVolume.LinkTo(modules.roadCaps.InVolume);
        modules.roadMesh.OutVMesh.LinkTo(modules.createRoadMesh.InVMeshArray);
        modules.roadCaps.OutVMesh.LinkTo(modules.createRoadMesh.InVMeshArray);
    }

    private void InitBarrierRails(RoadEssentialModules essentialModules, CurvyGenerator generator, RoadData roadData)
    {
        if (roadData.doBarrier)
        {
            if (roadData.barrier == null)
            {
                Debug.LogWarning("Add Barrier Prefab");
            }
            else
            {
                if (essentialModules.rasterPath == null)
                {
                    essentialModules.rasterPath = generator.AddModule<BuildRasterizedPath>();
                    essentialModules.rasterPath.InPath.LinkTo(essentialModules.path.Path);
                }

                if (essentialModules.railObjectInput == null)
                {
                    essentialModules.railObjectInput = generator.AddModule<InputGameObject>();
                    essentialModules.railObjectInput.ModuleName = ModuleNames.BarrierPlacerInput;
                }

                if (essentialModules.railObjectInput.GameObjects.Count == 0)
                {
                    essentialModules.railObjectInput.GameObjects.Add(new CGGameObjectProperties(roadData.barrier));
                }
                
                //RailBarrier Nodes Init
                essentialModules.path.Path.LinkTo(essentialModules.rasterPath.InPath);
                essentialModules.railObjectInput.OutGameObject.LinkTo(modules.railObjectLCreate.InGameObjectArray);
                modules.barrierLSpots.InPath.LinkTo(essentialModules.rasterPath.OutPath);
                modules.barrierLSpots.InBounds.LinkTo(essentialModules.railObjectInput.OutGameObject);
                modules.railObjectLCreate.InSpots.LinkTo(modules.barrierLSpots.OutSpots);
                modules.railObjectLCreate.InGameObjectArray.LinkTo(essentialModules.railObjectInput.OutGameObject);
                
                essentialModules.railObjectInput.OutGameObject.LinkTo(modules.railObjectRCreate.InGameObjectArray);
                modules.barrierRSpots.InPath.LinkTo(essentialModules.rasterPath.OutPath);
                modules.barrierRSpots.InBounds.LinkTo(essentialModules.railObjectInput.OutGameObject);
                modules.railObjectRCreate.InSpots.LinkTo(modules.barrierRSpots.OutSpots);
                modules.railObjectRCreate.InGameObjectArray.LinkTo(essentialModules.railObjectInput.OutGameObject);
            }
        }


        if (roadData.doRails)
        {
            //Rail Nodes Init
            modules.railLTrs.InShape.LinkTo(essentialModules.railShape.OutShape);
            modules.railRTrs.InShape.LinkTo(essentialModules.railShape.OutShape);
            modules.railLExtrusion.InCross.LinkTo(modules.railLTrs.OutShape);
            modules.railRExtrusion.InCross.LinkTo(modules.railRTrs.OutShape);
            modules.railLExtrusion.InPath.LinkTo(essentialModules.path.Path);
            modules.railRExtrusion.InPath.LinkTo(essentialModules.path.Path);
            modules.railLExtrusion.OutVolume.LinkTo(modules.railLMesh.InVolume);
            modules.railRExtrusion.OutVolume.LinkTo(modules.railRMesh.InVolume);
            modules.railLExtrusion.OutVolume.LinkTo(modules.railLCaps.InVolume);
            modules.railRExtrusion.OutVolume.LinkTo(modules.railRCaps.InVolume);
            modules.railLMesh.OutVMesh.LinkTo(essentialModules.createRailMesh.InVMeshArray);
            modules.railRMesh.OutVMesh.LinkTo(essentialModules.createRailMesh.InVMeshArray);
            modules.railLCaps.OutVMesh.LinkTo(essentialModules.createRailMesh.InVMeshArray);
            modules.railRCaps.OutVMesh.LinkTo(essentialModules.createRailMesh.InVMeshArray);
        }
    }

    public void Delete(CurvyGenerator generator)
    {
        var fields = modules.GetType().GetFields();

        foreach (var field in fields)
        {
            if (field.FieldType.BaseType == typeof(CGModule))
            {
                generator.DeleteModule((CGModule) field.GetValue(modules));

                field.SetValue(modules, default);
            }

            if (field.FieldType.BaseType == typeof(TRSModuleBase))
            {
                generator.DeleteModule((TRSModuleBase) field.GetValue(modules));

                field.SetValue(modules, default);
            }
        }

        initialized = false;
        
        DestroyImmediate(this);
    }

    public void UpdateRoadPart(RoadEssentialModules essentialModules, RoadData roadData)
    {
        if (!initialized)
            return;

        //Variables
        var maxLenght = MaxSplineLenght;
        var fromExtrusion = startPosition / maxLenght;
        var toExtrusion = Mathf.Min(1f, (startPosition + roadLenght) / maxLenght);


        UpdateRoad(essentialModules, roadData, fromExtrusion, toExtrusion);
        UpdateRoadPartObjects(essentialModules, roadData);

        UpdateRailBarrier(roadData, fromExtrusion, toExtrusion, essentialModules);
    }

    private void UpdateRoad(RoadEssentialModules essentialModules, RoadData roadData, float fromExtrusion,
        float toExtrusion)
    {
        //TRSModules
        modules.roadShapeTrs.Transpose = roadData.roadShapeTranspose;

        // modules.roadExtrusion.UpdateGenerator();

        //Rail/Road ShapeExtrusion
        modules.roadExtrusion.From = fromExtrusion;
        modules.roadExtrusion.To = toExtrusion;
        modules.roadExtrusion.Resolution = roadData.resolution;
        modules.roadExtrusion.Optimize = roadData.optimize;
        modules.roadExtrusion.AngleThreshold = roadData.angleThreshold;
        modules.roadExtrusion.CrossHardEdges = roadData.hardEdges;
        modules.roadExtrusion.CrossFrom = roadData.crossStart;
        modules.roadExtrusion.CrossTo = roadData.crossEnd;

        var pathShape = essentialModules.pathShape.Shape.gameObject.GetComponent<CSRectangle>();
        pathShape.Height = roadData.roadHeight;
        pathShape.Width = roadData.roadWidth;

        //VolumeMesh 
        modules.roadMesh.SetMaterial(0, roadData.roadMaterial);
        modules.roadCaps.StartMaterial = roadData.roadCapMaterial;
        modules.roadMesh.MaterialSetttings[0].KeepAspect = roadData.keepAspectUV;

        //CreateMesh
        modules.createRoadMesh.Collider = CGColliderEnum.Mesh;
        modules.createRoadMesh.Combine = true;
        modules.createRoadMesh.MakeStatic = roadData.isStatic;
        modules.createRoadMesh.Layer = roadData.roadLayer;
        modules.createRoadMesh.CastShadows = roadData.castShadows;
        modules.createRoadMesh.ReceiveShadows = roadData.receiveShadows;
    }

    private void UpdateRoadPartObjects(RoadEssentialModules essentialModules, RoadData roadData)
    {
        // InitRoadPartObjects(roadData);

        if (objects == null) return;

        if (!roadData.doRoadPartObjects)
        {
            foreach (var obj in objects)
            {
                if (obj != null)
                    obj.SetActive(false);
            }

            return;
        }

        if (objects.Length != 2 || objects[0] == null) return;


        foreach (var obj in objects)
        {
            obj.SetActive(true);
        }

        var spline = essentialModules.path.Spline;
        var startTF = spline.DistanceToTF((startPosition));
        var endTF = Mathf.Min(1f, spline.DistanceToTF((startPosition + roadLenght)));
        spline.InterpolateAndGetTangentFast(startTF, out Vector3 startPos, out Vector3 startTangent);
        spline.InterpolateAndGetTangentFast(endTF, out Vector3 endPos, out Vector3 endTangent);

        objects[0].transform.forward = -startTangent;
        objects[1].transform.forward = endTangent;
        objects[0].SetActive(doRoadPartObjectStart);
        objects[1].SetActive(doRoadPartObjectEnd);
        objects[0].transform.position = startPos;
        objects[1].transform.position = endPos;
    }

    private void UpdateRailBarrier(RoadData roadData, float fromExtrusion, float toExtrusion,
        RoadEssentialModules essentialModules)
    {
        if (roadData.doRails)
        {
            modules.railObjectLCreate.MakeStatic = true;
            modules.railObjectRCreate.MakeStatic = true;

            modules.railRTrs.Transpose = roadData.railMeshTranspose;
            modules.railLTrs.Transpose = roadData.railMeshTranspose.WithX(-roadData.railMeshTranspose.x);

            modules.railLMesh.SetMaterial(0, roadData.railMaterial);
            modules.railRMesh.SetMaterial(0, roadData.railMaterial);
            modules.railLCaps.StartMaterial = roadData.railCapMaterial;
            modules.railRCaps.StartMaterial = roadData.railCapMaterial;
            modules.railLMesh.MaterialSetttings[0].KeepAspect = roadData.keepAspectUV;
            modules.railRMesh.MaterialSetttings[0].KeepAspect = roadData.keepAspectUV;
            modules.railLExtrusion.From = fromExtrusion;
            modules.railLExtrusion.To = toExtrusion;
            modules.railLExtrusion.Resolution = roadData.resolution;
            modules.railLExtrusion.Optimize = roadData.optimize;
            modules.railLExtrusion.AngleThreshold = roadData.angleThreshold;
            modules.railLExtrusion.CrossHardEdges = roadData.hardEdges;
            modules.railRExtrusion.From = fromExtrusion;
            modules.railRExtrusion.To = toExtrusion;
            modules.railRExtrusion.Resolution = roadData.resolution;
            modules.railRExtrusion.Optimize = roadData.optimize;
            modules.railRExtrusion.AngleThreshold = roadData.angleThreshold;
            modules.railRExtrusion.CrossHardEdges = roadData.hardEdges;

            var railShape = essentialModules.railShape.Shape.gameObject.GetComponent<CSRectangle>();
            railShape.Height = roadData.railHeight;
            railShape.Width = roadData.railWidth;

            essentialModules.createRailMesh.Collider = CGColliderEnum.None;
            essentialModules.createRailMesh.Combine = true;
            essentialModules.createRailMesh.MakeStatic = true;
            essentialModules.createRailMesh.Layer = roadData.railLayer;
        }

        if (roadData.doBarrier)
        {
            var spaceAfter = new FloatRegion(roadData.barrierSpacing);
            var translationX = new FloatRegion(roadData.translation.x);
            var translationY = new FloatRegion(roadData.translation.y);
            var translationZ = new FloatRegion(roadData.translation.z);

            modules.barrierLSpots.Groups[0].Items[0].Index = 0;
            modules.barrierLSpots.Groups[0].SpaceAfter = spaceAfter;
            modules.barrierLSpots.Groups[0].TranslationY = translationY;
            modules.barrierLSpots.Groups[0].TranslationX = -translationX;
            modules.barrierLSpots.Groups[0].TranslationZ = translationZ;
            modules.barrierLSpots.LastRepeating = 1;
            modules.barrierLSpots.Range = new FloatRegion(fromExtrusion, toExtrusion);
        
            modules.barrierRSpots.Groups[0].Items[0].Index = 0;
            modules.barrierRSpots.Groups[0].SpaceAfter = spaceAfter;
            modules.barrierRSpots.Groups[0].TranslationY = translationY;
            modules.barrierRSpots.Groups[0].TranslationX = translationX;
            modules.barrierRSpots.Groups[0].TranslationZ = translationZ;
            modules.barrierRSpots.LastRepeating = 1;
            modules.barrierRSpots.Range = new FloatRegion(fromExtrusion, toExtrusion);
        }
    }

    public void Refresh()
    {
        var fields = modules.GetType().GetFields();

        foreach (var field in fields)
        {
            if (field.FieldType.BaseType == typeof(CGModule))
            {
                ((CGModule) field.GetValue(modules)).Refresh();
            }

            if (field.FieldType.BaseType == typeof(TRSModuleBase))
            {
                ((TRSModuleBase) field.GetValue(modules)).Refresh();
            }
        }
    }

    public void ReCreate(CurvyGenerator generator)
    {
        var fields = modules.GetType().GetFields();

        foreach (var field in fields)
        {
            if (field.FieldType.BaseType == typeof(CGModule))
            {
                generator.DeleteModule((CGModule) field.GetValue(modules));

                field.SetValue(modules, default);
            }

            if (field.FieldType.BaseType == typeof(TRSModuleBase))
            {
                generator.DeleteModule((TRSModuleBase) field.GetValue(modules));

                field.SetValue(modules, default);
            }
        }

        objects = null;
    }

    public override void DeletePart()
    {
        roadGenerator.DeletePart(this);
    }
}