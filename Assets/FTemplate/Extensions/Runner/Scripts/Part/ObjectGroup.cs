using FluffyUnderware.Curvy.Generator;
using FluffyUnderware.Curvy.Generator.Modules;
using FluffyUnderware.DevTools;
using UnityEngine;

public class ObjectGroup : GeneratorPartBase
{
    public GameObject prefab;
    [ReadOnly]public ObjectGenerator objectGenerator;
    [ReadOnly]public ObjectGroupEssentialModules EssentialModules;

    [ReadOnly] public int index;
    public float MaxSplineLenght => objectGenerator.GetSplineLenght();

    [SerializeField] private ObjectGroupData objectGroupData;

    public ObjectGroupData Data => objectGroupData;
    public void Init(CurvyGenerator generator, InputGameObject inputGameObject, BuildRasterizedPath path, ObjectGenerator objectGenerator)
    {
        this.objectGenerator = objectGenerator;
        objectGroupData = new ObjectGroupData(objectGenerator);
        EssentialModules = new ObjectGroupEssentialModules();
        EssentialModules.volumeSpots = generator.AddModule<BuildVolumeSpots>();
        EssentialModules.createGameObject = generator.AddModule<CreateGameObject>();
        EssentialModules.Path = path;
        EssentialModules.Path.Resolution = 100;
        EssentialModules.InputGameObject = inputGameObject;

        EssentialModules.properties = new CGGameObjectProperties(prefab);        
        EssentialModules.volumeSpots.InPath.LinkTo(path.OutPath);
        EssentialModules.volumeSpots.InBounds.LinkTo(EssentialModules.InputGameObject.OutGameObject);
        EssentialModules.volumeSpots.OutSpots.LinkTo(EssentialModules.createGameObject.InSpots);
        EssentialModules.InputGameObject.OutGameObject.LinkTo(EssentialModules.createGameObject.InGameObjectArray);

        UpdateObjectGroupData();
    }
    
    public void UpdateObjectGroupData()
    {
        var from = objectGroupData.placeAt / MaxSplineLenght;
        var to = Mathf.Min(1f,(objectGroupData.placeAt + objectGroupData.groupLenght) / MaxSplineLenght);

        if (prefab != null)
        {
            InitPrefabData();
        }
        
        UpdateVolumeSpotsModule(from, to);
    }

    private void UpdateVolumeSpotsModule(float @from, float to)
    {
        EssentialModules.volumeSpots.Range = new FloatRegion(@from, to);
        EssentialModules.volumeSpots.Groups[0].SpaceAfter = new FloatRegion(objectGroupData.distanceBetween);
        EssentialModules.volumeSpots.Groups[0].RelativeTranslation = true;
        EssentialModules.volumeSpots.Groups[0].TranslationX = new FloatRegion(objectGroupData.translation.x);
        EssentialModules.volumeSpots.Groups[0].TranslationY = new FloatRegion(objectGroupData.translation.y);
        EssentialModules.volumeSpots.Groups[0].TranslationZ = new FloatRegion(objectGroupData.translation.z);
        EssentialModules.volumeSpots.Groups[0].RotationX = new FloatRegion(objectGroupData.rotation.x);
        EssentialModules.volumeSpots.Groups[0].RotationY = new FloatRegion(objectGroupData.rotation.y);
        EssentialModules.volumeSpots.Groups[0].RotationZ = new FloatRegion(objectGroupData.rotation.z);
        EssentialModules.volumeSpots.Groups[0].ScaleX = new FloatRegion(objectGroupData.scale.x);
        EssentialModules.volumeSpots.Groups[0].ScaleY = new FloatRegion(objectGroupData.scale.y);
        EssentialModules.volumeSpots.Groups[0].ScaleZ = new FloatRegion(objectGroupData.scale.z);
        EssentialModules.volumeSpots.Groups[0].RotationMode = objectGroupData.rotationMode;
        EssentialModules.volumeSpots.Groups[0].UniformScaling = objectGroupData.uniformScaling;
        EssentialModules.volumeSpots.Groups[0].RelativeTranslation = objectGroupData.relativeTranslation;
        EssentialModules.volumeSpots.Groups[0].Items[0].Index = index;
        EssentialModules.volumeSpots.Refresh();
        EssentialModules.createGameObject.Refresh();
    }

    private void InitPrefabData()
    {
        if (EssentialModules.properties.Object != prefab)
        {
            EssentialModules.properties = new CGGameObjectProperties(prefab);
        }

        for (int i = 0; i < EssentialModules.InputGameObject.GameObjects.Count; i++)
        {
            var o = EssentialModules.InputGameObject.GameObjects[i];
            if (o.Object == EssentialModules.properties.Object)
            {
                index = EssentialModules.InputGameObject.GameObjects.IndexOf(o);
                break;
            }

            if (EssentialModules.InputGameObject.GameObjects.IndexOf(o) !=
                EssentialModules.InputGameObject.GameObjects.Count - 1) continue;
            
            EssentialModules.InputGameObject.GameObjects.Add(EssentialModules.properties);
            index = EssentialModules.InputGameObject.GameObjects.Count - 1;
        }

        if (EssentialModules.InputGameObject.GameObjects.Count == 0)
        {
            EssentialModules.InputGameObject.GameObjects.Add(EssentialModules.properties);
            index = 0;
        }
        
        EssentialModules.InputGameObject.GameObjects[index] = EssentialModules.properties;
        EssentialModules.InputGameObject.Refresh();
    }

    public void Delete(CurvyGenerator generator)
    {
        generator.DeleteModule(EssentialModules.createGameObject);
        generator.DeleteModule(EssentialModules.volumeSpots);
        EssentialModules.InputGameObject.GameObjects.Remove(EssentialModules.properties);
    }

    public override void DeletePart()
    {
        objectGenerator.Delete(this);
    }
}